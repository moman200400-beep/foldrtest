import sqlite3
import os

db_path = os.path.abspath('d:/Almizaj_ERP/almizaj_erp.db')
print('Connecting to', db_path)

conn = sqlite3.connect(db_path)
cursor = conn.cursor()

try:
    cursor.execute('ALTER TABLE "order" ADD COLUMN coupon_code TEXT')
    print('Added coupon_code column')
except sqlite3.OperationalError as e:
    print('coupon_code warning/error:', e)

try:
    cursor.execute('ALTER TABLE "order" ADD COLUMN discount_amount FLOAT DEFAULT 0.0')
    print('Added discount_amount column')
except sqlite3.OperationalError as e:
    print('discount_amount warning/error:', e)

conn.commit()
conn.close()
print('Done.')
