from flask import render_template, request, session, redirect, url_for
from app.admin import admin_bp
from src.backend.core.extensions import db
from app.models import SystemSetting, AuditLog, WheelLog
from app.utils import upload_image

def get_setting(key, default=''):
    s = SystemSetting.query.get(key)
    return s.value if s else default

def set_setting(key, value):
    s = SystemSetting.query.get(key)
    if s: s.value = str(value)
    else: db.session.add(SystemSetting(key=key, value=str(value)))
    db.session.commit()

@admin_bp.route('/system', methods=['GET', 'POST'])
def system_page():
    if 'user_id' not in session or session.get('role') != 'admin':
        return redirect(url_for('admin.login'))

    if request.method == 'POST':
        action = request.form.get('action')
        if action == 'save_settings':
            set_setting('store_name', request.form.get('store_name'))
            set_setting('phone', request.form.get('phone'))       # 📱 حفظ رقم الجوال
            set_setting('whatsapp', request.form.get('whatsapp')) # 📱 حفظ رقم الواتساب
            set_setting('maintenance_mode', 'true' if request.form.get('maintenance_mode') else 'false')
            set_setting('wheel_win_chance', request.form.get('wheel_win_chance'))
            set_setting('wheel_daily_limit', request.form.get('wheel_daily_limit', '1'))
            set_setting('wheel_max_profit', request.form.get('wheel_max_profit', '1000'))
            set_setting('wheel_active', 'true' if request.form.get('wheel_active') else 'false')
            
            # 🚚 إعدادات التوصيل المجاني
            set_setting('free_delivery_active', '1' if request.form.get('free_delivery_active') else '0')
            set_setting('free_delivery_threshold', request.form.get('free_delivery_threshold', '300'))
            
            # 🖼️ حفظ شعار المتجر
            if 'logo_file' in request.files and request.files['logo_file'].filename != '':
                logo_url = upload_image(request.files['logo_file'])
                if logo_url: set_setting('store_logo', logo_url)
            
            db.session.add(AuditLog(admin_id=session.get('user_id'), action="تحديث إعدادات النظام", ip_address=request.remote_addr))
            db.session.commit()
            
        elif action == 'backup_db':
            import os, shutil
            from datetime import datetime
            
            db_path = os.path.join(os.path.dirname(__file__), '..', '..', 'almizaj_erp.db')
            backup_dir = os.path.join(os.path.dirname(__file__), '..', '..', 'backups')
            
            try:
                os.makedirs(backup_dir, exist_ok=True)
                backup_file = f"backup_{datetime.utcnow().strftime('%Y%m%d_%H%M%S')}.db"
                shutil.copy2(db_path, os.path.join(backup_dir, backup_file))
                
                db.session.add(AuditLog(admin_id=session.get('user_id'), action=f"أخذ نسخة احتياطية: {backup_file}", ip_address=request.remote_addr))
                db.session.commit()
            except Exception as e:
                print("Backup failed:", e)
                
        return redirect(url_for('admin.system_page'))

    settings = {
        'store_name': get_setting('store_name', 'المزاج الأول'),
        'phone': get_setting('phone', ''),
        'whatsapp': get_setting('whatsapp', ''),
        'store_logo': get_setting('store_logo', ''),
        'maintenance_mode': get_setting('maintenance_mode', 'false') == 'true',
        'wheel_win_chance': get_setting('wheel_win_chance', '30'),
        'wheel_daily_limit': get_setting('wheel_daily_limit', '1'),
        'wheel_max_profit': get_setting('wheel_max_profit', '1000'),
        'wheel_active': get_setting('wheel_active', 'true') == 'true',
        
        # التوصيل المجاني
        'free_delivery_active': get_setting('free_delivery_active', '0') == '1',
        'free_delivery_threshold': get_setting('free_delivery_threshold', '300'),
    }
    
    logs = AuditLog.query.order_by(AuditLog.timestamp.desc()).limit(50).all()
    wheel_logs = WheelLog.query.order_by(WheelLog.timestamp.desc()).limit(10).all()
    
    # قراءة مؤشرات صحة النظام (System Health)
    try:
        import psutil
        health = {
            'cpu': psutil.cpu_percent(interval=0.1),
            'ram': psutil.virtual_memory().percent,
            'disk': psutil.disk_usage('/').percent
        }
    except Exception:
        health = {'cpu': 0, 'ram': 0, 'disk': 0}
    
    return render_template('system.html', settings=settings, logs=logs, wheel_logs=wheel_logs, health=health)
