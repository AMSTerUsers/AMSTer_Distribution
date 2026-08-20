#!/opt/local/amster_python_env/bin/python
#	The script search in each *yyyymmdd*yyyymmdd* dir of the pwd in */i12/GeoProjection/ all the files named 
# e.g. deformationMap.interpolated.flattened*.interpolated*deg.ras and open them by batches 
# (set as hardcoded parameter batch_size). When all the figures from the batch are open
# it pauses to allow closing them before opening the next batch. 
#
# If the script is provided with two parmeters in the form of two numbers, it displays only 
# the files between these two numbers (corresponding to their index in the listing of the dir). 

import os
import re
import sys
from tqdm import tqdm
import matplotlib.pyplot as plt
from PIL import Image
import math

# ------------------- CONFIGURATION -------------------
batch_size = 20
max_display_width = 400   # width per subplot in pixels
max_display_height = 300  # height per subplot in pixels
dpi = 150                  # figure DPI
# -----------------------------------------------------

base_dir = os.getcwd()
files = []

# Regex to match directories containing two 8-digit numbers
dir_pattern = re.compile(r'.*\d{8}.*\d{8}.*')

# Find top-level directories, skipping GeocodedRasters
top_dirs = [d for d in os.listdir(base_dir)
            if os.path.isdir(d) and dir_pattern.match(d) and d != "GeocodedRasters"]

# displaying the selected dirs:
#print("Directories to scan:")
#for d in top_dirs:
#    print("  ", d)
# displaying the selected dirs with index
print("Directories to scan:")
for idx, d in enumerate(top_dirs, start=1):
    print(f"  {idx:3d}. {d}")
print("")
print(f"Scanning {len(top_dirs)} directories...")

# Scan each i12/GeoProjection subdir
for d in tqdm(top_dirs, desc="Scanning directories"):
    geo_dir = os.path.join(base_dir, d, "i12", "GeoProjection")
    if not os.path.isdir(geo_dir):
        continue

    # Only collect one main deformationMap raster per folder
    ras_files = [f for f in os.listdir(geo_dir)
                 if f.startswith("deformationMap.interpolated.flattened")
                 and "interpolated" in f
                 and f.endswith(".ras")]  # ignore .ras.sh

    if ras_files:
        ras_files.sort()  # pick first alphabetically
        files.append(os.path.join(geo_dir, ras_files[0]))

files.sort()
total_files = len(files)
print(f"\nFound {total_files} deformationMap ras files.\n")

# ------------------- HANDLE OPTIONAL SUBSET -------------------
start_idx = 0
end_idx = total_files

if len(sys.argv) == 3:
    try:
        start_idx = max(0, int(sys.argv[1]) - 1)  # convert to 0-based index
        end_idx   = min(total_files, int(sys.argv[2]))  # exclusive
        if start_idx >= end_idx:
            raise ValueError
        print(f"Displaying subset: images {start_idx+1} to {end_idx} of {total_files}\n")
    except ValueError:
        print("Invalid command-line arguments. Usage: script.py [start_index end_index]")
        sys.exit(1)
elif len(sys.argv) != 1:
    print("Usage: script.py [start_index end_index]")
    sys.exit(1)

subset_files = files[start_idx:end_idx]
total_subset = len(subset_files)

# ------------------- GRID FUNCTION -------------------
def compute_grid(n):
    cols = math.ceil(math.sqrt(n))
    rows = math.ceil(n / cols)
    return rows, cols

# ------------------- DISPLAY IN BATCHES -------------------
for start in range(0, total_subset, batch_size):
    end = min(start + batch_size, total_subset)
    batch = subset_files[start:end]
    n_imgs = len(batch)

    # Compute grid
    rows, cols = compute_grid(n_imgs)
    fig_width = cols * max_display_width / dpi
    fig_height = rows * max_display_height / dpi

    fig, axes = plt.subplots(nrows=rows, ncols=cols, figsize=(fig_width, fig_height), dpi=dpi)
    axes = axes.flatten() if n_imgs > 1 else [axes]

    # Add batch header
    fig.suptitle(f"Images {start_idx + start + 1} – {start_idx + end} of {total_files}", fontsize=16)

    # Display images
    for ax, fpath in zip(axes, batch):
        try:
            img = Image.open(fpath)
            w, h = img.size
            scale = min(max_display_width / w, max_display_height / h)
            new_w = max(1, int(w * scale))
            new_h = max(1, int(h * scale))
            img_small = img.resize((new_w, new_h), resample=Image.Resampling.LANCZOS)
            ax.imshow(img_small, cmap='gray')
            ax.set_title(os.path.basename(fpath), fontsize=6)
            ax.axis('off')
        except Exception as e:
            ax.text(0.5, 0.5, "Error", ha='center', va='center')
            ax.axis('off')
            print(f"Failed to load {fpath}: {e}")

    # Hide unused axes
    for ax in axes[n_imgs:]:
        ax.axis('off')

    plt.tight_layout(rect=[0, 0, 1, 0.95])  # leave space for suptitle
    plt.show()
    plt.close(fig)  # free memory