# Copyright (c) 2025 CuongKenn and ICTU-OpenAgri Contributors
# Licensed under the MIT License. See LICENSE file in the project root for full license information.

"""
Pest risk forecasting use cases - business logic layer.
"""
import logging
from typing import Optional, List, Dict, Any

from app.infrastructure.external_services.gbif_service import GBIFService
from app.application.dto.pest_dto import (
    PestRiskForecastResponseDTO,
    LocationDTO,
    PestSummaryDTO,
    PestWarningDTO,
    SearchPeriodDTO,
    SpeciesSearchResponseDTO,
    SpeciesSearchDTO
)

logger = logging.getLogger(__name__)


class GetPestRiskForecastUseCase:
    """Get pest risk forecast for a field location."""
    
    def __init__(self, gbif_service: GBIFService):
        self.gbif_service = gbif_service
    
    async def execute(
        self,
        latitude: float,
        longitude: float,
        radius_km: float = 10.0,
        pest_scientific_names: Optional[List[str]] = None,
        years_back: int = 5
    ) -> PestRiskForecastResponseDTO:
        """
        Get pest risk forecast for given coordinates.
        
        Args:
            latitude: Field latitude
            longitude: Field longitude
            radius_km: Search radius in kilometers (default: 10km)
            pest_scientific_names: Optional list of specific pests to check
            years_back: Number of years to look back (default: 5)
        
        Returns:
            PestRiskForecastResponseDTO with warnings and historical data
        """
        try:
            # Get forecast data from GBIF
            forecast_data = await self.gbif_service.get_pest_risk_forecast(
                latitude=latitude,
                longitude=longitude,
                radius_km=radius_km,
                pest_scientific_names=pest_scientific_names,
                years_back=years_back
            )
            
            # Convert to DTOs
            location = LocationDTO(
                latitude=forecast_data["location"]["latitude"],
                longitude=forecast_data["location"]["longitude"],
                radius_km=forecast_data["location"]["radius_km"]
            )
            
            # Convert pest summary
            pest_summary = {}
            for pest_name, data in forecast_data.get("pest_summary", {}).items():
                pest_summary[pest_name] = PestSummaryDTO(
                    pest_name=pest_name,
                    species_key=data.get("species_key"),
                    yearly_occurrences=data.get("yearly_occurrences", {}),
                    total_occurrences=data.get("total_occurrences", 0),
                    most_recent_year=data.get("most_recent_year")
                )
            
            # Convert warnings
            warnings = [
                PestWarningDTO(
                    pest_name=w["pest_name"],
                    risk_level=w.get("risk_level", "low"),
                    message=w.get("message", ""),
                    last_seen_year=w.get("last_seen_year"),
                    occurrence_count=w.get("occurrence_count", 0)
                )
                for w in forecast_data.get("warnings", [])
            ]
            
            search_period = SearchPeriodDTO(
                start_year=forecast_data["search_period"]["start_year"],
                end_year=forecast_data["search_period"]["end_year"]
            )
            
            return PestRiskForecastResponseDTO(
                location=location,
                pest_summary=pest_summary,
                warnings=warnings,
                checked_pests=forecast_data.get("checked_pests", []),
                total_occurrences=forecast_data.get("total_occurrences", 0),
                search_period=search_period
            )
        
        except Exception as e:
            logger.error(f"Error in GetPestRiskForecastUseCase: {str(e)}")
            raise


class SearchSpeciesUseCase:
    """Search for species by name."""
    
    def __init__(self, gbif_service: GBIFService):
        self.gbif_service = gbif_service
    
    async def execute(
        self,
        query: str,
        limit: int = 20
    ) -> SpeciesSearchResponseDTO:
        """
        Search for species by name.
        
        Args:
            query: Species name (common or scientific)
            limit: Maximum number of results
        
        Returns:
            List of matching species
        """
        try:
            search_data = await self.gbif_service.search_species(query, limit)
            
            results = []
            for result in search_data.get("results", []):
                # Extract common name from vernacular names
                common_name = None
                if result.get("vernacularNames"):
                    for vn in result.get("vernacularNames", []):
                        if vn.get("vernacularName"):
                            common_name = vn.get("vernacularName")
                            break
                
                results.append(
                    SpeciesSearchDTO(
                        key=result.get("key", 0),
                        scientific_name=result.get("scientificName", ""),
                        canonical_name=result.get("canonicalName"),
                        common_name=common_name,
                        kingdom=result.get("kingdom")
                    )
                )
            
            return SpeciesSearchResponseDTO(
                results=results,
                count=len(results)
            )
        
        except Exception as e:
            logger.error(f"Error in SearchSpeciesUseCase: {str(e)}")
            raise

