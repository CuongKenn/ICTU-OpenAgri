"""
Land Map Use Cases
"""
from typing import Optional, List
from app.domain.entities.landmap_entity import (
    LandMapQuery,
    LandMapResponse,
    GeoLocation,
    LandClassification,
    RasterData,
)
from app.domain.repositories.landmap_repository import (
    LandMapRepository,
    ExternalDataSourceRepository,
)
from datetime import datetime


class GetLandMapDataUseCase:
    """Use case for retrieving land map data"""

    def __init__(
        self,
        landmap_repo: LandMapRepository,
        external_repo: ExternalDataSourceRepository,
    ):
        self.landmap_repo = landmap_repo
        self.external_repo = external_repo

    async def execute(self, query: LandMapQuery) -> Optional[LandMapResponse]:
        """
        Execute the use case to get land map data.
        
        First checks cache, then fetches from external source if needed.
        """
        try:
            # Try to get from external source based on data_type
            raster_data = None

            if query.data_type == "dem":
                raster_data = await self.external_repo.fetch_from_copernicus(
                    query.location, "dem"
                )
            elif query.data_type == "lulc":
                raster_data = await self.external_repo.fetch_from_copernicus(
                    query.location, "lulc"
                )
            elif query.data_type == "ndvi":
                raster_data = await self.external_repo.fetch_from_sentinel(
                    query.location
                )

            if not raster_data:
                return None

            return LandMapResponse(
                location=query.location,
                data_type=query.data_type,
                resolution=query.resolution,
                data=raster_data,
                timestamp=datetime.utcnow(),
            )
        except Exception as e:
            import logging
            logger = logging.getLogger(__name__)
            logger.error(f"Error in GetLandMapDataUseCase: {e}")
            return None


class ListLandClassificationsUseCase:
    """Use case for listing land classifications"""

    def __init__(self, landmap_repo: LandMapRepository):
        self.landmap_repo = landmap_repo

    async def execute(self, data_type: str) -> List[LandClassification]:
        """Get all classifications for a data type"""
        return await self.landmap_repo.list_classifications(data_type)


class CacheLandMapTileUseCase:
    """Use case for caching tiles"""

    def __init__(self, landmap_repo: LandMapRepository):
        self.landmap_repo = landmap_repo

    async def execute(
        self,
        x: int,
        y: int,
        z: int,
        data_source: str,
        data_type: str,
    ) -> bool:
        """Download and cache a tile"""
        # Implementation would fetch from external source and save locally
        pass


class GetAreaStatisticsUseCase:
    """Use case for getting statistics for an area"""

    def __init__(self, external_repo: ExternalDataSourceRepository):
        self.external_repo = external_repo

    async def execute(
        self,
        location: GeoLocation,
        data_type: str,
    ) -> dict:
        """
        Get statistics for land data at a location.
        Returns min, max, mean, and classification breakdown.
        """
        raster_data = await self.external_repo.fetch_from_copernicus(
            location, data_type
        )

        if not raster_data:
            return {}

        # Calculate statistics
        return {
            "bounds": raster_data.bounds,
            "crs": raster_data.crs,
            "no_data_value": raster_data.no_data_value,
        }
