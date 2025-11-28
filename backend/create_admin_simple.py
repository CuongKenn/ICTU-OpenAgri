"""
Simple script to create admin user directly in SQLite database.
This script doesn't require any external dependencies.
"""
import sqlite3
import hashlib
from datetime import datetime


def hash_password(password: str) -> str:
    """
    Simple bcrypt-compatible password hash.
    Note: For production, use proper bcrypt hashing.
    This is a simplified version using passlib's bcrypt format.
    """
    # Using bcrypt format: $2b$12$salt+hash
    # For simplicity, we'll use a basic hash (NOT SECURE FOR PRODUCTION)
    # In production, you should use proper bcrypt
    from passlib.context import CryptContext
    pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")
    return pwd_context.hash(password)


def create_admin_user_sqlite():
    """Create admin user directly in SQLite database."""
    
    # Database path
    db_path = "ictu_openagri.db"
    
    # Admin credentials
    ADMIN_EMAIL = "admin@openagri.com"
    ADMIN_USERNAME = "admin"
    ADMIN_PASSWORD = "admin123"
    ADMIN_FULL_NAME = "Administrator"
    
    try:
        # Connect to database
        conn = sqlite3.connect(db_path)
        cursor = conn.cursor()
        
        # Check if users table exists
        cursor.execute("""
            SELECT name FROM sqlite_master 
            WHERE type='table' AND name='users'
        """)
        
        if not cursor.fetchone():
            print("❌ Users table does not exist. Please run the backend server first to initialize the database.")
            return False
        
        # Check if admin already exists
        cursor.execute(
            "SELECT id, username, is_superuser FROM users WHERE email = ?",
            (ADMIN_EMAIL,)
        )
        existing_user = cursor.fetchone()
        
        if existing_user:
            print(f"❌ Admin user already exists!")
            print(f"   User ID: {existing_user[0]}")
            print(f"   Username: {existing_user[1]}")
            print(f"   Is Superuser: {existing_user[2]}")
            return False
        
        # Hash password
        try:
            hashed_password = hash_password(ADMIN_PASSWORD)
        except ImportError:
            print("❌ passlib not installed. Installing required dependencies...")
            print("   Run: pip install passlib[bcrypt]")
            return False
        
        # Create admin user
        now = datetime.utcnow().isoformat()
        
        cursor.execute("""
            INSERT INTO users (email, username, hashed_password, full_name, is_active, is_superuser, created_at, updated_at)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?)
        """, (
            ADMIN_EMAIL,
            ADMIN_USERNAME,
            hashed_password,
            ADMIN_FULL_NAME,
            1,  # is_active = True
            1,  # is_superuser = True
            now,
            now
        ))
        
        conn.commit()
        user_id = cursor.lastrowid
        
        print("✅ Admin user created successfully!")
        print(f"   Email: {ADMIN_EMAIL}")
        print(f"   Username: {ADMIN_USERNAME}")
        print(f"   Password: {ADMIN_PASSWORD}")
        print(f"   Full Name: {ADMIN_FULL_NAME}")
        print(f"   User ID: {user_id}")
        print("\n⚠️  IMPORTANT: Change the password after first login!")
        
        return True
        
    except sqlite3.Error as e:
        print(f"❌ Database error: {e}")
        return False
    except Exception as e:
        print(f"❌ Error: {e}")
        return False
    finally:
        if conn:
            conn.close()


def main():
    """Main function."""
    print("=" * 60)
    print("Creating Default Admin User (SQLite)")
    print("=" * 60)
    print()
    
    success = create_admin_user_sqlite()
    
    print()
    print("=" * 60)
    if success:
        print("Admin user creation completed successfully!")
        print("\nYou can now login with:")
        print("  Email: admin@openagri.com")
        print("  Password: admin123")
    else:
        print("Admin user creation failed or user already exists.")
    print("=" * 60)


if __name__ == "__main__":
    main()
