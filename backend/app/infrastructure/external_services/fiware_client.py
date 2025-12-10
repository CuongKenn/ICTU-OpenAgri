# Copyright (c) 2025 CuongKenn and ICTU-OpenAgri Contributors
# Licensed under the MIT License. See LICENSE file in the project root for full license information.

"""
FIWARE Orion Context Broker client for NGSI-LD API.
Implements Smart Data Models for Agriculture (AgriFood).
"""
import httpx
import logging
from typing import Dict, Any, Optional, List
from datetime import datetime
from app.infrastructure.config.settings import get_settings

logger = logging.getLogger(__name__)
settings = get_settings()

# FIWARE Smart Data Models for Agriculture
CONTEXT = [
    "https://uri.etsi.org/ngsi-ld/v1/ngsi-ld-core-context.jsonld",
    "https://raw.githubusercontent.com/smart-data-models/dataModel.Agrifood/master/context.jsonld"
]


class FiwareClient:
    """Client for FIWARE Orion Context Broker (NGSI-LD)."""
    
    def __init__(self, orion_url: str = None):
        self.orion_url = orion_url or settings.ORION_URL
        self.headers = {
            "Content-Type": "application/ld+json",
            "Accept": "application/ld+json"
        }
    
    async def health_check(self) -> bool:
        """Check if Orion Context Broker is available."""
        async with httpx.AsyncClient(timeout=5.0) as client:
            try:
                response = await client.get(f"{self.orion_url}/version")
                return response.status_code == 200
            except Exception as e:
                logger.error(f"Orion health check failed: {e}")
                return False
    
    async def create_entity(self, entity: Dict[str, Any]) -> bool:
        """Create a new entity in Orion."""
        async with httpx.AsyncClient(timeout=30.0) as client:
            try:
                response = await client.post(
                    f"{self.orion_url}/ngsi-ld/v1/entities",
                    json=entity,
                    headers=self.headers
                )
                if response.status_code in [201, 204]:
                    logger.info(f"Entity created: {entity.get('id')}")
                    return True
                elif response.status_code == 409:
                    logger.info(f"Entity already exists, updating: {entity.get('id')}")
                    return await self.update_entity(entity["id"], entity)
                else:
                    logger.error(f"Failed to create entity: {response.status_code} - {response.text}")
                    return False
            except Exception as e:
                logger.error(f"Error creating entity: {e}")
                return False
    
    async def update_entity(self, entity_id: str, attrs: Dict[str, Any]) -> bool:
        """Update entity attributes."""
        # Remove @context and id for PATCH request
        update_attrs = {k: v for k, v in attrs.items() if k not in ["@context", "id", "type"]}
        
        async with httpx.AsyncClient(timeout=30.0) as client:
            try:
                headers = {
                    "Content-Type": "application/json",
                    "Link": f'<{CONTEXT[0]}>; rel="http://www.w3.org/ns/json-ld#context"; type="application/ld+json"'
                }
                response = await client.patch(
                    f"{self.orion_url}/ngsi-ld/v1/entities/{entity_id}/attrs",
                    json=update_attrs,
                    headers=headers
                )
                if response.status_code in [200, 204]:
                    logger.info(f"Entity updated: {entity_id}")
                    return True
                else:
                    logger.error(f"Failed to update entity: {response.status_code} - {response.text}")
                    return False
            except Exception as e:
                logger.error(f"Error updating entity: {e}")
                return False
    
    async def get_entity(self, entity_id: str) -> Optional[Dict[str, Any]]:
        """Get entity by ID."""
        async with httpx.AsyncClient(timeout=30.0) as client:
            try:
                response = await client.get(
                    f"{self.orion_url}/ngsi-ld/v1/entities/{entity_id}",
                    headers=self.headers
                )
                if response.status_code == 200:
                    return response.json()
                return None
            except Exception as e:
                logger.error(f"Error getting entity: {e}")
                return None
    
    async def delete_entity(self, entity_id: str) -> bool:
        """Delete entity by ID."""
        async with httpx.AsyncClient(timeout=30.0) as client:
            try:
                response = await client.delete(
                    f"{self.orion_url}/ngsi-ld/v1/entities/{entity_id}"
                )
                return response.status_code in [200, 204]
            except Exception as e:
                logger.error(f"Error deleting entity: {e}")
                return False
    
    async def query_entities(
        self, 
        entity_type: str, 
        q: Optional[str] = None,
        limit: int = 100
    ) -> List[Dict[str, Any]]:
        """Query entities by type."""
        async with httpx.AsyncClient(timeout=30.0) as client:
            try:
                params = {"type": entity_type, "limit": limit}
                if q:
                    params["q"] = q
                response = await client.get(
                    f"{self.orion_url}/ngsi-ld/v1/entities",
                    params=params,
                    headers=self.headers
                )
                if response.status_code == 200:
                    return response.json()
                return []
            except Exception as e:
                logger.error(f"Error querying entities: {e}")
                return []
    
    async def subscribe_to_entity(
        self,
        entity_type: str,
        notification_url: str,
        watched_attrs: List[str] = None
    ) -> Optional[str]:
        """Create a subscription for entity changes."""
        subscription = {
            "@context": CONTEXT,
            "type": "Subscription",
            "entities": [{"type": entity_type}],
            "notification": {
                "endpoint": {
                    "uri": notification_url,
                    "accept": "application/json"
                }
            }
        }
        
        if watched_attrs:
            subscription["watchedAttributes"] = watched_attrs
        
        async with httpx.AsyncClient(timeout=30.0) as client:
            try:
                response = await client.post(
                    f"{self.orion_url}/ngsi-ld/v1/subscriptions",
                    json=subscription,
                    headers=self.headers
                )
                if response.status_code in [201, 204]:
                    location = response.headers.get("Location", "")
                    subscription_id = location.split("/")[-1] if location else None
                    logger.info(f"Subscription created: {subscription_id}")
                    return subscription_id
                else:
                    logger.error(f"Failed to create subscription: {response.text}")
                    return None
            except Exception as e:
                logger.error(f"Error creating subscription: {e}")
                return None


