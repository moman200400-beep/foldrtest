import uuid
from flask import request, jsonify
from app.api import api_bp
from src.backend.core.extensions import db
from app.models import User
from werkzeug.security import generate_password_hash, check_password_hash

def _json(data):
    res = jsonify(data)
    res.headers['Access-Control-Allow-Origin'] = '*'
    res.headers['Access-Control-Allow-Headers'] = 'Content-Type'
    return res

def _cors():
    res = jsonify({'ok': True})
    res.headers['Access-Control-Allow-Origin'] = '*'
    res.headers['Access-Control-Allow-Methods'] = 'POST, OPTIONS'
    res.headers['Access-Control-Allow-Headers'] = 'Content-Type'
    return res

@api_bp.route('/login', methods=['POST', 'OPTIONS'])
def login():
    if request.method == 'OPTIONS':
        return _cors()
    try:
        data = request.get_json(force=True)
        phone = data.get('phone', '').strip()
        password = data.get('password', '')

        if not phone or not password:
            return _json({'ok': False, 'error': 'يرجى ملء جميع الحقول'})

        user = User.query.filter_by(phone=phone).first()
        if not user:
            return _json({'ok': False, 'error': 'لا يوجد حساب بهذا الرقم'})

        if not check_password_hash(user.password_hash, password):
            return _json({'ok': False, 'error': 'كلمة المرور غير صحيحة'})

        if user.status == 'banned':
            return _json({'ok': False, 'error': 'هذا الحساب محظور'})

        return _json({
            'ok': True,
            'name': user.name or 'عميل المزاج',
            'phone': user.phone,
            'uid': user.uid
        })
    except Exception as e:
        return _json({'ok': False, 'error': str(e)})


@api_bp.route('/register', methods=['POST', 'OPTIONS'])
def register():
    if request.method == 'OPTIONS':
        return _cors()
    try:
        data = request.get_json(force=True)
        name = data.get('name', '').strip()
        phone = data.get('phone', '').strip()
        password = data.get('password', '')

        if not name or not phone or not password:
            return _json({'ok': False, 'error': 'يرجى ملء جميع الحقول'})

        if len(password) < 6:
            return _json({'ok': False, 'error': 'كلمة المرور 6 أحرف على الأقل'})

        existing = User.query.filter_by(phone=phone).first()
        if existing:
            return _json({'ok': False, 'error': 'هذا الرقم مسجّل مسبقاً'})

        user = User(
            uid=str(uuid.uuid4())[:20],
            name=name,
            phone=phone,
            password_hash=generate_password_hash(password),
            role='customer',
            status='active'
        )
        db.session.add(user)
        db.session.commit()

        return _json({
            'ok': True,
            'name': name,
            'phone': phone,
            'uid': user.uid
        })
    except Exception as e:
        db.session.rollback()
        return _json({'ok': False, 'error': str(e)})