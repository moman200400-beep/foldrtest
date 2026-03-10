from src.backend.core.extensions import db
import datetime
import random
import string

def generate_mix_code():
    # Generates a code like MIX-8421
    random_str = ''.join(random.choices(string.digits, k=4))
    return f"MIX-{random_str}"

class MixFlavor(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    name = db.Column(db.String(100), nullable=False)
    icon = db.Column(db.String(50), default='🔥') # Emoji or FontAwesome class
    category = db.Column(db.String(50), default='عام')
    base_price = db.Column(db.Float, default=0.0) # If flavors have extra cost
    is_active = db.Column(db.Boolean, default=True)

class MixMood(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    name = db.Column(db.String(100), nullable=False)
    icon = db.Column(db.String(50), default='🌟') # Emoji or FontAwesome class
    description = db.Column(db.Text, default='')
    suggested_flavors = db.Column(db.Text, default='[]') # JSON array of flavor IDs
    is_active = db.Column(db.Boolean, default=True)

class MixSize(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    name = db.Column(db.String(100), nullable=False) # e.g. "رأس واحد", "250 جرام"
    type = db.Column(db.String(50), default='head') # 'head' or 'weight'
    price = db.Column(db.Float, nullable=False)
    is_active = db.Column(db.Boolean, default=True)
    sort_order = db.Column(db.Integer, default=0)

class CustomMix(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    code = db.Column(db.String(20), unique=True, default=generate_mix_code)
    name = db.Column(db.String(100), default='خلطة مخصصة')
    flavors_data = db.Column(db.Text, nullable=False) # JSON array of {flavor_id, percentage}
    strength = db.Column(db.String(50), default='متوسط') # خفيف، متوسط، قوي
    size_id = db.Column(db.Integer, db.ForeignKey('mix_size.id'), nullable=True)
    total_price = db.Column(db.Float, nullable=False)
    created_at = db.Column(db.DateTime, default=datetime.datetime.utcnow)
    
    # User who created it (optional if guest)
    user_phone = db.Column(db.String(20), nullable=True) 
    
    # Admin can mark some CustomMix as "Featured" (الخلطات المميزة)
    is_featured = db.Column(db.Boolean, default=False)
    featured_image = db.Column(db.String(300), nullable=True)

class MixSetting(db.Model):
    # Single row table for global mix settings
    id = db.Column(db.Integer, primary_key=True)
    max_flavors = db.Column(db.Integer, default=3)
    min_percentage = db.Column(db.Integer, default=10)
    max_percentage = db.Column(db.Integer, default=100)
