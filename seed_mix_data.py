from src.backend.app import create_app
from src.backend.core.extensions import db
from src.backend.models.mix import MixFlavor, MixMood, MixSize, MixSetting

app = create_app()

with app.app_context():
    print("Seeding Mix Your Mood initial data...")

    # Create MixSetting if none
    if not MixSetting.query.first():
        setting = MixSetting(max_flavors=3, min_percentage=10, max_percentage=100)
        db.session.add(setting)

    # Initial Moods
    moods = [
        {"name": "مزاج قوي", "icon": "🔥"},
        {"name": "مزاج فواكه", "icon": "🍓"},
        {"name": "مزاج بارد", "icon": "❄️"},
        {"name": "مزاج حلو", "icon": "🍬"},
        {"name": "مزاج منعش", "icon": "🌿"},
        {"name": "فاجئني", "icon": "🎲", "description": "خلطة عشوائية مذهلة"}
    ]
    for m in moods:
        if not MixMood.query.filter_by(name=m['name']).first():
            new_mood = MixMood(name=m['name'], icon=m['icon'], description=m.get('description', ''))
            db.session.add(new_mood)

    # Initial Flavors
    flavors = [
        {"name": "عنب", "icon": "🍇", "category": "فواكه"},
        {"name": "فراولة", "icon": "🍓", "category": "فواكه"},
        {"name": "أناناس", "icon": "🍍", "category": "فواكه"},
        {"name": "ليمون", "icon": "🍋", "category": "حمضيات"},
        {"name": "خوخ", "icon": "🍑", "category": "فواكه"},
        {"name": "بطيخ", "icon": "🍉", "category": "فواكه"},
        {"name": "تفاح أخضر", "icon": "🍏", "category": "فواكه"},
        {"name": "مانجو", "icon": "🥭", "category": "فواكه"},
        {"name": "نعناع", "icon": "🌿", "category": "منعش"},
        {"name": "آيس", "icon": "❄️", "category": "بارد"},
        {"name": "فانيلا", "icon": "🍬", "category": "حلو"}
    ]
    for f in flavors:
        if not MixFlavor.query.filter_by(name=f['name']).first():
            new_flavor = MixFlavor(name=f['name'], icon=f['icon'], category=f['category'])
            db.session.add(new_flavor)

    # Initial Sizes
    sizes = [
        {"name": "رأس واحد", "type": "head", "price": 10.0, "sort": 1},
        {"name": "رأسين", "type": "head", "price": 18.0, "sort": 2},
        {"name": "3 رؤوس", "type": "head", "price": 25.0, "sort": 3},
        {"name": "250 جرام", "type": "weight", "price": 30.0, "sort": 4},
        {"name": "500 جرام", "type": "weight", "price": 50.0, "sort": 5},
        {"name": "1 كيلو", "type": "weight", "price": 90.0, "sort": 6}
    ]
    for s in sizes:
        if not MixSize.query.filter_by(name=s['name']).first():
            new_size = MixSize(name=s['name'], type=s['type'], price=s['price'], sort_order=s['sort'])
            db.session.add(new_size)

    try:
        db.session.commit()
        print("Data seeded successfully!")
    except Exception as e:
        db.session.rollback()
        print(f"Failed to seed data: {e}")
