# Copyright (c) 2025 CuongKenn and ICTU-OpenAgri Contributors
# Licensed under the MIT License. See LICENSE file in the project root for full license information.

"""
Admin farm management endpoints.
"""
from typing import List
from fastapi import APIRouter, Depends, HTTPException, status, Query
from app.application.dto.farm_dto import AdminFarmAreaResponseDTO, CoordinateDTO, CropDistributionDTO, FarmLocationDTO
from app.infrastructure.repositories.farm_repository_impl import SQLAlchemyFarmRepository
from app.presentation.deps import get_farm_repository, get_current_superuser
from app.domain.entities.user import User

router = APIRouter()

@router.get("/farms", response_model=List[AdminFarmAreaResponseDTO])
async def list_all_farms(
    page: int = Query(1, ge=1, description="Page number"),
    page_size: int = Query(10, ge=1, le=100, description="Items per page"),
    repository: SQLAlchemyFarmRepository = Depends(get_farm_repository),
    current_user: User = Depends(get_current_superuser)
):
    """
    List all farms with user details.
    
    Requires admin privileges.
    """
    try:
        skip = (page - 1) * page_size
        results = await repository.get_all_with_user(skip=skip, limit=page_size)
        
        return [
            AdminFarmAreaResponseDTO(
                id=farm.id,
                name=farm.name,
                description=farm.description,
                coordinates=[CoordinateDTO(lat=c.lat, lng=c.lng) for c in farm.coordinates],
                area_size=farm.area_size,
                crop_type=farm.crop_type,
                user_id=farm.user_id,
                user_email=user_info["email"],
                user_full_name=user_info["full_name"],
                username=user_info["username"]
            )
            for farm, user_info in results
        ]
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to retrieve farms: {str(e)}"
        )

@router.get("/farms/stats/crops", response_model=List[CropDistributionDTO])
async def get_crop_distribution(
    repository: SQLAlchemyFarmRepository = Depends(get_farm_repository),
    current_user: User = Depends(get_current_superuser)
):
    """
    Get crop distribution statistics.
    """
    try:
        return await repository.get_crop_distribution()
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to retrieve crop stats: {str(e)}"
        )

@router.get("/farms/locations", response_model=List[FarmLocationDTO])
async def get_farm_locations(
    repository: SQLAlchemyFarmRepository = Depends(get_farm_repository),
    current_user: User = Depends(get_current_superuser)
):
    """
    Get all farm locations for map visualization.
    """
    try:
        # Note: This method needs to be implemented in the repository
        # For now, we'll assume it exists or use a workaround if needed
        # But based on my previous edit, I added get_all_locations to the repo
        results = await repository.get_all_locations()
        return [
            FarmLocationDTO(
                id=row["id"],
                name=row["name"],
                coordinates=[CoordinateDTO(**c) for c in row["coordinates"]],
                crop_type=row["crop_type"],
                owner_name=row["owner_name"]
            )
            for row in results
        ]
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to retrieve farm locations: {str(e)}"
        )
