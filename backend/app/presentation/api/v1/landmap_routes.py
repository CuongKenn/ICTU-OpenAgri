import logging
from fastapi import APIRouter, HTTPException, Depends, Query
from typing import Optional
from datetime import datetime

from app.application.dto.landmap_dto import (
    LandMapQueryDTO,
    GeoLocationDTO,
)
from app.application.use_cases.landmap_use_case import (
    GetLandMapDataUseCase,
    ListLandClassificationsUseCase,
    GetAreaStatisticsUseCase,
)
from app.domain.entities.landmap_entity import (
    LandMapQuery,
    GeoLocation,
)
from app.infrastructure.repositories.landmap_repository_impl import (
    LandMapRepositoryImpl,
    ExternalDataSourceRepositoryImpl,
)
from app.application.soil_service import SoilService
from app.domain.soil_models import SoilDataResponse

logger = logging.getLogger(__name__)

router = APIRouter(
    prefix="/landmap",
    tags=["Land Map & Soil"],
)


def get_landmap_use_case():
    landmap_repo = LandMapRepositoryImpl()
    external_repo = ExternalDataSourceRepositoryImpl()
    return GetLandMapDataUseCase(landmap_repo, external_repo)


def get_classifications_use_case():
    landmap_repo = LandMapRepositoryImpl()
    return ListLandClassificationsUseCase(landmap_repo)


def get_statistics_use_case():
    external_repo = ExternalDataSourceRepositoryImpl()
    return GetAreaStatisticsUseCase(external_repo)


def get_soil_service():
    return SoilService()


@router.get("/data", summary="Get Land Map Data")
async def get_landmap_data(
    latitude: float = Query(..., ge=-90, le=90, description="Latitude"),
    longitude: float = Query(..., ge=-180, le=180, description="Longitude"),
    data_type: str = Query(
        "dem",
        pattern="^(dem|lulc|ndvi)$",
        description="Data type: dem, lulc, ndvi",
    ),
    use_case: GetLandMapDataUseCase = Depends(get_landmap_use_case),
):
    try:
        query = LandMapQuery(
            location=GeoLocation(
                latitude=latitude,
                longitude=longitude,
            ),
            data_type=data_type,
            resolution=250,
        )

        result = await use_case.execute(query)

        if not result:
            raise HTTPException(
                status_code=404,
                detail=f"No data available for location: {latitude}, {longitude}",
            )

        return {
            "location": {
                "latitude": result.location.latitude,
                "longitude": result.location.longitude,
            },
            "data_type": result.data_type,
            "resolution": result.resolution,
            "data_source": "copernicus",
            "timestamp": result.timestamp or datetime.utcnow(),
            "raster_info": {
                "crs": result.data.crs if result.data else "EPSG:4326",
                "bounds": result.data.bounds if result.data else {},
            },
        }

    except Exception as e:
        logger.error(f"Error retrieving land map data: {str(e)}")
        raise HTTPException(
            status_code=500,
            detail=f"Error retrieving land map data: {str(e)}",
        )


@router.get("/classifications/{data_type}", summary="Get Classification Categories")
async def get_classifications(
    data_type: str,
    use_case: ListLandClassificationsUseCase = Depends(get_classifications_use_case),
):
    try:
        classifications = await use_case.execute(data_type)
        return [
            {
                "code": c.code,
                "name": c.name,
                "description": c.description,
                "color": c.color_hex,
            }
            for c in classifications
        ]
    except Exception as e:
        logger.error(f"Error retrieving classifications: {str(e)}")
        raise HTTPException(
            status_code=500,
            detail=f"Error retrieving classifications: {str(e)}",
        )


@router.get("/statistics", summary="Get Area Statistics")
async def get_area_statistics(
    latitude: float = Query(..., ge=-90, le=90),
    longitude: float = Query(..., ge=-180, le=180),
    data_type: str = Query("dem", pattern="^(dem|lulc)$"),
    use_case: GetAreaStatisticsUseCase = Depends(get_statistics_use_case),
):
    try:
        location = GeoLocation(latitude=latitude, longitude=longitude)
        stats = await use_case.execute(location, data_type)

        return {
            "location": {"latitude": latitude, "longitude": longitude},
            "data_type": data_type,
            "statistics": stats,
            "timestamp": datetime.utcnow(),
        }

    except Exception as e:
        logger.error(f"Error retrieving statistics: {str(e)}")
        raise HTTPException(
            status_code=500,
            detail=f"Error retrieving statistics: {str(e)}",
        )


