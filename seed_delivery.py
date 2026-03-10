from app import create_app
from src.backend.core.extensions import db
from app.models import Zone, District, Driver, DriverZone
import json

def seed_delivery_data():
    """إضافة بيانات تجريبية لنظام التوصيل"""

    # إنشاء مناطق
    zones_data = [
        {
            'name': 'الرياض - الوسطى',
            'zone_type': 'inside',
            'commission_rate': 10.0,
            'estimated_time': 25,
            'peak_enabled': True,
            'peak_multiplier': 1.5,
            'peak_start': '17:00',
            'peak_end': '22:00',
            'polygon_coords': json.dumps([[24.7136,46.6753],[24.7136,46.7753],[24.8136,46.7753],[24.8136,46.6753],[24.7136,46.6753]]),
            'color': '#8B5CF6'
        },
        {
            'name': 'الرياض - الشمالية',
            'zone_type': 'inside',
            'commission_rate': 12.0,
            'estimated_time': 30,
            'peak_enabled': True,
            'peak_multiplier': 1.3,
            'peak_start': '18:00',
            'peak_end': '21:00',
            'polygon_coords': json.dumps([[24.8136,46.6753],[24.8136,46.7753],[24.9136,46.7753],[24.9136,46.6753],[24.8136,46.6753]]),
            'color': '#10B981'
        },
        {
            'name': 'الرياض - الجنوبية',
            'zone_type': 'outside',
            'commission_rate': 15.0,
            'estimated_time': 45,
            'peak_enabled': False,
            'peak_multiplier': 1.0,
            'peak_start': '17:00',
            'peak_end': '22:00',
            'polygon_coords': json.dumps([[24.6136,46.6753],[24.6136,46.7753],[24.7136,46.7753],[24.7136,46.6753],[24.6136,46.6753]]),
            'color': '#F59E0B'
        }
    ]

    zones = []
    for zone_data in zones_data:
        zone = Zone(**zone_data)
        db.session.add(zone)
        zones.append(zone)

    db.session.commit()

    # إنشاء أحياء
    districts_data = [
        # منطقة الوسطى
        {'name': 'الملز', 'zone_id': zones[0].id, 'base_price': 8.0, 'packaging_cost': 2.0, 'night_surcharge': 3.0, 'free_delivery_above': 150.0},
        {'name': 'الصحافة', 'zone_id': zones[0].id, 'base_price': 10.0, 'packaging_cost': 2.0, 'night_surcharge': 3.0, 'free_delivery_above': 200.0},
        {'name': 'الملك فهد', 'zone_id': zones[0].id, 'base_price': 12.0, 'packaging_cost': 3.0, 'night_surcharge': 4.0, 'free_delivery_above': 250.0},

        # منطقة الشمالية
        {'name': 'الشمال', 'zone_id': zones[1].id, 'base_price': 15.0, 'packaging_cost': 3.0, 'night_surcharge': 5.0, 'free_delivery_above': 300.0},
        {'name': 'النخيل', 'zone_id': zones[1].id, 'base_price': 18.0, 'packaging_cost': 4.0, 'night_surcharge': 6.0, 'free_delivery_above': 350.0},

        # منطقة الجنوبية
        {'name': 'الجنوب', 'zone_id': zones[2].id, 'base_price': 25.0, 'packaging_cost': 5.0, 'night_surcharge': 8.0, 'free_delivery_above': 500.0},
        {'name': 'العقيق', 'zone_id': zones[2].id, 'base_price': 30.0, 'packaging_cost': 6.0, 'night_surcharge': 10.0, 'free_delivery_above': 600.0},
    ]

    for district_data in districts_data:
        district = District(**district_data)
        db.session.add(district)

    db.session.commit()

    # إنشاء مندوبين
    drivers_data = [
        {'name': 'أحمد محمد', 'phone': '0501234567', 'max_daily_orders': 15, 'commission_rate': 8.0, 'shift_start': '08:00', 'shift_end': '20:00'},
        {'name': 'محمد علي', 'phone': '0502345678', 'max_daily_orders': 12, 'commission_rate': 10.0, 'shift_start': '09:00', 'shift_end': '21:00'},
        {'name': 'فاطمة أحمد', 'phone': '0503456789', 'max_daily_orders': 10, 'commission_rate': 12.0, 'shift_start': '10:00', 'shift_end': '22:00'},
        {'name': 'علي حسن', 'phone': '0504567890', 'max_daily_orders': 18, 'commission_rate': 7.0, 'shift_start': '07:00', 'shift_end': '19:00'},
        {'name': 'سارة محمد', 'phone': '0505678901', 'max_daily_orders': 14, 'commission_rate': 9.0, 'shift_start': '11:00', 'shift_end': '23:00'},
    ]

    drivers = []
    for driver_data in drivers_data:
        driver = Driver(**driver_data)
        db.session.add(driver)
        drivers.append(driver)

    db.session.commit()

    # ربط المندوبين بالمناطق
    driver_zone_assignments = [
        # أحمد محمد - منطقتان
        {'driver_id': drivers[0].id, 'zone_id': zones[0].id},
        {'driver_id': drivers[0].id, 'zone_id': zones[1].id},

        # محمد علي - منطقة واحدة
        {'driver_id': drivers[1].id, 'zone_id': zones[0].id},

        # فاطمة أحمد - منطقتان
        {'driver_id': drivers[2].id, 'zone_id': zones[1].id},
        {'driver_id': drivers[2].id, 'zone_id': zones[2].id},

        # علي حسن - منطقة واحدة
        {'driver_id': drivers[3].id, 'zone_id': zones[2].id},

        # سارة محمد - منطقتان
        {'driver_id': drivers[4].id, 'zone_id': zones[0].id},
        {'driver_id': drivers[4].id, 'zone_id': zones[2].id},
    ]

    for assignment in driver_zone_assignments:
        driver_zone = DriverZone(**assignment)
        db.session.add(driver_zone)

    db.session.commit()

    print("✅ تم إضافة البيانات التجريبية لنظام التوصيل بنجاح!")

if __name__ == "__main__":
    app = create_app()
    with app.app_context():
        # التحقق من وجود بيانات
        if Zone.query.count() == 0:
            seed_delivery_data()
        else:
            print("البيانات موجودة بالفعل!")