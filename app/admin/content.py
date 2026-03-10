from flask import render_template, request, session, redirect, url_for
from app.admin import admin_bp
from src.backend.core.extensions import db
from app.models import SystemSetting, AuditLog

# دوال مساعدة للإعدادات
def get_setting(key, default=''):
    s = SystemSetting.query.get(key)
    return s.value if s else default

def set_setting(key, value):
    s = SystemSetting.query.get(key)
    if s: 
        s.value = str(value)
    else: 
        db.session.add(SystemSetting(key=key, value=str(value)))

@admin_bp.route('/content', methods=['GET', 'POST'])
def content_page():
    if 'user_id' not in session or session.get('role') != 'admin':
        return redirect(url_for('admin.login'))

    if request.method == 'POST':
        # حفظ النصوص الجديدة
        set_setting('welcome_message', request.form.get('welcome_message'))
        set_setting('terms_conditions', request.form.get('terms_conditions'))
        set_setting('privacy_policy', request.form.get('privacy_policy'))
        set_setting('about_us', request.form.get('about_us'))

        # تسجيل أمني
        db.session.add(AuditLog(admin_id=session['user_id'], action="تحديث محتوى وصفحات التطبيق", ip_address=request.remote_addr))
        db.session.commit()
        
        return redirect(url_for('admin.content_page'))

    # جلب المحتوى الحالي
    content_data = {
        'welcome_message': get_setting('welcome_message', 'مرحباً بك في تطبيق المزاج الأول! 🚀'),
        'terms_conditions': get_setting('terms_conditions', 'اكتب الشروط والأحكام هنا...'),
        'privacy_policy': get_setting('privacy_policy', 'اكتب سياسة الخصوصية هنا...'),
        'about_us': get_setting('about_us', 'نحن متجر المزاج الأول...'),
    }
    
    return render_template('content.html', content=content_data)
