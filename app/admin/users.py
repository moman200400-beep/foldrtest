import csv
import io
from flask import render_template, request, session, redirect, url_for, make_response
from app.admin import admin_bp
from src.backend.core.extensions import db
from app.models import User, AuditLog, Ledger

@admin_bp.route('/users', methods=['GET', 'POST'])
def users_page():
    if 'user_id' not in session or session.get('role') != 'admin':
        return redirect(url_for('admin.login'))

    # 1. معالجة الإجراءات (تعديل رصيد، حظر، وتغيير صلاحيات)
    if request.method == 'POST':
        action = request.form.get('action')
        user = User.query.filter_by(uid=request.form.get('uid')).first()

        if user:
            if action == 'update_wallet':
                amount = float(request.form.get('amount', 0))
                user.wallet_balance += amount
                
                # إضافة سجل مالي للحركة في الليدجر (Wallet Ledger)
                trans_type = "إيداع" if amount > 0 else "خصم"
                note = f"تعديل إداري من قبل {session.get('role', 'admin')}"
                db.session.add(Ledger(user_id=user.id, trans_type=trans_type, amount=amount, description=note))
                
                # إضافة سجل أمني متقدم (Audit Log)
                db.session.add(AuditLog(admin_id=session['user_id'], action=f"تعديل محفظة {user.uid} بـ {amount}", ip_address=request.remote_addr))
                
            elif action == 'toggle_status':
                if user.role != 'admin':
                    user.status = 'banned' if user.status == 'active' else 'active'
                    db.session.add(AuditLog(admin_id=session['user_id'], action=f"تغيير حالة {user.uid} إلى {user.status}", ip_address=request.remote_addr))

            elif action == 'change_role':
                new_role = request.form.get('role')
                if new_role in ['admin', 'moderator', 'support', 'customer']:
                    user.role = new_role
                    db.session.add(AuditLog(admin_id=session['user_id'], action=f"تغيير صلاحية {user.uid} إلى {new_role}", ip_address=request.remote_addr))
                    
            elif action == 'update_notes':
                notes = request.form.get('internal_notes', '')
                user.internal_notes = notes
                db.session.add(AuditLog(admin_id=session['user_id'], action=f"تحديث ملاحظات العميل {user.uid}", ip_address=request.remote_addr))

            db.session.commit()
        return redirect(url_for('admin.users_page'))

    # ==========================================
    # 🌟 المنطق الواقعي: بناء استعلام البحث والفلترة أولاً
    # ==========================================
    search_query = request.args.get('search', '').strip()
    filter_role = request.args.get('role', 'all')
    
    query = User.query
    if search_query:
        query = query.filter((User.name.like(f"%{search_query}%")) | (User.phone.like(f"%{search_query}%")) | (User.uid.like(f"%{search_query}%")))
    
    if filter_role != 'all':
        if filter_role == 'banned': 
            query = query.filter_by(status='banned')
        else: 
            query = query.filter_by(role=filter_role)

    # ==========================================
    # 🌟 التصدير الذكي: يصدر نتائج الفلتر فقط
    # ==========================================
    if request.args.get('export') == 'csv':
        filtered_users = query.all() # جلب المستخدمين المفلترين فقط وليس الجميع
        
        si = io.StringIO()
        cw = csv.writer(si)
        cw.writerow(['المعرف (UID)', 'الاسم', 'الجوال', 'الصلاحية', 'الحالة', 'رصيد المحفظة', 'القيمة (LTV)']) # عناوين بالعربي للواقعية
        
        for u in filtered_users:
            cw.writerow([u.uid, u.name or 'غير محدد', u.phone or 'غير محدد', u.role, u.status, u.wallet_balance, u.lifetime_value])
        
        output = make_response(si.getvalue().encode('utf-8-sig')) # utf-8-sig يدعم فتح الملف في Excel العربي بدون مشاكل
        output.headers["Content-Disposition"] = "attachment; filename=Users_Export.csv"
        output.headers["Content-type"] = "text/csv"
        
        db.session.add(AuditLog(admin_id=session['user_id'], action=f"تصدير CSV لـ {len(filtered_users)} مستخدم", ip_address=request.remote_addr))
        db.session.commit()
        return output

    # 3. عرض الصفحة العادية مع نتائج الفلتر
    all_users = query.order_by(User.id.desc()).all()
    
    return render_template('users.html', users=all_users, search_query=search_query, current_filter=filter_role)


@admin_bp.route('/user/<uid>')
def user_details(uid):
    if 'user_id' not in session or session.get('role') != 'admin':
        return redirect(url_for('admin.login'))
        
    user = User.query.filter_by(uid=uid).first_or_404()
    
    # جلب الليدجر المالي
    ledger_entries = Ledger.query.filter_by(user_id=user.id).order_by(Ledger.id.desc()).all()
    
    # جلب الطلبات
    from app.models import Order
    orders = Order.query.filter_by(uid=user.uid).order_by(Order.id.desc()).all()
    
    return render_template('user_details.html', user=user, ledger=ledger_entries, orders=orders)