# ==================== Smart Data Model Factories ====================

def create_agriparcel_entity(
    farm_id: int, 
    name: str, 
    coordinates: List[Dict], 
    crop_type: str = None,
    area: float = None
) -> Dict[str, Any]:
    """
    Create AgriParcel entity following Smart Data Models.
    https://github.com/smart-data-models/dataModel.Agrifood/tree/master/AgriParcel
    
    Args:
        farm_id: Internal farm ID
        name: Name of the parcel
        coordinates: List of coordinate dicts with 'lat' and 'lng' keys
        crop_type: Type of crop being grown
        area: Area in hectares
    """
    # Convert coordinates to GeoJSON Polygon
    polygon_coords = [[c["lng"], c["lat"]] for c in coordinates]
    if polygon_coords[0] != polygon_coords[-1]:
        polygon_coords.append(polygon_coords[0])  # Close the polygon
    
    entity = {
        "@context": CONTEXT,
        "id": f"urn:ngsi-ld:AgriParcel:OpenAgri:{farm_id}",
        "type": "AgriParcel",
        "name": {
            "type": "Property",
            "value": name
        },
        "location": {
            "type": "GeoProperty",
            "value": {
                "type": "Polygon",
                "coordinates": [polygon_coords]
            }
        },
        "dateCreated": {
            "type": "Property",
            "value": datetime.utcnow().isoformat() + "Z"
        },
        "dateModified": {
            "type": "Property",
            "value": datetime.utcnow().isoformat() + "Z"
        }
    }
    
    if crop_type:
        entity["category"] = {
            "type": "Property",
            "value": crop_type
        }
    
    if area:
        entity["area"] = {
            "type": "Property",
            "value": area,
            "unitCode": "HAR"  # Hectare
        }
    
    return entity


def create_agriparcel_record(
    farm_id: int,
    record_type: str,
    value: float,
    observed_at: datetime,
    unit_code: str = None
) -> Dict[str, Any]:
    """
    Create AgriParcelRecord entity for observations (NDVI, soil moisture, etc.).
    https://github.com/smart-data-models/dataModel.Agrifood/tree/master/AgriParcelRecord
    
    Args:
        farm_id: Internal farm ID
        record_type: Type of record (e.g., 'ndvi', 'soilMoisture')
        value: Measured value
        observed_at: Timestamp of observation
        unit_code: UN/CEFACT unit code
    """
    timestamp_str = observed_at.strftime('%Y%m%dT%H%M%S')
    
    entity = {
        "@context": CONTEXT,
        "id": f"urn:ngsi-ld:AgriParcelRecord:OpenAgri:{farm_id}:{record_type}:{timestamp_str}",
        "type": "AgriParcelRecord",
        "hasAgriParcel": {
            "type": "Relationship",
            "object": f"urn:ngsi-ld:AgriParcel:OpenAgri:{farm_id}"
        },
        record_type: {
            "type": "Property",
            "value": value,
            "observedAt": observed_at.isoformat() + "Z"
        },
        "dateObserved": {
            "type": "Property",
            "value": observed_at.isoformat() + "Z"
        }
    }
    
    if unit_code:
        entity[record_type]["unitCode"] = unit_code
    
    return entity


