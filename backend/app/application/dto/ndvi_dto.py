# Copyright (c) 2025 CuongKenn and ICTU-OpenAgri Contributors
# Licensed under the MIT License. See LICENSE file in the project root for full license information.

from pydantic import BaseModel
from typing import List, Optional

class NDVIRequest(BaseModel):
    farm_id: Optional[int] = None
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
