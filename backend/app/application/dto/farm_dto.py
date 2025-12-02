# Copyright (c) 2025 CuongKenn and ICTU-OpenAgri Contributors
# Licensed under the MIT License. See LICENSE file in the project root for full license information.

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

class AdminFarmAreaResponseDTO(FarmAreaResponseDTO):
    user_email: str
    user_full_name: Optional[str] = None
    username: str
