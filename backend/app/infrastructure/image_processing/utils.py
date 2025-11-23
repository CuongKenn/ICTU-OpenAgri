import base64
import io
import rasterio
import numpy as np
import matplotlib
matplotlib.use('Agg') # Use non-interactive backend
import matplotlib.pyplot as plt

def convert_tiff_to_base64_png(tiff_path: str, colormap: str = 'viridis', vmin: float = None, vmax: float = None) -> str:
    """
    Reads a single-band GeoTIFF, applies a colormap, and returns a Base64 encoded PNG string.
    """
    with rasterio.open(tiff_path) as src:
        data = src.read(1)
        
        # Handle nodata if present
        if src.nodata is not None:
            data = np.ma.masked_equal(data, src.nodata)
            
        # Create a buffer
        buf = io.BytesIO()
        
        # Save with colormap
        # origin='upper' is default for images, but rasterio reads top-down usually.
        plt.imsave(buf, data, cmap=colormap, vmin=vmin, vmax=vmax, format='png')
        
        buf.seek(0)
        img_str = base64.b64encode(buf.read()).decode('utf-8')
        return img_str
