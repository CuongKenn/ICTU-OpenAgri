"""Weather forecast endpoints."""
import logging
from fastapi import APIRouter, HTTPException, Query
from app.application.weather_service import WeatherService
from app.domain.weather_models import (
    WeatherForecast,
    LocationSearchResponse,
    LocationInfo,
)

logger = logging.getLogger(__name__)

router = APIRouter()
weather_service = WeatherService()


@router.get("/forecast", response_model=WeatherForecast)
async def get_weather_forecast(
    latitude: float = Query(..., description="Latitude coordinate"),
    longitude: float = Query(..., description="Longitude coordinate"),
    location_name: str = Query(None, description="Optional location name"),
) -> WeatherForecast:
    """
    Get weather forecast for given coordinates.

    Args:
        latitude: Latitude coordinate
        longitude: Longitude coordinate
        location_name: Optional location name

    Returns:
        WeatherForecast with hourly data
    """
    try:
        forecast = await weather_service.get_weather_forecast(
            latitude=latitude,
            longitude=longitude,
            location_name=location_name,
        )
        return forecast
    except Exception as e:
        logger.error(f"Error getting weather forecast: {e}")
        raise HTTPException(status_code=500, detail="Failed to get weather forecast")


@router.get("/search", response_model=LocationSearchResponse)
async def search_locations(
    query: str = Query(..., description="Search query (address, place name)"),
    limit: int = Query(10, ge=1, le=50, description="Maximum number of results"),
) -> LocationSearchResponse:
    """
    Search locations by query.

    Args:
        query: Search query
        limit: Maximum number of results

    Returns:
        LocationSearchResponse with list of locations
    """
    try:
        results = await weather_service.search_locations(query=query, limit=limit)
        return results
    except Exception as e:
        logger.error(f"Error searching locations: {e}", exc_info=True)
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/location/{latitude}/{longitude}", response_model=LocationInfo)
async def get_location_info(
    latitude: float,
    longitude: float,
) -> LocationInfo:
    """
    Get location information from coordinates (reverse geocoding).

    Args:
        latitude: Latitude coordinate
        longitude: Longitude coordinate

    Returns:
        LocationInfo with location details
    """
    try:
        location = await weather_service.reverse_geocode(
            latitude=latitude, longitude=longitude
        )
        if location is None:
            raise HTTPException(status_code=404, detail="Location not found")
        return location
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error getting location info: {e}")
        raise HTTPException(status_code=500, detail="Failed to get location info")
