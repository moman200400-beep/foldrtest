from app.utils import upload_image
from werkzeug.datastructures import FileStorage
import io
from src.backend.app import create_app

app = create_app()
with app.app_context():
    f = FileStorage(stream=io.BytesIO(b'test'), filename='example.png')
    url = upload_image(f)
    print('returned', url)
