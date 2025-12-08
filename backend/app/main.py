# Copyright (c) 2025 CuongKenn and ICTU-OpenAgri Contributors
# Licensed under the MIT License. See LICENSE file in the project root for full license information.

"""
Main FastAPI application entry point.
"""
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from app.infrastructure.config.settings import get_settings
from app.presentation.api.v1.router import api_router
from app.infrastructure.database.database import init_db, AsyncSessionLocal
# Import models to register them with Base
from app.infrastructure.database import models

from app.infrastructure.database.models.user_model import UserModel
from app.infrastructure.security.jwt import get_password_hash
from sqlalchemy.future import select
from app.scheduler import start_scheduler

settings = get_settings()

cors_origins = settings.CORS_ORIGINS or ["*"]
allow_credentials = True

if "*" in cors_origins:
    # Browsers reject wildcard origins when credentials are allowed.
    cors_origins = ["*"]
    allow_credentials = False

app = FastAPI(
    title=settings.PROJECT_NAME,
    version=settings.VERSION,
    description="ICTU-OpenAgri API",
    docs_url="/api/docs",
    redoc_url="/api/redoc",
    openapi_url="/api/openapi.json"
)

@app.on_event("startup")
async def startup_event():
    """Initialize database and create admin user on startup."""
    # Startup: Initialize database
    await init_db()
    
    # Start Scheduler
    start_scheduler()
    
    # Create admin user if not exists
    async with AsyncSessionLocal() as session:
        try:
            # Check if admin exists by email or username
            result = await session.execute(
                select(UserModel).where(
                    (UserModel.email == settings.ADMIN_EMAIL) | 
                    (UserModel.username == "admin")
                )
            )
            admin_user = result.scalars().first()
            
            if not admin_user:
                new_admin = UserModel(
                    email=settings.ADMIN_EMAIL,
                    username="admin",
                    full_name="System Administrator",
                    hashed_password=get_password_hash(settings.ADMIN_PASSWORD),
                    is_active=True,
                    is_superuser=True
                )
                session.add(new_admin)
                await session.commit()
                print(f"Admin user created with email: {settings.ADMIN_EMAIL}")
            else:
                print(f"Admin user already exists (username: {admin_user.username}, email: {admin_user.email})")
        except Exception as e:
            print(f"Error creating admin user: {e}")

# Configure CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=cors_origins,
    allow_credentials=allow_credentials,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Include API router
app.include_router(api_router, prefix="/api/v1")


@app.get("/health")
async def health_check():
    """Health check endpoint."""
    return {"status": "healthy", "version": settings.VERSION}
