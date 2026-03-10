import sys
import os
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..', '..'))
from flask import Blueprint, request, render_template, redirect, url_for, flash
from app.models import Ad
from src.backend.core.extensions import db
from werkzeug.utils import secure_filename
import os

ads_admin_bp = Blueprint('admin_ads', __name__, url_prefix='/admin')

UPLOAD_FOLDER = 'app/static/uploads'
ALLOWED_EXTENSIONS = {'png', 'jpg', 'jpeg', 'gif', 'webp'}

def allowed_file(filename):
    return '.' in filename and filename.rsplit('.', 1)[1].lower() in ALLOWED_EXTENSIONS

@ads_admin_bp.route('/ads', methods=['GET'])
def list_ads():
    """عرض قائمة الإعلانات"""
    ads = Ad.query.order_by(Ad.position).all()
    return render_template('admin/ads.html', ads=ads)

@ads_admin_bp.route('/ads/add', methods=['GET', 'POST'])
def add_ad():
    """إضافة إعلان جديد"""
    if request.method == 'POST':
        try:
            title = request.form.get('title', '').strip()
            description = request.form.get('description', '').strip()
            bg_color = request.form.get('bg_color', '#1E293B').strip()
            link = request.form.get('link', '#').strip()
            position = request.form.get('position', '0')
            is_active = request.form.get('is_active') == 'on'
            
            if not title:
                flash('العنوان مطلوب', 'error')
                return redirect(url_for('admin_ads.add_ad'))
            
            # معالجة الصورة
            image_url = '/uploads/default-ad.png'
            if 'image' in request.files and request.files['image'].filename:
                file = request.files['image']
                if file and allowed_file(file.filename):
                    filename = secure_filename(file.filename)
                    # إضافة timestamp لتجنب التضارب في الأسماء
                    import time
                    filename = f"ad_{int(time.time())}_{filename}"
                    file.save(os.path.join(UPLOAD_FOLDER, filename))
                    image_url = f'/uploads/{filename}'
            
            ad = Ad(
                title=title,
                description=description,
                image=image_url,
                bg_color=bg_color,
                link=link,
                position=int(position) if position else 0,
                is_active=is_active
            )
            db.session.add(ad)
            db.session.commit()
            
            flash('تم إضافة الإعلان بنجاح', 'success')
            return redirect(url_for('admin_ads.list_ads'))
        except Exception as e:
            db.session.rollback()
            flash(f'خطأ: {str(e)}', 'error')
            return redirect(url_for('admin_ads.add_ad'))
    
    return render_template('admin/ads_form.html', action='add')

@ads_admin_bp.route('/ads/edit/<int:ad_id>', methods=['GET', 'POST'])
def edit_ad(ad_id):
    """تعديل إعلان"""
    ad = Ad.query.get_or_404(ad_id)
    
    if request.method == 'POST':
        try:
            ad.title = request.form.get('title', '').strip() or ad.title
            ad.description = request.form.get('description', '').strip()
            ad.bg_color = request.form.get('bg_color', '#1E293B').strip()
            ad.link = request.form.get('link', '#').strip()
            ad.position = int(request.form.get('position', ad.position)) if request.form.get('position') else ad.position
            ad.is_active = request.form.get('is_active') == 'on'
            
            # معالجة الصورة الجديدة
            if 'image' in request.files and request.files['image'].filename:
                file = request.files['image']
                if file and allowed_file(file.filename):
                    filename = secure_filename(file.filename)
                    import time
                    filename = f"ad_{int(time.time())}_{filename}"
                    file.save(os.path.join(UPLOAD_FOLDER, filename))
                    ad.image = f'/uploads/{filename}'
            
            db.session.commit()
            flash('تم تحديث الإعلان بنجاح', 'success')
            return redirect(url_for('admin_ads.list_ads'))
        except Exception as e:
            db.session.rollback()
            flash(f'خطأ: {str(e)}', 'error')
            return redirect(url_for('admin_ads.edit_ad', ad_id=ad_id))
    
    return render_template('admin/ads_form.html', ad=ad, action='edit')

@ads_admin_bp.route('/ads/delete/<int:ad_id>', methods=['POST'])
def delete_ad(ad_id):
    """حذف إعلان"""
    try:
        ad = Ad.query.get_or_404(ad_id)
        db.session.delete(ad)
        db.session.commit()
        flash('تم حذف الإعلان بنجاح', 'success')
    except Exception as e:
        db.session.rollback()
        flash(f'خطأ: {str(e)}', 'error')
    
    return redirect(url_for('admin_ads.list_ads'))

@ads_admin_bp.route('/ads/toggle/<int:ad_id>', methods=['POST'])
def toggle_ad(ad_id):
    """تفعيل/تعطيل الإعلان"""
    try:
        ad = Ad.query.get_or_404(ad_id)
        ad.is_active = not ad.is_active
        db.session.commit()
        flash(f"تم {'تفعيل' if ad.is_active else 'تعطيل'} الإعلان", 'success')
    except Exception as e:
        db.session.rollback()
        flash(f'خطأ: {str(e)}', 'error')
    
    return redirect(url_for('admin_ads.list_ads'))
