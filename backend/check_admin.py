"""Check if admin user exists in database."""
import sqlite3

db_path = "ictu_openagri.db"

try:
    conn = sqlite3.connect(db_path)
    cursor = conn.cursor()
    
    cursor.execute('SELECT id, email, username, is_superuser, is_active FROM users WHERE email = ?', 
                   ('admin@openagri.com',))
    result = cursor.fetchone()
    
    if result:
        print("✅ Admin user found in database!")
        print(f"   ID: {result[0]}")
        print(f"   Email: {result[1]}")
        print(f"   Username: {result[2]}")
        print(f"   Is Superuser: {bool(result[3])}")
        print(f"   Is Active: {bool(result[4])}")
    else:
        print("❌ Admin user not found in database.")
        print("   Run create_admin_simple.py to create the admin user.")
    
    conn.close()
    
except Exception as e:
    print(f"❌ Error: {e}")
