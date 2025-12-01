# Copyright (c) 2025 CuongKenn and ICTU-OpenAgri Contributors
# Licensed under the MIT License. See LICENSE file in the project root for full license information.

"""
Pest risk forecasting API endpoints.
"""
from typing import List, Optional
from fastapi import APIRouter, Depends, Query, HTTPException, status
import logging

from app.application.use_cases.pest_use_cases import (
    GetPestRiskForecastUseCase,
    SearchSpeciesUseCase
)
from app.application.dto.pest_dto import (
    PestRiskForecastResponseDTO,
    SpeciesSearchResponseDTO
)
from app.infrastructure.external_services.gbif_service import GBIFService
from app.domain.entities.user import User
from app.presentation.deps import get_current_user

logger = logging.getLogger(__name__)

router = APIRouter()


@router.get(
    "/forecast",
    response_model=PestRiskForecastResponseDTO,
    summary="Get pest risk forecast",
    description="Get pest risk forecast based on historical occurrence data from GBIF"
)
async def get_pest_risk_forecast(
    latitude: float = Query(..., ge=-90, le=90, description="Location latitude"),
    longitude: float = Query(..., ge=-180, le=180, description="Location longitude"),
    radius_km: float = Query(10.0, ge=1.0, le=100.0, description="Search radius in km"),
    pest_names: Optional[List[str]] = Query(None, description="Specific pest scientific names to check"),
    years_back: int = Query(5, ge=1, le=20, description="Number of years to look back"),
    current_user: User = Depends(get_current_user)
) -> PestRiskForecastResponseDTO:
    """
    Get pest risk forecast for a location.
    
    - **latitude**: Location latitude
    - **longitude**: Location longitude
    - **radius_km**: Search radius in km (default: 10)
    - **pest_names**: Optional list of scientific names (e.g. "Nilaparvata lugens")
    - **years_back**: Years of history to analyze (default: 5)
    
    Returns risk warnings and historical occurrence data.
    """
    try:
        gbif_service = GBIFService()
        use_case = GetPestRiskForecastUseCase(gbif_service)
        
        return await use_case.execute(
            latitude=latitude,
            longitude=longitude,
            radius_km=radius_km,
            pest_scientific_names=pest_names,
            years_back=years_back
        )
    except Exception as e:
        logger.error(f"Error fetching pest forecast: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to fetch pest risk forecast"
        )


@router.get(
    "/search",
    response_model=SpeciesSearchResponseDTO,
    summary="Search pest species",
    description="Search for pest species by name in GBIF database"
)
async def search_species(
    query: str = Query(..., min_length=2, description="Species name query"),
    limit: int = Query(20, ge=1, le=100, description="Max results"),
    current_user: User = Depends(get_current_user)
) -> SpeciesSearchResponseDTO:
    """
    Search for species by name.
    
    - **query**: Name to search (common or scientific)
    - **limit**: Max results (default: 20)
    """
    try:
        gbif_service = GBIFService()
        use_case = SearchSpeciesUseCase(gbif_service)
        
        return await use_case.execute(query=query, limit=limit)
    except Exception as e:
        logger.error(f"Error searching species: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to search species"
        )
