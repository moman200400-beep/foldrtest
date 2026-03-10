from flask import render_template, request, redirect, url_for, flash
from . import admin_bp
from app.models import Courier, CourierOrder, CourierDailyInventory
from src.backend.core.extensions import db
from src.backend.models.delivery.driver import Driver
from datetime import datetime, timedelta

@admin_bp.route('/couriers')
def couriers_list():
    couriers = Courier.query.all()
    return render_template('admin/couriers.html', couriers=couriers, title='إدارة المندوبين')

@admin_bp.route('/couriers/add', methods=['POST'])
def add_courier():
    name = request.form.get('name')
    phone = request.form.get('phone')
    status = request.form.get('status') == 'on'
    
    if name:
        new_courier = Courier(name=name, phone=phone, status=status)
        db.session.add(new_courier)
        # Auto-sync: also create matching Driver record
        drv = Driver(name=name, phone=phone or '', is_active=status)
        db.session.add(drv)
        db.session.commit()
    return redirect(url_for('admin.couriers_list'))

@admin_bp.route('/couriers/edit/<int:id>', methods=['POST'])
def edit_courier(id):
    courier = Courier.query.get_or_404(id)
    courier.name = request.form.get('name')
    courier.phone = request.form.get('phone')
    courier.status = request.form.get('status') == 'on'
    # Auto-sync: update matching Driver
    drv = Driver.query.filter_by(phone=courier.phone).first()
    if not drv:
        drv = Driver.query.filter_by(name=courier.name).first()
    if drv:
        drv.name = courier.name
        drv.phone = courier.phone or ''
        drv.is_active = courier.status
    db.session.commit()
    return redirect(url_for('admin.couriers_list'))

@admin_bp.route('/couriers/delete/<int:id>', methods=['POST'])
def delete_courier(id):
    courier = Courier.query.get_or_404(id)
    # Auto-sync: delete matching Driver
    drv = Driver.query.filter_by(name=courier.name).first()
    if not drv:
        drv = Driver.query.filter_by(phone=courier.phone).first()
    if drv:
        db.session.delete(drv)
    db.session.delete(courier)
    db.session.commit()
    return redirect(url_for('admin.couriers_list'))


@admin_bp.route('/courier_orders')
def courier_orders_list():
    filter_type = request.args.get('filter', 'today')
    date_str = request.args.get('date', '')

    query = CourierOrder.query

    # Time filtering
    now = datetime.utcnow()
    # Saudi Arabia time adjustment roughly +3 hours
    saudi_now = now + timedelta(hours=3)
    today_start = saudi_now.replace(hour=0, minute=0, second=0, microsecond=0) - timedelta(hours=3)
    
    if filter_type == 'today':
        query = query.filter(CourierOrder.created_at >= today_start)
    elif filter_type == 'yesterday':
        yesterday_start = today_start - timedelta(days=1)
        query = query.filter(CourierOrder.created_at >= yesterday_start, CourierOrder.created_at < today_start)
    elif filter_type == 'week':
        week_start = today_start - timedelta(days=7)
        query = query.filter(CourierOrder.created_at >= week_start)
    elif filter_type == 'custom' and date_str:
        try:
            custom_date = datetime.strptime(date_str, '%Y-%m-%d')
            custom_start = custom_date - timedelta(hours=3)
            custom_end = custom_start + timedelta(days=1)
            query = query.filter(CourierOrder.created_at >= custom_start, CourierOrder.created_at < custom_end)
        except ValueError:
            pass

    orders = query.order_by(CourierOrder.created_at.desc()).all()
    couriers = Courier.query.filter_by(status=True).all()
    
    # Fetch today's inventories
    today_date = saudi_now.date()
    inventories = CourierDailyInventory.query.filter_by(date=today_date).all()
    inventory_map = {inv.courier_id: inv for inv in inventories}
    
    # Calculate used boxes for today to easily show 'remaining' even on the orders page
    couriers_data = []
    for c in couriers:
        # Get orders for today for this courier
        todays_orders = CourierOrder.query.filter(
            CourierOrder.courier_id == c.id, 
            CourierOrder.order_status != 'ملغي', 
            CourierOrder.created_at >= today_start
        ).all()
        shisha_used = sum(o.shisha_boxes_used for o in todays_orders)
        head_used = sum(o.head_boxes_used for o in todays_orders)
        
        inv = inventory_map.get(c.id)
        couriers_data.append({
            'courier': c,
            'inventory': inv,
            'shisha_used': shisha_used,
            'head_used': head_used,
        })
    
    return render_template('admin/courier_orders.html', orders=orders, couriers_data=couriers_data, filter_type=filter_type)


