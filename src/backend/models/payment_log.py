import sys
import os
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..', '..', '..'))
from src.backend.core.extensions import db
import datetime

class PaymentLog(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    transaction_id = db.Column(db.String(100), unique=True)
    order_id = db.Column(db.Integer, nullable=True)
    uid = db.Column(db.String(50), nullable=False)
    amount = db.Column(db.Float, nullable=False)
    gateway = db.Column(db.String(50))
    status = db.Column(db.String(20))
    error_msg = db.Column(db.Text, nullable=True)
    created_at = db.Column(db.DateTime, default=datetime.datetime.utcnow)
