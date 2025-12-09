from fastapi import APIRouter, Depends, HTTPException, Query
from typing import List, Optional
from app.domain.entities.soil_analysis import SoilAnalysisResult, SoilProperties, CropRecommendation
from app.infrastructure.external_services.soilgrids_service import SoilGridsService
from app.application.services.crop_recommendation_engine import CropRecommendationEngine

router = APIRouter()

# Dependency injection (simplified)
def get_soil_service():
    return SoilGridsService()

def get_recommendation_engine():
    return CropRecommendationEngine()

@router.get("/analyze", response_model=SoilAnalysisResult)
async def analyze_soil(
    latitude: float,
    longitude: float,
    soil_service: SoilGridsService = Depends(get_soil_service),
    recommendation_engine: CropRecommendationEngine = Depends(get_recommendation_engine)
):
    """
    Analyze soil properties at a specific location and recommend crops.
    """
    try:
        # 1. Fetch soil properties
        soil_props = await soil_service.get_soil_properties(latitude, longitude)
        
        # 2. Generate recommendations
        recommendations = recommendation_engine.recommend(soil_props)
        
        # 3. Construct result
        return SoilAnalysisResult(
            latitude=latitude,
            longitude=longitude,
            soil_properties=soil_props,
            crop_recommendations=recommendations
        )
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.get("/crops", response_model=List[CropRecommendation])
async def get_crop_recommendations_only(
    latitude: float,
    longitude: float,
    soil_service: SoilGridsService = Depends(get_soil_service),
    recommendation_engine: CropRecommendationEngine = Depends(get_recommendation_engine)
):
    """
    Get only crop recommendations for a location.
    """
    soil_props = await soil_service.get_soil_properties(latitude, longitude)
    return recommendation_engine.recommend(soil_props)
