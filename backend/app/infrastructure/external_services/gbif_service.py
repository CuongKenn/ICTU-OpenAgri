"""
GBIF (Global Biodiversity Information Facility) service for pest and biodiversity data.
GBIF API is 100% open source and free to use.
"""
import logging
from typing import Optional, List, Dict, Any
from datetime import datetime, timedelta

try:
    import httpx
except ImportError:
    import requests as httpx

logger = logging.getLogger(__name__)


class GBIFService:
    """
    Service for GBIF API - Open source biodiversity data.
    
    GBIF provides free and open access to biodiversity data.
    License: CC0 1.0 (Public Domain Dedication)
    API Documentation: https://www.gbif.org/developer/summary
    """
    
    BASE_URL = "https://api.gbif.org/v1"
    
    def __init__(self, timeout: int = 30):
        self.timeout = timeout
    
    async def search_occurrences(
        self,
        latitude: float,
        longitude: float,
        radius_km: float = 10.0,
        species_key: Optional[int] = None,
        scientific_name: Optional[str] = None,
        year: Optional[int] = None,
        limit: int = 100
    ) -> Dict[str, Any]:
        """
        Search for species occurrences within a radius around coordinates.
        
        Args:
            latitude: Center latitude
            longitude: Center longitude
            radius_km: Search radius in kilometers (default: 10km)
            species_key: GBIF species key (optional)
            scientific_name: Scientific name of species (optional)
            year: Filter by year (optional)
            limit: Maximum number of results (default: 100, max: 300)
        
        Returns:
            Occurrence data from GBIF
        """
        # Convert radius from km to decimal degrees (approximate)
        # 1 degree latitude ≈ 111 km
        radius_degrees = radius_km / 111.0
        
        params = {
            "decimalLatitude": latitude,
            "decimalLongitude": longitude,
            "radius": radius_degrees,
            "limit": min(limit, 300),
            "offset": 0
        }
        
        if species_key:
            params["speciesKey"] = species_key
        
        if scientific_name:
            params["scientificName"] = scientific_name
        
        if year:
            params["year"] = year
        
        async with httpx.AsyncClient() as client:
            try:
                response = await client.get(
                    f"{self.BASE_URL}/occurrence/search",
                    params=params,
                    timeout=self.timeout
                )
                response.raise_for_status()
                return response.json()
            except httpx.HTTPError as e:
                logger.error(f"Error fetching occurrences from GBIF: {str(e)}")
                raise Exception(f"Failed to fetch GBIF data: {str(e)}")
    
    async def search_species(
        self,
        query: str,
        limit: int = 20
    ) -> Dict[str, Any]:
        """
        Search for species by name.
        
        Args:
            query: Species name (common or scientific)
            limit: Maximum number of results
        
        Returns:
            Species search results
        """
        params = {
            "q": query,
            "limit": min(limit, 100),
            "offset": 0
        }
        
        async with httpx.AsyncClient() as client:
            try:
                response = await client.get(
                    f"{self.BASE_URL}/species/search",
                    params=params,
                    timeout=self.timeout
                )
                response.raise_for_status()
                return response.json()
            except httpx.HTTPError as e:
                logger.error(f"Error searching species from GBIF: {str(e)}")
                raise Exception(f"Failed to search species: {str(e)}")
    
    async def get_species_info(
        self,
        species_key: int
    ) -> Dict[str, Any]:
        """
        Get detailed information about a species.
        
        Args:
            species_key: GBIF species key
        
        Returns:
            Species information
        """
        async with httpx.AsyncClient() as client:
            try:
                response = await client.get(
                    f"{self.BASE_URL}/species/{species_key}",
                    timeout=self.timeout
                )
                response.raise_for_status()
                return response.json()
            except httpx.HTTPError as e:
                logger.error(f"Error fetching species info from GBIF: {str(e)}")
                raise Exception(f"Failed to fetch species info: {str(e)}")
    
    async def get_pest_risk_forecast(
        self,
        latitude: float,
        longitude: float,
        radius_km: float = 10.0,
        pest_scientific_names: Optional[List[str]] = None,
        years_back: int = 5
    ) -> Dict[str, Any]:
        """
        Get pest risk forecast based on historical occurrence data.
        
        This method analyzes historical pest occurrences in the area to provide
        early warning about potential pest risks.
        
        Args:
            latitude: Field latitude
            longitude: Field longitude
            radius_km: Search radius in kilometers
            pest_scientific_names: List of pest scientific names to check
            years_back: Number of years to look back for historical data
        
        Returns:
            Pest risk forecast data with historical occurrences and warnings
        """
        current_year = datetime.now().year
        start_year = current_year - years_back
        
        # Common rice pests in Vietnam (can be expanded)
        default_pests = pest_scientific_names or [
            "Nilaparvata lugens",  # Rầy nâu (Brown planthopper)
            "Sogatella furcifera",  # Rầy lưng trắng
            "Chilo suppressalis",  # Sâu đục thân
            "Scirpophaga incertulas",  # Sâu cuốn lá
        ]
        
        all_occurrences = []
        pest_summary = {}
        
        for pest_name in default_pests:
            try:
                # Search for species key
                logger.info(f"Searching for species: {pest_name}")
                species_search = await self.search_species(pest_name, limit=1)
                if not species_search.get("results"):
                    logger.warning(f"Species not found in GBIF: {pest_name}")
                    continue
                
                species_key = species_search["results"][0].get("key")
                if not species_key:
                    logger.warning(f"No species key found for: {pest_name}")
                    continue
                
                logger.info(f"Found species key {species_key} for {pest_name}, searching occurrences...")
                
                # Search occurrences for each year
                yearly_occurrences = {}
                for year in range(start_year, current_year + 1):
                    occurrences = await self.search_occurrences(
                        latitude=latitude,
                        longitude=longitude,
                        radius_km=radius_km,
                        species_key=species_key,
                        year=year,
                        limit=50
                    )
                    
                    count = occurrences.get("count", 0)
                    if count > 0:
                        logger.info(f"Found {count} occurrences for {pest_name} in year {year}")
                        yearly_occurrences[year] = count
                        all_occurrences.extend(occurrences.get("results", [])[:10])
                    else:
                        logger.debug(f"No occurrences found for {pest_name} in year {year}")
                
                if yearly_occurrences:
                    pest_summary[pest_name] = {
                        "species_key": species_key,
                        "yearly_occurrences": yearly_occurrences,
                        "total_occurrences": sum(yearly_occurrences.values()),
                        "most_recent_year": max(yearly_occurrences.keys()) if yearly_occurrences else None
                    }
                else:
                    logger.info(f"No historical occurrences found for {pest_name} in the specified area")
            
            except Exception as e:
                logger.error(f"Error processing pest {pest_name}: {str(e)}", exc_info=True)
                continue
        
        # Analyze patterns and generate warnings
        warnings = []
        for pest_name, data in pest_summary.items():
            yearly = data["yearly_occurrences"]
            if not yearly:
                continue
            
            # Check if pest appeared in recent years
            recent_years = [y for y in yearly.keys() if y >= current_year - 2]
            if recent_years:
                current_month = datetime.now().month
                # Generate warning based on historical patterns
                warnings.append({
                    "pest_name": pest_name,
                    "risk_level": "medium" if len(recent_years) >= 2 else "low",
                    "message": f"Khu vực của bạn có lịch sử xuất hiện {pest_name} trong các năm {', '.join(map(str, recent_years))}. Hãy kiểm tra đồng ruộng.",
                    "last_seen_year": max(recent_years),
                    "occurrence_count": yearly[max(recent_years)]
                })
        
        return {
            "location": {
                "latitude": latitude,
                "longitude": longitude,
                "radius_km": radius_km
            },
            "pest_summary": pest_summary,
            "warnings": warnings,
            "checked_pests": default_pests,
            "total_occurrences": len(all_occurrences),
            "search_period": {
                "start_year": start_year,
                "end_year": current_year
            }
        }

