"""Soil data domain models."""
from pydantic import BaseModel
from typing import Optional


class SoilChemistry(BaseModel):
    """Soil chemistry properties."""
    ph_h2o: Optional[float] = None  # pH in water
    ph_kcl: Optional[float] = None  # pH in KCl
    organic_carbon: Optional[float] = None  # g/kg
    total_nitrogen: Optional[float] = None  # g/kg
    cation_exchange_capacity: Optional[float] = None  # cmol/kg
    cec_soil: Optional[float] = None  # cmol/kg


class SoilPhysics(BaseModel):
    """Soil physical properties."""
    sand_content: Optional[float] = None  # %
    silt_content: Optional[float] = None  # %
    clay_content: Optional[float] = None  # %
    bulk_density: Optional[float] = None  # kg/m3
    moisture_content: Optional[float] = None  # %
    water_holding_capacity: Optional[float] = None  # %


class SoilNutrients(BaseModel):
    """Soil nutrient content."""
    nitrogen_n: Optional[float] = None  # mg/kg
    phosphorus_p: Optional[float] = None  # mg/kg
    potassium_k: Optional[float] = None  # mg/kg
    sulfur_s: Optional[float] = None  # mg/kg
    zinc_zn: Optional[float] = None  # ppm
    iron_fe: Optional[float] = None  # ppm
    manganese_mn: Optional[float] = None  # ppm
    copper_cu: Optional[float] = None  # ppm
    boron_b: Optional[float] = None  # ppm
    magnesium_mg: Optional[float] = None  # ppm


class SoilData(BaseModel):
    """Complete soil data for a location."""
    latitude: float
    longitude: float
    depth_cm: int  # Soil depth in cm
    chemistry: SoilChemistry
    physics: SoilPhysics
    nutrients: SoilNutrients


class SoilDataResponse(BaseModel):
    """Soil data response."""
    location: dict
    depths: list[SoilData]
    data_source: str = "OpenLandMap"
