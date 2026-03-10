import csv
import io
import json
from flask import render_template, request, session, redirect, url_for, make_response
from app.admin import admin_bp
from src.backend.core.extensions import db
from app.models import Order, Ledger, User, AuditLog
from src.backend.models.order import OrderTimeline
from src.backend.models.payment_log import PaymentLog

# ── خريطة الحالات بالعربي ──
STATUS_LABELS = {
    'pending':    'قيد المعالجة',
    'processing': 'جاري التحضير',
    'shipping':   'في الطريق',
    'completed':  'مكتمل',
    'cancelled':  'ملغي',
    'refunded':   'مسترجع',
    'paid':       'مدفوع',
}

@admin_bp.route('/orders', methods=['GET', 'POST'])
def orders_page():
    if 'user_id' not in session or session.get('role') != 'admin':
        return redirect(url_for('admin.login'))

    if request.method == 'POST':
        order_id = request.form.get('order_id')
        new_status = request.form.get('status')
        order = Order.query.get(order_id)

        if order and order.status != new_status:
            old_status = order.status
            order.status = new_status

            # المعالجة المحاسبية التلقائية
            if new_status in ['completed', 'paid']:
                existing_income = Ledger.query.filter_by(
                    order_id=order.id, trans_type='income').first()
                if not existing_income:
                    db.session.add(Ledger(
                        trans_type="income",
                        amount=order.total_amount,
                        description=f"إيراد طلب #{order.id}",
                        order_id=order.id
                    ))
                    user = User.query.filter_by(uid=order.uid).first()
                    if user:
                        user.lifetime_value += order.total_amount

            elif new_status == 'refunded':
                db.session.add(Ledger(
                    trans_type="refund",
                    amount=-order.total_amount,
                    description=f"استرجاع أموال لطلب #{order.id}",
                    order_id=order.id
                ))
                user = User.query.filter_by(uid=order.uid).first()
                if user:
                    user.lifetime_value = max(0, user.lifetime_value - order.total_amount)

            label = STATUS_LABELS.get(new_status, new_status)
            db.session.add(AuditLog(
                admin_id=session['user_id'],
                action=f"تغيير حالة الطلب #{order.id} من {STATUS_LABELS.get(old_status, old_status)} إلى {label}",
                ip_address=request.remote_addr
            ))
            
            # تسجيل الحالة في السجل الزمني
            db.session.add(OrderTimeline(
                order_id=order.id, 
                status=new_status, 
                notes=f"تم تغيير الحالة بواسطة المشرف"
            ))
            
            db.session.commit()

        return redirect(url_for('admin.orders_page'))

    # البحث والفلترة
    search_query = request.args.get('search', '').strip()
    filter_status = request.args.get('status', 'all')

    query = Order.query
    if search_query:
        query = query.filter(
            (Order.id.like(f"%{search_query}%")) |
            (Order.customer_name.like(f"%{search_query}%")) |
            (Order.customer_phone.like(f"%{search_query}%"))
        )

    if filter_status != 'all':
        query = query.filter_by(status=filter_status)

    # تصدير CSV
    if request.args.get('export') == 'csv':
        filtered_orders = query.order_by(Order.id.desc()).all()
        si = io.StringIO()
        cw = csv.writer(si)
        cw.writerow(['رقم الطلب', 'التاريخ', 'اسم العميل', 'الجوال',
                     'العنوان', 'الحي', 'سعر التوصيل', 'رابط الموقع',
                     'المبلغ', 'طريقة الدفع', 'الحالة'])
        for o in filtered_orders:
            cw.writerow([
                o.id,
                o.created_at.strftime('%Y-%m-%d %H:%M'),
                o.customer_name,
                o.customer_phone,
                o.address_details or o.address,
                o.delivery_neighborhood,
                o.delivery_price,
                o.location_link or '',
                o.total_amount,
                o.payment_method,
                STATUS_LABELS.get(o.status, o.status)
            ])
        output = make_response(si.getvalue().encode('utf-8-sig'))
        output.headers["Content-Disposition"] = "attachment; filename=Orders_Export.csv"
        output.headers["Content-type"] = "text/csv"
        return output

    all_orders = query.order_by(Order.id.desc()).all()
    for o in all_orders:
        try:
            o.parsed_items = json.loads(o.cart_items)
        except Exception:
            o.parsed_items = []

    return render_template(
        'orders.html',
        orders=all_orders,
        search_query=search_query,
        current_filter=filter_status,
        status_labels=STATUS_LABELS
    )


@admin_bp.route('/order/<int:order_id>/invoice')
def order_invoice(order_id):
    if 'user_id' not in session or session.get('role') != 'admin':
        return redirect(url_for('admin.login'))

    order = Order.query.get_or_404(order_id)
    try:
        order.parsed_items = json.loads(order.cart_items)
    except Exception:
        order.parsed_items = []

    db.session.add(AuditLog(
        admin_id=session['user_id'],
        action=f"طباعة/استخراج بوليصة الطلب #{order.id}",
        ip_address=request.remote_addr
    ))
    db.session.commit()

    return render_template('invoice.html', order=order)

@admin_bp.route('/order/<int:order_id>/details')
def order_details(order_id):
    if 'user_id' not in session or session.get('role') != 'admin':
        return redirect(url_for('admin.login'))

    order = Order.query.get_or_404(order_id)
    try:
        order.parsed_items = json.loads(order.cart_items)
    except Exception:
        order.parsed_items = []

    # حساب هامش الربح
    profit_margin = 0.0
    if order.total_cost and order.total_cost > 0:
        profit_margin = order.total_amount - order.total_cost

    timeline = OrderTimeline.query.filter_by(order_id=order.id).order_by(OrderTimeline.created_at.desc()).all()
    payments = PaymentLog.query.filter_by(order_id=order.id).order_by(PaymentLog.created_at.desc()).all()

    return render_template('order_details.html', order=order, timeline=timeline, payments=payments, profit_margin=profit_margin, status_labels=STATUS_LABELS)