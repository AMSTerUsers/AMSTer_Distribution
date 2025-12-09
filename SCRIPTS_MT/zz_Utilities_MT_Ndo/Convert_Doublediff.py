#!/opt/local/amster_python_env/bin/python
######################################################################################
# This script convert a list of DoubleDiff coordinates in pixels to keep the same locations on a different grid. 
# It will:	- read the ENVI headers files directly (.hdr).
#			- Converts source pixel → map coordinates → target CRS → target pixel.
# It works even if initial and final hdr cover different UTM zones, have different resolutions and have different origins.
#
# If an input pixel is outside the target raster, it ouputs NaN.
#
# Parameters:	- hdr header file the original maps (found in MapInfo in the hdr file)
# 				- hdr header file of the target maps (found in MapInfo in the hdr file)
# 				- input file full path (List_DoubleDiff_EW_UD.txt like file, that is a list of line1 col1 line2 col2 label)
# 				- output file full path (same structure as input file, that is a list of line1 col1 line2 col2 label)

# Dependencies:	- python3 and modules loaded below

# New in V2.0 20250908: - drastic change from the .sh version in order to cope with change in UTM zone
#
# AMSTer: SAR & InSAR Automated Mass processing Software for Multidimensional Time series
# Delphine Smittarello, (c)2024; NdO 2025
######################################################################################

import os
import rasterio
from rasterio.transform import rowcol
from rasterio.warp import transform
import sys
import numpy as np

def resolve_envi_file(path):
    # If user gives .hdr, replace with binary file
    if path.lower().endswith(".hdr"):
        candidate = path[:-4]  # remove ".hdr"
        if os.path.exists(candidate):
            return candidate
        else:
            raise FileNotFoundError(f"Binary file not found for header: {path}")
    return path
    
def convert_pixel_positions(src_hdr, dst_hdr, input_txt, output_txt):
    src_path = resolve_envi_file(src_hdr)
    dst_path = resolve_envi_file(dst_hdr)
    # Open source and target ENVI datasets
    with rasterio.open(src_path) as src, rasterio.open(dst_path) as dst:
        src_crs = src.crs
        dst_crs = dst.crs
        src_transform = src.transform
        dst_transform = dst.transform

        results = []
        with open(input_txt, "r") as f:
            for line in f:
                parts = line.strip().split()
                if len(parts) < 5:
                    continue  # skip malformed lines
                l1, c1, l2, c2 = map(int, parts[:4])
                label = parts[4]

                # ---- First pixel ----
                x1, y1 = src_transform * (c1, l1)
                x1r, y1r = transform(src_crs, dst_crs, [x1], [y1])
                try:
                    l1_new, c1_new = rowcol(dst_transform, x1r[0], y1r[0])
                except Exception:
                    l1_new, c1_new = np.nan, np.nan

                # ---- Second pixel ----
                x2, y2 = src_transform * (c2, l2)
                x2r, y2r = transform(src_crs, dst_crs, [x2], [y2])
                try:
                    l2_new, c2_new = rowcol(dst_transform, x2r[0], y2r[0])
                except Exception:
                    l2_new, c2_new = np.nan, np.nan

                results.append([l1_new, c1_new, l2_new, c2_new, label])

        # Save results
        with open(output_txt, "w") as f:
            for r in results:
                f.write(f"{int(r[0]) if not np.isnan(r[0]) else 'NaN'} "
                        f"{int(r[1]) if not np.isnan(r[1]) else 'NaN'} "
                        f"{int(r[2]) if not np.isnan(r[2]) else 'NaN'} "
                        f"{int(r[3]) if not np.isnan(r[3]) else 'NaN'} "
                        f"{r[4]}\n")

if __name__ == "__main__":
    if len(sys.argv) != 5:
        print("Usage: python convert_pixels.py source.hdr target.hdr input.txt output.txt")
        sys.exit(1)

    convert_pixel_positions(sys.argv[1], sys.argv[2], sys.argv[3], sys.argv[4])

