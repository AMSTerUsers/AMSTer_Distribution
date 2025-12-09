#!/opt/local/amster_python_env/bin/python
######################################################################################
# This script displays EW, UD, and NS velocity maps stored 
# in a MSBAS directory. 
# It takes crop coordinates as an optional argument and displays all 3 maps with respect to this crop. 
# Optionally, it can also display a profile on the maps.
#
# V1.0 (20250303)
# New in Distro V1.1 (20250304) -DS - Adjust number of subplot if NS is present or not
# New in Distro V1.2 (20250305) -DS - option to use UTM for crop and plot + plot a profile position
# New in Distro V1.3 (20250307) -DS - cosmetic plot and saving as png
# New in Distro V 2.0 20250813:	- launched from python3 venv
#
#
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
    parser = argparse.ArgumentParser(description="Process SAR images and visualize MSBAS maps .")
    
    parser.add_argument("base_path", type=str, help="MSBAS directory.")
    parser.add_argument("label", type=str, help="MBSBAS Label")
    
    # Optional arguments
    parser.add_argument("--crop", type=int, nargs=4, metavar=("row_start", "row_end", "col_start", "col_end"),
                        help="Crop area as four integers: row_start row_end col_start col_end (default: None).")
    parser.add_argument("--profile", type=float, nargs=4, metavar=("x1", "y1", "x2", "y2"),
                        help="Profile coordinates as four floats: x1 y1 x2 y2 (either in pixels or UTM depending on --utm flag).")
    parser.add_argument("--utm", action='store_true', help="Flag indicating that the profile is in UTM coordinates (default: pixels).")
    
    return parser.parse_args()

def find_msbas_file(base_path, prefix, filename):
    """Search for the specified file in directories matching the prefix."""
    for subdir in os.listdir(base_path):
        if subdir.startswith(prefix):
            file_path = os.path.join(base_path, subdir, filename)
            if os.path.isfile(file_path):
                return file_path
    return None

def load_image_envi(envi_file, crop=None, transform=None, utm=False):
    """Load an ENVI image and return the first band, optionally applying a crop."""
    with rasterio.open(envi_file) as src:
        image = src.read(1)
        transform = src.transform  # Get the affine transformation for the raster
        # Apply cropping if specified
        if crop:
        	if utm: 
        		# Convertir les coordonnées UTM en pixels
        		x1, y1 = crop[0], crop[2]
        		x2, y2 = crop[1], crop[3]
        		col1, row1 = convert_utm_to_pixels(x1, y1, transform)
        		col2, row2 = convert_utm_to_pixels(x2, y2, transform)
        		# Appliquer le crop sur l'image en pixels
        		image = image[ min(row1,row2):max(row1,row2),min(col1,col2):max(col1,col2)]

        	else:
        		image = image[crop[0]:crop[1], crop[2]:crop[3]]
    
    return image, transform  # Return both image and transform

def convert_utm_to_pixels(x_utm, y_utm, transform):
    """Convert UTM coordinates to pixel indices."""
    col = round((x_utm - transform[2]) / transform[0])
    row = round((y_utm - transform[5]) / transform[4])
    return col, row

def convert_pixels_to_utm(col, row, transform):
    """Convert pixel indices to UTM coordinates."""
    x_utm = transform[0] * col + transform[2]
    y_utm = transform[4] * row + transform[5]
    return x_utm, y_utm

def plot_maps(EWmap, UDmap, NSmap, label, transform, crs, profile=None, crop=None, utm=None):
    """Display a figure with three subplots: Deformation, Coherence, and Interferogram."""
    figfilename=f"Quicklook_MSBAS_{label}.png"
    # Determine subplot configuration based on which maps are available
    if (EWmap is not None) and (UDmap is not None) and (NSmap is not None):
        fig, axes = plt.subplots(1, 3, figsize=(15, 5))
        numaxE, numaxU, numaxN = 0, 1, 2
    elif (EWmap is None) and (UDmap is not None) and (NSmap is not None): 
        fig, axes = plt.subplots(1, 2, figsize=(15, 5))
        numaxE, numaxU, numaxN = 2, 0, 1
    elif (EWmap is not None) and (UDmap is None) and (NSmap is not None): 
        fig, axes = plt.subplots(1, 2, figsize=(15, 5))
        numaxE, numaxU, numaxN = 0, 2, 1
    elif (EWmap is not None) and (UDmap is not None) and (NSmap is None): 
        fig, axes = plt.subplots(1, 2, figsize=(15, 5))
        numaxE, numaxU, numaxN = 0, 1, 2
    else:
        fig, axes = plt.subplots(1, 4, figsize=(18, 6))
        numaxE, numaxU, numaxN = 0, 0, 0

    # Deformation map (EW)
    if EWmap is not None:
        max_val = np.nanmax(np.abs(EWmap))  # Ignore NaNs
#        max_val = 0.001  # Ignore NaNs
        im1 = axes[numaxE].imshow(EWmap, cmap='coolwarm', vmin=-max_val, vmax=max_val)
        fig.colorbar(im1, ax=axes[numaxE], fraction=0.046, pad=0.04)
        axes[numaxE].set_title(f"Deformation EW (m)")

    # Deformation map (UD)
    if UDmap is not None:
        max_val = np.nanmax(np.abs(UDmap))  # Ignore NaNs
#        max_val = 0.001  # Ignore NaNs
        im2 = axes[numaxU].imshow(UDmap, cmap='coolwarm', vmin=-max_val, vmax=max_val)
        fig.colorbar(im2, ax=axes[numaxU], fraction=0.046, pad=0.04)
        axes[numaxU].set_title(f"Deformation UD (m)")

    # Deformation map (NS)
    if NSmap is not None:
        max_val = np.nanmax(np.abs(NSmap))  # Ignore NaNs
