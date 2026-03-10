import os
from flask import Flask, send_from_directory
from flask_cors import CORS
# db is imported from core.extensions to ensure single instance
from src.backend.core.extensions import db, cors, migrate, limiter
from config import Config

# تعريف كائن قاعدة البيانات (بدون ربطه بالتطبيق حالياً)
# db = SQLAlchemy()  # replaced by imported object

def create_app():
    # 1. إعداد مسار الملفات الثابتة (الصور)
    static_folder_path = os.path.join(os.path.dirname(os.path.abspath(__file__)), 'static')
    app = Flask(__name__, static_folder=static_folder_path, static_url_path='/static')
    
    app.config.from_object(Config)
    
    # 2. تهيئة الملحقات (extensions)
    cors.init_app(app, resources={r"/*": {"origins": "*"}}, supports_credentials=True)
    limiter.init_app(app)
    migrate.init_app(app, db)

    # 3. ربط قاعدة البيانات بالتطبيق
    db.init_app(app)

    # 4. بناء الجداول إذا لم تكن موجودة
    with app.app_context():
        from app import models
        db.create_all()

    # ==========================================
    # 🌟 الحل السحري: تسجيل الـ Blueprints هنا داخل الدالة بعد تهيئة الـ db
    # ==========================================
    
    # قسم الإدارة
    from app.admin import admin_bp
    app.register_blueprint(admin_bp, url_prefix='/admin')

    from app.admin.ads import ads_admin_bp
    app.register_blueprint(ads_admin_bp)

    # قسم تطبيق فلاتر (API)
    from app.api import api_bp
    app.register_blueprint(api_bp, url_prefix='/api')

    # ==========================================

    @app.route('/')
    def index():
        return "<h1 style='text-align:center; margin-top:50px; color:#3b82f6;'>🚀 النواة الأساسية لنظام Almizaj ERP تعمل بنجاح!</h1>"

    # السماح بعرض الصور المرفوعة لتطبيق فلاتر
    @app.route('/static/uploads/<path:filename>')
    def serve_static_uploads(filename):
        return send_from_directory(app.config['UPLOAD_FOLDER'], filename)

    return app

from flask import Blueprint

admin_bp = Blueprint('admin', __name__, template_folder='../templates')

# 🌟 ميزة متقدمة (Context Processor): تمرير متغير "غير المقروءة" لكل صفحات HTML تلقائياً
@admin_bp.context_processor
def inject_notifications():
    from app.models import Notification
    try:
        unread_count = Notification.query.filter_by(is_read=False).count()
        return dict(unread_count=unread_count)
    except:
        return dict(unread_count=0)

# تعريف الملفات
from app.admin import dashboard, users, products, orders, accounting, system, carts, content, payments, notifications, delivery, ads
