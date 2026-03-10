from flask import jsonify, request
from app.api import api_bp
from src.backend.models.mix import MixFlavor, MixMood, MixSize, MixSetting, CustomMix
from src.backend.core.extensions import db
import json

@api_bp.route('/mix/data', methods=['GET'])
def get_mix_data():
    """يرجع جميع بيانات الإعدادات، وأمور صانع الخلطات"""
    setting = MixSetting.query.first()
    if not setting:
        setting = MixSetting(max_flavors=3, min_percentage=10, max_percentage=100)
    
    flavors = MixFlavor.query.filter_by(is_active=True).all()
    moods = MixMood.query.filter_by(is_active=True).all()
    sizes = MixSize.query.filter_by(is_active=True).order_by(MixSize.sort_order).all()

    return jsonify({
        "ok": True,
        "settings": {
            "max_flavors": setting.max_flavors,
            "min_percentage": setting.min_percentage,
            "max_percentage": setting.max_percentage
        },
        "flavors": [
            {
                "id": f.id,
                "name": f.name,
                "icon": f.icon,
                "category": f.category,
                "base_price": float(f.base_price)
            } for f in flavors
        ],
        "moods": [
            {
                "id": m.id,
                "name": m.name,
                "icon": m.icon,
                "description": m.description,
            } for m in moods
        ],
        "sizes": [
            {
                "id": s.id,
                "name": s.name,
                "type": s.type,
                "price": float(s.price)
            } for s in sizes
        ]
    })

@api_bp.route('/mix/save', methods=['POST', 'OPTIONS'])
def save_custom_mix():
    if request.method == 'OPTIONS':
        return jsonify({"message": "OK"}), 200
        
    try:
        data = request.get_json(force=True, silent=True)
        if not data:
            return jsonify({"ok": False, "error": "No data"}), 400
            
        name = data.get('name', 'خلطة مخصصة')
        flavors_data = data.get('flavors', []) # list of {id, name, percentage}
        strength = data.get('strength', 'متوسط')
        size_id = data.get('size_id')
        total_price = float(data.get('total_price', 0.0))
        user_phone = data.get('user_phone')
        
        mix = CustomMix(
            name=name,
            flavors_data=json.dumps(flavors_data, ensure_ascii=False),
            strength=strength,
            size_id=size_id,
            total_price=total_price,
            user_phone=user_phone
        )
        db.session.add(mix)
        db.session.commit()
        
        return jsonify({
            "ok": True,
            "code": mix.code,
            "message": "تم حفظ الخلطة بنجاح"
        })
    except Exception as e:
        db.session.rollback()
        import traceback
        traceback.print_exc()
        return jsonify({"ok": False, "error": str(e)}), 500

@api_bp.route('/mix/shared/<code>', methods=['GET'])
def get_shared_mix(code):
    mix = CustomMix.query.filter_by(code=code).first()
    if not mix:
        return jsonify({"ok": False, "error": "الخلطة غير موجودة"}), 404
        
    try:
        flavors = json.loads(mix.flavors_data)
    except:
        flavors = []
        
    size_name = ""
    if mix.size_id:
        size = MixSize.query.get(mix.size_id)
        if size:
            size_name = size.name

    return jsonify({
        "ok": True,
        "mix": {
            "name": mix.name,
            "code": mix.code,
            "strength": mix.strength,
            "total_price": float(mix.total_price),
            "size_name": size_name,
            "size_id": mix.size_id,
            "flavors": flavors
        }
    })
