from typing import List
from app.domain.entities.farm import FarmArea, Coordinate
from app.application.dto.farm_dto import FarmAreaCreateDTO
from app.domain.repositories.farm_repository import FarmRepository

class CreateFarmAreaUseCase:
    def __init__(self, farm_repository: FarmRepository):
        self.farm_repository = farm_repository

    async def execute(self, user_id: int, dto: FarmAreaCreateDTO) -> FarmArea:
        coordinates = [Coordinate(lat=c.lat, lng=c.lng) for c in dto.coordinates]
        
        farm = FarmArea(
            name=dto.name,
            description=dto.description,
            coordinates=coordinates,
            area_size=dto.area_size,
            crop_type=dto.crop_type,
            user_id=user_id
        )
        
        return await self.farm_repository.save(farm)

class GetUserFarmsUseCase:
    def __init__(self, farm_repository: FarmRepository):
        self.farm_repository = farm_repository

    async def execute(self, user_id: int) -> List[FarmArea]:
        return await self.farm_repository.get_by_user_id(user_id)
