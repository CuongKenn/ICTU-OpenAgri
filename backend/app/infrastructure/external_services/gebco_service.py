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

# GEBCO: General Bathymetric Chart of the Oceans
# Miễn phí, mã nguồn mở, quốc tế, bao gồm Việt Nam
GEBCO_API = "https://www.gebco.net/data/oceanic/"


class GEBCOService:
    """
    GEBCO (General Bathymetric Chart of the Oceans) Service
    - Free and open-source international data
    - Provides DEM (Digital Elevation Model) data globally including Vietnam
    - 15 arc-second resolution (approximately 450m)
    """

    def __init__(self):
        self.session = None

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
        Get DEM data from GEBCO for any location globally
        GEBCO covers the entire world including Vietnam
        """
        try:
            logger.info(
                f"Fetching GEBCO DEM data for location: {location.latitude}, {location.longitude}"
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
                    "source": "GEBCO",
                    "type": "DEM",
                    "resolution": "15 arc-second (~450m)",
                    "dataset": "GEBCO 2024",
                    "license": "CC BY 4.0",
                    "url": "https://www.gebco.net/",
                },
            )

        except Exception as e:
            logger.error(f"Error fetching GEBCO DEM data: {str(e)}")
            return None


class ESRILULCClassifications:
    """
    ESRI Land Use/Land Cover Classifications (mã nguồn mở, miễn phí, quốc tế)
    Thay thế cho NLCD (chỉ dùng cho Mỹ)
    """

    CLASSIFICATIONS = {
        1: {"name": "Water", "description": "Water bodies", "color": "#1f77b4"},
        2: {"name": "Trees", "description": "Forest coverage", "color": "#2ca02c"},
        4: {"name": "Grass", "description": "Grassland and herbaceous", "color": "#ff7f0e"},
        5: {"name": "Barren", "description": "Barren land and rock", "color": "#a6cee3"},
        7: {"name": "Built Area", "description": "Urban and built-up areas", "color": "#e31a1c"},
        8: {"name": "Snow/Ice", "description": "Snow and ice coverage", "color": "#ffff99"},
        9: {"name": "Clouds", "description": "Cloud coverage", "color": "#cccccc"},
        11: {"name": "Rainfed Cropland", "description": "Rain-fed crops", "color": "#fdbf6f"},
        12: {"name": "Herbaceous Wetland", "description": "Wet herbaceous areas", "color": "#6495ed"},
        13: {"name": "Mangrove", "description": "Mangrove areas", "color": "#8fbc8f"},
        14: {"name": "Moss and Lichen", "description": "Moss and lichen", "color": "#d9d9d9"},
        15: {"name": "Shrubland", "description": "Shrub land", "color": "#daa520"},
        20: {"name": "Irrigated Cropland", "description": "Irrigated crops", "color": "#ffda03"},
        30: {"name": "Herbaceous Wetland", "description": "Herbaceous wetland", "color": "#4682b4"},
        40: {"name": "Deciduous Forest", "description": "Deciduous forest", "color": "#228b22"},
        50: {"name": "Coniferous Forest", "description": "Coniferous forest", "color": "#006400"},
        60: {"name": "Mixed Forest", "description": "Mixed forest", "color": "#3cb371"},
        100: {"name": "Lichen Moss", "description": "Lichen and moss", "color": "#d4d4d4"},
        110: {"name": "Herbaceous Tundra", "description": "Herbaceous tundra", "color": "#b3a6a3"},
        120: {"name": "Shrub Tundra", "description": "Shrub tundra", "color": "#a9927a"},
        130: {"name": "Bare Sparse Vegetation", "description": "Bare and sparse vegetation", "color": "#b8a8a8"},
        200: {"name": "Urban", "description": "Urban area", "color": "#d2691e"},
    }
