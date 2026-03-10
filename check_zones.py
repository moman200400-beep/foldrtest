#!/usr/bin/env python
from src.backend.app import create_app
from app.models import Zone, District

app = create_app()
with app.app_context():
    zones = Zone.query.all()
    print(f"Total Zones: {len(zones)}")
    for z in zones:
        print(f"  Zone {z.id}: '{z.name}' (active={z.is_active})")
        districts = District.query.filter_by(zone_id=z.id).all()
        print(f"    Total Districts: {len(districts)}")
        for d in districts:
            print(f"      District {d.id}: '{d.name}' (active={d.is_active})")
