import os
from flask import Flask, send_from_directory
from .core.config import Config
from .core.extensions import db, cors, migrate, limiter


def create_app():
    # static folder is two levels up from backend directory
    static_folder_path = os.path.abspath(os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', '..', 'app', 'static'))
    app = Flask(__name__, static_folder=static_folder_path, static_url_path='/static')
    app.config.from_object(Config)

    cors.init_app(app, resources={r"/*": {"origins": "*"}}, supports_credentials=True)
    limiter.init_app(app)
    migrate.init_app(app, db)
    db.init_app(app)

    with app.app_context():
        # ensure models imported so migrations work
        import sys
        sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..', '..'))
        from app import models
        db.create_all()

    # register blueprints
    from app.admin import admin_bp
    app.register_blueprint(admin_bp, url_prefix='/admin')
    
    from app.admin.coupons import coupons_bp
    app.register_blueprint(coupons_bp)
    
    from app.admin.ads import ads_admin_bp
    app.register_blueprint(ads_admin_bp)
    
    from app.admin.mixes import mixes_bp
    app.register_blueprint(mixes_bp)
    
    from app.api import api_bp
    app.register_blueprint(api_bp, url_prefix='/api')

    @app.route('/')
    def index():
        return "<h1 style='text-align:center; margin-top:50px; color:#3b82f6;'>🚀 نواة Almizaj ERP تشغيلية</h1>"

    @app.route('/static/uploads/<path:filename>')
    def serve_static_uploads(filename):
        return send_from_directory(app.config['UPLOAD_FOLDER'], filename)

    return app
