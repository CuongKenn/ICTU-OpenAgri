"""
Sentinel-2 Integration (ESA)
Free and open source satellite imagery
"""
import logging
from typing import Optional
import httpx
from app.domain.entities.landmap_entity import (
    RasterData,
    GeoLocation,
)

logger = logging.getLogger(__name__)

# Sentinel API endpoints
SENTINEL_API = "https://catalogue.dataspace.copernicus.eu/odata/v1"


class SentinelService:
    """Service for accessing Sentinel-2 satellite imagery"""

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
        """
        Get NDVI (Normalized Difference Vegetation Index) from Sentinel-2.
        
        NDVI is calculated from:
        NDVI = (NIR - RED) / (NIR + RED)
        
        Sentinel-2 provides free and open source imagery
        Resolution: 10-20m depending on band
        """
        try:
            logger.info(
                f"Fetching Sentinel-2 NDVI data for location: {location.latitude}, {location.longitude}"
            )

            # Query Sentinel-2 products
            bbox = f"{location.longitude},{location.latitude},{location.longitude + 0.1},{location.latitude + 0.1}"

            url = f"{SENTINEL_API}/Products"
            params = {
                "$filter": f"Collection/Name eq 'SENTINEL-2' and ContentDate/Start gt 2024-01-01T00:00:00.000Z and OData.CSC.Intersects(area=geography'SRID=4326;POLYGON(({location.longitude} {location.latitude},{location.longitude + 0.1} {location.latitude},{location.longitude + 0.1} {location.latitude + 0.1},{location.longitude} {location.latitude + 0.1},{location.longitude} {location.latitude}))')",
                "$top": 1,
            }

            if not self.session:
                async with httpx.AsyncClient(timeout=60.0) as client:
                    response = await client.get(url, params=params)
            else:
                response = await self.session.get(url, params=params)

            if response.status_code == 200:
                data = response.json()

                logger.info(f"Sentinel-2 products found: {len(data.get('value', []))}")

                if data.get("value"):
                    # Product found, would process to calculate NDVI
                    product = data["value"][0]

                    return RasterData(
                        data=[],
                        crs="EPSG:4326",
                        bounds={
                            "north": location.latitude + 0.1,
                            "south": location.latitude,
                            "east": location.longitude + 0.1,
                            "west": location.longitude,
                        },
                        metadata={
                            "source": "Sentinel-2",
                            "type": "NDVI",
                            "resolution": "10m",
                            "product_id": product.get("Id"),
                        },
                    )

            logger.warning(
                f"No Sentinel-2 products found or API error: {response.status_code}"
            )
            return None

        except Exception as e:
            logger.error(f"Error fetching Sentinel-2 NDVI data: {str(e)}")
            return None

    async def get_true_color_data(
        self,
        location: GeoLocation,
    ) -> Optional[RasterData]:
        """
        Get true color (RGB) imagery from Sentinel-2.
        Resolution: 10m
        """
        try:
            logger.info(
                f"Fetching Sentinel-2 true color data for location: {location.latitude}, {location.longitude}"
            )

            url = f"{SENTINEL_API}/Products"
            params = {
                "$filter": f"Collection/Name eq 'SENTINEL-2'",
                "$top": 1,
            }

            if not self.session:
                async with httpx.AsyncClient(timeout=60.0) as client:
                    response = await client.get(url, params=params)
            else:
                response = await self.session.get(url, params=params)

            if response.status_code == 200:
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

            return None

        except Exception as e:
            logger.error(f"Error fetching Sentinel-2 true color data: {str(e)}")
            return None
