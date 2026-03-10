from app import create_app
from src.backend.core.extensions import db
from src.backend.models.courier import Courier, CourierOrder

app = create_app()

def setup_couriers():
    with app.app_context():
        # Create all tables including couriers and courier_orders 
        db.create_all()
        print("Courier and CourierOrder tables created successfully.")

        # Optionally add a test courier
        if Courier.query.count() == 0:
            default_courier = Courier(name="مندوب افتراضي", phone="0500000000")
            db.session.add(default_courier)
            db.session.commit()
            print("Default courier added successfully.")

if __name__ == "__main__":
    setup_couriers()
