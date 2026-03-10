import json
from datetime import datetime, timedelta
from flask import render_template, request, session, redirect, url_for
from app.admin import admin_bp
from src.backend.core.extensions import db
from app.models import Cart, User, AuditLog

@admin_bp.route('/carts', methods=['GET', 'POST'])
def carts_page():
    if 'user_id' not in session or session.get('role') != 'admin':
        return redirect(url_for('admin.login'))

    # معالجة حذف سلة مستخدم
    if request.method == 'POST':
        action = request.form.get('action')
        if action == 'delete_cart':
            uid = request.form.get('uid')
            cart = Cart.query.filter_by(uid=uid).first()
            if cart:
                db.session.delete(cart)
                db.session.add(AuditLog(admin_id=session['user_id'], action=f"حذف سلة المستخدم {uid}", ip_address=request.remote_addr))
                db.session.commit()
                
        elif action == 'send_reminder':
            uid = request.form.get('uid')
            # من هنا يمكنك ربط بوابة رسائل SMS أو خدمة بريد إلكتروني
            # نحاكي الإرسال بتسجيل العملية في السجل الأمني
            db.session.add(AuditLog(admin_id=session['user_id'], action=f"إرسال تذكير سلة مهجورة للمستخدم {uid}", ip_address=request.remote_addr))
            db.session.commit()
            
        return redirect(url_for('admin.carts_page'))

    # جلب جميع السلات
    all_carts = Cart.query.order_by(Cart.last_updated.desc()).all()
    
    # معالجة البيانات للعرض (تحليل السلات المهجورة)
    processed_carts = []
    now = datetime.utcnow()
    
    for c in all_carts:
        items = json.loads(c.items)
        if not items: continue # تجاهل السلات الفارغة تماماً
        
        # حساب إجمالي قيمة السلة
        total_value = sum(float(item.get('price', 0)) * int(item.get('quantity', 1)) for item in items)
        
        # جلب بيانات العميل لمعرفة اسمه
        user = User.query.filter_by(uid=c.uid).first()
        customer_name = user.name if user and user.name else "زائر غير مسجل"
        customer_phone = user.phone if user and user.phone else "لا يوجد"

        # تحديد هل هي مهجورة؟ (لم تتحدث منذ 24 ساعة)
        hours_since_update = (now - c.last_updated).total_seconds() / 3600
        is_abandoned = hours_since_update > 24

        processed_carts.append({
            "uid": c.uid,
            "customer_name": customer_name,
            "customer_phone": customer_phone,
            "items_count": len(items),
            "items_details": "<br>".join([f"- {i['name']} (x{i['quantity']})" for i in items]),
            "total_value": total_value,
            "last_updated": c.last_updated.strftime('%Y-%m-%d %H:%M'),
            "is_abandoned": is_abandoned,
            "hours_idle": int(hours_since_update)
        })

    return render_template('carts.html', carts=processed_carts)