@router.post("/batch", summary="Batch Query")
async def batch_query(
    locations: list[LandMapQueryDTO],
    use_case: GetLandMapDataUseCase = Depends(get_landmap_use_case),
):
    try:
        results = []

        for location_query in locations:
            query = LandMapQuery(
                location=GeoLocation(
                    latitude=location_query.location.latitude,
                    longitude=location_query.location.longitude,
                ),
                data_type=location_query.data_type,
                resolution=location_query.resolution,
            )

            result = await use_case.execute(query)
            if result:
                results.append(
                    {
                        "location": {
                            "latitude": result.location.latitude,
                            "longitude": result.location.longitude,
                        },
                        "data_type": result.data_type,
                        "timestamp": result.timestamp,
                    }
                )

        return {"count": len(results), "results": results}

    except Exception as e:
        logger.error(f"Error in batch query: {str(e)}")
        raise HTTPException(
            status_code=500,
            detail=f"Error in batch query: {str(e)}",
        )


@router.get("/soil/data", response_model=SoilDataResponse, summary="Get Soil Data")
async def get_soil_data(
    latitude: float = Query(..., ge=-90, le=90, description="Latitude"),
    longitude: float = Query(..., ge=-180, le=180, description="Longitude"),
    depths: Optional[str] = Query(
        None,
        description="Comma-separated soil depths in cm (default: 0,10,30,60,100,200)",
    ),
    soil_service: SoilService = Depends(get_soil_service),
) -> SoilDataResponse:
    """
    Get soil data (pH, nutrients, texture) from Local Vietnam Database.
    
    Note: Data available only for Vietnam (8°N-24°N, 102°E-110°E).
    Uses open-source CSV data, no external API calls.
    
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


@router.get("/soil/recommendations", summary="Get Soil Recommendations")
async def get_soil_recommendations(
    latitude: float = Query(..., ge=-90, le=90, description="Latitude"),
    longitude: float = Query(..., ge=-180, le=180, description="Longitude"),
    soil_service: SoilService = Depends(get_soil_service),
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


@router.get("/info", summary="Land Map Information")
async def get_landmap_info():
    return {
        "service": "Global Land Map + Soil Data",
        "description": "Free and open source global land data at 250m resolution with detailed soil analysis",
        "data_sources": [
            {
                "name": "Copernicus",
                "types": ["dem", "lulc"],
                "resolution": ["30m", "100m"],
                "coverage": "Global",
                "license": "CC-BY-4.0",
                "url": "https://land.copernicus.eu/",
            },
            {
                "name": "Sentinel-2 (ESA)",
                "types": ["ndvi", "true_color"],
                "resolution": "10m",
                "coverage": "Global",
                "license": "CC-BY-4.0",
                "url": "https://sentinel.esa.int/",
            },
            {
                "name": "USGS",
                "types": ["dem", "nlcd"],
                "resolution": "30m",
                "coverage": "USA (NLCD), Global (DEM)",
                "license": "Public Domain",
                "url": "https://www.usgs.gov/",
            },
            {
                "name": "Local Vietnam Soil Database",
                "types": ["soil_pH", "soil_nutrients", "soil_texture", "bulk_density"],
                "resolution": "Provincial level (30 provinces)",
                "coverage": "Vietnam (8°N-24°N, 102°E-110°E)",
                "license": "CC-BY-4.0 (Open Data)",
                "url": "backend/data/soil_vietnam.csv",
                "mutable": True,
            },
        ],
        "endpoints": [
            {"path": "/api/v1/landmap/data", "method": "GET", "description": "Get land map data"},
            {
                "path": "/api/v1/landmap/classifications/{data_type}",
                "method": "GET",
                "description": "Get classifications",
            },
            {
                "path": "/api/v1/landmap/statistics",
                "method": "GET",
                "description": "Get statistics",
            },
            {
                "path": "/api/v1/landmap/batch",
                "method": "POST",
                "description": "Batch query",
            },
            {
                "path": "/api/v1/landmap/soil/data",
                "method": "GET",
                "description": "Get soil data (pH, nutrients, texture)",
            },
            {
                "path": "/api/v1/landmap/soil/recommendations",
                "method": "GET",
                "description": "Get soil management recommendations",
            },
        ],
    }
