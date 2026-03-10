from flask import render_template, request, session, redirect, url_for
from app.admin import admin_bp
from src.backend.core.extensions import db
from app.models import Product, Banner, AuditLog
from app.utils import upload_image, get_categories, save_categories

@admin_bp.route('/products', methods=['GET', 'POST'])
def products_page():
    if 'user_id' not in session or session.get('role') != 'admin':
        return redirect(url_for('admin.login'))

    if request.method == 'POST':
        action = request.form.get('action')
        
        # 1. إضافة منتج
        if action == 'add_product':
            discount = request.form.get('discount_price')
            image_url = ""
            if 'image_file' in request.files and request.files['image_file'].filename != '':
                image_url = upload_image(request.files['image_file'])

            new_p = Product(
                name=request.form.get('name'), 
                type=request.form.get('type'),
                category=request.form.get('category'), 
                price=float(request.form.get('price', 0)),
                cost_price=float(request.form.get('cost_price', 0)), # 🌟 التكلفة
                discount_price=float(discount) if discount else None, 
                stock=int(request.form.get('stock', 0)),
                description=request.form.get('description', ''), # 🌟 إضافة الوصف
                image_url=image_url, 
                sort_order=int(request.form.get('sort_order', 0))
            )
            db.session.add(new_p)
            db.session.add(AuditLog(admin_id=session['user_id'], action=f"إضافة منتج: {new_p.name}", ip_address=request.remote_addr))
            db.session.commit()

        # 🌟 2. دالة تعديل منتج (التي كانت مفقودة)
        elif action == 'edit_product':
            p = Product.query.get(int(request.form.get('pid')))
            if p:
                p.name = request.form.get('name')
                p.price = float(request.form.get('price', 0))
                p.cost_price = float(request.form.get('cost_price', 0)) # 🌟 حفظ التكلفة
                discount = request.form.get('discount_price')
                p.discount_price = float(discount) if discount else None
                p.stock = int(request.form.get('stock', 0))
                p.category = request.form.get('category')
                p.description = request.form.get('description', '') # 🌟 تحديث الوصف
                
                # تحديث الصورة فقط إذا رفع المستخدم صورة جديدة
                if 'image_file' in request.files and request.files['image_file'].filename != '':
                    p.image_url = upload_image(request.files['image_file'])
                
                db.session.add(AuditLog(admin_id=session['user_id'], action=f"تعديل منتج: {p.name}", ip_address=request.remote_addr))
                db.session.commit()

        elif action == 'toggle_product':
            p = Product.query.get(int(request.form.get('pid')))
            if p: 
                p.is_active = not p.is_active
                db.session.commit()

        elif action == 'delete_product':
            p = Product.query.get(int(request.form.get('pid')))
            if p: 
                db.session.add(AuditLog(admin_id=session['user_id'], action=f"حذف منتج: {p.name}", ip_address=request.remote_addr))
                db.session.delete(p)
                db.session.commit()

        # 3. إدارة الأقسام
        elif action == 'add_category':
            new_cat = request.form.get('new_category').strip()
            cats = get_categories()
            if new_cat and new_cat not in cats:
                cats.append(new_cat)
                save_categories(cats)
                db.session.add(AuditLog(admin_id=session['user_id'], action=f"إضافة قسم: {new_cat}", ip_address=request.remote_addr))
                db.session.commit()

        elif action == 'delete_category':
            cat_to_del = request.form.get('category_name')
            cats = get_categories()
            if cat_to_del in cats:
                cats.remove(cat_to_del)
                save_categories(cats)
                db.session.add(AuditLog(admin_id=session['user_id'], action=f"حذف قسم: {cat_to_del}", ip_address=request.remote_addr))
                db.session.commit()

        # 4. 🖼️ إدارة البنرات الإعلانية
        elif action == 'add_banner':
            image_url = ""
            if 'banner_file' in request.files and request.files['banner_file'].filename != '':
                image_url = upload_image(request.files['banner_file'])
            
            if image_url:
                new_b = Banner(
                    image_url=image_url,
                    action_link=request.form.get('action_link', ''),
                    sort_order=int(request.form.get('sort_order', 0))
                )
                db.session.add(new_b)
                db.session.commit()

        elif action == 'delete_banner':
            b = Banner.query.get(int(request.form.get('bid')))
            if b: 
                db.session.delete(b)
                db.session.commit()

        return redirect(url_for('admin.products_page'))

    all_products = Product.query.order_by(Product.sort_order.asc(), Product.id.desc()).all()
    all_banners = Banner.query.order_by(Banner.sort_order.asc()).all()
    categories = get_categories()
    
    return render_template('products.html', products=all_products, banners=all_banners, categories=categories)
