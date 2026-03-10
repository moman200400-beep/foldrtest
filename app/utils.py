import os
import uuid
import json
from werkzeug.utils import secure_filename
from flask import current_app
from src.backend.core.extensions import db
from app.models import SystemSetting

def allowed_file(filename):
    return '.' in filename and \
           filename.rsplit('.', 1)[1].lower() in current_app.config['ALLOWED_EXTENSIONS']

def upload_image(file):
    if file and allowed_file(file.filename):
        ext = file.filename.rsplit('.', 1)[1].lower()
        unique_filename = f"{uuid.uuid4().hex}.{ext}"
        save_folder = current_app.config['UPLOAD_FOLDER']
        if not os.path.exists(save_folder):
            os.makedirs(save_folder, exist_ok=True)
        save_path = os.path.join(save_folder, unique_filename)
        file.save(save_path)
        return f"/static/uploads/{unique_filename}"
    return None

# --- دوال إدارة الأقسام (Categories) المضافة حديثاً ---
def get_categories():
    s = SystemSetting.query.get('categories')
    if s and s.value:
        return json.loads(s.value)
    return ["شيش", "معسل", "فحم", "إكسسوارات"] # الأقسام الافتراضية

def save_categories(cats_list):
    s = SystemSetting.query.get('categories')
    json_cats = json.dumps(cats_list, ensure_ascii=False)
    if s:
        s.value = json_cats
    else:
        db.session.add(SystemSetting(key='categories', value=json_cats))
    db.session.commit()
