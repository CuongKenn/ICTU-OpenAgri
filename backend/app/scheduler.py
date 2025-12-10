# Copyright (c) 2025 CuongKenn and ICTU-OpenAgri Contributors
# Licensed under the MIT License. See LICENSE file in the project root for full license information.

import logging
import asyncio
import datetime
from apscheduler.schedulers.asyncio import AsyncIOScheduler

logger = logging.getLogger(__name__)
from sqlalchemy import select
from app.infrastructure.database.database import AsyncSessionLocal
from app.infrastructure.database.models.farm_model import FarmModel
from app.infrastructure.database.models.satellite_data_model import SatelliteDataModel
from app.application.use_cases.ndvi_use_cases import CalculateNDVIUseCase
from app.infrastructure.external_services.sentinel_client import search_sentinel_products, download_product
from app.infrastructure.image_processing.soil_moisture_processing import find_s1_band_path, compute_soil_moisture_proxy
from app.infrastructure.repositories.satellite_repository_impl import SatelliteRepositoryImpl
from app.domain.entities.farm import Coordinate
from app.infrastructure.config.settings import get_settings
from app.infrastructure.external_services.fiware_client import (
    FiwareClient,
    sync_farm_to_fiware,
    sync_observation_to_fiware
)

scheduler = AsyncIOScheduler()
settings = get_settings()

# Retry configuration
MAX_RETRIES = 3
RETRY_DELAY_SECONDS = 60  # Wait 1 minute between retries


async def sync_to_fiware_if_enabled(
    farm,
    data_type: str,
    value: float,
    acquisition_date: datetime.date
):
    """
    Sync observation data to FIWARE if enabled in settings.
    
    Args:
        farm: Farm model instance
        data_type: Type of data ('ndvi' or 'soilMoisture')
        value: Measured value
        acquisition_date: Date of observation
    """
    if not settings.FIWARE_ENABLED:
        return
    
    try:
        fiware = FiwareClient()
        
        # Check FIWARE health first
        if not await fiware.health_check():
            logger.warning("FIWARE Orion is not available, skipping sync")
            return
        
        # Sync farm entity
        coords = farm.coordinates if hasattr(farm, 'coordinates') else []
        await sync_farm_to_fiware(
            fiware_client=fiware,
            farm_id=farm.id,
            farm_name=farm.name,
            coordinates=coords,
            crop_type=getattr(farm, 'crop_type', None)
        )
        
        # Sync observation
        observation_datetime = datetime.datetime.combine(
            acquisition_date,
            datetime.time(12, 0, 0)  # Default to noon
        )
        await sync_observation_to_fiware(
            fiware_client=fiware,
            farm_id=farm.id,
            observation_type=data_type,
            value=value,
            observed_at=observation_datetime
        )
        
        logger.info(f"Synced {data_type} to FIWARE for farm {farm.id}")
    except Exception as e:
        logger.warning(f"Failed to sync to FIWARE for farm {farm.id}: {e}")


async def sync_farm_with_retry(use_case: CalculateNDVIUseCase, farm_id: int, bbox: list, db, farm=None):
    """
    Sync NDVI data for a single farm with retry mechanism.
    """
    for attempt in range(1, MAX_RETRIES + 1):
        try:
            result = await use_case.sync_latest_data_for_farm(farm_id, bbox, db)
            
            # Sync to FIWARE if we have the farm and valid result
            if farm and result and hasattr(result, 'mean_value'):
                await sync_to_fiware_if_enabled(
                    farm=farm,
                    data_type='ndvi',
                    value=result.mean_value,
                    acquisition_date=result.acquisition_date
                )
            
            return True
        except Exception as e:
            logger.warning(f"Attempt {attempt}/{MAX_RETRIES} failed for farm {farm_id}: {e}")
            if attempt < MAX_RETRIES:
                await asyncio.sleep(RETRY_DELAY_SECONDS)
            else:
                logger.error(f"All {MAX_RETRIES} attempts failed for farm {farm_id}")
                return False


