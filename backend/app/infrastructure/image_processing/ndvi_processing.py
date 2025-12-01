# Copyright (c) 2025 CuongKenn and ICTU-OpenAgri Contributors
# Licensed under the MIT License. See LICENSE file in the project root for full license information.

import os
import rasterio
import numpy as np
from rasterio.warp import calculate_default_transform
from rasterio.enums import Resampling
from typing import Tuple

def find_band_paths(safe_path: str) -> Tuple[str, str]:
    """Given a Sentinel-2 SAFE folder or zip, find paths to B04 (red) and B08 (nir).
    This function assumes the L2A SAFE file structure. For zipped products you may need to unzip first.
    """
    # naive search - walk folder
    red = None
    nir = None
    for root, dirs, files in os.walk(safe_path):
        for f in files:
            if f.endswith('.jp2'):
                if '_B04' in f or 'B04' in f and 'TCI' not in f:
                    red = os.path.join(root, f)
                if '_B08' in f or 'B08' in f:
                    nir = os.path.join(root, f)
    if not red or not nir:
        raise FileNotFoundError('Could not find B04 or B08 in SAFE product')
    return red, nir

def compute_ndvi(red_path: str, nir_path: str, out_path: str, resampling=Resampling.bilinear) -> Tuple[str, float, float, float]:
    """Compute NDVI from red and nir bands and save to GeoTIFF.
    NDVI = (NIR - RED) / (NIR + RED)
    """
    with rasterio.open(red_path) as r_red, rasterio.open(nir_path) as r_nir:
        # reproject to match if necessary
        if r_red.crs != r_nir.crs or r_red.transform != r_nir.transform or r_red.width != r_nir.width or r_red.height != r_nir.height:
            # reproject nir to red's profile
            # Note: In a real scenario, we might want to reproject both to a common grid or handle this more robustly
            # For now, we align NIR to RED as per the original script
            
            # We actually need to read the data first or setup a VRT. 
            # The original script read into memory and assumed it could just read with out_shape.
            # Let's follow the original logic but be careful.
            
            nir_arr = r_nir.read(1, out_shape=(r_red.count, r_red.height, r_red.width), resampling=resampling)
        else:
            nir_arr = r_nir.read(1).astype('float32')
            
        red_arr = r_red.read(1).astype('float32')

        # Ensure float32 for division
        if nir_arr.dtype != 'float32':
            nir_arr = nir_arr.astype('float32')

        np.seterr(divide='ignore', invalid='ignore')
        ndvi = (nir_arr - red_arr) / (nir_arr + red_arr)
        # Clip to -1..1
        ndvi = np.clip(ndvi, -1, 1)

        # write to GeoTIFF
        profile = r_red.meta.copy()
        profile.update(
            driver='GTiff',
            count=1, 
            dtype=rasterio.float32, 
            compress='lzw'
        )
        
        with rasterio.open(out_path, 'w', **profile) as dst:
            dst.write(ndvi.astype(rasterio.float32), 1)

    # Calculate stats
    # Mask out NaN values for stats
    valid_ndvi = ndvi[~np.isnan(ndvi)]
    mean_val = float(np.mean(valid_ndvi)) if valid_ndvi.size > 0 else 0.0
    min_val = float(np.min(valid_ndvi)) if valid_ndvi.size > 0 else 0.0
    max_val = float(np.max(valid_ndvi)) if valid_ndvi.size > 0 else 0.0

    return out_path, mean_val, min_val, max_val