@admin_bp.route('/courier_orders/add', methods=['POST'])
def add_courier_order():
    try:
        courier_id = request.form.get('courier_id', type=int)
        district = request.form.get('district')
        shisha_boxes_used = request.form.get('shisha_boxes_used', type=int, default=0)
        head_boxes_used = request.form.get('head_boxes_used', type=int, default=0)
        shisha_price = request.form.get('shisha_price', type=float, default=0.0)
        head_price = request.form.get('head_price', type=float, default=0.0)
        delivery_fee = request.form.get('delivery_fee', type=float, default=0.0)
        cash_amount = request.form.get('cash_amount', type=float, default=0.0)
        card_amount = request.form.get('card_amount', type=float, default=0.0)
        
        new_order = CourierOrder(
            courier_id=courier_id,
            district=district,
            shisha_boxes_used=shisha_boxes_used,
            head_boxes_used=head_boxes_used,
            shisha_price=shisha_price,
            head_price=head_price,
            delivery_fee=delivery_fee,
            cash_amount=cash_amount,
            card_amount=card_amount
        )
        new_order.calculate_total()
        
        db.session.add(new_order)
        db.session.commit()
    except Exception as e:
        flash(f'خطأ أثناء إضافة الطلب: {str(e)}')
        
    return redirect(url_for('admin.courier_orders_list'))

@admin_bp.route('/courier_orders/edit_status/<int:id>', methods=['POST'])
def edit_courier_order_status(id):
    order = CourierOrder.query.get_or_404(id)
    new_status = request.form.get('order_status')
    if new_status:
        order.order_status = new_status
        db.session.commit()
    
    # redirect back to where came from
    return redirect(request.referrer or url_for('admin.courier_orders_list'))

@admin_bp.route('/courier_inventory/update', methods=['POST'])
def update_courier_inventory():
    courier_id = request.form.get('courier_id', type=int)
    shisha_qty = request.form.get('shisha_received', type=int, default=0)
    head_qty = request.form.get('head_received', type=int, default=0)
    
    # Check if inventory exists for today
    now = datetime.utcnow()
    saudi_now = now + timedelta(hours=3)
    today_date = saudi_now.date()
    
    inventory = CourierDailyInventory.query.filter_by(courier_id=courier_id, date=today_date).first()
    if inventory:
        inventory.shisha_boxes_received += shisha_qty
        inventory.head_boxes_received += head_qty
    else:
        inventory = CourierDailyInventory(
            courier_id=courier_id,
            date=today_date,
            shisha_boxes_received=shisha_qty,
            head_boxes_received=head_qty
        )
        db.session.add(inventory)
    
    try:
        db.session.commit()
        flash('تم تحديث العهدة الصباحية للمندوب بنجاح.', 'success')
    except Exception as e:
        flash(f'خطأ أثناء تحديث العهدة: {str(e)}', 'error')
        
    return redirect(url_for('admin.courier_orders_list'))


