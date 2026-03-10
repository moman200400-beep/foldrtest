import sys
import os
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..', '..', '..', '..'))
from src.backend.core.extensions import db
import datetime

class Driver(db.Model):
    __tablename__ = 'drivers'
    id               = db.Column(db.Integer, primary_key=True)
    name             = db.Column(db.String(100), nullable=False)
    phone            = db.Column(db.String(20), nullable=False)
    is_active        = db.Column(db.Boolean, default=True)
    max_daily_orders = db.Column(db.Integer, default=20)
    commission_rate  = db.Column(db.Float, default=10.0)
    shift_start      = db.Column(db.String(5), default='08:00')
    shift_end        = db.Column(db.String(5), default='22:00')
    created_at       = db.Column(db.DateTime, default=datetime.datetime.utcnow)
    zones            = db.relationship('DriverZone', backref='driver', lazy=True, cascade='all, delete-orphan')

class DriverZone(db.Model):
    __tablename__ = 'driver_zones'
    id        = db.Column(db.Integer, primary_key=True)
    driver_id = db.Column(db.Integer, db.ForeignKey('drivers.id'), nullable=False)
    zone_id   = db.Column(db.Integer, db.ForeignKey('zones.id'), nullable=False)
