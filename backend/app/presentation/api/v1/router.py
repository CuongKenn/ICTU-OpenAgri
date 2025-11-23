"""
API v1 router.
"""
from fastapi import APIRouter
from app.presentation.api.v1.endpoints import users, ndvi

api_router = APIRouter()

api_router.include_router(users.router, prefix="/users", tags=["users"])
api_router.include_router(ndvi.router, prefix="/ndvi", tags=["ndvi"])
