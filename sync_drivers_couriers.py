"""One-time script to sync existing Driver records to the Courier table."""
import sys, os
sys.path.insert(0, os.path.dirname(__file__))

from app import create_app
from src.backend.core.extensions import db
from src.backend.models.delivery.driver import Driver
from src.backend.models.courier import Courier

app = create_app()
with app.app_context():
    drivers = Driver.query.all()
    synced = 0
    for drv in drivers:
        existing = Courier.query.filter_by(name=drv.name).first()
        if not existing and drv.phone:
            existing = Courier.query.filter_by(phone=drv.phone).first()
        if not existing:
            courier = Courier(name=drv.name, phone=drv.phone, status=drv.is_active)
            db.session.add(courier)
            synced += 1
    
    db.session.commit()
    print(f"Done! Synced {synced} new courier records from {len(drivers)} drivers.")
