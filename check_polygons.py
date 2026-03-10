#!/usr/bin/env python
from src.backend.app import create_app
from app.models import Zone, District
import json

app = create_app()
with app.app_context():
    zones = Zone.query.all()
    for z in zones:
        print(f"Zone: {z.name}")
        print(f"  polygon_coords type: {type(z.polygon_coords)}")
        print(f"  polygon_coords value: {z.polygon_coords}")
        if z.polygon_coords:
            try:
                parsed = json.loads(z.polygon_coords)
                print(f"  parsed polygon: {parsed}")
            except:
                print(f"  ERROR parsing polygon")
        
        for d in z.districts:
            print(f"  District: {d.name}")
