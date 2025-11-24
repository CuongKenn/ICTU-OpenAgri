from dataclasses import dataclass
from typing import Optional, List, Dict, Any
from datetime import datetime


@dataclass
class GeoLocation:
    latitude: float
    longitude: float
    altitude: Optional[float] = None


@dataclass
class RasterData:
    data: List[List[float]]
    crs: str
    bounds: Dict[str, float]
    no_data_value: Optional[float] = None
    metadata: Optional[Dict[str, Any]] = None


@dataclass
class LandMapTile:
    tile_id: str
    x: int
    y: int
    z: int
    data_source: str
    data_type: str
    file_path: Optional[str]
    created_at: datetime
    updated_at: datetime
    metadata: Optional[dict] = None


@dataclass
class LandClassification:
    code: int
    name: str
    description: str
    color_hex: str


@dataclass
class LandMapQuery:
    location: GeoLocation
    data_type: str
    date_range: Optional[tuple] = None
    resolution: int = 250


@dataclass
class LandMapResponse:
    location: GeoLocation
    data_type: str
    resolution: int
    data: RasterData
    statistics: Optional[dict] = None
    timestamp: datetime = None
