"""
Weather API endpoints.
"""
from typing import Optional
from fastapi import APIRouter, HTTPException, Query, Path, status, Depends
import logging

from app.application.use_cases.weather_use_cases import (
    GetWeatherForecastUseCase,
    SearchLocationUseCase,
    ReverseGeocodeUseCase
)
from app.application.dto.weather_dto import (
    ForecastResponseDTO,
    LocationSearchResponseDTO,
    ReverseGeocodeDTO
)
from app.infrastructure.external_services.weather_service import (
    OpenMeteoService,
    PhotonGeocodingService
)
from app.domain.entities.user import User
from app.presentation.deps import get_current_user

logger = logging.getLogger(__name__)

router = APIRouter()


@router.get(
    "/forecast",
    response_model=ForecastResponseDTO,
    summary="Get weather forecast",
    description="Get weather forecast for a specific location"
)
async def get_weather_forecast(
    latitude: float = Query(..., ge=-90, le=90, description="Location latitude"),
    longitude: float = Query(..., ge=-180, le=180, description="Location longitude"),
    location_name: Optional[str] = Query(None, description="Optional location name"),
    hours_ahead: int = Query(24, ge=1, le=240, description="Number of hours to forecast"),
    current_user: User = Depends(get_current_user)
) -> ForecastResponseDTO:
    """
    Get weather forecast for given coordinates.
    
    - **latitude**: Location latitude (-90 to 90)
    - **longitude**: Location longitude (-180 to 180)
    - **location_name**: Optional custom location name
    - **hours_ahead**: Hours to forecast (1-240, default: 24)
    
    Returns current weather and hourly forecast data from Open-Meteo.
    """
    try:
        open_meteo_service = OpenMeteoService()
        photon_service = PhotonGeocodingService()
        use_case = GetWeatherForecastUseCase(open_meteo_service, photon_service)
        return await use_case.execute(
            latitude=latitude,
            longitude=longitude,
            location_name=location_name,
            hours_ahead=hours_ahead
        )
    except ValueError as e:
        logger.warning(f"Validation error: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=str(e)
        )
    except Exception as e:
        logger.error(f"Error fetching forecast: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to fetch weather forecast"
        )


@router.get(
    "/search",
    response_model=LocationSearchResponseDTO,
    summary="Search locations",
    description="Search for locations by query string"
)
async def search_locations(
    query: str = Query(..., min_length=1, max_length=100, description="Search query"),
    limit: int = Query(10, ge=1, le=50, description="Maximum number of results"),
    current_user: User = Depends(get_current_user)
) -> LocationSearchResponseDTO:
    """
    Search for locations by name or address.
    
    - **query**: Search query (city name, address, etc.)
    - **limit**: Maximum results to return (1-50, default: 10)
    
    Returns list of matching locations with coordinates from Photon API.
    """
    try:
        photon_service = PhotonGeocodingService()
        use_case = SearchLocationUseCase(photon_service)
        return await use_case.execute(query=query, limit=limit)
    except ValueError as e:
        logger.warning(f"Search validation error: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=str(e)
        )
    except Exception as e:
        logger.error(f"Error searching locations: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to search locations"
        )


@router.get(
    "/location/{latitude}/{longitude}",
    response_model=ReverseGeocodeDTO,
    summary="Get location details",
    description="Get location name and address from coordinates (reverse geocoding)"
)
async def get_location_details(
    latitude: float = Path(..., ge=-90, le=90, description="Location latitude"),
    longitude: float = Path(..., ge=-180, le=180, description="Location longitude"),
    current_user: User = Depends(get_current_user)
) -> ReverseGeocodeDTO:
    """
    Get location information from coordinates.
    
    - **latitude**: Location latitude (-90 to 90)
    - **longitude**: Location longitude (-180 to 180)
    
    Returns location name, address, country, and other details from Photon API.
    """
    try:
        photon_service = PhotonGeocodingService()
        use_case = ReverseGeocodeUseCase(photon_service)
        return await use_case.execute(latitude=latitude, longitude=longitude)
    except ValueError as e:
        logger.warning(f"Reverse geocode validation error: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=str(e)
        )
    except Exception as e:
        logger.error(f"Error reverse geocoding: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to reverse geocode location"
        )
