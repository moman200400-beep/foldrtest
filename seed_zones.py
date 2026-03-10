#!/usr/bin/env python
import json
from src.backend.app import create_app
from app.models import Zone, District
from src.backend.core.extensions import db

app = create_app()
with app.app_context():
    # Create test data for delivery zones and districts
    
    # Zone 1: Riyadh North with polygon coordinates
    z1 = Zone.query.filter_by(id=1).first()
    if z1:
        # Coordinates for Riyadh North area (sample)
        riyadh_north_polygon = [
            [24.8500, 46.6000],  # top-left
            [24.8500, 46.8000],  # top-right
            [24.7200, 46.8000],  # bottom-right
            [24.7200, 46.6000],  # bottom-left
        ]
        z1.polygon_coords = json.dumps(riyadh_north_polygon)
        z1.name = 'المنطقه الشماليه'  # Ensure name is set
        z1.color = '#E0A6FF'
        z1.estimated_time = 15
        z1.commission_rate = 10.0
        z1.is_active = True
        db.session.commit()
        print("✅ Updated Zone 1 with polygon coordinates")
    
    # Add districts to Zone 1 if not exists
    if not District.query.filter_by(zone_id=1).first():
        districts_data = [
            {'name': 'النرجس', 'base_price': 15.0, 'zone_id': 1},
            {'name': 'الملز', 'base_price': 18.0, 'zone_id': 1},
            {'name': 'الربوة', 'base_price': 20.0, 'zone_id': 1},
        ]
        for d in districts_data:
            district = District(
                name=d['name'],
                base_price=d['base_price'],
                zone_id=d['zone_id'],
                is_active=True
            )
            db.session.add(district)
        db.session.commit()
        print("✅ Added 3 test districts to Zone 1")
    
    # Create Zone 2: East Riyadh
    z2 = Zone.query.filter_by(id=2).first()
    if not z2:
        riyadh_east_polygon = [
            [24.7500, 46.9000],  # top-left
            [24.7500, 47.1000],  # top-right
            [24.6000, 47.1000],  # bottom-right
            [24.6000, 46.9000],  # bottom-left
        ]
        z2 = Zone(
            name='المنطقه الشرقيه',
            color='#FFD700',
            estimated_time=20,
            polygon_coords=json.dumps(riyadh_east_polygon),
            is_active=True,
            commission_rate=10.0,
            peak_enabled=False
        )
        db.session.add(z2)
        db.session.commit()
        
        # Add districts to Zone 2
        districts_data = [
            {'name': 'العقيق', 'base_price': 12.0, 'zone_id': z2.id},
            {'name': 'الشاطئ', 'base_price': 14.0, 'zone_id': z2.id},
            {'name': 'حي بني مالك', 'base_price': 16.0, 'zone_id': z2.id},
        ]
        for d in districts_data:
            district = District(
                name=d['name'],
                base_price=d['base_price'],
                zone_id=d['zone_id'],
                is_active=True
            )
            db.session.add(district)
        db.session.commit()
        print("✅ Added Zone 2 (شرقيه) with 3 districts")
    else:
        # Update existing zone 2
        riyadh_east_polygon = [
            [24.7500, 46.9000],
            [24.7500, 47.1000],
            [24.6000, 47.1000],
            [24.6000, 46.9000],
        ]
        z2.polygon_coords = json.dumps(riyadh_east_polygon)
        db.session.commit()
        print("✅ Updated Zone 2 polygon")
    
    print("\n📊 Database Summary:")
    zones = Zone.query.all()
    for z in zones:
        districts = District.query.filter_by(zone_id=z.id).all()
        polygon_len = len(json.loads(z.polygon_coords or '[]'))
        print(f"  Zone '{z.name}': {len(districts)} districts, {polygon_len} polygon points")

