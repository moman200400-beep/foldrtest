from src.backend.app import create_app
from src.backend.core.extensions import db
import src.backend.models

app = create_app()

with app.app_context():
    print("Creating new Mix Your Mood tables...")
    db.create_all()
    print("Done!")