def create_weather_observed(
    location_id: str,
    lat: float,
    lng: float,
    temperature: float = None,
    humidity: float = None,
    precipitation: float = None,
    wind_speed: float = None,
    observed_at: datetime = None
) -> Dict[str, Any]:
    """
    Create WeatherObserved entity.
    https://github.com/smart-data-models/dataModel.Weather/tree/master/WeatherObserved
    
    Args:
        location_id: Identifier for the location
        lat: Latitude
        lng: Longitude
        temperature: Temperature in Celsius
        humidity: Relative humidity (0-100)
        precipitation: Precipitation in mm
        wind_speed: Wind speed in m/s
        observed_at: Observation timestamp
    """
    if observed_at is None:
        observed_at = datetime.utcnow()
    
    timestamp_str = observed_at.strftime('%Y%m%dT%H%M%S')
    
    entity = {
        "@context": CONTEXT,
        "id": f"urn:ngsi-ld:WeatherObserved:OpenAgri:{location_id}:{timestamp_str}",
        "type": "WeatherObserved",
        "location": {
            "type": "GeoProperty",
            "value": {
                "type": "Point",
                "coordinates": [lng, lat]
            }
        },
        "dateObserved": {
            "type": "Property",
            "value": observed_at.isoformat() + "Z"
        }
    }
    
    if temperature is not None:
        entity["temperature"] = {
            "type": "Property",
            "value": temperature,
            "unitCode": "CEL"
        }
    
    if humidity is not None:
        entity["relativeHumidity"] = {
            "type": "Property",
            "value": humidity / 100,  # Convert to 0-1 range
            "unitCode": "P1"  # Percent
        }
    
    if precipitation is not None:
        entity["precipitation"] = {
            "type": "Property",
            "value": precipitation,
            "unitCode": "MMT"  # Millimeter
        }
    
    if wind_speed is not None:
        entity["windSpeed"] = {
            "type": "Property",
            "value": wind_speed,
            "unitCode": "MTS"  # Meters per second
        }
    
    return entity


def create_device_entity(
    device_id: str,
    device_type: str,
    lat: float,
    lng: float,
    farm_id: int = None,
    description: str = None
) -> Dict[str, Any]:
    """
    Create Device entity for IoT sensors.
    https://github.com/smart-data-models/dataModel.Device/tree/master/Device
    
    Args:
        device_id: Unique device identifier
        device_type: Type of device (e.g., 'SoilMoistureSensor', 'TemperatureSensor')
        lat: Latitude
        lng: Longitude
        farm_id: Associated farm ID
        description: Device description
    """
    entity = {
        "@context": CONTEXT,
        "id": f"urn:ngsi-ld:Device:OpenAgri:{device_id}",
        "type": "Device",
        "category": {
            "type": "Property",
            "value": [device_type]
        },
        "location": {
            "type": "GeoProperty",
            "value": {
                "type": "Point",
                "coordinates": [lng, lat]
            }
        },
        "dateInstalled": {
            "type": "Property",
            "value": datetime.utcnow().isoformat() + "Z"
        },
        "controlledProperty": {
            "type": "Property",
            "value": _get_controlled_property(device_type)
        }
    }
    
    if farm_id:
        entity["refAgriParcel"] = {
            "type": "Relationship",
            "object": f"urn:ngsi-ld:AgriParcel:OpenAgri:{farm_id}"
        }
    
    if description:
        entity["description"] = {
            "type": "Property",
            "value": description
        }
    
    return entity


def _get_controlled_property(device_type: str) -> List[str]:
    """Get controlled properties based on device type."""
    property_map = {
        "SoilMoistureSensor": ["soilMoisture"],
        "TemperatureSensor": ["temperature"],
        "HumiditySensor": ["humidity"],
        "WeatherStation": ["temperature", "humidity", "precipitation", "windSpeed"],
        "NDVISensor": ["ndvi"],
    }
    return property_map.get(device_type, ["unknown"])


# ==================== Utility Functions ====================

async def sync_farm_to_fiware(
    fiware_client: FiwareClient,
    farm_id: int,
    farm_name: str,
    coordinates: List[Dict],
    crop_type: str = None
) -> bool:
    """
    Sync a farm entity to FIWARE Orion.
    
    Args:
        fiware_client: FiwareClient instance
        farm_id: Internal farm ID
        farm_name: Name of the farm
        coordinates: List of coordinate dicts
        crop_type: Type of crop
    
    Returns:
        True if successful, False otherwise
    """
    try:
        entity = create_agriparcel_entity(
            farm_id=farm_id,
            name=farm_name,
            coordinates=coordinates,
            crop_type=crop_type
        )
        return await fiware_client.create_entity(entity)
    except Exception as e:
        logger.error(f"Failed to sync farm {farm_id} to FIWARE: {e}")
        return False


async def sync_observation_to_fiware(
    fiware_client: FiwareClient,
    farm_id: int,
    observation_type: str,
    value: float,
    observed_at: datetime,
    unit_code: str = None
) -> bool:
    """
    Sync an observation record to FIWARE Orion.
    
    Args:
        fiware_client: FiwareClient instance
        farm_id: Internal farm ID
        observation_type: Type of observation (e.g., 'ndvi', 'soilMoisture')
        value: Observed value
        observed_at: Timestamp of observation
        unit_code: UN/CEFACT unit code
    
    Returns:
        True if successful, False otherwise
    """
    try:
        entity = create_agriparcel_record(
            farm_id=farm_id,
            record_type=observation_type,
            value=value,
            observed_at=observed_at,
            unit_code=unit_code
        )
        return await fiware_client.create_entity(entity)
    except Exception as e:
        logger.error(f"Failed to sync observation for farm {farm_id} to FIWARE: {e}")
        return False
