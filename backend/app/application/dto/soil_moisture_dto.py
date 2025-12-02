# Copyright (c) 2025 CuongKenn and ICTU-OpenAgri Contributors
# Licensed under the MIT License. See LICENSE file in the project root for full license information.

from pydantic import BaseModel
from typing import List

class SoilMoistureRequest(BaseModel):
    bbox: List[float]
    date: str  # YYYY-MM-DD

class SoilMoistureResponse(BaseModel):
    status: str
    soil_moisture_map: str
    image_base64: str
    mean_value: float = 0.0
