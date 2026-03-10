import csv
import io
import json
import datetime
from flask import render_template, request, session, redirect, url_for, jsonify, make_response
from app.admin import admin_bp
from src.backend.core.extensions import db
from app.models import Neighborhood, Driver, DeliveryLog, Order, AuditLog
from src.backend.models.order import OrderTimeline
from src.backend.models.courier import Courier

# ── خريطة الحالات ──
STATUS_LABELS = {
    'pending':    'قيد المعالجة',
    'processing': 'جاري التحضير',
    'shipping':   'في الطريق',
    'completed':  'مكتمل',
    'cancelled':  'ملغي',
    'refunded':   'مسترجع',
    'paid':       'مدفوع',
}

STATUS_COLORS = {
    'pending':    ('#fbbf24', 'rgba(251,191,36,.15)'),
    'processing': ('#60a5fa', 'rgba(96,165,250,.15)'),
    'shipping':   ('#f97316', 'rgba(249,115,22,.15)'),
    'completed':  ('#34d399', 'rgba(52,211,153,.15)'),
    'cancelled':  ('#f87171', 'rgba(248,113,113,.15)'),
    'refunded':   ('#a78bfa', 'rgba(167,139,250,.15)'),
    'paid':       ('#34d399', 'rgba(52,211,153,.15)'),
}

# ─────────────────────────────────────────────────────────
# صفحة الإدارة الرئيسية لنظام التوصيل
# ─────────────────────────────────────────────────────────
@admin_bp.route('/delivery')
def delivery_page():
    if 'user_id' not in session or session.get('role') != 'admin':
        return redirect(url_for('admin.login'))

    neighborhoods = Neighborhood.query.order_by(Neighborhood.id.desc()).all()
    drivers = Driver.query.order_by(Driver.id.desc()).all()

    active_neighborhoods = Neighborhood.query.filter_by(is_active=True).count()
    active_drivers = Driver.query.filter_by(is_active=True).count()
    total_deliveries = DeliveryLog.query.count()

    # ── طلبات اليوم ──
    today_start = datetime.datetime.now().replace(hour=0, minute=0, second=0, microsecond=0)
    today_orders = Order.query.filter(
        Order.created_at >= today_start
    ).order_by(Order.id.desc()).all()

    for o in today_orders:
        try:
            o.parsed_items = json.loads(o.cart_items)
        except Exception:
            o.parsed_items = []

    today_orders_count = len(today_orders)
    today_sales = sum(o.total_amount for o in today_orders)
    today_delivery_revenue = sum(o.delivery_price or 0 for o in today_orders)
    today_completed = sum(1 for o in today_orders if o.status in ('completed', 'paid'))
    today_pending = sum(1 for o in today_orders if o.status == 'pending')
    today_shipping = sum(1 for o in today_orders if o.status == 'shipping')

    # أكثر حي طلبات اليوم
    hood_counts = {}
    for o in today_orders:
        h = o.delivery_neighborhood or 'غير محدد'
        hood_counts[h] = hood_counts.get(h, 0) + 1
    top_hood = max(hood_counts, key=hood_counts.get) if hood_counts else '-'

    return render_template('delivery.html',
        neighborhoods=neighborhoods,
        drivers=drivers,
        today_orders=today_orders,
        active_neighborhoods=active_neighborhoods,
        active_drivers=active_drivers,
        total_deliveries=total_deliveries,
        today_orders_count=today_orders_count,
        today_sales=today_sales,
        today_delivery_revenue=today_delivery_revenue,
        today_completed=today_completed,
        today_pending=today_pending,
        today_shipping=today_shipping,
        top_hood=top_hood,
        status_labels=STATUS_LABELS,
        status_colors=STATUS_COLORS,
    )

# ─────────────────────────────────────────────────────────
# تغيير حالة الطلب سريعاً من لوحة التوصيل
# ─────────────────────────────────────────────────────────
@admin_bp.route('/delivery/order/status', methods=['POST'])
def delivery_order_status():
    if 'user_id' not in session or session.get('role') != 'admin':
        return jsonify({'ok': False}), 403

    order_id = request.form.get('order_id')
    new_status = request.form.get('status')
    order = Order.query.get(order_id)

    if order and order.status != new_status:
        old_status = order.status
        order.status = new_status
        db.session.add(AuditLog(
            admin_id=session['user_id'],
            action=f"تغيير حالة الطلب #{order.id} من {STATUS_LABELS.get(old_status, old_status)} إلى {STATUS_LABELS.get(new_status, new_status)} (من لوحة التوصيل)",
            ip_address=request.remote_addr
        ))
        db.session.add(OrderTimeline(
            order_id=order.id,
            status=new_status,
            notes="تم تغيير الحالة من لوحة التوصيل"
        ))
        db.session.commit()

    return redirect(url_for('admin.delivery_page') + '#today')

# ─────────────────────────────────────────────────────────
# CRUD الأحياء
# ─────────────────────────────────────────────────────────
@admin_bp.route('/delivery/neighborhood/add', methods=['POST'])
def add_neighborhood():
    if 'user_id' not in session or session.get('role') != 'admin':
        return redirect(url_for('admin.login'))
    
    is_active = True
    if 'is_active' in request.form and not request.form.get('is_active'):
        is_active = False

    n = Neighborhood(
        name=request.form.get('name', '').strip(),
        delivery_price=float(request.form.get('delivery_price', 0)),
        is_active=is_active
    )

    db.session.add(n)
    db.session.add(AuditLog(admin_id=session['user_id'], action=f"إضافة حي: {n.name}", ip_address=request.remote_addr))
    db.session.commit()
    return redirect(url_for('admin.delivery_page') + '#neighborhoods')

