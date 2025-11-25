"""Weather service for weather forecast logic."""
import httpx
import logging
from typing import Optional, List
from datetime import datetime
from app.domain.weather_models import (
    LocationCoordinates,
    LocationInfo,
    WeatherForecast,
    WeatherData,
    LocationSearchResult,
    LocationSearchResponse,
)

logger = logging.getLogger(__name__)

OPEN_METEO_API = "https://api.open-meteo.com/v1/forecast"
PHOTON_API = "https://photon.komoot.io"


class WeatherService:
    """Service for weather operations."""

    async def get_weather_forecast(
        self,
        latitude: float,
        longitude: float,
        location_name: Optional[str] = None,
    ) -> WeatherForecast:
        """
        Get weather forecast from Open-Meteo.

        Args:
            latitude: Latitude coordinate
            longitude: Longitude coordinate
            location_name: Optional location name

        Returns:
            WeatherForecast object
        """
        async with httpx.AsyncClient() as client:
            params = {
                "latitude": latitude,
                "longitude": longitude,
                "hourly": "temperature_2m,relative_humidity_2m,weather_code,wind_speed_10m,precipitation",
                "daily": "temperature_2m_max,temperature_2m_min,precipitation_sum,weather_code",
                "timezone": "auto",
                "forecast_days": 7,
            }

            try:
                response = await client.get(OPEN_METEO_API, params=params, timeout=10)
                response.raise_for_status()
                data = response.json()

                # Parse hourly data
                hourly_times = data["hourly"]["time"]
                hourly_temps = data["hourly"]["temperature_2m"]
                hourly_humidity = data["hourly"]["relative_humidity_2m"]
                hourly_codes = data["hourly"]["weather_code"]
                hourly_wind = data["hourly"]["wind_speed_10m"]
                hourly_precip = data["hourly"]["precipitation"]

                hourly_data = [
                    WeatherData(
                        time=datetime.fromisoformat(hourly_times[i]),
                        temperature=hourly_temps[i],
                        relative_humidity=hourly_humidity[i],
                        weather_code=hourly_codes[i],
                        wind_speed=hourly_wind[i],
                        precipitation=hourly_precip[i],
                    )
                    for i in range(len(hourly_times))
                ]

                location = LocationInfo(
                    latitude=latitude,
                    longitude=longitude,
                    name=location_name or f"{latitude}, {longitude}",
                )

                return WeatherForecast(
                    location=location,
                    hourly=hourly_data,
                )

            except httpx.HTTPError as e:
                logger.error(f"Error fetching weather data: {e}")
                raise

    async def search_locations(self, query: str, limit: int = 10) -> LocationSearchResponse:
        """
        Search locations using Photon API.

        Args:
            query: Search query (address, place name, etc.)
            limit: Maximum number of results

        Returns:
            LocationSearchResponse with list of results
        """
        async with httpx.AsyncClient() as client:
            params = {
                "q": query,
                "limit": limit,
            }

            try:
                response = await client.get(
                    f"{PHOTON_API}/api", params=params, timeout=10
                )
                response.raise_for_status()
                data = response.json()

                results = []
                for feature in data.get("features", []):
                    try:
                        props = feature.get("properties", {})
                        coords = feature.get("geometry", {}).get("coordinates", [])
                        
                        if len(coords) >= 2:
                            result = LocationSearchResult(
                                latitude=coords[1],
                                longitude=coords[0],
                                name=props.get("name", ""),
                                address=props.get("name", ""),
                                osm_id=props.get("osm_id"),
                                osm_type=props.get("osm_type"),
                            )
                            results.append(result)
                    except (KeyError, IndexError, TypeError) as e:
                        logger.warning(f"Error parsing feature: {e}")
                        continue

                return LocationSearchResponse(
                    results=results,
                    total=len(results),
                )

            except httpx.HTTPError as e:
                logger.error(f"Error searching locations: {e}")
                raise
            except Exception as e:
                logger.error(f"Unexpected error in search_locations: {e}")
                raise

    async def reverse_geocode(
        self, latitude: float, longitude: float
    ) -> Optional[LocationInfo]:
        """
        Reverse geocode coordinates to get location name.

        Args:
            latitude: Latitude coordinate
            longitude: Longitude coordinate

        Returns:
            LocationInfo with location details
        """
        async with httpx.AsyncClient() as client:
            params = {
                "lon": longitude,
                "lat": latitude,
            }

            try:
                response = await client.get(
                    f"{PHOTON_API}/reverse", params=params, timeout=10
                )
                response.raise_for_status()
                data = response.json()

                if data.get("features"):
                    feature = data["features"][0]
                    props = feature["properties"]

                    return LocationInfo(
                        latitude=latitude,
                        longitude=longitude,
                        name=props.get("name", f"{latitude}, {longitude}"),
                        address=props.get("name", ""),
                        country=props.get("country"),
                    )

                return LocationInfo(
                    latitude=latitude,
                    longitude=longitude,
                    name=f"{latitude}, {longitude}",
                )

            except httpx.HTTPError as e:
                logger.error(f"Error reverse geocoding: {e}")
                return LocationInfo(
                    latitude=latitude,
                    longitude=longitude,
                    name=f"{latitude}, {longitude}",
                )
