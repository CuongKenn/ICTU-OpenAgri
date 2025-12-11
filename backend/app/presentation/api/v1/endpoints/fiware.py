# Copyright (c) 2025 CuongKenn and ICTU-OpenAgri Contributors
# Licensed under the MIT License. See LICENSE file in the project root for full license information.

"""
FIWARE API endpoints for managing NGSI-LD entities.
"""
from typing import List, Optional
from fastapi import APIRouter, HTTPException, status, Query
from pydantic import BaseModel, Field
from datetime import datetime

from app.infrastructure.config.settings import get_settings
from app.infrastructure.external_services.fiware_client import (
    FiwareClient,
    FiwareClientError,
    create_agriparcel_entity,
    create_agriparcel_record,
    create_weather_observed,
    sync_farm_to_fiware,
    sync_observation_to_fiware
)

router = APIRouter()
settings = get_settings()


# ==================== Pydantic Models ====================

class CoordinateModel(BaseModel):
    lat: float = Field(..., description="Latitude")
    lng: float = Field(..., description="Longitude")


class FiwareHealthResponse(BaseModel):
    status: str
    orion_url: str
    orion_available: bool
    fiware_enabled: bool


class FiwareEntityResponse(BaseModel):
    success: bool
    entity_id: Optional[str] = None
    message: str


class FiwareQueryResponse(BaseModel):
    success: bool
    entities: List[dict]
    count: int


class SyncFarmRequest(BaseModel):
    farm_id: int
    farm_name: str
    coordinates: List[CoordinateModel]
    crop_type: Optional[str] = None


class SyncObservationRequest(BaseModel):
    farm_id: int
    observation_type: str = Field(..., description="Type of observation (ndvi, soilMoisture)")
    value: float
    observed_at: Optional[datetime] = None


class WeatherObservationRequest(BaseModel):
    location_id: str
    lat: float
    lng: float
    temperature: Optional[float] = None
    humidity: Optional[float] = None
    precipitation: Optional[float] = None
    wind_speed: Optional[float] = None
    observed_at: Optional[datetime] = None


# ==================== Endpoints ====================

@router.get("/health", response_model=FiwareHealthResponse)
async def check_fiware_health():
    """
    Check FIWARE Orion Context Broker health status.
    """
    fiware = FiwareClient()
    is_available = await fiware.health_check()
    
    return FiwareHealthResponse(
        status="healthy" if is_available else "unavailable",
        orion_url=settings.ORION_URL,
        orion_available=is_available,
        fiware_enabled=settings.FIWARE_ENABLED
    )


@router.post("/entities/farm", response_model=FiwareEntityResponse)
async def create_farm_entity(request: SyncFarmRequest):
    """
    Create or update a farm entity (AgriParcel) in FIWARE.
    """
    if not settings.FIWARE_ENABLED:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="FIWARE integration is disabled"
        )
    if not request.coordinates or len(request.coordinates) < 3:
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail="coordinates must include at least 3 points to form a polygon"
        )
    
    fiware = FiwareClient()
    
    if not await fiware.health_check():
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="FIWARE Orion is not available"
        )
    
    coords = [{"lat": c.lat, "lng": c.lng} for c in request.coordinates]
    
    try:
        success = await sync_farm_to_fiware(
            fiware_client=fiware,
            farm_id=request.farm_id,
            farm_name=request.farm_name,
            coordinates=coords,
            crop_type=request.crop_type
        )
    except FiwareClientError as e:
        raise HTTPException(status_code=e.status_code, detail=f"FIWARE error: {e}") from e
    
    if success:
        entity_id = f"urn:ngsi-ld:AgriParcel:OpenAgri:{request.farm_id}"
        return FiwareEntityResponse(
            success=True,
            entity_id=entity_id,
            message="Farm entity created/updated successfully"
        )
    else:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to create/update farm entity"
        )


@router.post("/entities/observation", response_model=FiwareEntityResponse)
async def create_observation_entity(request: SyncObservationRequest):
    """
    Create an observation record (AgriParcelRecord) in FIWARE.
    """
    if not settings.FIWARE_ENABLED:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="FIWARE integration is disabled"
        )
    
    fiware = FiwareClient()
    
    if not await fiware.health_check():
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="FIWARE Orion is not available"
        )
    
    observed_at = request.observed_at or datetime.utcnow()
    try:
        success = await sync_observation_to_fiware(
            fiware_client=fiware,
            farm_id=request.farm_id,
            observation_type=request.observation_type,
            value=request.value,
            observed_at=observed_at
        )
    except FiwareClientError as e:
        raise HTTPException(status_code=e.status_code, detail=f"FIWARE error: {e}") from e
    
    if success:
        timestamp_str = observed_at.strftime('%Y%m%dT%H%M%S')
        entity_id = f"urn:ngsi-ld:AgriParcelRecord:OpenAgri:{request.farm_id}:{request.observation_type}:{timestamp_str}"
        return FiwareEntityResponse(
            success=True,
            entity_id=entity_id,
            message="Observation entity created successfully"
        )
    else:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to create observation entity"
        )


