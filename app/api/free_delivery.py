from flask import jsonify
from app.api import api_bp
from app.models import SystemSetting

def _get_setting(key, default=''):
    s = SystemSetting.query.get(key)
    return s.value if s else default

@api_bp.route('/settings/free_delivery', methods=['GET'])
def get_free_delivery_settings():
    """إرجاع إعدادات التوصيل المجاني مباشرة من قاعدة البيانات"""
    active = _get_setting('free_delivery_active', '0') == '1'
    threshold = float(_get_setting('free_delivery_threshold', '300'))
    
    return jsonify({
        'ok': True,
        'free_delivery_active': active,
        'free_delivery_threshold': threshold,
    })
