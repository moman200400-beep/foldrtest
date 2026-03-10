import json
from flask import jsonify, request
from app.api import api_bp
from app.models import Product, Banner, SystemSetting

# دالة مساعدة لقراءة الإعدادات
def get_setting(key, default=''):
    s = SystemSetting.query.get(key)
    return s.value if s else default

# دالة مساعدة لبناء الرابط الكامل للصورة لكي تظهر في فلاتر بشكل صحيح
def build_full_url(image_path):
    if not image_path:
        return ""
    if image_path.startswith('http://') or image_path.startswith('https://'):
        return image_path
    
    # استخدام request.host_url لجلب الدومين الأساسي تلقائياً (مثلاً http://127.0.0.1:8080/)
    base_url = request.host_url.rstrip('/') 
    if image_path.startswith('/'):
        return f"{base_url}{image_path}"
    return f"{base_url}/{image_path}"

@api_bp.route('/home', methods=['GET'])
def app_home():
    # 1. التحقق من حالة المتجر واللوجو
    is_maintenance = get_setting('maintenance_mode', 'false') == 'true'
    store_name = get_setting('store_name', 'المزاج الأول')
    
    # 🌟 بناء الرابط الكامل للشعار
    raw_logo = get_setting('store_logo', '')
    store_logo = build_full_url(raw_logo)
    
    # 2. جلب الأقسام الديناميكية
    cats_setting = SystemSetting.query.get('categories')
    if cats_setting and cats_setting.value:
        categories = json.loads(cats_setting.value)
    else:
        categories = ["شيش", "معسل", "فحم", "إكسسوارات"]
        
    # 3. جلب البنرات الإعلانية النشطة فقط
    banners = Banner.query.filter_by(is_active=True).order_by(Banner.sort_order.asc()).all()
    banner_list = []
    for b in banners:
        banner_list.append({
            "img": build_full_url(b.image_url), # 🌟 بناء الرابط الكامل للبانر
            "link": b.action_link
        })
    
    # 4. جلب المنتجات النشطة فقط
    products = Product.query.filter_by(is_active=True).order_by(Product.sort_order.asc(), Product.id.desc()).all()
    prod_list = []
    for p in products:
        prod_list.append({
            "id": p.id,
            "name": p.name,
            "type": p.type,
            "price": p.price,
            "discount_price": p.discount_price,
            "stock": p.stock,
            "cat": p.category, 
            "category": p.category,
            "img": build_full_url(p.image_url), # 🌟 بناء الرابط الكامل لصورة المنتج
            "description": p.description
        })
        
    # 5. إرسال الحزمة الكاملة لتطبيق فلاتر!
    result = jsonify({
        "ok": True,
        "store_open": not is_maintenance, # إذا كان في وضع الصيانة، المتجر مغلق
        "store_name": store_name,
        "store_logo": store_logo,
        "categories": ["الكل"] + categories,
        "banners": banner_list,
        "products": prod_list,
        "free_delivery_active": get_setting('free_delivery_active', '0') == '1',
        "free_delivery_threshold": float(get_setting('free_delivery_threshold', '300'))
    })
    
    return result
