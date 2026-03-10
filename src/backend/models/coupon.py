import sys
import os
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..', '..', '..'))
from src.backend.core.extensions import db
import datetime

class Coupon(db.Model):
    __tablename__ = 'coupons'
    
    id = db.Column(db.Integer, primary_key=True)
    code = db.Column(db.String(50), unique=True, nullable=False, index=True)
    discount_type = db.Column(db.String(20), nullable=False, default='percentage') # 'percentage' or 'fixed'
    discount_value = db.Column(db.Float, nullable=False) # e.g. 10.0 for 10% or 50.0 for 50 SAR
    
    min_order_amount = db.Column(db.Float, default=0.0)
    
    usage_limit = db.Column(db.Integer, default=0) # 0 means unlimited
    times_used = db.Column(db.Integer, default=0)
    
    valid_until = db.Column(db.DateTime, nullable=True)
    is_active = db.Column(db.Boolean, default=True)
    
    created_at = db.Column(db.DateTime, default=datetime.datetime.utcnow)

    def is_valid(self, cart_total):
        if not self.is_active:
            return False, "الكوبون غير فعال"
            
        if self.valid_until and self.valid_until < datetime.datetime.utcnow():
            return False, "الكوبون منتهي الصلاحية"
            
        if self.usage_limit > 0 and self.times_used >= self.usage_limit:
            return False, "تم الوصول للحد الأقصى لاستخدام الكوبون"
            
        if self.min_order_amount > 0 and cart_total < self.min_order_amount:
            return False, f"الحد الأدنى للطلب لاستخدام هذا الكوبون هو {self.min_order_amount} ريال"
            
        return True, "الكوبون صالح"

    def calculate_discount(self, cart_total):
        if self.discount_type == 'percentage':
            discount = cart_total * (self.discount_value / 100.0)
            return round(discount, 2)
        elif self.discount_type == 'fixed':
            # Handle case where fixed discount is greater than subtotal
            discount = min(self.discount_value, cart_total)
            return round(discount, 2)
        return 0.0
