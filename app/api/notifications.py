from flask import request, jsonify
from app.api import api_bp
from src.backend.core.extensions import db
from app.models import Notification

def _json(data):
    res = jsonify(data)
    res.headers['Access-Control-Allow-Origin'] = '*'
    res.headers['Access-Control-Allow-Headers'] = 'Content-Type'
    return res

def _cors():
    res = jsonify({'ok': True})
    res.headers['Access-Control-Allow-Origin'] = '*'
    res.headers['Access-Control-Allow-Methods'] = 'GET, POST, OPTIONS'
    res.headers['Access-Control-Allow-Headers'] = 'Content-Type'
    return res

@api_bp.route('/notifications', methods=['GET', 'OPTIONS'])
def get_notifications():
    if request.method == 'OPTIONS':
        return _cors()
    try:
        notifs = Notification.query.order_by(Notification.created_at.desc()).limit(50).all()
        unread = Notification.query.filter_by(is_read=False).count()
        return _json({
            'ok': True,
            'unread': unread,
            'notifications': [{
                'id': n.id,
                'title': n.title,
                'message': n.message,
                'type': n.type,
                'is_read': n.is_read,
                'created_at': n.created_at.strftime('%Y-%m-%d %H:%M')
            } for n in notifs]
        })
    except Exception as e:
        return _json({'ok': False, 'error': str(e)})

@api_bp.route('/notifications/read_all', methods=['POST', 'OPTIONS'])
def read_all_notifications():
    if request.method == 'OPTIONS':
        return _cors()
    try:
        Notification.query.filter_by(is_read=False).update({'is_read': True})
        db.session.commit()
        return _json({'ok': True})
    except Exception as e:
        return _json({'ok': False, 'error': str(e)})

@api_bp.route('/notifications/read/<int:notif_id>', methods=['POST', 'OPTIONS'])
def read_notification(notif_id):
    if request.method == 'OPTIONS':
        return _cors()
    try:
        n = Notification.query.get(notif_id)
        if n:
            n.is_read = True
            db.session.commit()
        return _json({'ok': True})
    except Exception as e:
        return _json({'ok': False, 'error': str(e)})