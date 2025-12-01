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
