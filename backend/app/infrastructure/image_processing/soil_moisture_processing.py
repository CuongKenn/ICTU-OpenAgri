import os
import rasterio
import numpy as np
from rasterio.enums import Resampling
from typing import Tuple

def find_s1_band_path(safe_path: str, polarization: str = 'vv') -> str:
    """
    Find the measurement tiff for a specific polarization in Sentinel-1 SAFE folder.
    """
    # Sentinel-1 structure: measurement/s1a-iw-grd-vv-....tiff
    for root, dirs, files in os.walk(safe_path):
        for f in files:
            if f.endswith('.tiff') or f.endswith('.tif'):
                if f'iw-grd-{polarization}' in f.lower():
                    return os.path.join(root, f)
    
    raise FileNotFoundError(f'Could not find {polarization} band in SAFE product')

def compute_soil_moisture_proxy(vv_path: str, out_path: str) -> Tuple[str, float]:
    """
    Compute a simple Soil Moisture proxy from Sentinel-1 VV band.
    We convert the raw DN to dB (Backscatter) which correlates with moisture.
    Formula (Simplified): dB = 10 * log10(DN^2)
    Note: Real calibration requires the calibration vector from XML, but for visualization
    of relative moisture, this is a starting point.
    """
    mean_val = 0.0
    with rasterio.open(vv_path) as src:
        # Read the first band
        # S1 images can be large, we might want to downsample for web display
        # For now, read as is or with a small decimation if needed
        
        # Read data
        dn = src.read(1).astype('float32')
        
        # Avoid log of zero
        dn[dn == 0] = np.nan
        
        # Convert to dB (Simplified)
        # In reality, sigma0 = DN^2 / A^2 (where A is calibration factor)
        # Here we just visualize the log intensity
        db = 10 * np.log10(dn**2 + 1e-6)
        
        # Normalize for visualization (e.g., -25 dB to 0 dB)
        # Wet soil ~ -5 to 0 dB, Dry soil ~ -15 to -20 dB
        min_db = -25.0
        max_db = 0.0
        
        soil_moisture_index = (db - min_db) / (max_db - min_db)
        soil_moisture_index = np.clip(soil_moisture_index, 0, 1)
        
        # Calculate mean (ignoring NaNs)
        mean_val = float(np.nanmean(soil_moisture_index))

        # Write output
        profile = src.meta.copy()
        profile.update(
            driver='GTiff',
            count=1,
            dtype=rasterio.float32,
            compress='lzw'
        )
        
        with rasterio.open(out_path, 'w', **profile) as dst:
            dst.write(soil_moisture_index, 1)
            
    return out_path, mean_val
