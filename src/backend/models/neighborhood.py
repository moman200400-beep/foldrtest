from src.backend.core.extensions import db

class Neighborhood(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    name = db.Column(db.String(100), nullable=False)
    delivery_price = db.Column(db.Float, default=0.0)
    is_active = db.Column(db.Boolean, default=True)

    def to_dict(self):
        return {
            'id': self.id,
            'name': self.name,
            'delivery_price': self.delivery_price,
            'is_active': self.is_active
        }
