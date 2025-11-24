from abc import ABC, abstractmethod
from typing import Optional, List
from app.domain.entities.landmap_entity import (
    LandMapTile,
    LandClassification,
    RasterData,
    GeoLocation,
)


class LandMapRepository(ABC):

    @abstractmethod
    async def get_tile(
        self,
        x: int,
        y: int,
        z: int,
        data_source: str,
        data_type: str,
    ) -> Optional[LandMapTile]:
        pass

    @abstractmethod
    async def get_data_at_location(
        self,
        location: GeoLocation,
        data_type: str,
    ) -> Optional[RasterData]:
        pass

    @abstractmethod
    async def list_classifications(
        self,
        data_type: str,
    ) -> List[LandClassification]:
        pass

    @abstractmethod
    async def cache_tile(self, tile: LandMapTile) -> bool:
        pass

    @abstractmethod
    async def get_cached_tile(
        self,
        x: int,
        y: int,
        z: int,
        data_source: str,
        data_type: str,
    ) -> Optional[str]:
        pass


class ExternalDataSourceRepository(ABC):

    @abstractmethod
    async def fetch_from_copernicus(
        self,
        location: GeoLocation,
        data_type: str,
    ) -> Optional[RasterData]:
        pass

    @abstractmethod
    async def fetch_from_usgs(
        self,
        location: GeoLocation,
        data_type: str,
    ) -> Optional[RasterData]:
        pass

    @abstractmethod
    async def fetch_from_sentinel(
        self,
        location: GeoLocation,
    ) -> Optional[RasterData]:
        pass
