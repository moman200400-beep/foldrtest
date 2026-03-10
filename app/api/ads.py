import sys
import os
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..', '..'))
from flask import jsonify
from app.api import api_bp
from app.models import Ad

@api_bp.route('/ads', methods=['GET'])
def get_ads():
    """الحصول على قائمة الإعلانات النشطة"""
    try:
        ads = Ad.query.filter_by(is_active=True).order_by(Ad.position).all()
        return jsonify({
            'ok': True,
            'ads': [ad.to_dict() for ad in ads]
        }), 200
    except Exception as e:
        return jsonify({'ok': False, 'error': str(e)}), 500
