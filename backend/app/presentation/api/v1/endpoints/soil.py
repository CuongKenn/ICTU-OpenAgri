"""Soil data endpoints."""
import logging
from fastapi import APIRouter, HTTPException, Query
from typing import Optional, List
from app.application.soil_service import SoilService
from app.domain.soil_models import SoilDataResponse

logger = logging.getLogger(__name__)

router = APIRouter()
soil_service = SoilService()


@router.get("/data", response_model=SoilDataResponse)
async def get_soil_data(
    latitude: float = Query(..., description="Latitude coordinate"),
    longitude: float = Query(..., description="Longitude coordinate"),
    depths: Optional[str] = Query(
        None,
        description="Comma-separated soil depths in cm (default: 0,10,30,60,100,200)",
    ),
) -> SoilDataResponse:
    """
    Get soil data for given coordinates from OpenLandMap.

    Args:
        latitude: Latitude coordinate
        longitude: Longitude coordinate
        depths: Optional comma-separated depths (e.g., "0,10,30,60")

    Returns:
        SoilDataResponse with soil properties at different depths
    """
    try:
        # Parse depths if provided
        depth_list = None
        if depths:
            try:
                depth_list = [int(d.strip()) for d in depths.split(",")]
            except ValueError:
                raise HTTPException(
                    status_code=400, detail="Depths must be comma-separated integers"
                )

        soil_data = await soil_service.get_soil_data(
            latitude=latitude,
            longitude=longitude,
            depths=depth_list,
        )
        return soil_data

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error getting soil data: {e}", exc_info=True)
        raise HTTPException(
            status_code=500, detail=f"Failed to get soil data: {str(e)}"
        )


@router.get("/recommendations")
async def get_soil_recommendations(
    latitude: float = Query(..., description="Latitude coordinate"),
    longitude: float = Query(..., description="Longitude coordinate"),
) -> dict:
    """
    Get soil management recommendations based on soil analysis.

    Args:
        latitude: Latitude coordinate
        longitude: Longitude coordinate

    Returns:
        Dictionary with location and recommendations
    """
    try:
        recommendations = await soil_service.get_soil_recommendations(
            latitude=latitude,
            longitude=longitude,
        )
        return recommendations

    except Exception as e:
        logger.error(f"Error getting soil recommendations: {e}", exc_info=True)
        raise HTTPException(
            status_code=500, detail=f"Failed to get recommendations: {str(e)}"
        )
