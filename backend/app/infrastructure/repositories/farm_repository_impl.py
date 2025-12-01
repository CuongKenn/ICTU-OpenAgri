# Copyright (c) 2025 CuongKenn and ICTU-OpenAgri Contributors
# Licensed under the MIT License. See LICENSE file in the project root for full license information.

from typing import List, Optional
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from app.domain.repositories.farm_repository import FarmRepository
from app.domain.entities.farm import FarmArea, Coordinate
from app.infrastructure.database.models.farm_model import FarmModel

class SQLAlchemyFarmRepository(FarmRepository):
    def __init__(self, db: AsyncSession):
        self.db = db

    async def save(self, farm: FarmArea) -> FarmArea:
        # Convert domain entity to SQLAlchemy model
        coordinates_json = [coord.dict() for coord in farm.coordinates]
        
        db_farm = FarmModel(
            name=farm.name,
            description=farm.description,
            coordinates=coordinates_json,
            area_size=farm.area_size,
            crop_type=farm.crop_type,
            user_id=farm.user_id
        )
        
        self.db.add(db_farm)
        await self.db.commit()
        await self.db.refresh(db_farm)
        
        # Update ID from DB
        farm.id = db_farm.id
        return farm

    async def get_by_user_id(self, user_id: int) -> List[FarmArea]:
        result = await self.db.execute(
            select(FarmModel).where(FarmModel.user_id == user_id)
        )
        farms = result.scalars().all()
        
        return [
            FarmArea(
                id=farm.id,
                name=farm.name,
                description=farm.description,
                coordinates=[Coordinate(**c) for c in farm.coordinates],
                area_size=farm.area_size,
                crop_type=farm.crop_type,
                user_id=farm.user_id
            )
            for farm in farms
        ]

    async def get_by_id(self, farm_id: int) -> Optional[FarmArea]:
        result = await self.db.execute(
            select(FarmModel).where(FarmModel.id == farm_id)
        )
        farm = result.scalar_one_or_none()
        
        if farm:
            return FarmArea(
                id=farm.id,
                name=farm.name,
                description=farm.description,
                coordinates=[Coordinate(**c) for c in farm.coordinates],
                area_size=farm.area_size,
                crop_type=farm.crop_type,
                user_id=farm.user_id
            )
        return None
