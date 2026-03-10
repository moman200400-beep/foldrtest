import sqlite3
import sys

def alter_db():
    conn = sqlite3.connect('almizaj_erp.db')
    cursor = conn.cursor()
    
    try:
        cursor.execute("ALTER TABLE ads ADD COLUMN description TEXT;")
        print("Added description to ads.")
    except Exception as e:
        print(f"Error adding description: {e}")
        
    try:
        cursor.execute("ALTER TABLE ads ADD COLUMN bg_color TEXT DEFAULT '#1E293B';")
        print("Added bg_color to ads.")
    except Exception as e:
        print(f"Error adding bg_color: {e}")
        
    conn.commit()
    conn.close()

if __name__ == '__main__':
    alter_db()
