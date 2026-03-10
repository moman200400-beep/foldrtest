from flask import render_template, session, request, redirect, url_for
from app.admin import admin_bp
from app.models import Ledger, Order
from sqlalchemy import extract
from datetime import datetime

@admin_bp.route('/accounting')
def accounting_page():
    if 'user_id' not in session or session.get('role') != 'admin':
        return redirect(url_for('admin.login'))

    # الفلترة بالشهر
    month_str = request.args.get('month', datetime.utcnow().strftime('%Y-%m'))
    try:
        year, month = map(int, month_str.split('-'))
    except Exception:
        year, month = datetime.utcnow().year, datetime.utcnow().month
        month_str = f"{year}-{month:02d}"

    # جلب الحركات المحاسبية للشهر المحدد
    ledgers = Ledger.query.filter(
        extract('year', Ledger.created_at) == year,
        extract('month', Ledger.created_at) == month
    ).order_by(Ledger.id.desc()).all()
    
    total_income = 0
    total_refunds = 0
    total_cogs = 0 # Cost of Goods Sold (التكلفة)

    for l in ledgers:
        if l.trans_type == 'income':
            total_income += l.amount
            if l.order_id:
                o = Order.query.get(l.order_id)
                if o and o.total_cost:
                    total_cogs += o.total_cost
        elif l.trans_type == 'refund':
            total_refunds += abs(l.amount)

    # صافي الأرباح = الإيرادات - المرتجعات - التكلفة
    net_profit = total_income - total_refunds - total_cogs

    return render_template('accounting.html', 
                            ledgers=ledgers, 
                            income=total_income, 
                            refunds=total_refunds, 
                            cogs=total_cogs,
                            net=net_profit,
                            current_month=month_str)
