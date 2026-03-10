from flask import jsonify, request
from app.api import api_bp
from app.models import Neighborhood, DeliveryLog
import datetime

@api_bp.route('/delivery/neighborhoods')
def api_neighborhoods():
    neighborhoods = Neighborhood.query.filter_by(is_active=True).all()
    result = [n.to_dict() for n in neighborhoods]
    return jsonify({'ok': True, 'neighborhoods': result})

@api_bp.route('/delivery/search')
def search_delivery():
    """Search for neighborhoods by name"""
    name = request.args.get('name', '').strip()
    if not name:
        return jsonify({'ok': False, 'error': 'اسم مطلوب', 'results': []}), 400

    matches = []
    for n in Neighborhood.query.filter(Neighborhood.name.ilike(f"%{name}%"), Neighborhood.is_active==True).all():
        matches.append({
            'id': n.id,
            'name': n.name
        })

    return jsonify({'ok': True, 'results': matches})

@api_bp.route('/delivery/calculate', methods=['POST'])
def api_calculate():
    data = request.get_json(force=True)
    neighborhood_id = data.get('neighborhood_id')
    neighborhood_name = data.get('neighborhood_name')
    
    neighborhood = None
    if neighborhood_id:
        neighborhood = Neighborhood.query.get(neighborhood_id)
    elif neighborhood_name:
        # Fallback to searching by exact name if id is not provided
        neighborhood = Neighborhood.query.filter_by(name=neighborhood_name, is_active=True).first()

    if not neighborhood or not neighborhood.is_active:
        return jsonify({'ok': False, 'error': 'الحي غير متاح أو غير موجود', 'price': 0})

    price = float(neighborhood.delivery_price)
    
    # ── التوصيل المجاني ──
    free_delivery_applied = False
    free_delivery_active_flag = False
    free_delivery_threshold_val = 300.0
    try:
        from src.backend.models.system_setting import SystemSetting
        is_free_active = SystemSetting.query.get('free_delivery_active')
        free_threshold = SystemSetting.query.get('free_delivery_threshold')
        
        active_val = str(is_free_active.value).strip() if is_free_active else '0'
        threshold_val = float(free_threshold.value) if free_threshold else 300.0
        free_delivery_active_flag = active_val == '1'
        free_delivery_threshold_val = threshold_val
        
        if active_val == '1':
            order_total = float(data.get('order_total', 0.0))
            if order_total >= threshold_val:
                price = 0.0
                free_delivery_applied = True
    except Exception as e:
        print(f"Error checking free delivery settings: {e}")

    return jsonify({
        'ok': True,
        'price': round(price, 2),
        'neighborhood_id': neighborhood.id,
        'neighborhood': neighborhood.name,
        'free_delivery_active': free_delivery_active_flag,
        'free_delivery_threshold': free_delivery_threshold_val,
        'free_delivery_applied': free_delivery_applied,
    })
