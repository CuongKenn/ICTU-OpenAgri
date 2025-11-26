"""
Weather API DTOs.
"""
from typing import Optional, List
from pydantic import BaseModel, Field


class LocationDTO(BaseModel):
    """Location information."""
    name: str
    country: str
    latitude: float
    longitude: float
    address: Optional[str] = None
    
    class Config:
        from_attributes = True


class HourlyWeatherDTO(BaseModel):
    """Hourly weather data."""
    time: str
    temperature_2m: float
    relative_humidity_2m: int
    weather_code: int
    wind_speed_10m: float
    precipitation: float
    
    class Config:
        from_attributes = True


class CurrentWeatherDTO(BaseModel):
    """Current weather data."""
    time: str
    temperature_2m: float
    relative_humidity_2m: int
    weather_code: int
    wind_speed_10m: float
    precipitation: float
    is_day: int
    
    class Config:
        from_attributes = True


class ForecastResponseDTO(BaseModel):
    """Weather forecast response."""
    location: LocationDTO
    current: CurrentWeatherDTO
    hourly: List[HourlyWeatherDTO]
    
    class Config:
        from_attributes = True


class LocationSearchDTO(BaseModel):
    """Location search result."""
    name: str
    latitude: float
    longitude: float
    country: str
    state: Optional[str] = None
    type: str = Field(default="location")
    
    class Config:
        from_attributes = True


class LocationSearchResponseDTO(BaseModel):
    """Location search response."""
    results: List[LocationSearchDTO]
    count: int
    
    class Config:
        from_attributes = True


class ReverseGeocodeDTO(BaseModel):
    """Reverse geocode response."""
    name: str
    country: str
    country_code: str
    state: Optional[str] = None
    address: Optional[str] = None
    latitude: float
    longitude: float
    
    class Config:
        from_attributes = True
