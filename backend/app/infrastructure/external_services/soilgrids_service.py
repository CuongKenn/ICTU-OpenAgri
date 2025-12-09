import httpx
import logging
import random
from typing import Dict, Any, List, Optional
from app.domain.entities.soil_analysis import SoilProperties

logger = logging.getLogger(__name__)

class SoilGridsService:
    """
    Service to fetch soil data from ISRIC SoilGrids API.
    Docs: https://rest.isric.org/soilgrids/v2.0/docs
    """
    BASE_URL = "https://rest.isric.org/soilgrids/v2.0"
    
    def __init__(self, timeout: int = 30):
        self.timeout = timeout

    async def get_soil_properties(self, latitude: float, longitude: float) -> SoilProperties:
        """
        Fetch soil properties for a given location.
        We request data for topsoil (0-30cm approx).
        """
        # SoilGrids properties:
        # phh2o: pH in water (pH * 10)
        # soc: Soil Organic Carbon (dg/kg)
        # nitrogen: Nitrogen (cg/kg)
        # sand, silt, clay: Texture (g/kg)
        # bdticm: Bulk density (cg/cm3)
        
        properties = ["phh2o", "soc", "nitrogen", "sand", "silt", "clay"]
        depths = ["0-5cm", "5-15cm", "15-30cm"]
        
        params = {
            "lat": latitude,
            "lon": longitude,
        }
        
        # httpx handles list for multiple values of same key
        query_params = [("lat", str(latitude)), ("lon", str(longitude))]
        for prop in properties:
            query_params.append(("property", prop))
        for depth in depths:
            query_params.append(("depth", depth))
            
        async with httpx.AsyncClient() as client:
            try:
                response = await client.get(
                    f"{self.BASE_URL}/properties/query",
                    params=query_params,
                    timeout=self.timeout
                )
                response.raise_for_status()
                data = response.json()
                return self._parse_soilgrids_response(data)
            except httpx.HTTPError as e:
                logger.error(f"Error fetching data from SoilGrids: {str(e)}")
                return self._get_mock_data(latitude, longitude)
            except Exception as e:
                logger.error(f"Unexpected error in SoilGridsService: {str(e)}")
                return self._get_mock_data(latitude, longitude)

    def _parse_soilgrids_response(self, data: Dict[str, Any]) -> SoilProperties:
        """
        Normalize SoilGrids data.
        """
        layers = data.get("properties", {}).get("layers", [])
        
        parsed = {}
        
        for layer in layers:
            name = layer.get("name")
            depths = layer.get("depths", [])
            
            # Calculate average across depths
            values = []
            for d in depths:
                # mean value is usually in 'mean' or 'Q0.5'
                val = d.get("values", {}).get("mean")
                if val is not None:
                    values.append(val)
            
            if values:
                avg_val = sum(values) / len(values)
                parsed[name] = avg_val
        
        props = SoilProperties()
        
        if "phh2o" in parsed:
            props.ph_water = parsed["phh2o"] / 10.0
            
        if "soc" in parsed:
            props.organic_carbon = parsed["soc"] / 10.0
            
        if "nitrogen" in parsed:
            props.nitrogen = parsed["nitrogen"] / 100.0
            
        if "sand" in parsed:
            props.sand_percent = parsed["sand"] / 10.0
            
        if "silt" in parsed:
            props.silt_percent = parsed["silt"] / 10.0
            
        if "clay" in parsed:
            props.clay_percent = parsed["clay"] / 10.0
            
        # Determine texture class
        if props.sand_percent and props.silt_percent and props.clay_percent:
            props.soil_texture = self._determine_texture(
                props.sand_percent, props.silt_percent, props.clay_percent
            )
            
        return props

    def _determine_texture(self, sand: float, silt: float, clay: float) -> str:
        """
        Determine USDA soil texture class.
        """
        if clay >= 40:
            if sand <= 45 and silt < 40: return "Clay"
            if sand > 45: return "Sandy Clay"
            if silt >= 40: return "Silty Clay"
        
        if clay >= 27 and clay < 40:
            if sand > 45: return "Sandy Clay Loam"
            if silt >= 20 and sand <= 20: return "Silty Clay Loam"
            return "Clay Loam"
            
        if clay < 27:
            if silt >= 50 and clay >= 12 and clay < 27: return "Silty Loam"
            if silt >= 50 and clay < 12: return "Silt"
            if sand >= 50:
                if clay >= 20: return "Sandy Clay Loam" # Overlap fix, simplified
                if clay < 20 and sand > 70: 
                     if sand >= 85: return "Sand"
                     return "Loamy Sand"
                return "Sandy Loam"
            return "Loam"
            
        return "Unknown"

    def _get_mock_data(self, lat: float, lon: float) -> SoilProperties:
        """
        Return mock data when API fails.
        """
        logger.warning(f"Using mock soil data for {lat}, {lon}")
        
        seed = int((lat + lon) * 10000)
        rng = random.Random(seed)
        
        soil_types = [
            # Alluvial soil
            {
                "ph": rng.uniform(5.5, 6.5),
                "soc": rng.uniform(15, 25),
                "n": rng.uniform(1.5, 2.5),
                "sand": rng.uniform(20, 30),
                "silt": rng.uniform(40, 50),
                "clay": rng.uniform(30, 40)
            },
            # Basalt soil
            {
                "ph": rng.uniform(4.5, 5.5),
                "soc": rng.uniform(20, 30),
                "n": rng.uniform(2.0, 3.0),
                "sand": rng.uniform(30, 40),
                "silt": rng.uniform(20, 30),
                "clay": rng.uniform(30, 40)
            },
            # Sandy soil
            {
                "ph": rng.uniform(5.0, 6.0),
                "soc": rng.uniform(5, 10),
                "n": rng.uniform(0.5, 1.0),
                "sand": rng.uniform(70, 85),
                "silt": rng.uniform(10, 20),
                "clay": rng.uniform(5, 10)
            }
        ]
        
        selected = rng.choice(soil_types)
        
        props = SoilProperties(
            ph_water=selected["ph"],
            ph_kcl=selected["ph"] - 0.5,
            organic_carbon=selected["soc"],
            nitrogen=selected["n"],
            sand_percent=selected["sand"],
            silt_percent=selected["silt"],
            clay_percent=selected["clay"],
            soil_moisture=rng.uniform(20, 40),
            depth="0-30cm"
        )
        
        props.soil_texture = self._determine_texture(
            props.sand_percent, props.silt_percent, props.clay_percent
        )
        
        return props
