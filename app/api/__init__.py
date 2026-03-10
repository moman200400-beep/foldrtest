from flask import Blueprint

# تعريف قسم الـ API الخاص بتطبيق فلاتر
api_bp = Blueprint('api', __name__)
from flask import Blueprint
# استيراد الملفات الفرعية لكي يقرأها السيرفر
from app.api import products
from app.api import orders
from app.api import my_orders
from app.api import auth
from app.api import notifications
from app.api import delivery
from app.api import ads
from app.api import mix_api
from app.api import cart
from app.api import free_delivery