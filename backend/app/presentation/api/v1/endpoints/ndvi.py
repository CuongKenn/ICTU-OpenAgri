# Copyright (c) 2025 CuongKenn and ICTU-OpenAgri Contributors
# Licensed under the MIT License. See LICENSE file in the project root for full license information.

from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession
from app.application.dto.ndvi_dto import NDVIRequest, NDVIResponse
from app.application.use_cases.ndvi_use_cases import CalculateNDVIUseCase
from app.domain.entities.user import User
from app.presentation.deps import get_current_user
from app.infrastructure.database.database import get_db

router = APIRouter()

@router.post("/calculate", response_model=NDVIResponse)
async def calculate_ndvi(
    request: NDVIRequest,
    use_case: CalculateNDVIUseCase = Depends(CalculateNDVIUseCase),
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """
    Calculate NDVI for a given bounding box and date.
    Downloads Sentinel-2 data and processes it.
    Requires authentication.
    """
    return await use_case.execute(request, db)
