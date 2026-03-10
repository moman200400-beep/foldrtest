from flask import render_template, request, session, redirect, url_for
from app.admin import admin_bp
from src.backend.core.extensions import db
from app.models import PaymentLog

@admin_bp.route('/payments')
def payments_page():
    if 'user_id' not in session or session.get('role') != 'admin':
        return redirect(url_for('admin.login'))

    # جلب جميع عمليات الدفع
    all_payments = PaymentLog.query.order_by(PaymentLog.id.desc()).all()
    
    # إحصائيات سريعة
    total_successful = sum(p.amount for p in all_payments if p.status == 'success')
    failed_count = sum(1 for p in all_payments if p.status == 'failed')
    duplicate_count = sum(1 for p in all_payments if p.status == 'duplicate')

    return render_template('payments.html', 
                           payments=all_payments, 
                           total_success=total_successful, 
                           failed_count=failed_count,
                           duplicate_count=duplicate_count)
