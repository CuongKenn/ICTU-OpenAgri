"""Soil service for soil data operations."""
import httpx
import logging
import csv
import os
from typing import Optional
from app.domain.soil_models import (
    SoilData,
    SoilDataResponse,
    SoilChemistry,
    SoilPhysics,
    SoilNutrients,
)

logger = logging.getLogger(__name__)

# Load Vietnam soil data
VIETNAM_SOIL_FILE = "/app/data/soil_vietnam.csv"
VIETNAM_SOIL_DATA = {}

def _load_vietnam_soil_data():
    """Load Vietnam soil data from CSV."""
    global VIETNAM_SOIL_DATA
    if os.path.exists(VIETNAM_SOIL_FILE):
        try:
            with open(VIETNAM_SOIL_FILE, 'r', encoding='utf-8') as f:
                reader = csv.DictReader(f)
                for row in reader:
                    key = (float(row['latitude']), float(row['longitude']))
                    VIETNAM_SOIL_DATA[key] = row
            logger.info(f"Loaded {len(VIETNAM_SOIL_DATA)} Vietnam soil data points")
        except Exception as e:
            logger.warning(f"Failed to load Vietnam soil data: {e}")

_load_vietnam_soil_data()


class SoilService:
    """Service for soil data operations."""

    async def get_soil_data(
        self,
        latitude: float,
        longitude: float,
        depths: list[int] = None,
    ) -> SoilDataResponse:
        """
        Get soil data from local Vietnam database or SoilGrids (ISRIC).

        Args:
            latitude: Latitude coordinate
            longitude: Longitude coordinate
            depths: List of soil depths in cm (e.g., [0, 10, 30, 60, 100, 200])

        Returns:
            SoilDataResponse with soil data
        """
        if depths is None:
            depths = [0, 10, 30, 60, 100, 200]

        # Check if coordinates are in Vietnam (roughly 8°N - 24°N, 102°E - 110°E)
        is_vietnam = 8 <= latitude <= 24 and 102 <= longitude <= 110
        
        async with httpx.AsyncClient() as client:
            try:
                all_soil_data = []
                
                # Try to get Vietnam local data first
                local_data = None
                if is_vietnam:
                    local_data = self._find_nearest_vietnam_soil_data(latitude, longitude)
                
                for depth in depths:
                    try:
                        if local_data:
                            chemistry, physics, nutrients = self._parse_vietnam_soil_data(local_data)
                        else:
                            chemistry = await self._get_soil_chemistry(
                                client, latitude, longitude, depth
                            )
                            physics = await self._get_soil_physics(
                                client, latitude, longitude, depth
                            )
                            nutrients = await self._get_soil_nutrients(
                                client, latitude, longitude, depth
                            )

                        soil_data = SoilData(
                            latitude=latitude,
                            longitude=longitude,
                            depth_cm=depth,
                            chemistry=chemistry,
                            physics=physics,
                            nutrients=nutrients,
                        )
                        all_soil_data.append(soil_data)

                    except Exception as e:
                        logger.warning(f"Error getting soil data at depth {depth}: {e}")
                        continue

                # Only return data if found in local Vietnam database
                if not local_data:
                    logger.warning(f"No soil data available for coordinates {latitude}, {longitude}")
                    return SoilDataResponse(
                        location={
                            "latitude": latitude,
                            "longitude": longitude,
                        },
                        depths=[],
                        data_source="No data available (Vietnam database only)",
                    )
                
                return SoilDataResponse(
                    location={
                        "latitude": latitude,
                        "longitude": longitude,
                    },
                    depths=all_soil_data,
                    data_source="Local Database (Vietnam) - Open Source",
                )

            except Exception as e:
                logger.error(f"Error fetching soil data: {e}")
                raise

    async def _get_soil_chemistry(
        self,
        client: httpx.AsyncClient,
        latitude: float,
        longitude: float,
        depth: int,
    ) -> SoilChemistry:
        """Get soil chemistry data - requires local data."""
        return SoilChemistry()

    async def _get_soil_physics(
        self,
        client: httpx.AsyncClient,
        latitude: float,
        longitude: float,
        depth: int,
    ) -> SoilPhysics:
        """Get soil physics data - requires local data."""
        return SoilPhysics()

    async def _get_soil_nutrients(
        self,
        client: httpx.AsyncClient,
        latitude: float,
        longitude: float,
        depth: int,
    ) -> SoilNutrients:
        """Get soil nutrients data - requires local data."""
        return SoilNutrients()

    def _find_nearest_vietnam_soil_data(self, latitude: float, longitude: float) -> Optional[dict]:
        """Find nearest soil data point from Vietnam database."""
        if not VIETNAM_SOIL_DATA:
            return None
        
        nearest = None
        min_distance = float('inf')
        
        for (lat, lon), data in VIETNAM_SOIL_DATA.items():
            distance = ((lat - latitude) ** 2 + (lon - longitude) ** 2) ** 0.5
            if distance < min_distance:
                min_distance = distance
                nearest = data
        
        # Only return if within reasonable distance (0.5 degrees ≈ 55km)
        if min_distance < 0.5:
            return nearest
        return None

    def _parse_vietnam_soil_data(self, data: dict) -> tuple:
        """Parse Vietnam soil data into chemistry, physics, nutrients."""
        try:
            chemistry = SoilChemistry(
                ph_h2o=float(data.get('ph_h2o', 0)) if data.get('ph_h2o') else None,
                organic_carbon=float(data.get('organic_carbon', 0)) if data.get('organic_carbon') else None,
            )
            
            physics = SoilPhysics(
                sand_content=float(data.get('sand_percent', 0)) if data.get('sand_percent') else None,
                silt_content=float(data.get('silt_percent', 0)) if data.get('silt_percent') else None,
                clay_content=float(data.get('clay_percent', 0)) if data.get('clay_percent') else None,
                bulk_density=float(data.get('bulk_density', 0)) if data.get('bulk_density') else None,
                water_holding_capacity=float(data.get('water_holding_capacity', 0)) if data.get('water_holding_capacity') else None,
            )
            
            nutrients = SoilNutrients(
                nitrogen_n=float(data.get('nitrogen', 0)) if data.get('nitrogen') else None,
                phosphorus_p=float(data.get('phosphorus', 0)) if data.get('phosphorus') else None,
                potassium_k=float(data.get('potassium', 0)) if data.get('potassium') else None,
            )
            
            return chemistry, physics, nutrients
        except Exception as e:
            logger.warning(f"Error parsing Vietnam soil data: {e}")
            return SoilChemistry(), SoilPhysics(), SoilNutrients()

    async def get_soil_recommendations(
        self,
        latitude: float,
        longitude: float,
    ) -> dict:
        """
        Get soil management recommendations based on soil data.

        Args:
            latitude: Latitude coordinate
            longitude: Longitude coordinate

        Returns:
            Dictionary with recommendations
        """
        try:
            soil_data = await self.get_soil_data(latitude, longitude)

            recommendations = {
                "location": soil_data.location,
                "recommendations": [],
            }

            # Generate recommendations based on soil properties
            if soil_data.depths:
                surface_soil = soil_data.depths[0]

                # pH recommendations
                if surface_soil.chemistry.ph_h2o:
                    ph = surface_soil.chemistry.ph_h2o
                    if ph < 5.5:
                        recommendations["recommendations"].append(
                            "Đất acid - cần bón vôi để tăng pH"
                        )
                    elif ph > 7.5:
                        recommendations["recommendations"].append(
                            "Đất kiềm - cần thêm chất hữu cơ"
                        )
                    else:
                        recommendations["recommendations"].append(
                            "pH đất phù hợp cho hầu hết cây trồng"
                        )

                # Clay content recommendations
                if surface_soil.physics.clay_content:
                    clay = surface_soil.physics.clay_content
                    if clay > 40:
                        recommendations["recommendations"].append(
                            "Đất sét cao - cần cải thiện thoát nước"
                        )
                    elif clay < 10:
                        recommendations["recommendations"].append(
                            "Đất cát cao - cần tăng khả năng giữ nước"
                        )

                # Organic carbon recommendations
                if surface_soil.chemistry.organic_carbon:
                    carbon = surface_soil.chemistry.organic_carbon
                    if carbon < 5:
                        recommendations["recommendations"].append(
                            "Hàm lượng chất hữu cơ thấp - nên bón phân hữu cơ"
                        )

            return recommendations

        except Exception as e:
            logger.error(f"Error getting soil recommendations: {e}")
            raise
