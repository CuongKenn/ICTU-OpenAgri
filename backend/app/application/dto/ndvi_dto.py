from pydantic import BaseModel
from typing import List

class NDVIRequest(BaseModel):
    bbox: List[float]
    date: str  # YYYY-MM-DD

class NDVIResponse(BaseModel):
    status: str
    ndvi_geotiff: str
