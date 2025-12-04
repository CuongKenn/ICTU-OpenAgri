# Copyright (c) 2025 CuongKenn and ICTU-OpenAgri Contributors
# Licensed under the MIT License. See LICENSE file in the project root for full license information.

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
        
        # Create bounding box around the point
        # GBIF uses geometry in WKT format
        min_lat = latitude - radius_degrees
        max_lat = latitude + radius_degrees
        min_lng = longitude - radius_degrees
        max_lng = longitude + radius_degrees
        
        # Create WKT POLYGON for the bounding box
        geometry_wkt = f"POLYGON(({min_lng} {min_lat},{max_lng} {min_lat},{max_lng} {max_lat},{min_lng} {max_lat},{min_lng} {min_lat}))"
        
        params = {
            "geometry": geometry_wkt,
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
        import asyncio
        
        current_year = datetime.now().year
        start_year = current_year - years_back
        
        # Common agricultural pests (expanded for better GBIF coverage)
        default_pests = pest_scientific_names or [
            # Rice pests (Asia/India/Vietnam)
            "Nilaparvata lugens",  # Brown planthopper
            "Sogatella furcifera",  # White-backed planthopper
            "Chilo suppressalis",  # Striped stem borer
            "Scirpophaga incertulas",  # Yellow stem borer
            "Cnaphalocrocis medinalis",  # Rice leaffolder
            "Leptocorisa oratorius",  # Rice earhead bug
            "Dicladispa armigera",  # Rice hispa
            
            # Common agricultural pests (Global/USA/Europe - good GBIF coverage)
            "Sitophilus oryzae",  # Rice weevil
            "Tribolium castaneum",  # Red flour beetle
            "Acyrthosiphon pisum",  # Pea aphid
            "Myzus persicae",  # Green peach aphid
            "Diabrotica virgifera",  # Western corn rootworm
            "Helicoverpa armigera",  # Cotton bollworm
            "Spodoptera frugiperda",  # Fall armyworm
            "Agrotis ipsilon",  # Black cutworm
        ]
        
        all_occurrences = []
        pest_summary = {}
        
        async def process_pest(pest_name: str):
            try:
                # Search for species key
                logger.info(f"Searching for species: {pest_name}")
                species_search = await self.search_species(pest_name, limit=1)
                if not species_search.get("results"):
                    logger.warning(f"Species not found in GBIF: {pest_name}")
                    return None
                
                species_key = species_search["results"][0].get("key")
                if not species_key:
                    logger.warning(f"No species key found for: {pest_name}")
                    return None
                
                logger.info(f"Found species key {species_key} for {pest_name}, searching occurrences...")
                
                # Fetch ALL occurrences in ONE request to avoid rate limiting
                try:
                    all_data = await self.search_occurrences(
                        latitude=latitude,
                        longitude=longitude,
                        radius_km=radius_km,
                        species_key=species_key,
                        year=None,  # Don't filter by year
                        limit=300
                    )
                    
                    # Group by year manually
                    yearly_occurrences = {}
                    local_occurrences = []
                    
                    for occurrence in all_data.get("results", []):
                        year = occurrence.get("year")
                        if year and start_year <= year <= current_year:
                            yearly_occurrences[year] = yearly_occurrences.get(year, 0) + 1
                            if len(local_occurrences) < 10:
                                local_occurrences.append(occurrence)
                    
                    if yearly_occurrences:
                        logger.info(f"Found {sum(yearly_occurrences.values())} total occurrences for {pest_name}")
                except Exception as e:
                    logger.error(f"Error fetching occurrences for {pest_name}: {e}")
                    yearly_occurrences = {}
                    local_occurrences = []
                
                if yearly_occurrences:
                    return {
                        "pest_name": pest_name,
                        "data": {
                            "species_key": species_key,
                            "yearly_occurrences": yearly_occurrences,
                            "total_occurrences": sum(yearly_occurrences.values()),
                            "most_recent_year": max(yearly_occurrences.keys()) if yearly_occurrences else None
                        },
                        "occurrences": local_occurrences
                    }
                else:
                    logger.info(f"No historical occurrences found for {pest_name} in the specified area")
                    return None
            
            except Exception as e:
                logger.error(f"Error processing pest {pest_name}: {str(e)}", exc_info=True)
                return None

        # Process all pests in parallel
        pest_tasks = [process_pest(pest) for pest in default_pests]
        pest_results = await asyncio.gather(*pest_tasks)
        
        for result in pest_results:
            if result:
                pest_name = result["pest_name"]
                pest_summary[pest_name] = result["data"]
                all_occurrences.extend(result["occurrences"])
        
        # Analyze patterns and generate warnings
        warnings = []
        for pest_name, data in pest_summary.items():
            yearly = data["yearly_occurrences"]
            if not yearly:
                continue
            
            # Check if pest appeared in recent years
            recent_years = [y for y in yearly.keys() if y >= current_year - 2]
            if recent_years:
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

