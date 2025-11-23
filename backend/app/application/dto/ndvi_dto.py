from pydantic import BaseModel
from typing import List

class NDVIRequest(BaseModel):
    bbox: List[float]
    start_date: str  # YYYY-MM-DD
    end_date: str    # YYYY-MM-DD

class NDVIResponse(BaseModel):
    status: str
    ndvi_geotiff: str
    image_base64: str
    mean_ndvi: float
    min_ndvi: float
    max_ndvi: float
    acquisition_date: str
    chart_data: List[dict] # List of {'date': str, 'value': float}
