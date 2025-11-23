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
            
            # pick first product
            # In a real app, we might want to let the user choose or pick the best one based on cloud cover etc.
            first_uuid, prod = next(iter(products.items()))
            
            # Download
            out = download_product(api, prod, out_dir=settings.OUTPUT_DIR)
            
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
