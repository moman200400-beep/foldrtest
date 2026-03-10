from src.backend.app import create_app
from src.backend.core.extensions import db
from src.backend.models.system_setting import SystemSetting

app = create_app()

with app.app_context():
    # 1. Read current value
    val1 = SystemSetting.query.get("free_delivery_active")
    print(f"Current Value before update: {val1.value if val1 else 'NOT FOUND'}")
    
    # 2. Update to 0
    if val1:
        val1.value = "0"
    else:
        db.session.add(SystemSetting(key="free_delivery_active", value="0"))
    db.session.commit()
    
    # 3. Read again
    val2 = SystemSetting.query.get("free_delivery_active")
    print(f"Value after update to 0: {val2.value if val2 else 'NOT FOUND'}")
    
    # 4. Check if we have multiple entries? (Not possible as key is PK)
    count = SystemSetting.query.filter_by(key="free_delivery_active").count()
    print(f"Count of entries: {count}")
