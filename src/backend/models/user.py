import sys
import os
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..', '..', '..'))
from src.backend.core.extensions import db
import datetime

class User(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    uid = db.Column(db.String(50), unique=True, nullable=False)
    name = db.Column(db.String(100))
    phone = db.Column(db.String(20), unique=True)
    password_hash = db.Column(db.String(200))
    role = db.Column(db.String(20), default='customer')
    status = db.Column(db.String(20), default='active')
    wallet_balance = db.Column(db.Float, default=0.0)
    lifetime_value = db.Column(db.Float, default=0.0)
    internal_notes = db.Column(db.Text)
    two_factor_secret = db.Column(db.String(32))  # For 2FA
    created_at = db.Column(db.DateTime, default=datetime.datetime.utcnow)