#        max_val = 0.001  # Ignore NaNs
        im3 = axes[numaxN].imshow(NSmap, cmap='coolwarm', vmin=-max_val, vmax=max_val)
        fig.colorbar(im3, ax=axes[2], fraction=0.046, pad=0.04)
        axes[numaxN].set_title(f"Deformation NS (m)")

    # Plot profile if provided
    if profile:
        print(profile)
        x1, y1, x2, y2 = profile
    
        if utm:
            # Convert UTM to pixels
            x1, y1 = convert_utm_to_pixels(x1, y1, transform)
            x2, y2 = convert_utm_to_pixels(x2, y2, transform)
            if crop:
            	xcropmin, xcropmax, ycropmin, ycropmax = crop
            	col_start,row_start = convert_utm_to_pixels(xcropmin, ycropmax, transform)
            	# Adjust the coordinates by subtracting the crop start indices
            	x1 -= col_start  # Adjust x1 (column index) by the col_start offset
            	x2 -= col_start  # Adjust x2 (column index) by the col_start offset
            	y1 -= row_start  # Adjust y1 (row index) by the row_start offset
            	y2 -= row_start  # Adjust y2 (row index) by the row_start offset

        # If crop is applied, adjust the profile coordinates to the cropped image
        else:
            if crop:
            	row_start, row_end, col_start, col_end = crop
            	# Adjust the coordinates by subtracting the crop start indices
            	x1 -= col_start  # Adjust x1 (column index) by the col_start offset
            	x2 -= col_start  # Adjust x2 (column index) by the col_start offset
            	y1 -= row_start  # Adjust y1 (row index) by the row_start offset
            	y2 -= row_start  # Adjust y2 (row index) by the row_start offset
    
    
        # Plot the profile on each subplot
        for ax in axes:
            ax.plot([x1, x2], [y1, y2], '--',color='black', linewidth=2, label='Profile')
            ax.legend()
 
    # Set axis labels in UTM if needed
    for ax in axes:
        ax.set_xlabel(f"Eastern (pixels)")
        ax.set_ylabel(f"Northern (pixels)")
        
        if utm:
            # Adjust the UTM ticks based on the crop offset
            if crop:
                x1, x2,y1,y2 = crop
                print(crop)
                # Adjust for the crop offset in the ticks' calculation
                x_ticks = (transform[0] * np.linspace(0, EWmap.shape[1], 5)) + x1
                y_ticks = (transform[4] * np.linspace(0, EWmap.shape[0], 5)) + y2
                print(x_ticks)
                print(y_ticks)
            else:
            # Convert pixel indices to UTM coordinates (in meters or km)
            	x_ticks = (transform[0] * np.linspace(0, EWmap.shape[1], 5) + transform[2])  # UTM X
            	y_ticks = (transform[4] * np.linspace(0, EWmap.shape[0], 5) + transform[5])  # UTM Y
    
    
            # Convert the ticks to kilometers if desired
            x_ticks_km = x_ticks / 1000  # Convert to kilometers
            y_ticks_km = y_ticks / 1000  # Convert to kilometers
    
            ax.set_xticks(np.linspace(0, EWmap.shape[1], 5))  # Setting pixel ticks
            ax.set_yticks(np.linspace(0, EWmap.shape[0], 5))  # Setting pixel ticks
            ax.set_xticklabels(x_ticks_km)  # Setting UTM in km
            ax.set_yticklabels(y_ticks_km)  # Setting UTM in km
    
            ax.set_xlabel(f"Eastern UTM WGS84 (km)")
            ax.set_ylabel(f"Northern UTM WGS84 (km)")

    plt.suptitle(f"MSBAS Velocity Maps\n {label}\n ")
    plt.tight_layout()
    plt.savefig(figfilename)
    plt.show()


# Main block
if __name__ == "__main__":
    args = parse_arguments()
    base_path = args.base_path.rstrip("/") + "/"
    msbasdir=os.path.basename(base_path.rstrip("/"))
    print(msbasdir)
    label = args.label.lstrip('_')
    utm = args.utm

    # Search for MSBAS files
    ew_file = find_msbas_file(base_path, f"zz_EW_{label}", "MSBAS_LINEAR_RATE_EW.bin")
    ud_file = find_msbas_file(base_path, f"zz_UD_{label}", "MSBAS_LINEAR_RATE_UD.bin")
    ns_file = find_msbas_file(base_path, f"zz_NS_{label}", "MSBAS_LINEAR_RATE_NS.bin")

    # Print results
    print(f"EW File: {ew_file if ew_file else 'Not found'}")
    print(f"UD File: {ud_file if ud_file else 'Not found'}")
    print(f"NS File: {ns_file if ns_file else 'Not found'}")

    # Load images if files exist
    EWmap, transform = load_image_envi(ew_file, crop=args.crop,utm=utm) if ew_file else (None, None)
    UDmap, _ = load_image_envi(ud_file, crop=args.crop,utm=utm) if ud_file else (None, None)
    NSmap, _ = load_image_envi(ns_file, crop=args.crop,utm=utm) if ns_file else (None, None)
    
    msbaslabeling=f"{msbasdir}___{label}"

    # Display maps in a single figure
    plot_maps(EWmap, UDmap, NSmap, msbaslabeling, transform, crs="UTM", profile=args.profile, crop=args.crop, utm=utm)
