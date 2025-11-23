from typing import List, Optional
from pydantic import BaseModel

class CoordinateDTO(BaseModel):
    lat: float
    lng: float

class FarmAreaCreateDTO(BaseModel):
    name: str
    description: Optional[str] = None
    coordinates: List[CoordinateDTO]
    area_size: Optional[float] = None
    crop_type: Optional[str] = None

class FarmAreaResponseDTO(FarmAreaCreateDTO):
    id: int
    user_id: int
    
    class Config:
        from_attributes = True
