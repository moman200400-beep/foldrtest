from flask import request, jsonify
from app.api import api_bp
from app.models import Order
import json

@api_bp.route('/my_orders', methods=['GET', 'OPTIONS'])
def get_my_orders():
    # معالجة طلبات CORS Preflight من متصفح كروم
    if request.method == 'OPTIONS':
        response = jsonify({"message": "CORS preflight"})
        response.headers.add('Access-Control-Allow-Origin', '*')
        response.headers.add('Access-Control-Allow-Headers', 'Content-Type, Accept')
        response.headers.add('Access-Control-Allow-Methods', 'GET, OPTIONS')
        return response, 200

    try:
        # جلب معرف العميل (مؤقتاً نستخدم USER_FLUTTER كما في تطبيقك)
        uid = request.args.get('uid', '')
        
        # البحث عن طلبات هذا العميل تحديداً، مرتبة من الأحدث للأقدم
        user_orders = Order.query.filter_by(uid=uid).order_by(Order.id.desc()).all()
        
        orders_list = []
        for o in user_orders:
            orders_list.append({
                "id": o.id,
                "status": o.status,
                "total_amount": o.total_amount,
                "payment_method": o.payment_method,
                "cart_items": o.cart_items, # السلة محفوظة كنص JSON
                "created_at": o.created_at.strftime('%Y-%m-%d %H:%M')
            })

        response = jsonify({
            "ok": True, 
            "orders": orders_list
        })
        response.headers.add('Access-Control-Allow-Origin', '*')
        return response, 200

    except Exception as e:
        response = jsonify({"ok": False, "error": str(e)})
        response.headers.add('Access-Control-Allow-Origin', '*')
        return response, 500
