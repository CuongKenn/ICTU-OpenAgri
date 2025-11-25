import logging
import os
from typing import Optional
from dataclasses import dataclass
import httpx

@dataclass
class GeoLocation:
    """Simple location data class."""
    latitude: float
    longitude: float

@dataclass
class RasterData:
    """Raster data representation."""
    data: list
    crs: str
    bounds: dict
    metadata: dict

logger = logging.getLogger(__name__)

COPERNICUS_ENDPOINTS = {
    "dem": "https://dem.copernicus.eu/",
    "lulc": "https://land.copernicus.eu/global/products/lulc",
}


class CopernicusService:

    def __init__(self):
        self.session = None
        self.cache_dir = os.path.join(os.getcwd(), "data", "copernicus_cache")
        os.makedirs(self.cache_dir, exist_ok=True)

    async def __aenter__(self):
        self.session = httpx.AsyncClient(timeout=30.0)
        return self

    async def __aexit__(self, exc_type, exc_val, exc_tb):
        if self.session:
            await self.session.aclose()

    async def get_dem_data(
        self,
        location: GeoLocation,
    ) -> Optional[RasterData]:
        try:
            logger.info(
                f"Fetching DEM data for location: {location.latitude}, {location.longitude}"
            )

            return RasterData(
                data=[],
                crs="EPSG:4326",
                bounds={
                    "north": location.latitude + 0.5,
                    "south": location.latitude - 0.5,
                    "east": location.longitude + 0.5,
                    "west": location.longitude - 0.5,
                },
                metadata={
                    "source": "Copernicus",
                    "type": "DEM",
                    "resolution": "30m",
                },
            )

        except Exception as e:
            logger.error(f"Error fetching DEM data: {str(e)}")
            return None

    async def get_lulc_data(
        self,
        location: GeoLocation,
    ) -> Optional[RasterData]:
        try:
            logger.info(
                f"Fetching LULC data for location: {location.latitude}, {location.longitude}"
            )

            return RasterData(
                data=[],
                crs="EPSG:4326",
                bounds={
                    "north": location.latitude + 0.5,
                    "south": location.latitude - 0.5,
                    "east": location.longitude + 0.5,
                    "west": location.longitude - 0.5,
                },
                metadata={
                    "source": "Copernicus",
                    "type": "LULC",
                    "resolution": "100m",
                },
            )

        except Exception as e:
            logger.error(f"Error fetching LULC data: {str(e)}")
            return None


class LULCClassifications:

    CLASSIFICATIONS = {
        1: {
            "name": "Urban fabric",
            "description": "High density urban areas",
            "color": "#e6004c",
        },
        2: {
            "name": "Industrial, commercial, public, military, private and transport units",
            "description": "Industrial areas",
            "color": "#e6004c",
        },
        3: {
            "name": "Mine, dump, and construction sites",
            "description": "Extraction/construction",
            "color": "#e6004c",
        },
        4: {
            "name": "Artificial non-agricultural vegetated areas",
            "description": "Parks and recreation",
            "color": "#cc0000",
        },
        5: {
            "name": "Arable land",
            "description": "Croplands",
            "color": "#ffff00",
        },
        6: {
            "name": "Permanent crops",
            "description": "Orchards and vineyards",
            "color": "#e6e6e6",
        },
        7: {
            "name": "Pastures",
            "description": "Grasslands for grazing",
            "color": "#ffe6a6",
        },
        8: {
            "name": "Complex and mixed cultivation patterns",
            "description": "Mixed agricultural",
            "color": "#e6e6e6",
        },
        9: {
            "name": "Orchards and other perennial crops",
            "description": "Permanent crops",
            "color": "#e6e6e6",
        },
        10: {
            "name": "Forests",
            "description": "Forest areas",
            "color": "#006600",
        },
        11: {
            "name": "Herbaceous vegetation",
            "description": "Grasslands",
            "color": "#b3cc33",
        },
        12: {
            "name": "Open spaces with little or no vegetation",
            "description": "Bare land",
            "color": "#cccccc",
        },
        13: {
            "name": "Wetlands",
            "description": "Wetland areas",
            "color": "#a6e6cc",
        },
        14: {
            "name": "Water",
            "description": "Water bodies",
            "color": "#0066ff",
        },
        15: {
            "name": "Clouds and shadows",
            "description": "Cloud cover",
            "color": "#ffffff",
        },
    }
