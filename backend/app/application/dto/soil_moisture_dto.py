from pydantic import BaseModel
from typing import List

class SoilMoistureRequest(BaseModel):
    bbox: List[float]
    date: str  # YYYY-MM-DD

class SoilMoistureResponse(BaseModel):
    status: str
    soil_moisture_map: str
    image_base64: str
