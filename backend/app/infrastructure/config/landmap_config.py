"""
Land Map Configuration
"""
import os
from pathlib import Path

# Base cache directory
LANDMAP_CACHE_DIR = Path(os.getenv("LANDMAP_CACHE_DIR", "./data/landmap_cache"))
LANDMAP_CACHE_DIR.mkdir(parents=True, exist_ok=True)

# Copernicus configuration
COPERNICUS_CONFIG = {
    "base_url": "https://dem.copernicus.eu/",
    "lulc_url": "https://land.copernicus.eu/global/products/lulc",
    "dem_url": "https://cloud.sdsc.edu/v1/AUTH_cloud.sdsc.edu/Raster/DEM/",
    "timeout": 30,
    "retry_attempts": 3,
}

# Sentinel-2 configuration
SENTINEL_CONFIG = {
    "base_url": "https://catalogue.dataspace.copernicus.eu/odata/v1",
    "timeout": 60,
    "retry_attempts": 3,
    "max_cloud_cover": 20,  # Maximum cloud cover percentage
}

# USGS configuration
USGS_CONFIG = {
    "base_url": "https://m2m.cr.usgs.gov/api/v1",
    "nlcd_url": "https://lta.cr.usgs.gov/NLCD",
    "timeout": 30,
    "retry_attempts": 3,
}

# Cache configuration
CACHE_CONFIG = {
    "enabled": True,
    "ttl": 86400 * 30,  # 30 days in seconds
    "max_cache_size": 10 * 1024 * 1024 * 1024,  # 10 GB
    "cache_directory": LANDMAP_CACHE_DIR,
}

# Data type configurations
DATA_TYPES = {
    "dem": {
        "name": "Digital Elevation Model",
        "description": "Elevation data",
        "sources": ["copernicus", "usgs"],
        "resolution_m": 30,
        "crs": "EPSG:4326",
    },
    "lulc": {
        "name": "Land Use/Land Cover",
        "description": "Land cover classification",
        "sources": ["copernicus"],
        "resolution_m": 100,
        "crs": "EPSG:4326",
    },
    "ndvi": {
        "name": "Normalized Difference Vegetation Index",
        "description": "Vegetation health index",
        "sources": ["sentinel"],
        "resolution_m": 10,
        "crs": "EPSG:4326",
    },
    "nlcd": {
        "name": "National Land Cover Database",
        "description": "USA land cover (USGS)",
        "sources": ["usgs"],
        "resolution_m": 30,
        "crs": "EPSG:3857",  # Web Mercator for USA
    },
}

# Tile configuration for Web Mercator
TILE_CONFIG = {
    "tile_size": 256,  # pixels
    "min_zoom": 1,
    "max_zoom": 18,
    "projection": "EPSG:3857",
}
