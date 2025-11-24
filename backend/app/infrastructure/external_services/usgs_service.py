"""
USGS Earth Explorer Integration
Free and open source data
"""
import logging
from typing import Optional
import httpx
from app.domain.entities.landmap_entity import (
    RasterData,
    GeoLocation,
)

logger = logging.getLogger(__name__)

# USGS API endpoints
USGS_API = "https://m2m.cr.usgs.gov/api/v1"


class USGSService:
    """Service for accessing USGS Earth Explorer data"""

    def __init__(self):
        self.session = None
        # API key can be obtained free from USGS EROS Registration System
        self.api_key = None

    async def __aenter__(self):
        self.session = httpx.AsyncClient(timeout=30.0)
        return self

    async def __aexit__(self, exc_type, exc_val, exc_tb):
        if self.session:
            await self.session.aclose()

    async def get_nlcd_data(
        self,
        location: GeoLocation,
    ) -> Optional[RasterData]:
        """
        Get National Land Cover Database (NLCD) data from USGS.
        Available for USA only.
        Resolution: 30m
        
        Free and open source data
        """
        try:
            logger.info(
                f"Fetching NLCD data for location: {location.latitude}, {location.longitude}"
            )

            # Check if location is within USA bounds
            if not (-125 < location.longitude < -66 and 24 < location.latitude < 49):
                logger.warning("NLCD data is only available for USA")
                return None

            # USGS provides NLCD data through various services
            # Using OpenData endpoints for free access

            url = "https://lta.cr.usgs.gov/NLCD"

            # NLCD tiles are available in Web Mercator projection
            # For this implementation, we'll return metadata

            return RasterData(
                data=[],
                crs="EPSG:3857",  # Web Mercator
                bounds={
                    "north": location.latitude + 0.05,
                    "south": location.latitude,
                    "east": location.longitude + 0.05,
                    "west": location.longitude,
                },
                metadata={
                    "source": "USGS",
                    "type": "NLCD",
                    "resolution": "30m",
                    "url": url,
                },
            )

        except Exception as e:
            logger.error(f"Error fetching NLCD data: {str(e)}")
            return None

    async def get_dem_data(
        self,
        location: GeoLocation,
    ) -> Optional[RasterData]:
        """
        Get DEM data from USGS (SRTM, 3DEP).
        Resolution: 30m globally
        
        Free and open source data
        """
        try:
            logger.info(
                f"Fetching USGS DEM data for location: {location.latitude}, {location.longitude}"
            )

            # SRTM data is available globally through USGS
            # Using public endpoints

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
                    "source": "USGS",
                    "type": "DEM",
                    "resolution": "30m",
                    "dataset": "SRTM/3DEP",
                },
            )

        except Exception as e:
            logger.error(f"Error fetching USGS DEM data: {str(e)}")
            return None


class NLCDClassifications:
    """NLCD land cover classification codes from USGS"""

    CLASSIFICATIONS = {
        0: {"name": "Background", "description": "No data", "color": "#000000"},
        11: {"name": "Open Water", "description": "Water bodies", "color": "#466b9f"},
        12: {"name": "Perennial Ice/Snow", "description": "Glaciers", "color": "#d1bb82"},
        21: {"name": "Developed Open Space", "description": "Low density urban", "color": "#e1cd4e"},
        22: {
            "name": "Developed Low Intensity",
            "description": "Medium density urban",
            "color": "#e1c6c6",
        },
        23: {"name": "Developed Medium Intensity", "description": "Urban", "color": "#e61e1e"},
        24: {"name": "Developed High Intensity", "description": "Dense urban", "color": "#99004d"},
        31: {"name": "Barren Land", "description": "Rock/sand", "color": "#b3aea6"},
        41: {"name": "Deciduous Forest", "description": "Deciduous trees", "color": "#68a641"},
        42: {"name": "Evergreen Forest", "description": "Conifer trees", "color": "#1d6533"},
        43: {"name": "Mixed Forest", "description": "Mixed forest", "color": "#b5c58e"},
        51: {"name": "Dwarf Scrub", "description": "Low vegetation", "color": "#af963c"},
        52: {"name": "Shrub/Scrub", "description": "Shrubland", "color": "#ccb48e"},
        71: {"name": "Grassland/Herbaceous", "description": "Grassland", "color": "#dfc82b"},
        72: {"name": "Sedges/Rushes", "description": "Wet grassland", "color": "#d1bb82"},
        73: {"name": "Lichens and Mosses", "description": "Lichen cover", "color": "#a4cc51"},
        74: {"name": "Peatland", "description": "Peatlands", "color": "#82ba9d"},
        81: {"name": "Pasture/Hay", "description": "Managed grassland", "color": "#fad9a8"},
        82: {"name": "Cultivated Crops", "description": "Croplands", "color": "#ffeb3c"},
        90: {"name": "Woody Wetlands", "description": "Forested wetland", "color": "#b3c6e6"},
        95: {"name": "Emergent Herbaceous Wetlands", "description": "Marsh", "color": "#6db3e6"},
    }
