from flask import Blueprint

admin_bp = Blueprint('admin', __name__, template_folder='../templates')

# 🌟 ميزة متقدمة (Context Processor): تمرير متغير "غير المقروءة" لكل صفحات HTML تلقائياً
@admin_bp.context_processor
def inject_notifications():
    from app.models import Notification
    try:
        unread_count = Notification.query.filter_by(is_read=False).count()
        return dict(unread_count=unread_count)
    except:
        return dict(unread_count=0)

from app.admin import dashboard, users, products, orders, accounting, system, carts, content, payments, notifications, delivery, ads, couriers

# تعريف الملفات
from app.admin import dashboard, users, products, orders, accounting, system, carts, content, payments, notifications, ads, couriers
