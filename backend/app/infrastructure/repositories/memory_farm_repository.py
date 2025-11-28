from typing import List, Optional
from app.domain.entities.farm import FarmArea
from app.domain.repositories.farm_repository import FarmRepository

class InMemoryFarmRepository(FarmRepository):
    def __init__(self):
        self.farms: List[FarmArea] = []
        self._id_counter = 1

    async def save(self, farm: FarmArea) -> FarmArea:
        farm.id = self._id_counter
        self._id_counter += 1
        self.farms.append(farm)
        return farm

    async def get_by_user_id(self, user_id: int) -> List[FarmArea]:
        return [f for f in self.farms if f.user_id == user_id]

    async def get_by_id(self, farm_id: int) -> Optional[FarmArea]:
        for farm in self.farms:
            if farm.id == farm_id:
                return farm
        return None
