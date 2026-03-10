from flask import request, jsonify
from app.api import api_bp
from src.backend.models.coupon import Coupon

def _cors():
    res = jsonify({'ok': True})
    res.headers['Access-Control-Allow-Origin'] = '*'
    res.headers['Access-Control-Allow-Methods'] = 'POST, OPTIONS'
    res.headers['Access-Control-Allow-Headers'] = 'Content-Type'
    return res

def _json(data):
    res = jsonify(data)
    res.headers['Access-Control-Allow-Origin'] = '*'
    res.headers['Access-Control-Allow-Headers'] = 'Content-Type'
    return res

@api_bp.route('/cart/validate_coupon', methods=['POST', 'OPTIONS'])
def validate_coupon():
    if request.method == 'OPTIONS':
        return _cors()

    try:
        data = request.get_json(force=True, silent=True)
        if not data:
            return _json({"ok": False, "error": "لا توجد بيانات المرسلة"})

        code = data.get('code', '').strip().upper()
        cart_total = float(data.get('cart_total', 0.0))

        if not code:
            return _json({"ok": False, "error": "يرجى إدخال كود الخصم"})

        coupon = Coupon.query.filter_by(code=code).first()
        
        if not coupon:
            return _json({"ok": False, "error": "الكوبون غير صحيح أو لا يوجد"})

        if not coupon.is_active:
            return _json({"ok": False, "error": "هذا الكوبون غير فعال"})
            
        import datetime
        if coupon.valid_until and coupon.valid_until < datetime.datetime.utcnow():
             return _json({"ok": False, "error": "الكوبون منتهي الصلاحية"})

        if coupon.min_order_amount and cart_total < coupon.min_order_amount:
            return _json({"ok": False, "error": f"هذا الكوبون يشرط أن يكون الحد الأدنى للطلب {coupon.min_order_amount}"})
        if coupon.usage_limit and coupon.times_used >= coupon.usage_limit:
            return _json({"ok": False, "error": "لقد وصل هذا الكوبون للحد الأقصى للإستخدام"})

        discount_amount = 0.0
        if coupon.discount_type == 'percentage':
            discount_amount = cart_total * (coupon.discount_value / 100.0)
        else:
            discount_amount = coupon.discount_value

        return _json({
            "ok": True,
            "discount_amount": discount_amount,
            "new_total": cart_total - discount_amount,
            "message": "تم تطبيق الكوبون بنجاح"
        })

    except Exception as e:
        print(f"Error validating coupon: {str(e)}")
        return _json({"ok": False, "error": f"حدث خطأ داخلي: {str(e)}"})
