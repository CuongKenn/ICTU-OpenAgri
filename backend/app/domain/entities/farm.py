# Copyright (c) 2025 CuongKenn and ICTU-OpenAgri Contributors
# Licensed under the MIT License. See LICENSE file in the project root for full license information.

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
