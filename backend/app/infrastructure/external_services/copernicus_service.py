"""
Copernicus Global Land Service Integration
Open source and free data access
"""
import logging
import os
from typing import Optional
import httpx
import numpy as np
from app.domain.entities.landmap_entity import (
    RasterData,
    GeoLocation,
)

logger = logging.getLogger(__name__)

# Copernicus data endpoints (all open access)
COPERNICUS_ENDPOINTS = {
    "dem": "https://dem.copernicus.eu/",
    "lulc": "https://land.copernicus.eu/global/products/lulc",
}


class CopernicusService:
    """Service for accessing Copernicus Global Land data"""

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
        """
        Get Digital Elevation Model (DEM) from Copernicus.
        Resolution: 30m globally
        
        Free and open source data from ESA/Copernicus
        """
        try:
            logger.info(
                f"Fetching DEM data for location: {location.latitude}, {location.longitude}"
            )

            # Copernicus DEM tiles are available in 1x1 degree tiles
            tile_x = int(location.longitude)
            tile_y = int(location.latitude)

            # Construct tile ID
            if tile_x >= 0:
                lon_dir = "E"
            else:
                lon_dir = "W"
                tile_x = abs(tile_x)

            if tile_y >= 0:
                lat_dir = "N"
            else:
                lat_dir = "S"
                tile_y = abs(tile_y)

            tile_name = f"Copernicus_DSM_10_{lat_dir}{tile_y:02d}_{lon_dir}{tile_x:03d}_DEM"

            # URL for public access
            dem_url = f"https://cloud.sdsc.edu/v1/AUTH_cloud.sdsc.edu/Raster/DEM/SRTM_GL30/SRTM_GL30_srtm/{tile_name}.tif"

            # Try to download
            if not self.session:
                async with httpx.AsyncClient(timeout=30.0) as client:
                    response = await client.get(dem_url)
            else:
                response = await self.session.get(dem_url)

            if response.status_code == 200:
                # Save temporarily
                cache_file = os.path.join(
                    self.cache_dir, f"{tile_name}_{location.latitude}_{location.longitude}.tif"
                )

                with open(cache_file, "wb") as f:
                    f.write(response.content)

                logger.info(f"DEM data cached at: {cache_file}")

                return RasterData(
                    data=[],  # Actual raster data would be loaded with rasterio
                    crs="EPSG:4326",
                    bounds={
                        "north": tile_y + 1,
                        "south": tile_y,
                        "east": tile_x + 1,
                        "west": tile_x,
                    },
                    metadata={"source": "Copernicus", "type": "DEM", "resolution": "30m"},
                )

            logger.warning(f"Failed to fetch DEM data: {response.status_code}")
            return None

        except Exception as e:
            logger.error(f"Error fetching DEM data: {str(e)}")
            return None

    async def get_lulc_data(
        self,
        location: GeoLocation,
    ) -> Optional[RasterData]:
        """
        Get Land Use/Land Cover (LULC) data from Copernicus.
        Resolution: 100m globally
        
        Free and open source data from ESA/Copernicus
        """
        try:
            logger.info(
                f"Fetching LULC data for location: {location.latitude}, {location.longitude}"
            )

            # Copernicus LULC data endpoint
            # Using Copernicus Land Monitoring Service (CLMS)
            url = "https://land.copernicus.vgt.vito.be/lcviewer/api/"

            params = {
                "lat": location.latitude,
                "lon": location.longitude,
                "year": 2023,
            }

            if not self.session:
                async with httpx.AsyncClient(timeout=30.0) as client:
                    response = await client.get(url, params=params)
            else:
                response = await self.session.get(url, params=params)

            if response.status_code == 200:
                data = response.json()

                logger.info(f"LULC data retrieved: {data}")

                return RasterData(
                    data=[],
                    crs="EPSG:4326",
                    bounds={
                        "north": location.latitude + 0.01,
                        "south": location.latitude - 0.01,
                        "east": location.longitude + 0.01,
                        "west": location.longitude - 0.01,
                    },
                    metadata={
                        "source": "Copernicus",
                        "type": "LULC",
                        "resolution": "100m",
                        "response": data,
                    },
                )

            logger.warning(f"Failed to fetch LULC data: {response.status_code}")
            return None

        except Exception as e:
            logger.error(f"Error fetching LULC data: {str(e)}")
            return None


class LULCClassifications:
    """Land Use/Land Cover classification codes from Copernicus"""

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
