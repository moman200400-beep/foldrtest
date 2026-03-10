from flask import render_template, request, session, redirect, url_for
from app.admin import admin_bp
from src.backend.core.extensions import db
from app.models import Notification, Product, Order

# دالة ذكية تفحص النظام وتولد إشعارات تلقائية
def generate_system_alerts():
    # 1. فحص المخزون المنخفض (أقل من 5)
    low_stock_products = Product.query.filter(Product.stock <= 5).all()
    for p in low_stock_products:
        # التأكد من عدم تكرار نفس الإشعار إذا كان غير مقروء
        existing = Notification.query.filter_by(title=f"تنبيه مخزون: {p.name}", is_read=False).first()
        if not existing:
            db.session.add(Notification(
                title=f"تنبيه مخزون: {p.name}",
                message=f"المنتج '{p.name}' أوشك على النفاد. المتبقي: {p.stock} فقط!",
                type="warning" if p.stock > 0 else "danger"
            ))

    # 2. فحص الطلبات ذات القيمة العالية (أكثر من 500 ريال)
    high_value_orders = Order.query.filter(Order.total_amount >= 500, Order.status == 'pending').all()
    for o in high_value_orders:
        existing = Notification.query.filter_by(title=f"طلب ضخم! #{o.id}", is_read=False).first()
        if not existing:
            db.session.add(Notification(
                title=f"طلب ضخم! #{o.id}",
                message=f"لقد تلقيت طلباً بقيمة {o.total_amount} ر.س من العميل {o.customer_name}. يرجى مراجعته فوراً!",
                type="success"
            ))
    db.session.commit()

@admin_bp.route('/notifications', methods=['GET', 'POST'])
def notifications_page():
    if 'user_id' not in session or session.get('role') != 'admin':
        return redirect(url_for('admin.login'))

    # معالجة قراءة الإشعارات
    if request.method == 'POST':
        action = request.form.get('action')
        if action == 'mark_all_read':
            unread_notifs = Notification.query.filter_by(is_read=False).all()
            for n in unread_notifs:
                n.is_read = True
            db.session.commit()
        return redirect(url_for('admin.notifications_page'))

    # تشغيل الفاحص الذكي قبل عرض الصفحة
    generate_system_alerts()

    # جلب الإشعارات
    all_notifs = Notification.query.order_by(Notification.is_read.asc(), Notification.id.desc()).limit(50).all()
    
    return render_template('notifications.html', notifications=all_notifs)
