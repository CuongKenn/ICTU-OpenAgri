import os
import datetime
from typing import List, Optional, Tuple, Dict, Any
from sentinelsat import SentinelAPI
from app.infrastructure.config.settings import get_settings

settings = get_settings()

if not os.path.exists(settings.OUTPUT_DIR):
    os.makedirs(settings.OUTPUT_DIR, exist_ok=True)

def bbox_to_wkt(bbox: List[float]) -> str:
    """Convert bbox [minx,miny,maxx,maxy] to WKT POLYGON"""
    minx, miny, maxx, maxy = bbox
    return f"POLYGON(({minx} {miny}, {minx} {maxy}, {maxx} {maxy}, {maxx} {miny}, {minx} {miny}))"

def search_sentinel_products(bbox: List[float], date: str, platformname='Sentinel-2', processinglevel='Level-2A') -> Tuple[SentinelAPI, Dict[str, Any]]:
    """Search Copernicus Open Access Hub via sentinelsat for given bbox and date (YYYY-MM-DD)."""
    if not settings.COPERNICUS_USERNAME or not settings.COPERNICUS_PASSWORD:
        raise RuntimeError('COPERNICUS_USERNAME/PASSWORD not set')

    api = SentinelAPI(settings.COPERNICUS_USERNAME, settings.COPERNICUS_PASSWORD, 'https://apihub.copernicus.eu/apihub')
    footprint = bbox_to_wkt(bbox)
    
    try:
        date_obj = datetime.datetime.fromisoformat(date)
    except ValueError:
        # Fallback if date string is not ISO format or just YYYY-MM-DD
        date_obj = datetime.datetime.strptime(date, '%Y-%m-%d')
        
    date_from = date_obj.strftime('%Y%m%d')
    date_to = (date_obj + datetime.timedelta(days=1)).strftime('%Y%m%d')

    products = api.query(footprint,
                         platformname=platformname,
                         processinglevel=processinglevel,
                         date=(date_from, date_to))
    
    # sort by ingestiondate
    products_sorted = sorted(products.items(), key=lambda kv: kv[1]['ingestiondate'], reverse=True)
    selected = products_sorted[:settings.MAX_PRODUCTS]
    return api, {k:v for k,v in selected}

def download_product(api: SentinelAPI, product_info: dict, out_dir: Optional[str]=None) -> str:
    """Download product and return path to SAFE folder or zip"""
    out_dir = out_dir or settings.OUTPUT_DIR
    uuid = product_info['uuid']
    title = product_info['title']
    print(f"Downloading {title} ...")
    
    # Check if already downloaded
    # This is a basic check, sentinelsat might handle this but good to be explicit or handle existing files
    path = api.download(uuid, directory_path=out_dir)
    
    # sentinelsat returns a dict of files
    # We return the directory path or zip path
    if isinstance(path, dict):
        # path may include 'path'
        return path.get('path') or out_dir
    return path