@admin_bp.route('/courier_reports')
def courier_reports():
    filter_type = request.args.get('filter', 'today')
    date_str = request.args.get('date', '')

    now = datetime.utcnow()
    saudi_now = now + timedelta(hours=3)
    today_start = saudi_now.replace(hour=0, minute=0, second=0, microsecond=0) - timedelta(hours=3)
    
    start_date = today_start
    end_date = None

    if filter_type == 'yesterday':
        start_date = today_start - timedelta(days=1)
        end_date = today_start
    elif filter_type == 'week':
        start_date = today_start - timedelta(days=7)
    elif filter_type == 'month':
        start_date = today_start - timedelta(days=30)
    elif filter_type == 'custom' and date_str:
        try:
            custom_date = datetime.strptime(date_str, '%Y-%m-%d')
            start_date = custom_date - timedelta(hours=3)
            end_date = start_date + timedelta(days=1)
        except ValueError:
            pass

    couriers = Courier.query.all()
    report_data = []
    
    for courier in couriers:
        query = CourierOrder.query.filter(CourierOrder.courier_id == courier.id, CourierOrder.order_status != 'ملغي', CourierOrder.created_at >= start_date)
        if end_date:
            query = query.filter(CourierOrder.created_at < end_date)
            
        c_orders = query.all()
        
        total_shisha_used = sum(o.shisha_boxes_used for o in c_orders)
        total_head_used = sum(o.head_boxes_used for o in c_orders)
        total_boxes = sum(o.boxes_count for o in c_orders)
        total_delivery = sum(o.delivery_fee for o in c_orders)
        total_cash = sum(o.cash_amount for o in c_orders)
        total_card = sum(o.card_amount for o in c_orders)
        grand_total = sum(o.total for o in c_orders)
        
        local_start_date = (start_date + timedelta(hours=3)).date()
        inv_query = CourierDailyInventory.query.filter(
            CourierDailyInventory.courier_id == courier.id,
            CourierDailyInventory.date >= local_start_date
        )
        if end_date:
            local_end_date = (end_date + timedelta(hours=3)).date()
            inv_query = inv_query.filter(CourierDailyInventory.date < local_end_date)
            
        inv_list = inv_query.all()
        shisha_received = sum(i.shisha_boxes_received for i in inv_list)
        head_received = sum(i.head_boxes_received for i in inv_list)
        
        report_data.append({
            'courier': courier,
            'orders_count': len(c_orders),
            'total_boxes': total_boxes,
            'total_shisha_used': total_shisha_used,
            'total_head_used': total_head_used,
            'shisha_received': shisha_received,
            'head_received': head_received,
            'shisha_remaining': shisha_received - total_shisha_used,
            'head_remaining': head_received - total_head_used,
            'total_delivery': total_delivery,
            'total_cash': total_cash,
            'total_card': total_card,
            'grand_total': grand_total
        })
        
    # Sort by performance (grand_total DESC)
    report_data.sort(key=lambda x: x['grand_total'], reverse=True)
        
    return render_template('admin/courier_reports.html', reports=report_data, filter_type=filter_type, date_str=date_str)

@admin_bp.route('/courier_close_day', methods=['POST'])
def courier_close_day():
    flash('تم إغلاق اليوم بنجاح و أرشفة الطلبات.')
    return redirect(url_for('admin.courier_reports'))


@admin_bp.route('/courier_reports/print_all')
def courier_reports_print_all():
    filter_type = request.args.get('filter', 'today')
    date_str = request.args.get('date', '')

    now = datetime.utcnow()
    saudi_now = now + timedelta(hours=3)
    today_start = saudi_now.replace(hour=0, minute=0, second=0, microsecond=0) - timedelta(hours=3)
    
    start_date = today_start
    end_date = None

    if filter_type == 'yesterday':
        start_date = today_start - timedelta(days=1)
        end_date = today_start
    elif filter_type == 'week':
        start_date = today_start - timedelta(days=7)
    elif filter_type == 'month':
        start_date = today_start - timedelta(days=30)
    elif filter_type == 'custom' and date_str:
        try:
            custom_date = datetime.strptime(date_str, '%Y-%m-%d')
            start_date = custom_date - timedelta(hours=3)
            end_date = start_date + timedelta(days=1)
        except ValueError:
            pass

    couriers = Courier.query.all()
    report_data = []
    
    for courier in couriers:
        query = CourierOrder.query.filter(CourierOrder.courier_id == courier.id, CourierOrder.order_status != 'ملغي', CourierOrder.created_at >= start_date)
        if end_date:
            query = query.filter(CourierOrder.created_at < end_date)
            
        c_orders = query.all()
        if not c_orders:
            continue
            
        total_shisha_used = sum(o.shisha_boxes_used for o in c_orders)
        total_head_used = sum(o.head_boxes_used for o in c_orders)
        
        local_start_date = (start_date + timedelta(hours=3)).date()
        inv_query = CourierDailyInventory.query.filter(
            CourierDailyInventory.courier_id == courier.id,
            CourierDailyInventory.date >= local_start_date
        )
        if end_date:
            local_end_date = (end_date + timedelta(hours=3)).date()
            inv_query = inv_query.filter(CourierDailyInventory.date < local_end_date)
            
        inv_list = inv_query.all()
        shisha_received = sum(i.shisha_boxes_received for i in inv_list)
        head_received = sum(i.head_boxes_received for i in inv_list)
            
        report_data.append({
            'courier': courier,
            'orders_count': len(c_orders),
            'total_boxes': sum(o.boxes_count for o in c_orders),
            'total_shisha_used': total_shisha_used,
            'total_head_used': total_head_used,
            'shisha_received': shisha_received,
            'head_received': head_received,
            'shisha_remaining': shisha_received - total_shisha_used,
            'head_remaining': head_received - total_head_used,
            'total_delivery': sum(o.delivery_fee for o in c_orders),
            'total_cash': sum(o.cash_amount for o in c_orders),
            'total_card': sum(o.card_amount for o in c_orders),
            'grand_total': sum(o.total for o in c_orders)
        })
        
    report_data.sort(key=lambda x: x['grand_total'], reverse=True)
    
    return render_template('admin/print_couriers_all.html', reports=report_data, print_date=saudi_now)


