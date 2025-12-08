# Copyright (c) 2025 CuongKenn and ICTU-OpenAgri Contributors
# Licensed under the MIT License. See LICENSE file in the project root for full license information.

from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession
from app.application.dto.soil_moisture_dto import (
    SoilMoistureRequest, SoilMoistureResponse,
    SoilMoistureQueryRequest, SoilMoistureQueryResponse
)
from app.application.use_cases.soil_moisture_use_cases import CalculateSoilMoistureUseCase, GetSoilMoistureUseCase
from app.domain.entities.user import User
from app.presentation.deps import get_current_user, get_db

router = APIRouter()


@router.post("/get", response_model=SoilMoistureQueryResponse)
async def get_soil_moisture(
    request: SoilMoistureQueryRequest,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """
    Get Soil Moisture data from database (cached from scheduled sync).
    This is the fast endpoint that returns pre-computed data.
    Requires authentication.
    """
    use_case = GetSoilMoistureUseCase()
    return await use_case.execute(request, db)


@router.post("/calculate", response_model=SoilMoistureResponse)
async def calculate_soil_moisture(
    request: SoilMoistureRequest,
    use_case: CalculateSoilMoistureUseCase = Depends(CalculateSoilMoistureUseCase),
    current_user: User = Depends(get_current_user)
):
    """
    Calculate Soil Moisture Proxy from Sentinel-1 data (real-time).
    Downloads Sentinel-1 GRD data and processes VV band.
    This is slow - prefer using /get endpoint for cached data.
    Requires authentication.
    """
    return await use_case.execute(request)
