# Copyright (c) 2025 CuongKenn and ICTU-OpenAgri Contributors
# Licensed under the MIT License. See LICENSE file in the project root for full license information.

from abc import ABC, abstractmethod
from typing import List, Optional
from app.domain.entities.farm import FarmArea

class FarmRepository(ABC):
    @abstractmethod
    async def save(self, farm: FarmArea) -> FarmArea:
        pass

    @abstractmethod
    async def get_by_user_id(self, user_id: int) -> List[FarmArea]:
        pass

    @abstractmethod
    async def get_by_id(self, farm_id: int) -> Optional[FarmArea]:
        pass

    @abstractmethod
    async def get_all_with_user(self, skip: int = 0, limit: int = 100) -> List[tuple[FarmArea, dict]]:
        """Get all farms with user details."""
        pass

    @abstractmethod
    async def update(self, farm_id: int, user_id: int, name: Optional[str] = None, 
                     description: Optional[str] = None, coordinates: Optional[list] = None,
                     area_size: Optional[float] = None, crop_type: Optional[str] = None) -> Optional[FarmArea]:
        """Update a farm area. Only the owner can update."""
        pass

    @abstractmethod
    async def delete(self, farm_id: int, user_id: int) -> bool:
        """Delete a farm area. Only the owner can delete."""
        pass
