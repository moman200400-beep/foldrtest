import sys
import os
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..', '..', '..', '..'))
from src.backend.core.extensions import db
import datetime

class District(db.Model):
    __tablename__ = 'districts'
    id                   = db.Column(db.Integer, primary_key=True)
    name                 = db.Column(db.String(100), nullable=False)
    zone_id              = db.Column(db.Integer, db.ForeignKey('zones.id'), nullable=False)
    base_price           = db.Column(db.Float, default=10.0)
    packaging_cost       = db.Column(db.Float, default=0.0)
    night_surcharge      = db.Column(db.Float, default=0.0)
    free_delivery_above  = db.Column(db.Float, default=0.0)
    is_active            = db.Column(db.Boolean, default=True)
    created_at           = db.Column(db.DateTime, default=datetime.datetime.utcnow)
