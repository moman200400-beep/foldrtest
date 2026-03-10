from flask import render_template, request, session, redirect, url_for
from config import Config
from src.backend.core.extensions import db
from app.models import Order, User, Product, WheelLog
import json
from datetime import datetime, date

# 🌟 الحل هنا: استيراد admin_bp من العصب المركزي بدلاً من خلقه من جديد!
from app.admin import admin_bp

@admin_bp.route('/login', methods=['GET', 'POST'])
def login():
    error = ""
    if request.method == 'POST':
        password = request.form.get('password')
        if password == Config.ADMIN_PASS:
            session['user_id'] = 1
            session['role'] = 'admin'
            return redirect(url_for('admin.dashboard'))
        error = "الرمز السري غير صحيح ❌"
    return render_template('login.html', error=error)

@admin_bp.route('/logout')
def logout():
    session.clear()
    return redirect(url_for('admin.login'))

@admin_bp.route('/')
def dashboard():
    if 'user_id' not in session or session.get('role') != 'admin':
        return redirect(url_for('admin.login'))
    
    # 1. الإحصائيات المالية الأساسية
    completed_orders = Order.query.filter(Order.status.in_(['completed', 'paid'])).all()
    total_revenue = sum(o.total_amount for o in completed_orders)
    orders_count = len(completed_orders)
    
    # متوسط قيمة الطلب (Average Order Value - AOV)
    aov = round(total_revenue / orders_count, 2) if orders_count > 0 else 0.0

    # 2. إحصائيات المستخدمين ومعدل التحويل
    today = date.today()
    new_users_today = User.query.filter(User.created_at >= today).count()
    total_users = User.query.count()
    
    # معدل التحويل التقريبي (عدد الطلبات مقارنة بعدد المستخدمين)
    conversion_rate = round((orders_count / total_users * 100), 1) if total_users > 0 else 0.0

    # 3. تحليل المنتجات الأكثر مبيعاً (Top Selling)
    product_sales = {}
    for o in completed_orders:
        items = json.loads(o.cart_items)
        for item in items:
            name = item['name']
            qty = item['quantity']
            product_sales[name] = product_sales.get(name, 0) + qty
    
    # ترتيب المنتجات من الأعلى مبيعاً إلى الأقل (أعلى 5 منتجات)
    top_products = sorted(product_sales.items(), key=lambda x: x[1], reverse=True)[:5]

    # 4. تحليل عجلة الحظ (Win/Loss Ratio)
    total_spins = WheelLog.query.count()
    wins = WheelLog.query.filter(WheelLog.prize != 'خسارة').count()
    losses = total_spins - wins
    win_rate = round((wins / total_spins * 100), 1) if total_spins > 0 else 0.0

    return render_template('dashboard.html', 
                           revenue=total_revenue, 
                           orders_count=orders_count, 
                           aov=aov, 
                           new_users=new_users_today,
                           conversion_rate=conversion_rate,
                           top_products=top_products,
                           wheel_stats={"total": total_spins, "wins": wins, "losses": losses, "rate": win_rate})
