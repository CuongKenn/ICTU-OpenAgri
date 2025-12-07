# Copyright (c) 2025 CuongKenn and ICTU-OpenAgri Contributors
# Licensed under the MIT License. See LICENSE file in the project root for full license information.

import logging
import datetime
import os
import uuid

logger = logging.getLogger(__name__)
from fastapi import HTTPException
from app.application.dto.soil_moisture_dto import SoilMoistureRequest, SoilMoistureResponse
from app.infrastructure.external_services.sentinel_client import search_sentinel_products, download_product
from app.infrastructure.image_processing.soil_moisture_processing import find_s1_band_path, compute_soil_moisture_proxy
from app.infrastructure.image_processing.utils import convert_tiff_to_base64_png
from app.infrastructure.config.settings import get_settings

settings = get_settings()

class CalculateSoilMoistureUseCase:
    async def execute(self, req: SoilMoistureRequest) -> SoilMoistureResponse:
        # validate bbox
        if len(req.bbox) != 4:
            raise HTTPException(status_code=400, detail='bbox must be [minx,miny,maxx,maxy]')
        
        try:
            # Calculate date range for Sentinel-1 search
            # Sentinel-1 revisit time is 6-12 days, so we search ±7 days from requested date
            try:
                date_obj = datetime.datetime.fromisoformat(req.date)
            except ValueError:
                date_obj = datetime.datetime.strptime(req.date, '%Y-%m-%d')
            
            date_start = (date_obj - datetime.timedelta(days=7)).strftime('%Y-%m-%d')
            date_end = (date_obj + datetime.timedelta(days=7)).strftime('%Y-%m-%d')

            # search products (Sentinel-1)
            api, products = await search_sentinel_products(req.bbox, date_start, date_end, platformname='SENTINEL-1')
            if not products:
                raise HTTPException(status_code=404, detail='No Sentinel-1 product found for this bbox/date range (±7 days)')
            
            # pick product closest to requested date
            target_date = date_obj.date()
            best_product = None
            min_diff = None
            
            for uuid_val, info in products.items():
                prod_date_str = info['ingestiondate'].split('T')[0]
                prod_date = datetime.datetime.strptime(prod_date_str, '%Y-%m-%d').date()
                diff = abs((prod_date - target_date).days)
                
                if min_diff is None or diff < min_diff:
                    min_diff = diff
                    best_product = (uuid_val, info)
            
            first_uuid, prod = best_product
            
            logger.info(f"Selected Sentinel-1 product: {prod['title']} (closest to {req.date}, diff: {min_diff} days)")

            # Download
            out = await download_product(api, prod, out_dir=settings.OUTPUT_DIR)
            
            # find bands (VV polarization)
            vv_path = find_s1_band_path(out, polarization='vv')
            
            # Generate output path
            out_tif = os.path.join(settings.OUTPUT_DIR, f'soil_moisture_{uuid.uuid4().hex}.tif')
            
            # Compute
            _, mean_val = compute_soil_moisture_proxy(vv_path, out_tif, bbox=req.bbox)

            # Convert to Base64 PNG
            img_base64 = convert_tiff_to_base64_png(out_tif, colormap='Blues', vmin=0, vmax=1)

            return SoilMoistureResponse(
                status="success", 
                soil_moisture_map=out_tif, 
                image_base64=img_base64,
                mean_value=mean_val
            )
            
        except Exception as e:
            logger.error(f"Error in CalculateSoilMoistureUseCase: {e}")
            raise HTTPException(status_code=500, detail=str(e))
