from datetime import datetime
from src.backend.core.extensions import db

class Courier(db.Model):
    __tablename__ = 'couriers'
    
    id = db.Column(db.Integer, primary_key=True)
    name = db.Column(db.String(100), nullable=False)
    phone = db.Column(db.String(20), nullable=True)
    status = db.Column(db.Boolean, default=True)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)

    # Relationships
    orders = db.relationship('CourierOrder', backref='courier', lazy=True, cascade="all, delete-orphan")

    def to_dict(self):
        return {
            'id': self.id,
            'name': self.name,
            'phone': self.phone,
            'status': self.status,
            'created_at': self.created_at.isoformat() if self.created_at else None
        }

class CourierDailyInventory(db.Model):
    __tablename__ = 'courier_daily_inventory'
    
    id = db.Column(db.Integer, primary_key=True)
    courier_id = db.Column(db.Integer, db.ForeignKey('couriers.id'), nullable=False)
    date = db.Column(db.Date, nullable=False)
    shisha_boxes_received = db.Column(db.Integer, nullable=False, default=0)
    head_boxes_received = db.Column(db.Integer, nullable=False, default=0)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)

    courier = db.relationship('Courier', backref=db.backref('inventories', lazy=True, cascade="all, delete-orphan"))

    def to_dict(self):
        return {
            'id': self.id,
            'courier_id': self.courier_id,
            'date': self.date.isoformat() if self.date else None,
            'shisha_boxes_received': self.shisha_boxes_received,
            'head_boxes_received': self.head_boxes_received
        }


class CourierOrder(db.Model):
    __tablename__ = 'courier_orders'
    
    id = db.Column(db.Integer, primary_key=True)
    courier_id = db.Column(db.Integer, db.ForeignKey('couriers.id'), nullable=False)
    district = db.Column(db.String(100), nullable=False)
    shisha_boxes_used = db.Column(db.Integer, nullable=False, default=0)
    head_boxes_used = db.Column(db.Integer, nullable=False, default=0)
    shisha_price = db.Column(db.Float, nullable=False, default=0.0)
    head_price = db.Column(db.Float, nullable=False, default=0.0)
    boxes_count = db.Column(db.Integer, nullable=False, default=1) # Deprecated
    box_price = db.Column(db.Float, nullable=False, default=0.0) # Deprecated
    delivery_fee = db.Column(db.Float, nullable=False, default=0.0)
    cash_amount = db.Column(db.Float, nullable=False, default=0.0)
    card_amount = db.Column(db.Float, nullable=False, default=0.0)
    total = db.Column(db.Float, nullable=False, default=0.0)
    
    # Statuses: 'قيد التوصيل', 'تم التوصيل', 'ملغي'
    order_status = db.Column(db.String(50), nullable=False, default='قيد التوصيل') 
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    
    def calculate_total(self):
        self.boxes_count = self.shisha_boxes_used + self.head_boxes_used
        
        # Use new separate prices if provided, otherwise default to legacy box_price logic
        s_price = self.shisha_price if self.shisha_price > 0 else self.box_price
        h_price = self.head_price if self.head_price > 0 else self.box_price
        
        self.total = (self.shisha_boxes_used * s_price) + (self.head_boxes_used * h_price) + self.delivery_fee

        return {
            'id': self.id,
            'courier_id': self.courier_id,
            'courier_name': self.courier.name if self.courier else '',
            'district': self.district,
            'shisha_boxes_used': self.shisha_boxes_used,
            'head_boxes_used': self.head_boxes_used,
            'shisha_price': self.shisha_price,
            'head_price': self.head_price,
            'boxes_count': self.boxes_count,
            'box_price': self.box_price,
            'delivery_fee': self.delivery_fee,
            'cash_amount': self.cash_amount,
            'card_amount': self.card_amount,
            'total': self.total,
            'order_status': self.order_status,
            'created_at': self.created_at.isoformat() if self.created_at else None
        }
