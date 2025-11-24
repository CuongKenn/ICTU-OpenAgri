"""
Land Map Domain Entities
"""
from dataclasses import dataclass
from typing import Optional, List
from datetime import datetime


@dataclass
class LandMapTile:
    """Represents a single land map tile at 250m resolution"""
    tile_id: str
    x: int
    y: int
    z: int  # zoom level
    data_source: str  # "copernicus", "usgs", "sentinel2"
    data_type: str  # "dem", "lulc", "ndvi"
    file_path: Optional[str]
    created_at: datetime
    updated_at: datetime
    metadata: Optional[dict] = None


@dataclass
class LandClassification:
    """Represents land classification categories"""
    code: int
    name: str
    description: str
    color_hex: str


@dataclass
class GeoLocation:
    """Geographic coordinates"""
    latitude: float
    longitude: float
    altitude: Optional[float] = None


@dataclass
class LandMapQuery:
    """Query parameters for land map data"""
    location: GeoLocation
    data_type: str  # "dem", "lulc", "ndvi", "all"
    date_range: Optional[tuple] = None  # (start_date, end_date)
    resolution: int = 250  # meters


@dataclass
class LandMapResponse:
    """Response for land map queries"""
    location: GeoLocation
    data_type: str
    resolution: int
    data: dict  # raster data as GeoTIFF or array
    statistics: Optional[dict] = None
    timestamp: datetime = None


@dataclass
class RasterData:
    """Raster data representation"""
    data: List[List[float]]
    crs: str  # Coordinate Reference System (e.g., "EPSG:4326")
    bounds: dict  # {"north", "south", "east", "west"}
    no_data_value: Optional[float] = None
    metadata: Optional[dict] = None
