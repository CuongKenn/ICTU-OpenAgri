import sqlite3
import os

db_path = "ictu_openagri.db"

if not os.path.exists(db_path):
    print(f"❌ Database file not found: {db_path}")
    print("   Please run the backend server first to initialize the database.")
else:
    print(f"✅ Database file exists: {db_path}")
    
    try:
        conn = sqlite3.connect(db_path)
        cursor = conn.cursor()
        
        cursor.execute("SELECT name FROM sqlite_master WHERE type='table'")
        tables = [row[0] for row in cursor.fetchall()]
        
        print(f"\n📋 Tables in database: {tables}")
        
        if 'users' in tables:
            cursor.execute("SELECT COUNT(*) FROM users")
            count = cursor.fetchone()[0]
            print(f"\n👥 Total users in database: {count}")
            
            cursor.execute("SELECT id, email, username, is_superuser FROM users")
            users = cursor.fetchall()
            if users:
                print("\nUsers:")
                for user in users:
                    print(f"  - ID: {user[0]}, Email: {user[1]}, Username: {user[2]}, Is Superuser: {user[3]}")
        else:
            print("\n❌ 'users' table does not exist!")
            
        conn.close()
    except Exception as e:
        print(f"❌ Error: {e}")
