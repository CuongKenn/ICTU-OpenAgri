from typing import Optional, List
import logging
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

logger = logging.getLogger(__name__)


class GetLandMapDataUseCase:

    def __init__(
        self,
        landmap_repo: LandMapRepository,
        external_repo: ExternalDataSourceRepository,
    ):
        self.landmap_repo = landmap_repo
        self.external_repo = external_repo

    async def execute(self, query: LandMapQuery) -> Optional[LandMapResponse]:
        try:
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
            logger.error(f"Error in GetLandMapDataUseCase: {e}")
            return None


class ListLandClassificationsUseCase:

    def __init__(self, landmap_repo: LandMapRepository):
        self.landmap_repo = landmap_repo

    async def execute(self, data_type: str) -> List[LandClassification]:
        return await self.landmap_repo.list_classifications(data_type)


class CacheLandMapTileUseCase:

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
        pass


class GetAreaStatisticsUseCase:

    def __init__(self, external_repo: ExternalDataSourceRepository):
        self.external_repo = external_repo

    async def execute(
        self,
        location: GeoLocation,
        data_type: str,
    ) -> dict:
        raster_data = await self.external_repo.fetch_from_copernicus(
            location, data_type
        )

        if not raster_data:
            return {}

        return {
            "bounds": raster_data.bounds,
            "crs": raster_data.crs,
            "no_data_value": raster_data.no_data_value,
        }
