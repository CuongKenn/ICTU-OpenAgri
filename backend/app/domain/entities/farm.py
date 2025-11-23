from typing import List, Optional
from pydantic import BaseModel
from .base import BaseEntity

class Coordinate(BaseModel):
    lat: float
    lng: float

class FarmArea(BaseEntity):
    name: str
    description: Optional[str] = None
    coordinates: List[Coordinate]
    area_size: Optional[float] = None
    crop_type: Optional[str] = None
    user_id: int
