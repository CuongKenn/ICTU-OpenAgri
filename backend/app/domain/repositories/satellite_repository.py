# Copyright (c) 2025 CuongKenn and ICTU-OpenAgri Contributors
# Licensed under the MIT License. See LICENSE file in the project root for full license information.

from abc import ABC, abstractmethod
from typing import List, Optional
from datetime import date
from app.infrastructure.database.models.satellite_data_model import SatelliteDataModel

class SatelliteRepository(ABC):
    @abstractmethod
    async def save_data(self, data: SatelliteDataModel) -> SatelliteDataModel:
        pass

    @abstractmethod
    async def get_data_by_farm(self, farm_id: int, data_type: str, start_date: date, end_date: date) -> List[SatelliteDataModel]:
        pass
    
    @abstractmethod
    async def get_existing_record(self, farm_id: int, data_type: str, acquisition_date: date) -> Optional[SatelliteDataModel]:
        pass
