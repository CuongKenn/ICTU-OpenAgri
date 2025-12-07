# Copyright (c) 2025 CuongKenn and ICTU-OpenAgri Contributors
# Licensed under the MIT License. See LICENSE file in the project root for full license information.

import logging
import asyncio
from apscheduler.schedulers.asyncio import AsyncIOScheduler

logger = logging.getLogger(__name__)
from sqlalchemy import select
from app.infrastructure.database.database import AsyncSessionLocal
from app.infrastructure.database.models.farm_model import FarmModel
from app.application.use_cases.ndvi_use_cases import CalculateNDVIUseCase
from app.domain.entities.farm import Coordinate

scheduler = AsyncIOScheduler()

# Retry configuration
MAX_RETRIES = 3
RETRY_DELAY_SECONDS = 60  # Wait 1 minute between retries


async def sync_farm_with_retry(use_case: CalculateNDVIUseCase, farm_id: int, bbox: list, db):
    """
    Sync NDVI data for a single farm with retry mechanism.
    """
    for attempt in range(1, MAX_RETRIES + 1):
        try:
            await use_case.sync_latest_data_for_farm(farm_id, bbox, db)
            return True
        except Exception as e:
            logger.warning(f"Attempt {attempt}/{MAX_RETRIES} failed for farm {farm_id}: {e}")
            if attempt < MAX_RETRIES:
                await asyncio.sleep(RETRY_DELAY_SECONDS)
            else:
                logger.error(f"All {MAX_RETRIES} attempts failed for farm {farm_id}")
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
                
                success = await sync_farm_with_retry(use_case, farm.id, bbox, db)
                if success:
                    success_count += 1
                else:
                    fail_count += 1
                
        except Exception as e:
            logger.error(f"Error in scheduled job: {e}")
            
    logger.info(f"Scheduled NDVI update job finished. Success: {success_count}, Failed: {fail_count}")


def start_scheduler():
    """
    Start the background scheduler.
    """
    # Run every day at 00:00 with misfire grace time of 1 hour
    scheduler.add_job(
        update_all_farms_ndvi, 
        'cron', 
        hour=0, 
        minute=0,
        misfire_grace_time=3600,  # Allow job to run up to 1 hour late
        coalesce=True,  # If multiple runs were missed, only run once
        max_instances=1,  # Prevent overlapping runs
        id='ndvi_daily_sync'
    )
    
    scheduler.start()
    logger.info("Scheduler started.")
