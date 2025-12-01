# Copyright (c) 2025 CuongKenn and ICTU-OpenAgri Contributors
# Licensed under the MIT License. See LICENSE file in the project root for full license information.

"""
Weather use cases - business logic layer.
"""
import logging
from typing import Optional, List, Dict, Any
from datetime import datetime

from app.infrastructure.external_services.weather_service import (
    OpenMeteoService,
    PhotonGeocodingService
)
from app.application.dto.weather_dto import (
    ForecastResponseDTO,
    LocationDTO,
    CurrentWeatherDTO,
    HourlyWeatherDTO,
    LocationSearchResponseDTO,
    LocationSearchDTO,
    ReverseGeocodeDTO
)

logger = logging.getLogger(__name__)


class GetWeatherForecastUseCase:
    """Get weather forecast for a location."""
    
    def __init__(
        self,
        open_meteo_service: OpenMeteoService,
        photon_service: PhotonGeocodingService
    ):
        self.open_meteo_service = open_meteo_service
        self.photon_service = photon_service
    
    async def execute(
        self,
        latitude: float,
        longitude: float,
        location_name: Optional[str] = None,
        hours_ahead: int = 24
    ) -> ForecastResponseDTO:
        """
        Get weather forecast for given coordinates.
        
        Args:
            latitude: Location latitude
            longitude: Location longitude
            location_name: Optional location name (if not provided, will be fetched)
            hours_ahead: Number of hours to forecast
        
        Returns:
            ForecastResponseDTO with current and hourly weather data
        """
        try:
            # Get location name if not provided
            if not location_name:
                geo_data = await self.photon_service.reverse_geocode(latitude, longitude)
                if geo_data.get("features"):
                    props = geo_data["features"][0].get("properties", {})
                    location_name = props.get("name", "Unknown")
                    country = props.get("country", "Unknown")
                else:
                    location_name = "Unknown"
                    country = "Unknown"
            else:
                country = "Unknown"
            
            # Get weather forecast
            forecast_data = await self.open_meteo_service.get_forecast(
                latitude, 
                longitude,
                hours_ahead
            )
            
            # Parse current weather
            current = forecast_data.get("current", {})
            current_weather = CurrentWeatherDTO(
                time=current.get("time", ""),
                temperature_2m=current.get("temperature_2m", 0.0),
                relative_humidity_2m=current.get("relative_humidity_2m", 0),
                weather_code=current.get("weather_code", 0),
                wind_speed_10m=current.get("wind_speed_10m", 0.0),
                precipitation=current.get("precipitation", 0.0),
                is_day=current.get("is_day", 0)
            )
            
            # Parse hourly data
            hourly = forecast_data.get("hourly", {})
            hourly_times = hourly.get("time", [])
            hourly_temps = hourly.get("temperature_2m", [])
            hourly_humidity = hourly.get("relative_humidity_2m", [])
            hourly_weather_code = hourly.get("weather_code", [])
            hourly_wind_speed = hourly.get("wind_speed_10m", [])
            hourly_precipitation = hourly.get("precipitation", [])
            hourly_soil_moisture = hourly.get("soil_moisture_0_to_1cm", [])
            
            hourly_weather_list = []
            for i in range(min(len(hourly_times), hours_ahead)):
                hourly_weather_list.append(
                    HourlyWeatherDTO(
                        time=hourly_times[i] if i < len(hourly_times) else "",
                        temperature_2m=hourly_temps[i] if i < len(hourly_temps) else 0.0,
                        relative_humidity_2m=int(hourly_humidity[i]) if i < len(hourly_humidity) else 0,
                        weather_code=int(hourly_weather_code[i]) if i < len(hourly_weather_code) else 0,
                        wind_speed_10m=hourly_wind_speed[i] if i < len(hourly_wind_speed) else 0.0,
                        precipitation=hourly_precipitation[i] if i < len(hourly_precipitation) else 0.0,
                        soil_moisture_0_to_1cm=hourly_soil_moisture[i] if i < len(hourly_soil_moisture) else 0.0
                    )
                )
            
            location = LocationDTO(
                name=location_name,
                country=country,
                latitude=latitude,
                longitude=longitude
            )
            
            return ForecastResponseDTO(
                location=location,
                current=current_weather,
                hourly=hourly_weather_list
            )
        
        except Exception as e:
            logger.error(f"Error in GetWeatherForecastUseCase: {str(e)}")
            raise


class SearchLocationUseCase:
    """Search for locations by query."""
    
    def __init__(self, photon_service: PhotonGeocodingService):
        self.photon_service = photon_service
    
    async def execute(
        self,
        query: str,
        limit: int = 10
    ) -> LocationSearchResponseDTO:
        """
        Search for locations matching the query.
        
        Args:
            query: Search query
            limit: Maximum number of results
        
        Returns:
            List of matching locations with coordinates
        """
        try:
            search_data = await self.photon_service.search_location(query, limit)
            
            results = []
            for feature in search_data.get("features", []):
                props = feature.get("properties", {})
                coords = feature.get("geometry", {}).get("coordinates", [0, 0])
                
                result = LocationSearchDTO(
                    name=props.get("name", "Unknown"),
                    latitude=coords[1],
                    longitude=coords[0],
                    country=props.get("country", "Unknown"),
                    state=props.get("state"),
                    type=props.get("osm_type", "location")
                )
                results.append(result)
            
            return LocationSearchResponseDTO(
                results=results,
                count=len(results)
            )
        
        except Exception as e:
            logger.error(f"Error in SearchLocationUseCase: {str(e)}")
            raise


class ReverseGeocodeUseCase:
    """Get location information from coordinates."""
    
    def __init__(self, photon_service: PhotonGeocodingService):
        self.photon_service = photon_service
    
    async def execute(
        self,
        latitude: float,
        longitude: float
    ) -> ReverseGeocodeDTO:
        """
        Get location details from coordinates.
        
        Args:
            latitude: Location latitude
            longitude: Location longitude
        
        Returns:
            Location information (name, address, country, etc.)
        """
        try:
            geo_data = await self.photon_service.reverse_geocode(latitude, longitude, limit=1)
            
            if not geo_data.get("features"):
                raise ValueError("Location not found")
            
            feature = geo_data["features"][0]
            props = feature.get("properties", {})
            
            # Build address
            address_parts = []
            for key in ["street", "housenumber", "suburb", "district"]:
                if key in props and props[key]:
                    address_parts.append(props[key])
            address = ", ".join(address_parts) if address_parts else None
            
            return ReverseGeocodeDTO(
                name=props.get("name", "Unknown"),
                country=props.get("country", "Unknown"),
                country_code=props.get("country_code", ""),
                state=props.get("state"),
                address=address,
                latitude=latitude,
                longitude=longitude
            )
        
        except Exception as e:
            logger.error(f"Error in ReverseGeocodeUseCase: {str(e)}")
            raise
