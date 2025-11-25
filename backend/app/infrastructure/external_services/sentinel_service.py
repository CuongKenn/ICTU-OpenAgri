import logging
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

SENTINEL_API = "https://catalogue.dataspace.copernicus.eu/odata/v1"


class SentinelService:

    def __init__(self):
        self.session = None

    async def __aenter__(self):
        self.session = httpx.AsyncClient(timeout=60.0)
        return self

    async def __aexit__(self, exc_type, exc_val, exc_tb):
        if self.session:
            await self.session.aclose()

    async def get_ndvi_data(
        self,
        location: GeoLocation,
    ) -> Optional[RasterData]:
        try:
            logger.info(
                f"Fetching Sentinel-2 NDVI data for location: {location.latitude}, {location.longitude}"
            )

            return RasterData(
                data=[],
                crs="EPSG:4326",
                bounds={
                    "north": location.latitude + 0.1,
                    "south": location.latitude - 0.1,
                    "east": location.longitude + 0.1,
                    "west": location.longitude - 0.1,
                },
                metadata={
                    "source": "Sentinel-2",
                    "type": "NDVI",
                    "resolution": "10m",
                },
            )

        except Exception as e:
            logger.error(f"Error fetching Sentinel-2 NDVI data: {str(e)}")
            return None

    async def get_true_color_data(
        self,
        location: GeoLocation,
    ) -> Optional[RasterData]:
        try:
            logger.info(
                f"Fetching Sentinel-2 true color data for location: {location.latitude}, {location.longitude}"
            )

            return RasterData(
                data=[],
                crs="EPSG:4326",
                bounds={
                    "north": location.latitude + 0.05,
                    "south": location.latitude,
                    "east": location.longitude + 0.05,
                    "west": location.longitude,
                },
                metadata={
                    "source": "Sentinel-2",
                    "type": "TrueColor",
                    "resolution": "10m",
                },
            )

        except Exception as e:
            logger.error(f"Error fetching Sentinel-2 true color data: {str(e)}")
            return None
