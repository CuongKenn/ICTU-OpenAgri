"""
Land Map Repository Interface
"""
from abc import ABC, abstractmethod
from typing import Optional, List
from app.domain.entities.landmap_entity import (
    LandMapTile,
    LandClassification,
    RasterData,
    GeoLocation,
)


class LandMapRepository(ABC):
    """Abstract repository for land map operations"""

    @abstractmethod
    async def get_tile(
        self,
        x: int,
        y: int,
        z: int,
        data_source: str,
        data_type: str,
    ) -> Optional[LandMapTile]:
        """Get a specific tile by coordinates"""
        pass

    @abstractmethod
    async def get_data_at_location(
        self,
        location: GeoLocation,
        data_type: str,
    ) -> Optional[RasterData]:
        """Get raster data at a specific geographic location"""
        pass

    @abstractmethod
    async def list_classifications(
        self,
        data_type: str,
    ) -> List[LandClassification]:
        """List all classification categories for a data type"""
        pass

    @abstractmethod
    async def cache_tile(self, tile: LandMapTile) -> bool:
        """Cache a tile locally"""
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
        """Get path to cached tile file"""
        pass


class ExternalDataSourceRepository(ABC):
    """Abstract repository for external data sources"""

    @abstractmethod
    async def fetch_from_copernicus(
        self,
        location: GeoLocation,
        data_type: str,
    ) -> Optional[RasterData]:
        """Fetch data from Copernicus Global Land Service"""
        pass

    @abstractmethod
    async def fetch_from_usgs(
        self,
        location: GeoLocation,
        data_type: str,
    ) -> Optional[RasterData]:
        """Fetch data from USGS Earth Explorer"""
        pass

    @abstractmethod
    async def fetch_from_sentinel(
        self,
        location: GeoLocation,
    ) -> Optional[RasterData]:
        """Fetch data from Sentinel-2 (ESA)"""
        pass
