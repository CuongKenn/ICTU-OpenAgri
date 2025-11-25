#!/usr/bin/env python3
"""
Fetch real soil data from SoilGrids for Vietnam provinces
and generate soil_vietnam.csv

Data source: SoilGrids (ISRIC World Soil Information)
License: CC-BY 4.0
https://soilgrids.org/
"""

import asyncio
import csv
import httpx
import logging
from typing import Optional, Dict, Any

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# SoilGrids API endpoint
SOILGRIDS_API = "https://rest.soilgrids.org/soilgrids/v2.0"

# Vietnamese provinces with their approximate center coordinates
VIETNAM_PROVINCES = {
    # Northern region
    "Hanoi": {"lat": 20.8, "lon": 106.7, "region": "Northern"},
    "Hai Phong": {"lat": 20.9, "lon": 106.7, "region": "Northern"},
    "Bac Ninh": {"lat": 21.0, "lon": 106.0, "region": "Northern"},
    "Bac Giang": {"lat": 21.5, "lon": 106.5, "region": "Northern"},
    "Ha Giang": {"lat": 22.5, "lon": 104.5, "region": "Northern"},
    "Thai Nguyen": {"lat": 21.5, "lon": 105.5, "region": "Northern"},
    "Quang Ninh": {"lat": 21.0, "lon": 107.0, "region": "Northern"},
    "Hoa Binh": {"lat": 20.5, "lon": 105.0, "region": "Northern"},
    "Da Nang": {"lat": 16.1, "lon": 108.2, "region": "Northern"},
    
    # Central region
    "Thanh Hoa": {"lat": 19.8, "lon": 105.8, "region": "Central"},
    "Nghe An": {"lat": 18.5, "lon": 105.0, "region": "Central"},
    "Ha Tinh": {"lat": 18.0, "lon": 105.5, "region": "Central"},
    "Quang Binh": {"lat": 17.5, "lon": 106.5, "region": "Central"},
    "Quang Tri": {"lat": 16.5, "lon": 107.0, "region": "Central"},
    "Thua Thien Hue": {"lat": 16.5, "lon": 107.5, "region": "Central"},
    "Quang Nam": {"lat": 15.5, "lon": 108.5, "region": "Central"},
    "Quang Ngai": {"lat": 14.5, "lon": 109.0, "region": "Central"},
    "Binh Dinh": {"lat": 13.5, "lon": 109.5, "region": "Central"},
    "Phu Yen": {"lat": 13.0, "lon": 109.0, "region": "Central"},
    "Khanh Hoa": {"lat": 12.0, "lon": 109.0, "region": "Central"},
    
    # Southern region
    "Lam Dong": {"lat": 12.0, "lon": 108.5, "region": "Southern"},
    "Da Lat": {"lat": 12.0, "lon": 108.5, "region": "Southern"},
    "Binh Phuoc": {"lat": 11.5, "lon": 106.5, "region": "Southern"},
    "Tay Ninh": {"lat": 11.5, "lon": 106.0, "region": "Southern"},
    "Long An": {"lat": 10.5, "lon": 106.5, "region": "Southern"},
    "Ho Chi Minh City": {"lat": 10.8, "lon": 106.7, "region": "Southern"},
    "Dong Nai": {"lat": 10.8, "lon": 107.0, "region": "Southern"},
    "Ba Ria-Vung Tau": {"lat": 10.5, "lon": 107.5, "region": "Southern"},
    "Can Tho": {"lat": 10.0, "lon": 105.8, "region": "Southern"},
    "Mekong Delta": {"lat": 9.5, "lon": 105.0, "region": "Southern"},
}

# Properties to fetch from SoilGrids
SOIL_PROPERTIES = [
    ("phh2o", "ph_h2o"),  # pH in H2O
    ("organic_carbon", "organic_carbon"),  # Organic carbon (g/kg)
    ("nitrogen", "nitrogen"),  # Total nitrogen (g/kg) - Note: SoilGrids uses nitrogen
    ("sand", "sand_percent"),  # Sand content (%)
    ("silt", "silt_percent"),  # Silt content (%)
    ("clay", "clay_percent"),  # Clay content (%)
    ("bdod", "bulk_density"),  # Bulk density (kg/m3)
]


