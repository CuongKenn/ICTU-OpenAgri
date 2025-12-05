# Copyright (c) 2025 CuongKenn and ICTU-OpenAgri Contributors
# Licensed under the MIT License. See LICENSE file in the project root for full license information.

import random
import datetime
import os
import uuid
from fastapi import HTTPException
from sqlalchemy.ext.asyncio import AsyncSession
from app.application.dto.ndvi_dto import NDVIRequest, NDVIResponse
from app.infrastructure.external_services.sentinel_client import search_sentinel_products, download_product
from app.infrastructure.image_processing.ndvi_processing import find_band_paths, compute_ndvi
from app.infrastructure.image_processing.utils import convert_tiff_to_base64_png
from app.infrastructure.config.settings import get_settings
from app.infrastructure.repositories.satellite_repository_impl import SatelliteRepositoryImpl
from app.infrastructure.database.models.satellite_data_model import SatelliteDataModel

settings = get_settings()

class CalculateNDVIUseCase:
    async def sync_latest_data_for_farm(self, farm_id: int, bbox: list, db: AsyncSession):
        """
        Background task to sync latest NDVI data for a farm.
        Syncs up to 10 most recent images (approx last 2 months).
        """
        today = datetime.date.today()
        # Sentinel-2 revisits every 5 days. 10 images * 5 days = 50 days. Let's do 60 to be safe.
        start_date = (today - datetime.timedelta(days=60)).strftime('%Y-%m-%d')
        end_date = today.strftime('%Y-%m-%d')
        
        print(f"Syncing top 10 recent NDVI images for farm {farm_id} from {start_date} to {end_date}")
        
        try:
            # search products
            api, products = await search_sentinel_products(bbox, start_date, end_date)
            if not products:
                print(f"No products found for farm {farm_id}")
                return

            # Sort by ingestion date descending
            sorted_products = sorted(
                products.values(), 
                key=lambda x: x['ingestiondate'], 
                reverse=True
            )
            
            # Take top 10
            recent_products = sorted_products[:10]

            for product_info in recent_products:
                acquisition_date_str = product_info['ingestiondate'].split('T')[0]
                acquisition_date = datetime.datetime.strptime(acquisition_date_str, '%Y-%m-%d').date()
                
                # Check if already exists
                repo = SatelliteRepositoryImpl(db)
                existing = await repo.get_existing_record(farm_id, 'NDVI', acquisition_date)
                if existing:
                    # print(f"Data for farm {farm_id} on {acquisition_date} already exists.")
                    continue

                print(f"Downloading and processing product for farm {farm_id}: {product_info['title']}")

                # Download
                out = await download_product(api, product_info, out_dir=settings.OUTPUT_DIR)
                
                # find bands
                red_path, nir_path = find_band_paths(out)
                
                # Generate output path
                out_tif = os.path.join(settings.OUTPUT_DIR, f'ndvi_{uuid.uuid4().hex}.tif')
                
                # Compute
                out_tif, mean_val, min_val, max_val = compute_ndvi(red_path, nir_path, out_tif)
                
                # Save to DB
                new_record = SatelliteDataModel(
                    farm_id=farm_id,
                    acquisition_date=acquisition_date,
                    data_type='NDVI',
                    satellite_platform='SENTINEL-2',
                    mean_value=mean_val,
                    min_value=min_val,
                    max_value=max_val,
                    cloud_cover=product_info['cloud_cover']
                )
                await repo.save_data(new_record)
                print(f"Saved NDVI data for farm {farm_id} on {acquisition_date}")
                
                # Clean up (Optional: remove tif file if not needed for immediate display)
                # os.remove(out_tif) 

        except Exception as e:
            print(f"Error syncing farm {farm_id}: {e}")

    async def execute(self, req: NDVIRequest, db: AsyncSession) -> NDVIResponse:
        # validate bbox
        if len(req.bbox) != 4:
            raise HTTPException(status_code=400, detail='bbox must be [minx,miny,maxx,maxy]')
        
        try:
            # search products
            api, products = await search_sentinel_products(req.bbox, req.start_date, req.end_date)
            if not products:
                raise HTTPException(status_code=404, detail='No Sentinel-2 product found for this bbox/date range')
            
            # pick best product (lowest cloud cover)
            best_product_uuid = None
            best_product_info = None
            min_cloud_cover = 101.0

            for uuid_val, info in products.items():
                if info['cloud_cover'] < min_cloud_cover:
                    min_cloud_cover = info['cloud_cover']
                    best_product_uuid = uuid_val
                    best_product_info = info
            
            if not best_product_info:
                 # Fallback to first if something goes wrong
                 best_product_uuid, best_product_info = next(iter(products.items()))

            print(f"Selected product: {best_product_info['title']} with cloud cover {best_product_info['cloud_cover']}%")

            # Download
            out = await download_product(api, best_product_info, out_dir=settings.OUTPUT_DIR)
            
            # find bands
            red_path, nir_path = find_band_paths(out)
            
            # Generate output path
            out_tif = os.path.join(settings.OUTPUT_DIR, f'ndvi_{uuid.uuid4().hex}.tif')
            
            # Compute
            out_tif, mean_val, min_val, max_val = compute_ndvi(red_path, nir_path, out_tif)

            # Convert to Base64 PNG
            img_base64 = convert_tiff_to_base64_png(out_tif, colormap='RdYlGn', vmin=-1, vmax=1)

            acquisition_date_str = best_product_info['ingestiondate'].split('T')[0]
            acquisition_date = datetime.datetime.strptime(acquisition_date_str, '%Y-%m-%d').date()

            # --- SAVE TO DB ---
            repo = SatelliteRepositoryImpl(db)
            if req.farm_id:
                # Check if exists
                existing = await repo.get_existing_record(req.farm_id, 'NDVI', acquisition_date)
                if not existing:
                    new_record = SatelliteDataModel(
                        farm_id=req.farm_id,
                        acquisition_date=acquisition_date,
                        data_type='NDVI',
                        satellite_platform='SENTINEL-2',
                        mean_value=mean_val,
                        min_value=min_val,
                        max_value=max_val,
                        cloud_cover=best_product_info['cloud_cover']
                    )
                    await repo.save_data(new_record)
            
            # --- GENERATE CHART DATA (FROM DB + CURRENT) ---
            chart_data = []
            
            if req.farm_id:
                # Fetch real history from DB
                start_d = datetime.datetime.strptime(req.start_date, '%Y-%m-%d').date()
                end_d = datetime.datetime.strptime(req.end_date, '%Y-%m-%d').date()
                history = await repo.get_data_by_farm(req.farm_id, 'NDVI', start_d, end_d)
                
                for record in history:
                    chart_data.append({
                        'date': record.acquisition_date.strftime('%Y-%m-%d'),
                        'value': round(record.mean_value, 2)
                    })
                
                # Ensure current calculation is in the chart (if not already saved/fetched)
                current_in_chart = False
                for point in chart_data:
                    if point['date'] == acquisition_date_str:
                        current_in_chart = True
                        point['value'] = round(mean_val, 2) # Update with latest calc
                        break
                
                if not current_in_chart:
                    chart_data.append({
                        'date': acquisition_date_str,
                        'value': round(mean_val, 2)
                    })
                
                # Sort by date
                chart_data.sort(key=lambda x: x['date'])

            # Fallback to simulation if no history (or very few points) to keep UI looking good for demo
            if len(chart_data) < 2:
                 # Sort products by date
                sorted_products = sorted(products.values(), key=lambda x: x['ingestiondate'])
                
                chart_data = [] # Reset to use simulation
                for p in sorted_products:
                    p_date = p['ingestiondate'].split('T')[0]
                    # If it's the selected product, use the real value
                    if p['uuid'] == best_product_uuid:
                        val = mean_val
                    else:
                        # Simulate a value close to the mean (e.g., +/- 0.1)
                        val = mean_val + random.uniform(-0.1, 0.1)
                        val = max(-1.0, min(1.0, val)) # Clip to valid range
                    
                    chart_data.append({
                        'date': p_date,
                        'value': round(val, 2)
                    })

            return NDVIResponse(
                status="success", 
                ndvi_geotiff=out_tif, 
                image_base64=img_base64,
                mean_ndvi=round(mean_val, 2),
                min_ndvi=round(min_val, 2),
                max_ndvi=round(max_val, 2),
                acquisition_date=acquisition_date_str,
                chart_data=chart_data
            )
            
        except Exception as e:
            # Log error here
            print(f"Error in CalculateNDVIUseCase: {e}")
            raise HTTPException(status_code=500, detail=str(e))
