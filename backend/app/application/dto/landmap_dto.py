"""
Land Map Data Transfer Objects
"""
from pydantic import BaseModel, Field
from typing import Optional, List, Dict, Any
from datetime import datetime


class GeoLocationDTO(BaseModel):
    """Geographic location DTO"""
    latitude: float = Field(..., ge=-90, le=90)
    longitude: float = Field(..., ge=-180, le=180)
    altitude: Optional[float] = None


class LandMapTileDTO(BaseModel):
    """Land Map Tile DTO"""
    tile_id: str
    x: int
    y: int
    z: int
    data_source: str
    data_type: str
    created_at: datetime
    updated_at: datetime
    metadata: Optional[Dict[str, Any]] = None


class LandClassificationDTO(BaseModel):
    """Land Classification DTO"""
    code: int
    name: str
    description: str
    color_hex: str


class RasterDataDTO(BaseModel):
    """Raster Data DTO"""
    crs: str
    bounds: Dict[str, float]
    no_data_value: Optional[float] = None
    metadata: Optional[Dict[str, Any]] = None
    # Data returned as serializable format
    min_value: Optional[float] = None
    max_value: Optional[float] = None
    mean_value: Optional[float] = None


class LandMapQueryDTO(BaseModel):
    """Land Map Query DTO"""
    location: GeoLocationDTO
    data_type: str = Field(..., pattern="^(dem|lulc|ndvi|all)$")
    resolution: int = Field(default=250, ge=10, le=1000)


class LandMapResponseDTO(BaseModel):
    """Land Map Response DTO"""
    location: GeoLocationDTO
    data_type: str
    resolution: int
    data_source: str
    timestamp: datetime
    raster_info: RasterDataDTO
    data_url: Optional[str] = None  # URL to download GeoTIFF
    statistics: Optional[Dict[str, Any]] = None


class TileRequestDTO(BaseModel):
    """Tile request DTO"""
    x: int
    y: int
    z: int
    data_type: str = Field(..., pattern="^(dem|lulc|ndvi)$")
    data_source: str = Field(default="copernicus")


class BoundingBoxDTO(BaseModel):
    """Bounding box DTO"""
    north: float = Field(..., ge=-90, le=90)
    south: float = Field(..., ge=-90, le=90)
    east: float = Field(..., ge=-180, le=180)
    west: float = Field(..., ge=-180, le=180)


class AreaQueryDTO(BaseModel):
    """Query for area/polygon DTO"""
    bounding_box: BoundingBoxDTO
    data_type: str = Field(..., pattern="^(dem|lulc|ndvi)$")
    data_source: str = Field(default="copernicus")