async def fetch_soilgrids_data(
    lat: float, lon: float, depth: str = "0-5cm"
) -> Optional[Dict[str, Any]]:
    """
    Fetch soil data from SoilGrids REST API for a specific location
    """
    try:
        properties = [prop[0] for prop in SOIL_PROPERTIES]
        property_string = ",".join(properties)

        url = f"{SOILGRIDS_API}/properties/query"

        async with httpx.AsyncClient(timeout=30.0) as client:
            params = {
                "lon": lon,
                "lat": lat,
                "depth": depth,
                "property": property_string,
            }

            logger.info(f"Fetching SoilGrids data for lat={lat}, lon={lon}")
            response = await client.get(url, params=params)
            response.raise_for_status()

            data = response.json()

            # Parse response and extract mean values
            soil_data = {}

            if "properties" in data:
                for prop_obj in data["properties"]:
                    prop_name = prop_obj.get("name", "")
                    layers = prop_obj.get("layers", [])

                    if layers and len(layers) > 0:
                        layer = layers[0]
                        if "depths" in layer and len(layer["depths"]) > 0:
                            depth_data = layer["depths"][0]
                            values = depth_data.get("values", {})

                            if "mean" in values:
                                # Find the mapped CSV column name
                                for sg_prop, csv_prop in SOIL_PROPERTIES:
                                    if sg_prop == prop_name:
                                        soil_data[csv_prop] = round(
                                            values["mean"], 2
                                        )
                                        break

            # Add default values for missing properties
            # Water holding capacity (estimate based on texture)
            if "sand_percent" in soil_data and "clay_percent" in soil_data:
                # Rough estimation: higher clay = higher water capacity
                whc = (
                    30 + (soil_data["clay_percent"] * 0.5)
                )  # Between 30-55
                soil_data["water_holding_capacity"] = round(whc, 1)

            return soil_data if soil_data else None

    except httpx.HTTPError as e:
        logger.error(f"HTTP error fetching SoilGrids data: {str(e)}")
        return None
    except Exception as e:
        logger.error(f"Error fetching SoilGrids data: {str(e)}")
        return None


async def main():
    """
    Main function to fetch data for all Vietnam provinces
    and generate CSV file
    """

    output_file = "backend/data/soil_vietnam.csv"

    # CSV headers
    fieldnames = [
        "region",
        "province",
        "latitude",
        "longitude",
        "ph_h2o",
        "organic_carbon",
        "nitrogen",
        "sand_percent",
        "silt_percent",
        "clay_percent",
        "bulk_density",
        "water_holding_capacity",
    ]

    rows = []

    # Fetch data for each province
    for province, coords in VIETNAM_PROVINCES.items():
        logger.info(f"Processing {province}...")

        soil_data = await fetch_soilgrids_data(coords["lat"], coords["lon"])

        if soil_data:
            row = {
                "region": coords["region"],
                "province": province,
                "latitude": coords["lat"],
                "longitude": coords["lon"],
            }

            # Add soil properties
            for field in fieldnames[4:]:  # Skip first 4 fields (region, province, lat, lon)
                row[field] = soil_data.get(field, "")

            rows.append(row)
            logger.info(f"✓ {province}: {soil_data}")
        else:
            logger.warning(f"✗ Failed to fetch data for {province}")

        # Small delay to avoid rate limiting
        await asyncio.sleep(0.5)

    # Write to CSV
    try:
        with open(output_file, "w", newline="", encoding="utf-8") as csvfile:
            writer = csv.DictWriter(csvfile, fieldnames=fieldnames)
            writer.writeheader()
            writer.writerows(rows)

        logger.info(f"\n✓ Successfully wrote {len(rows)} provinces to {output_file}")
        logger.info(f"Data source: SoilGrids (ISRIC World Soil Information)")
        logger.info(f"License: CC-BY 4.0")
        logger.info(f"URL: https://soilgrids.org/")
        logger.info(f"Reference: Poggio et al. (2021) - SoilGrids 2.0")

    except Exception as e:
        logger.error(f"Error writing CSV file: {str(e)}")


if __name__ == "__main__":
    asyncio.run(main())