@admin_bp.route('/delivery/neighborhood/edit/<int:nid>', methods=['POST'])
def edit_neighborhood(nid):
    if 'user_id' not in session or session.get('role') != 'admin':
        return redirect(url_for('admin.login'))
    n = Neighborhood.query.get_or_404(nid)
    n.name = request.form.get('name', n.name).strip()
    n.delivery_price = float(request.form.get('delivery_price', n.delivery_price))
    n.is_active = request.form.get('is_active') == 'on'
    db.session.add(AuditLog(admin_id=session['user_id'], action=f"تعديل حي: {n.name}", ip_address=request.remote_addr))
    db.session.commit()
    return redirect(url_for('admin.delivery_page') + '#neighborhoods')

@admin_bp.route('/delivery/neighborhood/delete/<int:nid>', methods=['POST'])
def delete_neighborhood(nid):
    if 'user_id' not in session or session.get('role') != 'admin':
        return jsonify({'ok': False}), 403
    n = Neighborhood.query.get_or_404(nid)
    db.session.add(AuditLog(admin_id=session['user_id'], action=f"حذف حي: {n.name}", ip_address=request.remote_addr))
    db.session.delete(n)
    db.session.commit()
    return redirect(url_for('admin.delivery_page') + '#neighborhoods')

# ─────────────────────────────────────────────────────────
# CRUD المناديب
# ─────────────────────────────────────────────────────────
@admin_bp.route('/delivery/driver/add', methods=['POST'])
def add_driver():
    if 'user_id' not in session or session.get('role') != 'admin':
        return redirect(url_for('admin.login'))
    drv = Driver(
        name=request.form.get('name', '').strip(),
        phone=request.form.get('phone', '').strip(),
        max_daily_orders=int(request.form.get('max_daily_orders', 20)),
        commission_rate=float(request.form.get('commission_rate', 10)),
        shift_start=request.form.get('shift_start', '08:00'),
        shift_end=request.form.get('shift_end', '22:00'),
    )
    db.session.add(drv)
    db.session.flush()  # get drv.id
    # Auto-sync: also create matching Courier record
    courier = Courier(name=drv.name, phone=drv.phone, status=True)
    db.session.add(courier)
    db.session.add(AuditLog(admin_id=session['user_id'], action=f"إضافة مندوب: {drv.name}", ip_address=request.remote_addr))
    db.session.commit()
    return redirect(url_for('admin.delivery_page') + '#drivers')

@admin_bp.route('/delivery/driver/edit/<int:did>', methods=['POST'])
def edit_driver(did):
    if 'user_id' not in session or session.get('role') != 'admin':
        return redirect(url_for('admin.login'))
    drv = Driver.query.get_or_404(did)
    drv.name = request.form.get('name', drv.name).strip()
    drv.phone = request.form.get('phone', drv.phone).strip()
    drv.is_active = request.form.get('is_active') == 'on'
    drv.max_daily_orders = int(request.form.get('max_daily_orders', drv.max_daily_orders))
    drv.commission_rate = float(request.form.get('commission_rate', drv.commission_rate))
    drv.shift_start = request.form.get('shift_start', drv.shift_start)
    drv.shift_end = request.form.get('shift_end', drv.shift_end)
    db.session.add(AuditLog(admin_id=session['user_id'], action=f"تعديل مندوب: {drv.name}", ip_address=request.remote_addr))
    # Auto-sync: update matching Courier
    courier = Courier.query.filter_by(phone=drv.phone).first()
    if not courier:
        courier = Courier.query.filter_by(name=drv.name).first()
    if courier:
        courier.name = drv.name
        courier.phone = drv.phone
        courier.status = drv.is_active
    db.session.commit()
    return redirect(url_for('admin.delivery_page') + '#drivers')

@admin_bp.route('/delivery/driver/delete/<int:did>', methods=['POST'])
def delete_driver(did):
    if 'user_id' not in session or session.get('role') != 'admin':
        return redirect(url_for('admin.login'))
    drv = Driver.query.get_or_404(did)
    db.session.add(AuditLog(admin_id=session['user_id'], action=f"حذف مندوب: {drv.name}", ip_address=request.remote_addr))
    # Auto-sync: delete matching Courier
    courier = Courier.query.filter_by(name=drv.name).first()
    if not courier:
        courier = Courier.query.filter_by(phone=drv.phone).first()
    if courier:
        db.session.delete(courier)
    db.session.delete(drv)
    db.session.commit()
    return redirect(url_for('admin.delivery_page') + '#drivers')

# ─────────────────────────────────────────────────────────
# تصدير تقرير التوصيل CSV
# ─────────────────────────────────────────────────────────
@admin_bp.route('/delivery/export')
def export_delivery():
    if 'user_id' not in session or session.get('role') != 'admin':
        return redirect(url_for('admin.login'))
    logs = DeliveryLog.query.order_by(DeliveryLog.id.desc()).all()
    si = io.StringIO()
    cw = csv.writer(si)
    cw.writerow(['#', 'رقم الطلب', 'المندوب', 'سعر التوصيل', 'الحالة', 'التاريخ'])
    for l in logs:
        driver = Driver.query.get(l.driver_id) if l.driver_id else None
        cw.writerow([
            l.id, l.order_id or '-',
            driver.name if driver else '-',
            l.delivery_price,
            l.status,
            l.created_at.strftime('%Y-%m-%d %H:%M')
        ])
    out = make_response(si.getvalue().encode('utf-8-sig'))
    out.headers["Content-Disposition"] = "attachment; filename=Delivery_Report.csv"
    out.headers["Content-type"] = "text/csv"
    return out