async def sync_soil_moisture_for_farm(farm_id: int, bbox: list, db, farm=None):
    """
    Sync Soil Moisture data for a single farm using Sentinel-1.
    """
    for attempt in range(1, MAX_RETRIES + 1):
        try:
            today = datetime.date.today()
            # Sentinel-1 revisit is 6-12 days, search last 14 days
            start_date = (today - datetime.timedelta(days=14)).strftime('%Y-%m-%d')
            end_date = today.strftime('%Y-%m-%d')
            
            logger.info(f"Syncing Soil Moisture for farm {farm_id} from {start_date} to {end_date}")
            
            # Search Sentinel-1 products
            api, products = await search_sentinel_products(bbox, start_date, end_date, platformname='SENTINEL-1')
            if not products:
                logger.info(f"No Sentinel-1 products found for farm {farm_id}")
                return True  # Not a failure, just no data
            
            # Get the most recent product
            sorted_products = sorted(products.values(), key=lambda x: x['ingestiondate'], reverse=True)
            prod = sorted_products[0]
            
            acquisition_date_str = prod['ingestiondate'].split('T')[0]
            acquisition_date = datetime.datetime.strptime(acquisition_date_str, '%Y-%m-%d').date()
            
            # Check if already exists
            repo = SatelliteRepositoryImpl(db)
            existing = await repo.get_existing_record(farm_id, 'SOIL_MOISTURE', acquisition_date)
            if existing:
                logger.info(f"Soil Moisture data for farm {farm_id} on {acquisition_date} already exists")
                return True
            
            logger.info(f"Downloading Sentinel-1 product for farm {farm_id}: {prod['title']}")
            
            # Download
            from app.infrastructure.config.settings import get_settings
            settings = get_settings()
            out = await download_product(api, prod, out_dir=settings.OUTPUT_DIR)
            
            # Find VV band and compute
            import os
            import uuid as uuid_lib
            vv_path = find_s1_band_path(out, polarization='vv')
            out_tif = os.path.join(settings.OUTPUT_DIR, f'soil_moisture_{uuid_lib.uuid4().hex}.tif')
            _, mean_val = compute_soil_moisture_proxy(vv_path, out_tif, bbox=bbox)
            
            # Save to DB
            new_record = SatelliteDataModel(
                farm_id=farm_id,
                acquisition_date=acquisition_date,
                data_type='SOIL_MOISTURE',
                satellite_platform='SENTINEL-1',
                mean_value=mean_val,
                min_value=0.0,
                max_value=1.0,
                cloud_cover=0.0  # Sentinel-1 is all-weather
            )
            await repo.save_data(new_record)
            logger.info(f"Saved Soil Moisture data for farm {farm_id} on {acquisition_date}")
            
            # Sync to FIWARE
            if farm:
                await sync_to_fiware_if_enabled(
                    farm=farm,
                    data_type='soilMoisture',
                    value=mean_val,
                    acquisition_date=acquisition_date
                )
            
            # Cleanup
            import shutil
            try:
                if os.path.exists(out) and os.path.isdir(out):
                    shutil.rmtree(out)
                zip_path = os.path.join(settings.OUTPUT_DIR, f"{prod['title']}.zip")
                if os.path.exists(zip_path):
                    os.remove(zip_path)
                if os.path.exists(out_tif):
                    os.remove(out_tif)
            except Exception as cleanup_error:
                logger.warning(f"Error cleaning up files for farm {farm_id}: {cleanup_error}")
            
            return True
            
        except Exception as e:
            logger.warning(f"Soil Moisture attempt {attempt}/{MAX_RETRIES} failed for farm {farm_id}: {e}")
            if attempt < MAX_RETRIES:
                await asyncio.sleep(RETRY_DELAY_SECONDS)
            else:
                logger.error(f"All {MAX_RETRIES} Soil Moisture attempts failed for farm {farm_id}")
                return False


async def update_all_farms_ndvi():
    """
    Scheduled job to update NDVI data for all farms.
    """
    logger.info("Starting scheduled NDVI update job...")
    success_count = 0
    fail_count = 0
    
    async with AsyncSessionLocal() as db:
        try:
            # Fetch all farms
            result = await db.execute(select(FarmModel))
            farms = result.scalars().all()
            
            use_case = CalculateNDVIUseCase()
            
            for farm in farms:
                # Convert farm coordinates to bbox [minx, miny, maxx, maxy]
                # Assuming coordinates is a list of dicts or objects
                coords = farm.coordinates
                if not coords:
                    continue
                
                # Simple bbox calculation
                lats = [c['lat'] for c in coords]
                lngs = [c['lng'] for c in coords]
                bbox = [min(lngs), min(lats), max(lngs), max(lats)]
                
                success = await sync_farm_with_retry(use_case, farm.id, bbox, db, farm=farm)
                if success:
                    success_count += 1
                else:
                    fail_count += 1
                
        except Exception as e:
            logger.error(f"Error in scheduled job: {e}")
            
    logger.info(f"Scheduled NDVI update job finished. Success: {success_count}, Failed: {fail_count}")


async def update_all_farms_soil_moisture():
    """
    Scheduled job to update Soil Moisture data for all farms using Sentinel-1.
    """
    logger.info("Starting scheduled Soil Moisture update job...")
    success_count = 0
    fail_count = 0
    
    async with AsyncSessionLocal() as db:
        try:
            # Fetch all farms
            result = await db.execute(select(FarmModel))
            farms = result.scalars().all()
            
            for farm in farms:
                coords = farm.coordinates
                if not coords:
                    continue
                
                # Simple bbox calculation
                lats = [c['lat'] for c in coords]
                lngs = [c['lng'] for c in coords]
                bbox = [min(lngs), min(lats), max(lngs), max(lats)]
                
                success = await sync_soil_moisture_for_farm(farm.id, bbox, db, farm=farm)
                if success:
                    success_count += 1
                else:
                    fail_count += 1
                
        except Exception as e:
            logger.error(f"Error in Soil Moisture scheduled job: {e}")
            
    logger.info(f"Scheduled Soil Moisture update job finished. Success: {success_count}, Failed: {fail_count}")


def start_scheduler():
    """
    Start the background scheduler.
    """
    # NDVI (Sentinel-2): Run every day at 00:00
    scheduler.add_job(
        update_all_farms_ndvi, 
        'cron', 
        hour=0, 
        minute=0,
        misfire_grace_time=3600,
        coalesce=True,
        max_instances=1,
        id='ndvi_daily_sync'
    )
    
    # Soil Moisture (Sentinel-1): Run every day at 02:00 (offset to avoid overlap)
    scheduler.add_job(
        update_all_farms_soil_moisture,
        'cron',
        hour=2,
        minute=0,
        misfire_grace_time=3600,
        coalesce=True,
        max_instances=1,
        id='soil_moisture_daily_sync'
    )
    
    scheduler.start()
    logger.info("Scheduler started. Jobs: NDVI at 00:00, Soil Moisture at 02:00")
