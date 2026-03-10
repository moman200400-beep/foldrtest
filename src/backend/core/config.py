import os
from dotenv import load_dotenv

BASE_DIR = os.path.abspath(os.path.dirname(__file__))
load_dotenv(os.path.join(BASE_DIR, '..', '..', '.env'))

class Config:
    SECRET_KEY = os.getenv('SECRET_KEY') or 'change-me'
    SQLALCHEMY_DATABASE_URI = os.getenv('DATABASE_URL') or \
        'sqlite:///' + os.path.join(BASE_DIR, '..', '..', 'almizaj_erp.db')
    SQLALCHEMY_TRACK_MODIFICATIONS = False
    ADMIN_PASS = os.getenv('ADMIN_PASS') or '202020'
    UPLOAD_FOLDER = os.getenv('UPLOAD_FOLDER') or os.path.join(BASE_DIR, '..', '..', 'app', 'static', 'uploads')
    MAX_CONTENT_LENGTH = 16 * 1024 * 1024
    ALLOWED_EXTENSIONS = {'png', 'jpg', 'jpeg', 'gif', 'webp'}
