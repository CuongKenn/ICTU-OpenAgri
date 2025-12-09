from typing import List, Dict, Optional
from pydantic import BaseModel
from datetime import datetime

class SoilProperties(BaseModel):
    """Thuộc tính lý - hóa của đất"""
    ph_water: Optional[float] = None
    ph_kcl: Optional[float] = None
    organic_carbon: Optional[float] = None # g/kg
    nitrogen: Optional[float] = None # g/kg
    phosphorus: Optional[float] = None # mg/kg
    potassium: Optional[float] = None # mg/kg
    sand_percent: Optional[float] = None
    silt_percent: Optional[float] = None
    clay_percent: Optional[float] = None
    soil_moisture: Optional[float] = None # %
    soil_texture: Optional[str] = None
    depth: Optional[str] = "0-30cm"

class CropRecommendation(BaseModel):
    """Đề xuất cây trồng"""
    crop_name: str
    crop_name_vi: str
    suitability_score: float # 0-100
    reasons: List[str] = []
    warnings: List[str] = []
    ideal_conditions: Optional[Dict] = None

class SoilAnalysisResult(BaseModel):
    """Kết quả tổng hợp"""
    latitude: float
    longitude: float
    soil_properties: SoilProperties
    crop_recommendations: List[CropRecommendation] = []
    analyzed_at: datetime = datetime.now()
    data_source: str = "SoilGrids"
