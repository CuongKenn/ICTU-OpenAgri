"""
API v1 router.
"""
import logging
from fastapi import APIRouter
from app.presentation.api.v1.endpoints import users, ndvi, soil_moisture, commodity_prices, weather
from app.presentation.api import farm_api

logger = logging.getLogger(__name__)

api_router = APIRouter()

api_router.include_router(users.router, prefix="/users", tags=["users"])
api_router.include_router(farm_api.router, prefix="/farms", tags=["farms"])
api_router.include_router(ndvi.router, prefix="/ndvi", tags=["ndvi"])
api_router.include_router(soil_moisture.router, prefix="/soil-moisture", tags=["soil-moisture"])
api_router.include_router(commodity_prices.router, prefix="/commodity-prices", tags=["commodity-prices"])
api_router.include_router(weather.router, prefix="/weather", tags=["weather"])
