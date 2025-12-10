# Copyright (c) 2025 CuongKenn and ICTU-OpenAgri Contributors
# Licensed under the MIT License. See LICENSE file in the project root for full license information.

"""
API v1 router.
"""
from fastapi import APIRouter
from app.presentation.api.v1.endpoints import users, ndvi, soil_moisture, commodity_prices, pest
from app.presentation.api import farm_api

api_router = APIRouter()

api_router.include_router(users.router, prefix="/users", tags=["users"])
api_router.include_router(farm_api.router, prefix="/farms", tags=["farms"])
api_router.include_router(ndvi.router, prefix="/ndvi", tags=["ndvi"])
api_router.include_router(soil_moisture.router, prefix="/soil-moisture", tags=["soil-moisture"])
api_router.include_router(commodity_prices.router, prefix="/commodity-prices", tags=["commodity-prices"])
api_router.include_router(pest.router, prefix="/pest", tags=["pest"])

from app.presentation.api.v1.endpoints import disease_detection
api_router.include_router(disease_detection.router, prefix="/disease-detection", tags=["disease-detection"])

# Weather router - import after others
from app.presentation.api.v1.endpoints import weather
api_router.include_router(weather.router, prefix="/weather", tags=["weather"])

# FIWARE router
from app.presentation.api.v1.endpoints import fiware
api_router.include_router(fiware.router, prefix="/fiware", tags=["fiware"])

# Admin router - import admin endpoints
from app.presentation.api.admin.admin_router import admin_router
api_router.include_router(admin_router, prefix="/admin", tags=["admin"])
