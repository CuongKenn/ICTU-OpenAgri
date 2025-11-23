"""
SQLAlchemy Farm model.
"""
from datetime import datetime
from sqlalchemy import Column, Integer, String, Float, ForeignKey, DateTime, JSON
from sqlalchemy.orm import relationship
from app.infrastructure.database.database import Base

class FarmModel(Base):
    """Farm database model."""
    
    __tablename__ = "farms"
    
    id = Column(Integer, primary_key=True, index=True)
    name = Column(String, index=True, nullable=False)
    description = Column(String, nullable=True)
    coordinates = Column(JSON, nullable=False)  # Storing coordinates as JSON
    area_size = Column(Float, nullable=True)
    crop_type = Column(String, nullable=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

    # Relationship with user
    owner = relationship("UserModel", backref="farms")