@router.post("/entities/weather", response_model=FiwareEntityResponse)
async def create_weather_entity(request: WeatherObservationRequest):
    """
    Create a weather observation entity in FIWARE.
    """
    if not settings.FIWARE_ENABLED:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="FIWARE integration is disabled"
        )
    
    fiware = FiwareClient()
    
    if not await fiware.health_check():
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="FIWARE Orion is not available"
        )
    
    entity = create_weather_observed(
        location_id=request.location_id,
        lat=request.lat,
        lng=request.lng,
        temperature=request.temperature,
        humidity=request.humidity,
        precipitation=request.precipitation,
        wind_speed=request.wind_speed,
        observed_at=request.observed_at
    )
    
    try:
        success = await fiware.create_entity(entity)
    except FiwareClientError as e:
        raise HTTPException(status_code=e.status_code, detail=f"FIWARE error: {e}") from e
    
    if success:
        return FiwareEntityResponse(
            success=True,
            entity_id=entity["id"],
            message="Weather entity created successfully"
        )
    else:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to create weather entity"
        )


@router.get("/entities/{entity_id}")
async def get_entity(entity_id: str):
    """
    Get an entity from FIWARE by its ID.
    """
    if not settings.FIWARE_ENABLED:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="FIWARE integration is disabled"
        )
    
    fiware = FiwareClient()
    
    if not await fiware.health_check():
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="FIWARE Orion is not available"
        )
    
    try:
        entity = await fiware.get_entity(entity_id)
    except FiwareClientError as e:
        raise HTTPException(status_code=e.status_code, detail=f"FIWARE error: {e}") from e
    
    if entity:
        return entity
    else:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Entity {entity_id} not found"
        )


@router.delete("/entities/{entity_id}", response_model=FiwareEntityResponse)
async def delete_entity(entity_id: str):
    """
    Delete an entity from FIWARE by its ID.
    """
    if not settings.FIWARE_ENABLED:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="FIWARE integration is disabled"
        )
    
    fiware = FiwareClient()
    
    if not await fiware.health_check():
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="FIWARE Orion is not available"
        )
    
    try:
        success = await fiware.delete_entity(entity_id)
    except FiwareClientError as e:
        raise HTTPException(status_code=e.status_code, detail=f"FIWARE error: {e}") from e
    
    if success:
        return FiwareEntityResponse(
            success=True,
            entity_id=entity_id,
            message="Entity deleted successfully"
        )
    else:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to delete entity"
        )


@router.get("/entities", response_model=FiwareQueryResponse)
async def query_entities(
    entity_type: str = Query(..., description="Entity type to query (AgriParcel, AgriParcelRecord, WeatherObserved)"),
    q: Optional[str] = Query(None, description="NGSI-LD query filter"),
    limit: int = Query(100, description="Maximum number of results", ge=1, le=1000)
):
    """
    Query entities from FIWARE by type.
    
    Example entity types:
    - AgriParcel: Farm/parcel entities
    - AgriParcelRecord: NDVI, soil moisture observations
    - WeatherObserved: Weather observations
    """
    if not settings.FIWARE_ENABLED:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="FIWARE integration is disabled"
        )
    
    fiware = FiwareClient()
    
    if not await fiware.health_check():
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="FIWARE Orion is not available"
        )
    
    try:
        entities = await fiware.query_entities(entity_type, q=q, limit=limit)
    except FiwareClientError as e:
        raise HTTPException(status_code=e.status_code, detail=f"FIWARE error: {e}") from e
    
    return FiwareQueryResponse(
        success=True,
        entities=entities,
        count=len(entities)
    )


@router.get("/farms/{farm_id}/entities")
async def get_farm_entities(farm_id: int):
    """
    Get all FIWARE entities related to a specific farm.
    Returns the AgriParcel entity and all associated AgriParcelRecord observations.
    """
    if not settings.FIWARE_ENABLED:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="FIWARE integration is disabled"
        )
    
    fiware = FiwareClient()
    
    if not await fiware.health_check():
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="FIWARE Orion is not available"
        )
    
    # Get the farm entity
    farm_entity_id = f"urn:ngsi-ld:AgriParcel:OpenAgri:{farm_id}"
    try:
        farm_entity = await fiware.get_entity(farm_entity_id)
        
        # Query related observation records
        observations = await fiware.query_entities(
            "AgriParcelRecord",
            q=f'hasAgriParcel=={farm_entity_id}',
            limit=100
        )
    except FiwareClientError as e:
        raise HTTPException(status_code=e.status_code, detail=f"FIWARE error: {e}") from e
    
    return {
        "farm_id": farm_id,
        "fiware_entity_id": farm_entity_id,
        "farm_entity": farm_entity,
        "observations": observations,
        "observation_count": len(observations)
    }
