"""
Land Map API Routes
"""
import logging
from fastapi import APIRouter, HTTPException, Depends, Query
from typing import Optional

from app.application.dto.landmap_dto import (
    LandMapQueryDTO,
    LandMapResponseDTO,
    GeoLocationDTO,
    LandMapTileDTO,
    TileRequestDTO,
    AreaQueryDTO,
    BoundingBoxDTO,
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
from datetime import datetime

logger = logging.getLogger(__name__)

router = APIRouter(
    prefix="/landmap",
    tags=["Land Map"],
)


# Dependency injection
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


@router.get(
    "/data",
    summary="Get Land Map Data",
    description="Retrieve land map data (DEM, LULC, NDVI) for a specific location",
)
async def get_landmap_data(
    latitude: float = Query(..., ge=-90, le=90, description="Latitude"),
    longitude: float = Query(..., ge=-180, le=180, description="Longitude"),
    data_type: str = Query(
        "dem",
        pattern="^(dem|lulc|ndvi)$",
        description="Type of data: dem (Digital Elevation Model), lulc (Land Use/Land Cover), ndvi (Vegetation Index)",
    ),
    use_case: GetLandMapDataUseCase = Depends(get_landmap_use_case),
):
    """
    Get land map data at a specific geographic location.
    
    **Data Sources:**
    - DEM: Copernicus DEM (30m resolution)
    - LULC: Copernicus Land Use/Land Cover (100m resolution)
    - NDVI: Sentinel-2 NDVI (10m resolution)
    
    All data is free and open source from EU/ESA.
    """
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


@router.get(
    "/classifications/{data_type}",
    summary="Get Classification Categories",
    description="List all classification categories for a data type",
)
async def get_classifications(
    data_type: str,
    use_case: ListLandClassificationsUseCase = Depends(get_classifications_use_case),
):
    """
    Get all land classification categories for a specific data type.
    
    **Supported Types:**
    - lulc: Copernicus Land Use/Land Cover (15 classes)
    - nlcd: USGS National Land Cover Database (25 classes)
    """
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


@router.get(
    "/statistics",
    summary="Get Area Statistics",
    description="Get statistics for an area",
)
async def get_area_statistics(
    latitude: float = Query(..., ge=-90, le=90),
    longitude: float = Query(..., ge=-180, le=180),
    data_type: str = Query("dem", pattern="^(dem|lulc)$"),
    use_case: GetAreaStatisticsUseCase = Depends(get_statistics_use_case),
):
    """
    Get statistical information for land data at a location.
    
    Returns bounds, CRS, no-data values, and other metadata.
    """
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


@router.post(
    "/batch",
    summary="Batch Query",
    description="Query multiple locations at once",
)
async def batch_query(
    locations: list[LandMapQueryDTO],
    use_case: GetLandMapDataUseCase = Depends(get_landmap_use_case),
):
    """
    Query land map data for multiple locations in a single request.
    
    Useful for processing multiple areas efficiently.
    """
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


@router.get(
    "/info",
    summary="Land Map Information",
    description="Get information about available land map data",
)
async def get_landmap_info():
    """
    Get information about available land map datasets and sources.
    """
    return {
        "service": "Global Land Map",
        "description": "Free and open source global land data at 250m resolution",
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
        ],
        "endpoints": [
            {"path": "/api/v1/landmap/data", "method": "GET", "description": "Get data"},
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
        ],
    }
