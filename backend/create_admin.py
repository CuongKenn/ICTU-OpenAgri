"""
Script to create a default admin user.
Run this script to create an admin account with predefined credentials.
"""
import asyncio
import sys
from pathlib import Path

# Add parent directory to path to import app modules
sys.path.insert(0, str(Path(__file__).parent))

from app.infrastructure.database.database import AsyncSessionLocal
from app.infrastructure.database.models.user_model import UserModel
from app.infrastructure.security.jwt import get_password_hash
from sqlalchemy import select


async def create_admin_user():
    """Create default admin user if not exists."""
    
    # Admin credentials
    ADMIN_EMAIL = "admin@openagri.com"
    ADMIN_USERNAME = "admin"
    ADMIN_PASSWORD = "admin123"  # Change this in production!
    ADMIN_FULL_NAME = "Administrator"
    
    async with AsyncSessionLocal() as session:
        try:
            # Check if admin user already exists
            result = await session.execute(
                select(UserModel).where(UserModel.email == ADMIN_EMAIL)
            )
            existing_user = result.scalar_one_or_none()
            
            if existing_user:
                print(f"❌ Admin user already exists with email: {ADMIN_EMAIL}")
                print(f"   Username: {existing_user.username}")
                print(f"   Is Superuser: {existing_user.is_superuser}")
                return False
            
            # Create admin user
            admin_user = UserModel(
                email=ADMIN_EMAIL,
                username=ADMIN_USERNAME,
                hashed_password=get_password_hash(ADMIN_PASSWORD),
                full_name=ADMIN_FULL_NAME,
                is_active=True,
                is_superuser=True
            )
            
            session.add(admin_user)
            await session.commit()
            await session.refresh(admin_user)
            
            print("✅ Admin user created successfully!")
            print(f"   Email: {ADMIN_EMAIL}")
            print(f"   Username: {ADMIN_USERNAME}")
            print(f"   Password: {ADMIN_PASSWORD}")
            print(f"   Full Name: {ADMIN_FULL_NAME}")
            print(f"   User ID: {admin_user.id}")
            print("\n⚠️  IMPORTANT: Change the password after first login!")
            
            return True
            
        except Exception as e:
            await session.rollback()
            print(f"❌ Error creating admin user: {e}")
            return False


async def main():
    """Main function."""
    print("=" * 60)
    print("Creating Default Admin User")
    print("=" * 60)
    print()
    
    success = await create_admin_user()
    
    print()
    print("=" * 60)
    if success:
        print("Admin user creation completed successfully!")
    else:
        print("Admin user creation failed or user already exists.")
    print("=" * 60)


if __name__ == "__main__":
    asyncio.run(main())
