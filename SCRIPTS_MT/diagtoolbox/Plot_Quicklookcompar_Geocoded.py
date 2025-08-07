#!/opt/local/bin/python
######################################################################################
#This script displays interferogram, coherence and DefoInterpolx2Detrend maps stored 
#in a Geocoded directory as result of a SAR_MASSPROCESS. 
#It takes crop coordinates as an optional argument and displays all 3 maps with respect to this crop. 
#It takes a coherence threshold as an optional argument and mask all pixels where coherence is below this threshold.
#
# V 1.0 (20250226)
# AMSTer: SAR & InSAR Automated Mass processing Software for Multidimensional Time series
# DS
######################################################################################

import os
import re
import argparse
import rasterio
import numpy as np
import matplotlib.pyplot as plt

def parse_arguments():
    """Parse command-line arguments."""
    parser = argparse.ArgumentParser(description="Process SAR images and visualize deformation, coherence, and interferograms.")
    
    parser.add_argument("base_path", type=str, help="Base directory containing SAR data.")
    parser.add_argument("date1", type=str, help="First date (YYYYMMDD).")
    parser.add_argument("date2", type=str, help="Second date (YYYYMMDD).")
    
    # Optional arguments
    parser.add_argument("--coh_threshold", type=float, default=None, help="Threshold for coherence masking (default: None, masking disabled).")
    parser.add_argument("--crop", type=int, nargs=4, metavar=("row_start", "row_end", "col_start", "col_end"),
                        help="Crop area as four integers: row_start row_end col_start col_end (default: None).")
                        
    return parser.parse_args()

def find_file(directory, date1, date2):
    """Search for an ENVI file matching the two dates in the given directory."""
    pattern = re.compile(rf".*({date1}_{date2}|{date2}_{date1}).*deg$")
    for filename in os.listdir(directory):
        if pattern.match(filename):        
            return os.path.join(directory, filename)
    return None

def load_image_envi(envi_file, crop=None):
    """Load an ENVI image and return the first band, optionally applying a crop."""
    with rasterio.open(envi_file) as src:
        image = src.read(1)
        
        # Apply cropping if specified
        if crop:
            image = image[crop[0]:crop[1], crop[2]:crop[3]]
            print("CROPPING")
    
    return image

def apply_coherence_mask(defomap, cohmap, interfmap, coh_threshold):
    """Mask deformation and interferogram maps where coherence is below the threshold."""
    if cohmap is not None:
        mask = cohmap < coh_threshold  # Pixels below threshold are masked
        
        if defomap is not None:
            defomap = np.where(mask, np.nan, defomap)  # Apply mask
        if interfmap is not None:
            interfmap = np.where(mask, np.nan, interfmap)  # Apply mask

    return defomap, interfmap

def plot_maps(defomap, cohmap, interfmap, date1, date2):
    """Display a figure with three subplots: Deformation, Coherence, and Interferogram."""
    fig, axes = plt.subplots(1, 3, figsize=(15, 5))

    # Deformation map
    if defomap is not None:
        max_val = np.nanmax(np.abs(defomap))  # Ignore NaNs
        im1 = axes[2].imshow(defomap, cmap='seismic', vmin=-max_val, vmax=max_val)
        fig.colorbar(im1, ax=axes[2], fraction=0.046, pad=0.04)
        axes[2].set_title(f"Deformation {date1} - {date2}")
    else:
        axes[2].set_title("Deformation not found")

    # Coherence map
    if cohmap is not None:
        im2 = axes[1].imshow(cohmap, cmap='gray', vmin=0, vmax=1)
        fig.colorbar(im2, ax=axes[1], fraction=0.046, pad=0.04)
        axes[1].set_title(f"Coherence {date1} - {date2}")
    else:
        axes[1].set_title("Coherence not found")

    # Interferogram
    if interfmap is not None:
        im3 = axes[0].imshow(interfmap, cmap='twilight_shifted', vmin=-np.pi, vmax=np.pi)
        fig.colorbar(im3, ax=axes[0], fraction=0.046, pad=0.04)
        axes[0].set_title(f"Interferogram {date1} - {date2}")
    else:
        axes[0].set_title("Interferogram not found")

    for ax in axes:
        ax.axis('off')

    plt.suptitle(f"SAR Analysis {date1} - {date2}")
    plt.tight_layout()
    plt.show()

if __name__ == "__main__":
    args = parse_arguments()
    args.base_path = args.base_path.rstrip("/") + "/"

    # Determine if masking should be applied
    apply_masking = args.coh_threshold is not None

    # Find corresponding files
    defomap_file = find_file(args.base_path + 'DefoInterpolx2Detrend', args.date1, args.date2)
    cohmap_file = find_file(args.base_path + 'Coh', args.date1, args.date2)
    interfmap_file = find_file(args.base_path + 'InterfFilt', args.date1, args.date2)

    # Load images if files exist
    defomap = load_image_envi(defomap_file, crop=args.crop) if defomap_file else None
    cohmap = load_image_envi(cohmap_file, crop=args.crop) if cohmap_file else None
    interfmap = load_image_envi(interfmap_file, crop=args.crop) if interfmap_file else None

    # Apply coherence mask if enabled
    if apply_masking:
        defomap, interfmap = apply_coherence_mask(defomap, cohmap, interfmap, args.coh_threshold)

    # Display maps in a single figure
    plot_maps(defomap, cohmap, interfmap, args.date1, args.date2)
