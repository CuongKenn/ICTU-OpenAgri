import os
import uuid
from fastapi import HTTPException
from app.application.dto.ndvi_dto import NDVIRequest, NDVIResponse
from app.infrastructure.external_services.sentinel_client import search_sentinel_products, download_product
from app.infrastructure.image_processing.ndvi_processing import find_band_paths, compute_ndvi
from app.infrastructure.config.settings import get_settings

settings = get_settings()

class CalculateNDVIUseCase:
    def execute(self, req: NDVIRequest) -> NDVIResponse:
        # validate bbox
        if len(req.bbox) != 4:
            raise HTTPException(status_code=400, detail='bbox must be [minx,miny,maxx,maxy]')
        
        try:
            # search products
            api, products = search_sentinel_products(req.bbox, req.date)
            if not products:
                raise HTTPException(status_code=404, detail='No Sentinel-2 product found for this bbox/date')
            
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
            out = download_product(api, best_product_info, out_dir=settings.OUTPUT_DIR)
            
            # find bands
            red_path, nir_path = find_band_paths(out)
            
            # Generate output path
            out_tif = os.path.join(settings.OUTPUT_DIR, f'ndvi_{uuid.uuid4().hex}.tif')
            
            # Compute
            compute_ndvi(red_path, nir_path, out_tif)

            return NDVIResponse(status="success", ndvi_geotiff=out_tif)
            
        except Exception as e:
            # Log error here
            print(f"Error in CalculateNDVIUseCase: {e}")
            raise HTTPException(status_code=500, detail=str(e))
