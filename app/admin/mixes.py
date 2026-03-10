import sys
import os
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..', '..'))
from flask import Blueprint, request, render_template, redirect, url_for, flash
from src.backend.models.mix import MixFlavor, MixMood, MixSize, MixSetting, CustomMix
from src.backend.core.extensions import db

mixes_bp = Blueprint('admin_mixes', __name__, url_prefix='/admin/mixes')

# --- SECTION: Settings ---
@mixes_bp.route('/settings', methods=['GET', 'POST'])
def mix_settings():
    setting = MixSetting.query.first()
    if not setting:
        setting = MixSetting()
        db.session.add(setting)
        db.session.commit()
        
    if request.method == 'POST':
        setting.max_flavors = int(request.form.get('max_flavors', 3))
        setting.min_percentage = int(request.form.get('min_percentage', 10))
        setting.max_percentage = int(request.form.get('max_percentage', 100))
        db.session.commit()
        flash("تم تحديث إعدادات الخلط بنجاح", "success")
        return redirect(url_for('admin_mixes.mix_settings'))
        
    return render_template('admin/mixes/settings.html', setting=setting)

# --- SECTION: Flavors ---
@mixes_bp.route('/flavors', methods=['GET'])
def list_flavors():
    flavors = MixFlavor.query.all()
    return render_template('admin/mixes/flavors.html', flavors=flavors)

@mixes_bp.route('/flavors/add', methods=['GET', 'POST'])
def add_flavor():
    if request.method == 'POST':
        name = request.form.get('name')
        icon = request.form.get('icon', '🔥')
        category = request.form.get('category', 'عام')
        base_price = float(request.form.get('base_price', 0.0))
        is_active = request.form.get('is_active') == 'on'
        
        flavor = MixFlavor(name=name, icon=icon, category=category, base_price=base_price, is_active=is_active)
        db.session.add(flavor)
        db.session.commit()
        flash("تمت إضافة النكهة بنجاح", "success")
        return redirect(url_for('admin_mixes.list_flavors'))
    
    return render_template('admin/mixes/flavor_form.html', action='add')

@mixes_bp.route('/flavors/edit/<int:id>', methods=['GET', 'POST'])
def edit_flavor(id):
    flavor = MixFlavor.query.get_or_404(id)
    if request.method == 'POST':
        flavor.name = request.form.get('name')
        flavor.icon = request.form.get('icon', '🔥')
        flavor.category = request.form.get('category', 'عام')
        flavor.base_price = float(request.form.get('base_price', 0.0))
        flavor.is_active = request.form.get('is_active') == 'on'
        db.session.commit()
        flash("تم تعديل النكهة بنجاح", "success")
        return redirect(url_for('admin_mixes.list_flavors'))
        
    return render_template('admin/mixes/flavor_form.html', action='edit', flavor=flavor)

@mixes_bp.route('/flavors/delete/<int:id>', methods=['POST'])
def delete_flavor(id):
    flavor = MixFlavor.query.get_or_404(id)
    db.session.delete(flavor)
    db.session.commit()
    flash("تم حذف النكهة بنجاح", "success")
    return redirect(url_for('admin_mixes.list_flavors'))

# --- SECTION: Moods ---
@mixes_bp.route('/moods', methods=['GET'])
def list_moods():
    moods = MixMood.query.all()
    return render_template('admin/mixes/moods.html', moods=moods)

@mixes_bp.route('/moods/add', methods=['GET', 'POST'])
def add_mood():
    if request.method == 'POST':
        name = request.form.get('name')
        icon = request.form.get('icon', '🌟')
        description = request.form.get('description', '')
        is_active = request.form.get('is_active') == 'on'
        
        mood = MixMood(name=name, icon=icon, description=description, is_active=is_active)
        db.session.add(mood)
        db.session.commit()
        flash("تمت إضافة المزاج بنجاح", "success")
        return redirect(url_for('admin_mixes.list_moods'))
        
    return render_template('admin/mixes/mood_form.html', action='add')

@mixes_bp.route('/moods/edit/<int:id>', methods=['GET', 'POST'])
def edit_mood(id):
    mood = MixMood.query.get_or_404(id)
    if request.method == 'POST':
        mood.name = request.form.get('name')
        mood.icon = request.form.get('icon', '🌟')
        mood.description = request.form.get('description', '')
        mood.is_active = request.form.get('is_active') == 'on'
        db.session.commit()
        flash("تم تعديل المزاج بنجاح", "success")
        return redirect(url_for('admin_mixes.list_moods'))
        
    return render_template('admin/mixes/mood_form.html', action='edit', mood=mood)

@mixes_bp.route('/moods/delete/<int:id>', methods=['POST'])
def delete_mood(id):
    mood = MixMood.query.get_or_404(id)
    db.session.delete(mood)
    db.session.commit()
    flash("تم حذف المزاج بنجاح", "success")
    return redirect(url_for('admin_mixes.list_moods'))

# --- SECTION: Sizes ---
@mixes_bp.route('/sizes', methods=['GET'])
def list_sizes():
    sizes = MixSize.query.order_by(MixSize.sort_order).all()
    return render_template('admin/mixes/sizes.html', sizes=sizes)

@mixes_bp.route('/sizes/add', methods=['GET', 'POST'])
def add_size():
    if request.method == 'POST':
        name = request.form.get('name')
        type = request.form.get('type', 'head')
        price = float(request.form.get('price', 0.0))
        sort_order = int(request.form.get('sort_order', 0))
        is_active = request.form.get('is_active') == 'on'
        
        size = MixSize(name=name, type=type, price=price, sort_order=sort_order, is_active=is_active)
        db.session.add(size)
        db.session.commit()
        flash("تمت إضافة الحجم بنجاح", "success")
        return redirect(url_for('admin_mixes.list_sizes'))
        
    return render_template('admin/mixes/size_form.html', action='add')

@mixes_bp.route('/sizes/edit/<int:id>', methods=['GET', 'POST'])
def edit_size(id):
    size = MixSize.query.get_or_404(id)
    if request.method == 'POST':
        size.name = request.form.get('name')
        size.type = request.form.get('type', 'head')
        size.price = float(request.form.get('price', 0.0))
        size.sort_order = int(request.form.get('sort_order', 0))
        size.is_active = request.form.get('is_active') == 'on'
        db.session.commit()
        flash("تم تعديل الحجم بنجاح", "success")
        return redirect(url_for('admin_mixes.list_sizes'))
        
    return render_template('admin/mixes/size_form.html', action='edit', size=size)

@mixes_bp.route('/sizes/delete/<int:id>', methods=['POST'])
def delete_size(id):
    size = MixSize.query.get_or_404(id)
    db.session.delete(size)
    db.session.commit()
    flash("تم حذف الحجم بنجاح", "success")
    return redirect(url_for('admin_mixes.list_sizes'))
