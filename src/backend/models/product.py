import sys
import os
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..', '..', '..'))
from src.backend.core.extensions import db

class Product(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    name = db.Column(db.String(150), nullable=False)
    type = db.Column(db.String(50), default='physical')
    price = db.Column(db.Float, nullable=False)
    cost_price = db.Column(db.Float, default=0.0) # 🌟 التكلفة لحساب المارجن
    discount_price = db.Column(db.Float)
    stock = db.Column(db.Integer, default=0)
    category = db.Column(db.String(50), nullable=False)
    image_url = db.Column(db.String(300))
    description = db.Column(db.Text, default='لا يوجد وصف متاح لهذا المنتج.')
    extra_images = db.Column(db.Text, default='[]')
    is_active = db.Column(db.Boolean, default=True)
    sort_order = db.Column(db.Integer, default=0)

class Banner(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    image_url = db.Column(db.String(300), nullable=False)
    action_link = db.Column(db.String(300))
    is_active = db.Column(db.Boolean, default=True)
    sort_order = db.Column(db.Integer, default=0)
