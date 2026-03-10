import sys
import os
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..', '..', '..'))
from src.backend.core.extensions import db
import datetime

class Order(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    uid = db.Column(db.String(50), nullable=False)
    customer_name = db.Column(db.String(100))
    customer_phone = db.Column(db.String(20))
    address = db.Column(db.String(255))
    delivery_neighborhood = db.Column(db.String(100))
    delivery_price = db.Column(db.Float, default=0.0)
    location_link = db.Column(db.String(300))
    address_details = db.Column(db.String(500))
    cart_items = db.Column(db.Text, nullable=False)
    total_cost = db.Column(db.Float, default=0.0) # 🌟 التكلفة الإجمالية لحساب هامش الربح
    total_amount = db.Column(db.Float, nullable=False)
    payment_method = db.Column(db.String(50), default='cash')
    status = db.Column(db.String(20), default='pending')
    
    # معلومات الكوبون
    coupon_code = db.Column(db.String(50), nullable=True)
    discount_amount = db.Column(db.Float, default=0.0)
    
    created_at = db.Column(db.DateTime, default=datetime.datetime.utcnow)

class OrderTimeline(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    order_id = db.Column(db.Integer, db.ForeignKey('order.id'), nullable=False)
    status = db.Column(db.String(50), nullable=False)
    notes = db.Column(db.Text)
    created_at = db.Column(db.DateTime, default=datetime.datetime.utcnow)
