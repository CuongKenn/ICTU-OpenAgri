# Copyright (c) 2025 CuongKenn and ICTU-OpenAgri Contributors
# Licensed under the MIT License. See LICENSE file in the project root for full license information.

from typing import List, Optional
from datetime import date
from sqlalchemy import select, and_
from sqlalchemy.ext.asyncio import AsyncSession
from app.domain.repositories.satellite_repository import SatelliteRepository
from app.infrastructure.database.models.satellite_data_model import SatelliteDataModel

class SatelliteRepositoryImpl(SatelliteRepository):
    def __init__(self, session: AsyncSession):
        self.session = session

    async def save_data(self, data: SatelliteDataModel) -> SatelliteDataModel:
        self.session.add(data)
        await self.session.commit()
        await self.session.refresh(data)
        return data

    async def get_data_by_farm(self, farm_id: int, data_type: str, start_date: date, end_date: date) -> List[SatelliteDataModel]:
        query = select(SatelliteDataModel).where(
            and_(
                SatelliteDataModel.farm_id == farm_id,
                SatelliteDataModel.data_type == data_type,
                SatelliteDataModel.acquisition_date >= start_date,
                SatelliteDataModel.acquisition_date <= end_date
            )
        ).order_by(SatelliteDataModel.acquisition_date.asc())
        
        result = await self.session.execute(query)
        return result.scalars().all()

    async def get_existing_record(self, farm_id: int, data_type: str, acquisition_date: date) -> Optional[SatelliteDataModel]:
        query = select(SatelliteDataModel).where(
            and_(
                SatelliteDataModel.farm_id == farm_id,
                SatelliteDataModel.data_type == data_type,
                SatelliteDataModel.acquisition_date == acquisition_date
            )
        )
        result = await self.session.execute(query)
        return result.scalars().first()
