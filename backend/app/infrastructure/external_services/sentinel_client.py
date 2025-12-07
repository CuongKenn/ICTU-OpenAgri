# Copyright (c) 2025 CuongKenn and ICTU-OpenAgri Contributors
# Licensed under the MIT License. See LICENSE file in the project root for full license information.

import logging
import os
import datetime
import zipfile

logger = logging.getLogger(__name__)
import asyncio
from typing import List, Optional, Tuple, Dict, Any
from concurrent.futures import ThreadPoolExecutor

try:
    import httpx
except ImportError:
    import requests as httpx  # Fallback, though we should ensure httpx is installed

from app.infrastructure.config.settings import get_settings

settings = get_settings()

if not os.path.exists(settings.OUTPUT_DIR):
    os.makedirs(settings.OUTPUT_DIR, exist_ok=True)

def bbox_to_wkt(bbox: List[float]) -> str:
    """Convert bbox [minx,miny,maxx,maxy] to OData geography POLYGON"""
    minx, miny, maxx, maxy = bbox
    # OData geography literal
    return f"geography'SRID=4326;POLYGON(({minx} {miny}, {minx} {maxy}, {maxx} {maxy}, {maxx} {miny}, {minx} {miny}))'"

async def get_access_token() -> str:
    """Get Access Token from CDSE Identity Provider"""
    token_url = "https://identity.dataspace.copernicus.eu/auth/realms/CDSE/protocol/openid-connect/token"
    data = {
        'client_id': 'cdse-public',
        'username': settings.COPERNICUS_USERNAME,
        'password': settings.COPERNICUS_PASSWORD,
        'grant_type': 'password'
    }
    
    async with httpx.AsyncClient() as client:
        try:
            response = await client.post(token_url, data=data)
            response.raise_for_status()
            return response.json()['access_token']
        except httpx.HTTPError as e:
            raise RuntimeError(f"Authentication failed: {str(e)}. Check your COPERNICUS_USERNAME and COPERNICUS_PASSWORD.")

async def search_sentinel_products(bbox: List[float], date_start: str, date_end: str, platformname='SENTINEL-2', processinglevel='Level-2A') -> Tuple[Any, Dict[str, Any]]:
    """Search Copernicus Data Space Ecosystem (CDSE) via OData API."""
    if not settings.COPERNICUS_USERNAME or not settings.COPERNICUS_PASSWORD:
        raise RuntimeError('COPERNICUS_USERNAME/PASSWORD not set')

    token = await get_access_token()
    headers = {'Authorization': f'Bearer {token}'}
    
    try:
        start_obj = datetime.datetime.fromisoformat(date_start)
        end_obj = datetime.datetime.fromisoformat(date_end)
    except ValueError:
        start_obj = datetime.datetime.strptime(date_start, '%Y-%m-%d')
        end_obj = datetime.datetime.strptime(date_end, '%Y-%m-%d')
        
    date_from = start_obj.strftime('%Y-%m-%dT%H:%M:%S.000Z')
    date_to = end_obj.strftime('%Y-%m-%dT%H:%M:%S.000Z')

    # Construct OData Filter
    filter_query = (
        f"Collection/Name eq '{platformname}' "
        f"and ContentDate/Start ge {date_from} "
        f"and ContentDate/Start le {date_to} "
        f"and OData.CSC.Intersects(area={bbox_to_wkt(bbox)})"
    )
    
    if platformname == 'SENTINEL-2' and processinglevel == 'Level-2A':
        filter_query += " and Attributes/OData.CSC.StringAttribute/any(att:att/Name eq 'productType' and att/Value eq 'S2MSI2A')"
    elif platformname == 'SENTINEL-1':
        # Filter for GRD products (Ground Range Detected) and IW mode (Interferometric Wide Swath)
        filter_query += " and Attributes/OData.CSC.StringAttribute/any(att:att/Name eq 'productType' and att/Value eq 'GRD')"
        filter_query += " and Attributes/OData.CSC.StringAttribute/any(att:att/Name eq 'operationalMode' and att/Value eq 'IW')"

    url = "https://catalogue.dataspace.copernicus.eu/odata/v1/Products"
    params = {
        '$filter': filter_query,
        '$top': settings.MAX_PRODUCTS,
        '$orderby': 'ContentDate/Start desc'
    }
    
    logger.info(f"Searching CDSE: {url} with params {params}")
    
    async with httpx.AsyncClient() as client:
        response = await client.get(url, params=params, headers=headers, timeout=30.0)
        
        if response.status_code != 200:
            raise RuntimeError(f"Search failed: {response.status_code} {response.text}")
            
        results = response.json()
        
    products = {}
    for item in results.get('value', []):
        cloud_cover = 0.0
        if platformname == 'SENTINEL-2':
            cloud_cover = 100.0
            for attr in item.get('Attributes', []):
                if attr['Name'] == 'cloudCover':
                    cloud_cover = float(attr['Value'])
                    break

        products[item['Id']] = {
            'uuid': item['Id'],
            'title': item['Name'],
            'ingestiondate': item['ContentDate']['Start'],
            'cloud_cover': cloud_cover
        }
        
    return None, products

def _unzip_file(zip_path: str, extract_to: str):
    """Helper function to unzip file in a thread."""
    logger.info(f"Extracting {zip_path}...")
    with zipfile.ZipFile(zip_path, 'r') as zip_ref:
        zip_ref.extractall(extract_to)

async def download_product(api: Any, product_info: dict, out_dir: Optional[str]=None) -> str:
    """Download product from CDSE and unzip it."""
    out_dir = out_dir or settings.OUTPUT_DIR
    uuid = product_info['uuid']
    title = product_info['title']
    logger.info(f"Downloading {title} ({uuid}) ...")
    
    token = await get_access_token()
    headers = {'Authorization': f'Bearer {token}'}
    
    # Download URL
    url = f"https://zipper.dataspace.copernicus.eu/odata/v1/Products({uuid})/$value"
    
    local_zip = os.path.join(out_dir, f"{title}.zip")
    extract_path = os.path.join(out_dir, title + ".SAFE")
    
    if os.path.exists(extract_path):
        logger.info(f"Product already exists at {extract_path}")
        return extract_path

    if not os.path.exists(local_zip):
        logger.info(f"Downloading to {local_zip}...")
        async with httpx.AsyncClient() as client:
            async with client.stream('GET', url, headers=headers, timeout=None) as response:
                response.raise_for_status()
                with open(local_zip, 'wb') as f:
                    async for chunk in response.aiter_bytes(chunk_size=8192):
                        f.write(chunk)
    
    # Run unzip in a thread pool to avoid blocking the event loop
    loop = asyncio.get_event_loop()
    await loop.run_in_executor(None, _unzip_file, local_zip, out_dir)
        
    possible_path = os.path.join(out_dir, title + ".SAFE")
    if os.path.exists(possible_path):
        return possible_path
        
    for item in os.listdir(out_dir):
        if item.endswith(".SAFE") and title in item:
             return os.path.join(out_dir, item)
             
    return extract_path
