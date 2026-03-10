# legacy wrapper for backwards compatibility
from src.backend.core.extensions import db

# import all models from new modular package so that existing
# imports "from app.models import User, Product, ..." continue to work
from src.backend.models.user import User
from src.backend.models.product import Product, Banner
from src.backend.models.ad import Ad
from src.backend.models.order import Order
from src.backend.models.ledger import Ledger
from src.backend.models.audit_log import AuditLog
from src.backend.models.wheel_log import WheelLog
from src.backend.models.system_setting import SystemSetting
from src.backend.models.cart import Cart
from src.backend.models.payment_log import PaymentLog
from src.backend.models.notification import Notification
from src.backend.models.delivery.zone import Zone
from src.backend.models.delivery.district import District
from src.backend.models.delivery.driver import Driver, DriverZone
from src.backend.models.delivery.delivery_log import DeliveryLog
from src.backend.models.neighborhood import Neighborhood
from src.backend.models.courier import Courier, CourierOrder, CourierDailyInventory
from src.backend.models.coupon import Coupon

# NOTE: All model definitions have been moved to src/backend/models/*.py
# This file now serves as a compatibility layer for existing imports