"""
Pest risk forecasting DTOs.
"""
from typing import Optional, List, Dict, Any
from pydantic import BaseModel, Field


class LocationDTO(BaseModel):
    """Location information for pest risk forecast."""
    latitude: float
    longitude: float
    radius_km: float
    
    class Config:
        from_attributes = True


class YearlyOccurrenceDTO(BaseModel):
    """Yearly occurrence data for a pest."""
    year: int
    count: int
    
    class Config:
        from_attributes = True


class PestSummaryDTO(BaseModel):
    """Summary of pest occurrences."""
    pest_name: str
    species_key: Optional[int] = None
    yearly_occurrences: Dict[int, int] = Field(default_factory=dict)
    total_occurrences: int = 0
    most_recent_year: Optional[int] = None
    
    class Config:
        from_attributes = True


class PestWarningDTO(BaseModel):
    """Pest risk warning."""
    pest_name: str
    risk_level: str = Field(description="Risk level: low, medium, high")
    message: str
    last_seen_year: Optional[int] = None
    occurrence_count: int = 0
    
    class Config:
        from_attributes = True


class SearchPeriodDTO(BaseModel):
    """Search period for historical data."""
    start_year: int
    end_year: int
    
    class Config:
        from_attributes = True


class PestRiskForecastResponseDTO(BaseModel):
    """Pest risk forecast response."""
    location: LocationDTO
    pest_summary: Dict[str, PestSummaryDTO] = Field(default_factory=dict)
    warnings: List[PestWarningDTO] = Field(default_factory=list)
    checked_pests: List[str] = Field(default_factory=list, description="List of pests checked for risk")
    total_occurrences: int = 0
    search_period: SearchPeriodDTO
    
    class Config:
        from_attributes = True


class SpeciesSearchDTO(BaseModel):
    """Species search result."""
    key: int
    scientific_name: str
    canonical_name: Optional[str] = None
    common_name: Optional[str] = None
    kingdom: Optional[str] = None
    
    class Config:
        from_attributes = True


class SpeciesSearchResponseDTO(BaseModel):
    """Species search response."""
    results: List[SpeciesSearchDTO]
    count: int
    
    class Config:
        from_attributes = True

