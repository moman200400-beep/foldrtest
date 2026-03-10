import sys
import os
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..', '..', '..', '..'))
from src.backend.core.extensions import db
import datetime

class Zone(db.Model):
    __tablename__ = 'zones'
    id              = db.Column(db.Integer, primary_key=True)
    name            = db.Column(db.String(100), nullable=False)
    zone_type       = db.Column(db.String(30), default='inside')
    commission_rate = db.Column(db.Float, default=0.0)
    estimated_time  = db.Column(db.Integer, default=30)
    is_active       = db.Column(db.Boolean, default=True)
    peak_enabled    = db.Column(db.Boolean, default=False)
    peak_multiplier = db.Column(db.Float, default=1.5)
    peak_start      = db.Column(db.String(5), default='17:00')
    peak_end        = db.Column(db.String(5), default='22:00')
    polygon_coords  = db.Column(db.Text, default='[]')
    color           = db.Column(db.String(10), default='#8B5CF6')
    created_at      = db.Column(db.DateTime, default=datetime.datetime.utcnow)
    districts       = db.relationship('District', backref='zone', lazy=True, cascade='all, delete-orphan')
    drivers         = db.relationship('DriverZone', backref='zone', lazy=True, cascade='all, delete-orphan')
