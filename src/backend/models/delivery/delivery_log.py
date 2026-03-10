import sys
import os
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..', '..', '..', '..'))
from src.backend.core.extensions import db
import datetime

class DeliveryLog(db.Model):
    __tablename__ = 'delivery_logs'
    id             = db.Column(db.Integer, primary_key=True)
    order_id       = db.Column(db.Integer, db.ForeignKey('order.id'), nullable=True)
    driver_id      = db.Column(db.Integer, db.ForeignKey('drivers.id'), nullable=True)
    neighborhood_id= db.Column(db.Integer, db.ForeignKey('neighborhood.id'), nullable=True)
    delivery_price = db.Column(db.Float, default=0.0)
    customer_lat   = db.Column(db.Float, nullable=True)
    customer_lng   = db.Column(db.Float, nullable=True)
    status         = db.Column(db.String(20), default='pending')
    notes          = db.Column(db.Text)
    created_at     = db.Column(db.DateTime, default=datetime.datetime.utcnow)
