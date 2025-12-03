# Copyright (c) 2025 CuongKenn and ICTU-OpenAgri Contributors
# Licensed under the MIT License. See LICENSE file in the project root for full license information.

"""
Main FastAPI application entry point.
"""
from contextlib import asynccontextmanager
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from app.infrastructure.config.settings import get_settings
from app.presentation.api.v1.router import api_router
from app.infrastructure.database.database import init_db
# Import models to register them with Base
from app.infrastructure.database import models

settings = get_settings()

@asynccontextmanager
async def lifespan(app: FastAPI):
    """Lifecycle events."""
    # Startup: Initialize database
    await init_db()
    yield
    # Shutdown: Clean up resources if needed

app = FastAPI(
    title=settings.PROJECT_NAME,
    version=settings.VERSION,
    description="ICTU-OpenAgri API",
    docs_url="/api/docs",
    redoc_url="/api/redoc",
    openapi_url="/api/openapi.json",
    lifespan=lifespan
)

# Configure CORS
app.add_middleware(
    CORSMiddleware,
    allow_origin_regex=".*",  # Allow all origins using regex
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Include API router
app.include_router(api_router, prefix="/api/v1")


@app.get("/health")
async def health_check():
    """Health check endpoint."""
    return {"status": "healthy", "version": settings.VERSION}

@app.on_event("startup")
async def create_admin_user():
    """Create an admin user on startup if it doesn't exist."""
    from app.infrastructure.database.session import get_async_session
    from app.infrastructure.database.models.user import User
    from app.infrastructure.security.password_hashing import get_password_hash
    from sqlalchemy.future import select

    async with get_async_session() as session:
        result = await session.execute(select(User).where(User.email == settings.ADMIN_EMAIL))
        admin_user = result.scalars().first()
        if not admin_user:
            new_admin = User(
                email=settings.ADMIN_EMAIL,
                hashed_password=get_password_hash(settings.ADMIN_PASSWORD),
                is_active=True,
                is_superuser=True
            )
            session.add(new_admin)
            await session.commit()
            print(f"Admin user created with email: {settings.ADMIN_EMAIL}")
        else:
            print("Admin user already exists.")