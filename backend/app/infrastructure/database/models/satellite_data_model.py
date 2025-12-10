# Copyright (c) 2025 CuongKenn and ICTU-OpenAgri Contributors
# Licensed under the MIT License. See LICENSE file in the project root for full license information.

from datetime import datetime
from sqlalchemy import Column, Integer, String, Float, ForeignKey, DateTime, Date
from sqlalchemy.orm import relationship
from app.infrastructure.database.database import Base

class SatelliteDataModel(Base):
    """
    Stores historical satellite analysis results for a farm.
    """
    __tablename__ = "satellite_data"

    id = Column(Integer, primary_key=True, index=True)
    farm_id = Column(Integer, ForeignKey("farms.id", ondelete="CASCADE"), nullable=False, index=True)
    
    # Date of the satellite image acquisition
    acquisition_date = Column(Date, nullable=False, index=True)
    
    # Type of data: 'NDVI', 'SOIL_MOISTURE', etc.
    data_type = Column(String, nullable=False, index=True)
    
    # Satellite source: 'SENTINEL-2', 'SENTINEL-1'
    satellite_platform = Column(String, nullable=True)
    
    # Statistics
    mean_value = Column(Float, nullable=False)
    min_value = Column(Float, nullable=True)
    max_value = Column(Float, nullable=True)
    
    # Metadata
    cloud_cover = Column(Float, nullable=True) # Only for optical
    
    created_at = Column(DateTime, default=datetime.utcnow)

    # Relationship
    farm = relationship("FarmModel", backref="satellite_data")
