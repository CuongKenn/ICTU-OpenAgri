# Copyright (c) 2025 CuongKenn and ICTU-OpenAgri Contributors
# Licensed under the MIT License. See LICENSE file in the project root for full license information.

from typing import List, Optional
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from app.domain.repositories.farm_repository import FarmRepository
from app.domain.entities.farm import FarmArea, Coordinate
from app.infrastructure.database.models.farm_model import FarmModel
from app.infrastructure.database.models.user_model import UserModel

class SQLAlchemyFarmRepository(FarmRepository):
    def __init__(self, db: AsyncSession):
        self.db = db

    async def save(self, farm: FarmArea) -> FarmArea:
        # Convert domain entity to SQLAlchemy model
        # Manually convert coordinates to list of dicts to avoid Pydantic version issues
        coordinates_json = [{"lat": coord.lat, "lng": coord.lng} for coord in farm.coordinates]
        
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

    async def get_all_with_user(self, skip: int = 0, limit: int = 100) -> List[tuple[FarmArea, dict]]:
        from app.infrastructure.database.models.user_model import UserModel
        
        result = await self.db.execute(
            select(FarmModel, UserModel)
            .join(UserModel, FarmModel.user_id == UserModel.id)
            .offset(skip)
            .limit(limit)
        )
        rows = result.all()
        
        return [
            (
                FarmArea(
                    id=farm.id,
                    name=farm.name,
                    description=farm.description,
                    coordinates=[Coordinate(**c) for c in farm.coordinates],
                    area_size=farm.area_size,
                    crop_type=farm.crop_type,
                    user_id=farm.user_id
                ),
                {
                    "email": user.email,
                    "username": user.username,
                    "full_name": user.full_name
                }
            )
            for farm, user in rows
        ]

    async def get_crop_distribution(self) -> List[dict]:
        from sqlalchemy import func
        result = await self.db.execute(
            select(FarmModel.crop_type, func.count(FarmModel.id))
            .group_by(FarmModel.crop_type)
        )
        return [{"crop_type": row[0] or "Chưa xác định", "count": row[1]} for row in result.all()]

    async def get_all_locations(self) -> List[dict]:
        result = await self.db.execute(
            select(
                FarmModel.id, 
                FarmModel.name, 
                FarmModel.coordinates, 
                FarmModel.crop_type,
                UserModel.full_name,
                UserModel.username
            ).join(UserModel, FarmModel.user_id == UserModel.id)
        )
        return [
            {
                "id": row.id,
                "name": row.name,
                "coordinates": row.coordinates,
                "crop_type": row.crop_type,
                "owner_name": row.full_name or row.username
            }
            for row in result.all()
        ]

    async def update(self, farm_id: int, user_id: int, name: Optional[str] = None,
                     description: Optional[str] = None, coordinates: Optional[list] = None,
                     area_size: Optional[float] = None, crop_type: Optional[str] = None) -> Optional[FarmArea]:
        """Update a farm area. Only the owner can update."""
        result = await self.db.execute(
            select(FarmModel).where(FarmModel.id == farm_id, FarmModel.user_id == user_id)
        )
        farm = result.scalar_one_or_none()
        
        if not farm:
            return None
        
        # Update only provided fields
        if name is not None:
            farm.name = name
        if description is not None:
            farm.description = description
        if coordinates is not None:
            farm.coordinates = [c.model_dump() if hasattr(c, 'model_dump') else c for c in coordinates]
        if area_size is not None:
            farm.area_size = area_size
        if crop_type is not None:
            farm.crop_type = crop_type
        
        await self.db.commit()
        await self.db.refresh(farm)
        
        return FarmArea(
            id=farm.id,
            name=farm.name,
            description=farm.description,
            coordinates=[Coordinate(**c) for c in farm.coordinates],
            area_size=farm.area_size,
            crop_type=farm.crop_type,
            user_id=farm.user_id
        )

    async def delete(self, farm_id: int, user_id: int) -> bool:
        """Delete a farm area. Only the owner can delete."""
        result = await self.db.execute(
            select(FarmModel).where(FarmModel.id == farm_id, FarmModel.user_id == user_id)
        )
        farm = result.scalar_one_or_none()
        
        if not farm:
            return False
        
        await self.db.delete(farm)
        await self.db.commit()
        return True
