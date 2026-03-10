from werkzeug.security import generate_password_hash
from src.backend.app import create_app
from src.backend.core.extensions import db
from app.models import User
from config import Config

app = create_app()

if __name__ == "__main__":
    with app.app_context():
        # إنشاء المدير العام فقط (إذا لم يكن موجوداً)
        # لن ننشئ أي عملاء أو طلبات وهمية بعد الآن!
        if User.query.filter_by(role='admin').count() == 0:
            db.session.add(User(
                uid="ADMIN_001", 
                name="المدير العام", 
                role="admin", 
                password_hash=generate_password_hash(Config.ADMIN_PASS)
            ))
            db.session.commit()

    # run the server on port 8080 to match Flutter configuration
    app.run(host='0.0.0.0', port=8080, debug=True)

    print("=======================================")
    print("🚀 جاري تشغيل Almizaj ERP - وضع الإنتاج الحقيقي 🌟")
    print("=======================================")
    app.run(host="0.0.0.0", port=8080, debug=True)
