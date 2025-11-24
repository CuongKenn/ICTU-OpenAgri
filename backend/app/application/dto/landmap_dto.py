from pydantic import BaseModel, Field
from typing import Optional, List, Dict, Any
from datetime import datetime


class GeoLocationDTO(BaseModel):
    latitude: float = Field(..., ge=-90, le=90)
    longitude: float = Field(..., ge=-180, le=180)
    altitude: Optional[float] = None


class LandMapTileDTO(BaseModel):
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
    code: int
    name: str
    description: str
    color_hex: str


class RasterDataDTO(BaseModel):
    crs: str
    bounds: Dict[str, float]
    no_data_value: Optional[float] = None
    metadata: Optional[Dict[str, Any]] = None
    min_value: Optional[float] = None
    max_value: Optional[float] = None
    mean_value: Optional[float] = None


class LandMapQueryDTO(BaseModel):
    location: GeoLocationDTO
    data_type: str = Field(..., pattern="^(dem|lulc|ndvi|all)$")
    resolution: int = Field(default=250, ge=10, le=1000)


class LandMapResponseDTO(BaseModel):
    location: GeoLocationDTO
    data_type: str
    resolution: int
    data_source: str
    timestamp: datetime
    raster_info: RasterDataDTO
    data_url: Optional[str] = None
    statistics: Optional[Dict[str, Any]] = None


class TileRequestDTO(BaseModel):
    x: int
    y: int
    z: int
    data_type: str = Field(..., pattern="^(dem|lulc|ndvi)$")
    data_source: str = Field(default="copernicus")


class BoundingBoxDTO(BaseModel):
    north: float = Field(..., ge=-90, le=90)
    south: float = Field(..., ge=-90, le=90)
    east: float = Field(..., ge=-180, le=180)
    west: float = Field(..., ge=-180, le=180)


class AreaQueryDTO(BaseModel):
    bounding_box: BoundingBoxDTO
    data_type: str = Field(..., pattern="^(dem|lulc|ndvi)$")
    data_source: str = Field(default="copernicus")
