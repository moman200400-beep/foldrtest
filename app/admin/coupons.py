from flask import Blueprint, render_template, request, flash, redirect, url_for, session
from src.backend.core.extensions import db
from src.backend.models.coupon import Coupon
import datetime

coupons_bp = Blueprint('coupons', __name__, url_prefix='/admin/coupons')

@coupons_bp.route('/')
def index():
    if 'user_id' not in session or session.get('role') != 'admin':
        return redirect(url_for('admin.login'))
        
    current_admin = session.get('name', 'Admin')
    coupons_list = Coupon.query.order_by(Coupon.created_at.desc()).all()
    return render_template('admin/coupons/index.html', coupons=coupons_list, current_admin=current_admin)

@coupons_bp.route('/add', methods=['GET', 'POST'])
def add():
    if 'user_id' not in session or session.get('role') != 'admin':
        return redirect(url_for('admin.login'))
        
    current_admin = session.get('name', 'Admin')
    if request.method == 'POST':
        code = request.form.get('code', '').strip().upper()
        discount_type = request.form.get('discount_type', 'percentage')
        discount_value = float(request.form.get('discount_value', 0))
        min_order_amount = float(request.form.get('min_order_amount', 0))
        usage_limit = int(request.form.get('usage_limit', 0))
        
        valid_until_str = request.form.get('valid_until')
        valid_until = None
        if valid_until_str:
            try:
                valid_until = datetime.datetime.strptime(valid_until_str, '%Y-%m-%dT%H:%M')
            except ValueError:
                pass
                
        is_active = request.form.get('is_active') == 'on'

        if not code or discount_value <= 0:
            flash('يجب إدخال كود صحيح وقيمة خصم أكبر من صفر', 'danger')
            return redirect(url_for('coupons.add'))

        existing = Coupon.query.filter_by(code=code).first()
        if existing:
            flash('هذا الكود موجود مسبقاً', 'danger')
            return redirect(url_for('coupons.add'))

        new_coupon = Coupon(
            code=code,
            discount_type=discount_type,
            discount_value=discount_value,
            min_order_amount=min_order_amount,
            usage_limit=usage_limit,
            valid_until=valid_until,
            is_active=is_active
        )

        db.session.add(new_coupon)
        db.session.commit()
        flash('تم إضافة الكوبون بنجاح', 'success')
        return redirect(url_for('coupons.index'))

    return render_template('admin/coupons/form.html', current_admin=current_admin)

@coupons_bp.route('/delete/<int:coupon_id>', methods=['POST'])
def delete(coupon_id):
    if 'user_id' not in session or session.get('role') != 'admin':
        return redirect(url_for('admin.login'))
        
    coupon = Coupon.query.get_or_404(coupon_id)
    db.session.delete(coupon)
    db.session.commit()
    flash('تم الحذف بنجاح', 'success')
    return redirect(url_for('coupons.index'))

@coupons_bp.route('/toggle/<int:coupon_id>', methods=['POST'])
def toggle(coupon_id):
    if 'user_id' not in session or session.get('role') != 'admin':
        return redirect(url_for('admin.login'))
        
    coupon = Coupon.query.get_or_404(coupon_id)
    coupon.is_active = not coupon.is_active
    db.session.commit()
    flash(f'تم {"تفعيل" if coupon.is_active else "تعطيل"} الكوبون بنجاح', 'success')
    return redirect(url_for('coupons.index'))
