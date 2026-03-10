import json
import traceback
from flask import request, jsonify
from app.api import api_bp
from src.backend.core.extensions import db
from app.models import Order, Product, DeliveryLog, Neighborhood, Driver

@api_bp.route('/order', methods=['POST', 'OPTIONS'])
def place_order():
    if request.method == 'OPTIONS':
        response = jsonify({"message": "CORS preflight"})
        response.headers.add('Access-Control-Allow-Origin', '*')
        response.headers.add('Access-Control-Allow-Headers', 'Content-Type, Accept')
        response.headers.add('Access-Control-Allow-Methods', 'POST, OPTIONS')
        return response, 200

    try:
        print("\n====== 📥 استلام طلب جديد من فلاتر ======")
        
        d = request.get_json(force=True, silent=True)
        print(f"البيانات المستلمة: {d}")
        
        if not d:
            return jsonify({"ok": False, "error": "No data received or invalid JSON format"}), 400

        # ========== ☎️ التحقق من رقم الجوال ==========
        phone = str(d.get('phone', '')).strip()
        if not phone or len(phone) != 10 or not phone.startswith('05') or not phone.isdigit():
            return jsonify({"ok": False, "error": "رقم الجوال يجب أن يتكون من 10 أرقام ويبدأ بـ 05"}), 400

        uid = str(d.get('uid', 'USER_FLUTTER'))
        
        cart_data = d.get('cart', [])
        if isinstance(cart_data, str):
            try:
                cart = json.loads(cart_data)
            except:
                cart = []
        else:
            cart = cart_data

        # 1. خصم المخزون
        for item in cart:
            try:
                item_id = str(item.get('id', ''))
                if item_id.startswith('MIX-'):
                    # This is a custom mix, skip product stock deduction
                    continue
                
                prod_id = int(item_id) 
                prod = Product.query.get(prod_id)
                if prod and prod.stock > 0:
                    quantity_to_deduct = int(item.get('quantity', 1))
                    prod.stock = max(0, prod.stock - quantity_to_deduct)
            except Exception as item_err:
                print(f"⚠️ تحذير: خطأ في خصم مخزون المنتج {item}: {item_err}")

        # ========== تحديد الحي وسعر التوصيل (الأمان: سيرفر سايد) ==========
        neighborhood_id = d.get('neighborhood_id') or d.get('district_id')
        neighborhood_name = d.get('delivery_neighborhood')
        neighborhood = None
        
        if neighborhood_id:
            neighborhood = Neighborhood.query.get(neighborhood_id)
        elif neighborhood_name:
            neighborhood = Neighborhood.query.filter_by(name=neighborhood_name).first()
            
        payload_cart_total = 0.0
        for item in cart:
            try:
                payload_cart_total += float(item.get('price', 0)) * int(item.get('quantity', 1))
            except:
                pass
                
        delivery_price = 0.0
        if neighborhood and neighborhood.is_active:
            delivery_price = float(neighborhood.delivery_price)
            neighborhood_id = neighborhood.id
            neighborhood_name = neighborhood.name
            
            # --- 🚀 التوصيل المجاني ---
            try:
                from src.backend.models.system_setting import SystemSetting
                is_free_active = SystemSetting.query.get('free_delivery_active')
                free_threshold = SystemSetting.query.get('free_delivery_threshold')
                
                active_val = str(is_free_active.value).strip() if is_free_active else '0'
                threshold_val = float(free_threshold.value) if free_threshold else 300.0
                
                if active_val == '1':
                    if payload_cart_total >= threshold_val:
                        delivery_price = 0.0
            except Exception as e:
                print(f"Error checking free delivery settings: {e}")
                
        else:
            return jsonify({"ok": False, "error": "الرجاء اختيار حي التوصيل أو الحي المختار غير متاح"}), 400

        # ========== كوبونات الخصم ==========
        coupon_code = d.get('coupon_code', '').strip().upper()
        discount_amount = 0.0
        
        if coupon_code:
            from src.backend.models.coupon import Coupon
            coupon = Coupon.query.filter_by(code=coupon_code).first()
            if coupon:
                is_valid, _ = coupon.is_valid(payload_cart_total)
                if is_valid:
                    discount_amount = coupon.calculate_discount(payload_cart_total)
                    coupon.times_used += 1

        total_amount = payload_cart_total - discount_amount + delivery_price
        # Ensure total is not negative
        if total_amount < 0:
            total_amount = 0.0

        # 2. إنشاء الطلب
        new_order = Order(
            uid=uid,
            customer_name=d.get('name', 'عميل جديد'),
            customer_phone=d.get('phone', ''),
            address=d.get('address', ''),
            delivery_neighborhood=neighborhood_name,
            delivery_price=delivery_price,
            location_link=d.get('location_link'),
            address_details=d.get('address_details'),
            cart_items=json.dumps(cart, ensure_ascii=False),
            total_amount=total_amount,
            coupon_code=coupon_code if discount_amount > 0 else None,
            discount_amount=discount_amount,
            payment_method=d.get('payment_method', 'cash'),
            status="pending"
        )
        
        db.session.add(new_order)
        db.session.flush()  # للحصول على id قبل commit

        # ========== إضافة بيانات التوصيل (DeliveryLog) ==========
        driver_id = d.get('driver_id')
        customer_lat = d.get('lat')
        customer_lng = d.get('lng')

        delivery_log = DeliveryLog(
            order_id=new_order.id,
            neighborhood_id=neighborhood_id,
            driver_id=driver_id,
            delivery_price=delivery_price,
            customer_lat=customer_lat,
            customer_lng=customer_lng,
            status='pending'
        )
        db.session.add(delivery_log)

        db.session.commit()
        
        print(f"✅ تم حفظ الطلب بنجاح برقم: {new_order.id}\n")
        
        response = jsonify({"ok": True, "order_id": new_order.id})
        response.headers.add('Access-Control-Allow-Origin', '*')
        return response, 200

    except Exception as e:
        db.session.rollback()
        print("🔥 حدث خطأ داخلي في السيرفر أثناء حفظ الطلب:")
        traceback.print_exc()
        print("===========================================\n")
        
        response = jsonify({"ok": False, "error": str(e)})
        response.headers.add('Access-Control-Allow-Origin', '*')
        return response, 500