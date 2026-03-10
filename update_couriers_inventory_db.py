import os
from datetime import datetime
from sqlalchemy import text
from src.backend.core.extensions import db
from src.backend.app import create_app
from src.backend.models.courier import CourierOrder, CourierDailyInventory

app = create_app()

with app.app_context():
    # Execute raw SQL to add columns if they don't exist
    queries = [
        'ALTER TABLE courier_orders ADD COLUMN shisha_boxes_used INTEGER NOT NULL DEFAULT 0',
        'ALTER TABLE courier_orders ADD COLUMN head_boxes_used INTEGER NOT NULL DEFAULT 0',
        'ALTER TABLE courier_orders ADD COLUMN shisha_price FLOAT NOT NULL DEFAULT 0.0',
        'ALTER TABLE courier_orders ADD COLUMN head_price FLOAT NOT NULL DEFAULT 0.0'
    ]
    
    for query in queries:
        try:
            db.session.execute(text(query))
            print(f"Success: {query}")
        except Exception as e:
            print(f"Skipped (likely exists): {query.split('ADD COLUMN ')[1]}")
            
    try:
        db.session.commit()
    except Exception as e:
        print("Commit error:", e)
        
    # Migrate old data: set shisha_boxes_used = boxes_count for old rows
    try:
        db.session.execute(text('UPDATE courier_orders SET shisha_boxes_used = boxes_count WHERE shisha_boxes_used = 0 AND boxes_count > 0'))
        print("Migrated old boxes_count to shisha_boxes_used.")
    except Exception as e:
        print("Update existing data error:", e)
        
    # Create the new table CourierDailyInventory if it doesn't exist
    try:
        CourierDailyInventory.__table__.create(db.engine)
        print("Created courier_daily_inventory table.")
    except Exception as e:
        print("Table might already exist:", e)

    db.session.commit()
    print("Database updated successfully.")