@admin_bp.route('/courier_reports/print/<int:courier_id>')
def courier_reports_print_single(courier_id):
    courier = Courier.query.get_or_404(courier_id)
    filter_type = request.args.get('filter', 'today')
    date_str = request.args.get('date', '')

    now = datetime.utcnow()
    saudi_now = now + timedelta(hours=3)
    today_start = saudi_now.replace(hour=0, minute=0, second=0, microsecond=0) - timedelta(hours=3)
    
    start_date = today_start
    end_date = None

    if filter_type == 'yesterday':
        start_date = today_start - timedelta(days=1)
        end_date = today_start
    elif filter_type == 'week':
        start_date = today_start - timedelta(days=7)
    elif filter_type == 'month':
        start_date = today_start - timedelta(days=30)
    elif filter_type == 'custom' and date_str:
        try:
            custom_date = datetime.strptime(date_str, '%Y-%m-%d')
            start_date = custom_date - timedelta(hours=3)
            end_date = start_date + timedelta(days=1)
        except ValueError:
            pass

    query = CourierOrder.query.filter(CourierOrder.courier_id == courier.id, CourierOrder.order_status != 'ملغي', CourierOrder.created_at >= start_date)
    if end_date:
        query = query.filter(CourierOrder.created_at < end_date)
        
    orders = query.order_by(CourierOrder.created_at.asc()).all()
    
    total_shisha_used = sum(o.shisha_boxes_used for o in orders)
    total_head_used = sum(o.head_boxes_used for o in orders)
    
    local_start_date = (start_date + timedelta(hours=3)).date()
    inv_query = CourierDailyInventory.query.filter(
        CourierDailyInventory.courier_id == courier.id,
        CourierDailyInventory.date >= local_start_date
    )
    if end_date:
        local_end_date = (end_date + timedelta(hours=3)).date()
        inv_query = inv_query.filter(CourierDailyInventory.date < local_end_date)
        
    inv_list = inv_query.all()
    shisha_received = sum(i.shisha_boxes_received for i in inv_list)
    head_received = sum(i.head_boxes_received for i in inv_list)
    
    summary = {
        'orders_count': len(orders),
        'total_boxes': sum(o.boxes_count for o in orders),
        'total_shisha_used': total_shisha_used,
        'total_head_used': total_head_used,
        'shisha_received': shisha_received,
        'head_received': head_received,
        'shisha_remaining': shisha_received - total_shisha_used,
        'head_remaining': head_received - total_head_used,
        'total_delivery': sum(o.delivery_fee for o in orders),
        'total_cash': sum(o.cash_amount for o in orders),
        'total_card': sum(o.card_amount for o in orders),
        'grand_total': sum(o.total for o in orders)
    }

    return render_template('admin/print_courier_single.html', courier=courier, orders=orders, summary=summary, print_date=saudi_now)
