from abc import ABC, abstractmethod
from typing import List, Optional
from app.domain.entities.farm import FarmArea

class FarmRepository(ABC):
    @abstractmethod
    def create(self, farm: FarmArea) -> FarmArea:
        pass

    @abstractmethod
    def get_by_user_id(self, user_id: int) -> List[FarmArea]:
        pass

    @abstractmethod
    def get_by_id(self, farm_id: int) -> Optional[FarmArea]:
        pass
