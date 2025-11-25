"""Weather domain models."""
from pydantic import BaseModel
from typing import Optional, List
from datetime import datetime


class LocationCoordinates(BaseModel):
    """Location coordinates."""
    latitude: float
    longitude: float


class LocationInfo(BaseModel):
    """Location information."""
    latitude: float
    longitude: float
    name: str
    address: Optional[str] = None
    country: Optional[str] = None


class WeatherData(BaseModel):
    """Weather forecast data."""
    time: datetime
    temperature: float
    relative_humidity: int
    weather_code: int
    wind_speed: float
    precipitation: float


class WeatherForecast(BaseModel):
    """Weather forecast response."""
    location: LocationInfo
    hourly: List[WeatherData]
    daily: Optional[List[WeatherData]] = None


class LocationSearchResult(BaseModel):
    """Location search result."""
    latitude: float
    longitude: float
    name: str
    address: str
    osm_id: Optional[int] = None
    osm_type: Optional[str] = None


class LocationSearchResponse(BaseModel):
    """Location search response."""
    results: List[LocationSearchResult]
    total: int
