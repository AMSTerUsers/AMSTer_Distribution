#!/opt/local/bin/python
# -----------------------------------------------------------------------------------------
# This script aims at displaying comparison of MSBAS results from 2 processings
#
# Dependencies: python3
#
# New in 1.0 (20250205 - DS): - Compare EW and UD maps from 2 MSBAS Processing even if not exact same resolution and extent
#
# This script is part of the AMSTer Toolbox
# AMSTer: SAR & InSAR Automated Mass processing Software for Multidimensional Time series
#
# DS (c) 2025/02/05
# -----------------------------------------------------------------------------------------

import numpy as np
import matplotlib.pyplot as plt
import os
import sys
from scipy.ndimage import zoom

ResultDIR = sys.argv[1]
MSBAS_DIR_1 = sys.argv[2]
LABEL_1 = sys.argv[3]
MSBAS_DIR_2 = sys.argv[4]
LABEL_2 = sys.argv[5]

def read_hdr(hdr_file):
    """Read metadata from an ENVI header (.hdr) file."""
    metadata = {}
    with open(hdr_file, 'r') as f:
        for line in f:
            if '=' in line:
                key, value = map(str.strip, line.split('=', 1))
                if value.startswith('{') and value.endswith('}'):
                    value = value[1:-1].strip()  # Strip curly braces
                metadata[key] = value

    # Extract resolution and georeferencing (map_info)
    if 'Map info' in metadata:
        map_info = metadata['Map info']
        map_info_values = map_info.strip('{}').split(',')
        
        # Map info fields:
        # {Projection, x-cell size, y-cell size, ulx, uly, ...}
        try:
            resolution_x = float(map_info_values[5])  # Cell size in x (resolution)
            resolution_y = float(map_info_values[6])  # Cell size in y (resolution)
            ulx = float(map_info_values[3])  # Upper-left x-coordinate (longitude in UTM)
            uly = float(map_info_values[4])  # Upper-left y-coordinate (latitude in UTM)

            # Storing the extracted values in metadata
            metadata['resolution_x'] = resolution_x
            metadata['resolution_y'] = resolution_y
            metadata['ulx'] = ulx
            metadata['uly'] = uly
        except IndexError as e:
            print(f"Error parsing Map info: {e}")
            print(f"Map info: {map_info}")
            raise ValueError("Failed to extract resolution and coordinates from Map info.")
            
    return metadata


def read_binary_image(img_file, dimensions, dtype=np.float32, ignore_value=0):
    """Read ENVI binary image."""
    n_lines, n_samples, n_bands = dimensions
    image = np.fromfile(img_file, dtype=dtype).reshape((n_lines, n_samples, n_bands))
    image[image == ignore_value] = np.nan
    return image

def load_image_data(img_file):
    """Load image and metadata."""
    hdr_file = img_file + '.hdr'
    metadata = read_hdr(hdr_file)
    dimensions = (int(metadata['Lines']), int(metadata['Samples']), int(metadata['Bands']))
    return read_binary_image(img_file, dimensions, np.float32), metadata

def resize_image(image, target_shape):
    """Resize image using interpolation."""
    # Vérifier que l'image est bien 2D (lignes x colonnes)
    if len(image.shape) == 2:
        zoom_factors = [t / s for t, s in zip(target_shape, image.shape)]  # 2D: [target_lines / current_lines, target_cols / current_cols]
    elif len(image.shape) == 3:
        # Si l'image est 3D (par exemple avec des bandes), on doit ajuster les facteurs pour chaque dimension
        zoom_factors = [t / s for t, s in zip(target_shape, image.shape[:-1])] + [1]  # La dimension des bandes reste inchangée
    else:
        raise ValueError("L'image doit être soit 2D soit 3D.")

    return zoom(image, zoom_factors, order=1)  # Interpolation linéaire


def align_images(image1, image2, metadata1, metadata2):
    """Align images based on UTM coordinates and resolution, and crop the intersection."""
    
    # Extraction des coordonnées de localisation et résolution
    ulx1, uly1 = metadata1['ulx'], metadata1['uly']
    ulx2, uly2 = metadata2['ulx'], metadata2['uly']
    res_x1, res_y1 = metadata1['resolution_x'], metadata1['resolution_y']
    res_x2, res_y2 = metadata2['resolution_x'], metadata2['resolution_y']
    
    # Calcul des coins inférieur-droit
    lrx1 = ulx1 + image1.shape[1] * res_x1
    lry1 = uly1 - image1.shape[0] * res_y1
    lrx2 = ulx2 + image2.shape[1] * res_x2
    lry2 = uly2 - image2.shape[0] * res_y2
    
    # Vérification du chevauchement spatial
    x_overlap = (ulx1 < lrx2) and (ulx2 < lrx1)
    y_overlap = (uly1 > lry2) and (uly2 > lry1)
    
    if not x_overlap or not y_overlap:
        raise ValueError("No spatial overlap between the images")
    
    # Calcul de la zone d'intersection
    min_ulx = max(ulx1, ulx2)
    max_uly = min(uly1, uly2)
    max_lrx = min(lrx1, lrx2)
    min_lry = max(lry1, lry2)
    
    # Dimensions d'intersection en pixels
    intersect_cols1 = int((max_lrx - min_ulx) / res_x1)  # Nombre de colonnes dans l'intersection
    intersect_rows1 = int((max_uly - min_lry) / res_y1)  # Nombre de lignes dans l'intersection
    #print(intersect_cols1,intersect_rows1)
    # Dimensions d'intersection en pixels
    intersect_cols2 = int((max_lrx - min_ulx) / res_x2)  # Nombre de colonnes dans l'intersection
    intersect_rows2 = int((max_uly - min_lry) / res_y2)  # Nombre de lignes dans l'intersection
    #print(intersect_cols2,intersect_rows2)
    
    if intersect_cols1 <= 0 or intersect_rows1 <= 0:
        raise ValueError("No valid intersection area between the images")
    
    # Calcul des indices d'intersection dans chaque image
    start_col1 = int((min_ulx - ulx1) / res_x1)
    start_row1 = int((uly1 - max_uly) / res_y1)
    
    start_col2 = int((min_ulx - ulx2) / res_x2)
    start_row2 = int((uly2 - max_uly) / res_y2)
    
    # Extraire les zones d'intersection
    image1_intersection = image1[start_row1:start_row1 + intersect_rows1, start_col1:start_col1 + intersect_cols1]
    image2_intersection = image2[start_row2:start_row2 + intersect_rows2, start_col2:start_col2 + intersect_cols2]
    
    # Suréchantillonnage si nécessaire pour aligner les résolutions
    if res_x1 < res_x2:
        # Si l'image 1 a une meilleure résolution (plus petite taille de pixel), suréchantillonner image 2
        target_shape_2 = (int(image2_intersection.shape[0] * res_x1 / res_x2),
                          int(image2_intersection.shape[1] * res_y1 / res_y2))
        image2_resized = resize_image(image2_intersection, target_shape_2)
        image2_resized = resize_image(image2_resized, (intersect_rows1, intersect_cols1))
        image1_resized = resize_image(image1_intersection, (intersect_rows1, intersect_cols1))
    else:
        # Si l'image 2 a une meilleure résolution, suréchantillonner image 1
        target_shape_1 = (int(image1_intersection.shape[0] * res_x2 / res_x1),
                          int(image1_intersection.shape[1] * res_y2 / res_y1))
        image1_resized = resize_image(image1_intersection, target_shape_1)
        image1_resized = resize_image(image1_resized, (intersect_rows2, intersect_cols2))
        image2_resized = resize_image(image2_intersection, (intersect_rows2, intersect_cols2))
    
    return image1_intersection, image2_intersection, image1_resized, image2_resized


def find_valid_data_bounds(image):
    """Find the bounds of valid data in the image, ignoring NaN values."""
    # Trouver les indices des lignes et des colonnes valides (non NaN)
    valid_rows = np.any(~np.isnan(image), axis=1)  # Lignes où il y a des données valides
    valid_cols = np.any(~np.isnan(image), axis=0)  # Colonnes où il y a des données valides

    # Trouver les indices de la première et dernière ligne/colonne valide
    row_min, row_max = np.where(valid_rows)[0][[0, -1]]
    col_min, col_max = np.where(valid_cols)[0][[0, -1]]

    return row_min, row_max, col_min, col_max


def plot_valid_intersection(image1, image2, annot1, annot2):
    """Affiche l'intersection des zones valides de deux images."""

    # Trouver les zones valides de chaque image
    row_min1, row_max1, col_min1, col_max1 = find_valid_data_bounds(image1)
    row_min2, row_max2, col_min2, col_max2 = find_valid_data_bounds(image2)
    
    # Calculer l'intersection des zones valides
    intersect_row_min = max(row_min1, row_min2)
    intersect_row_max = min(row_max1, row_max2)
    intersect_col_min = max(col_min1, col_min2)
    intersect_col_max = min(col_max1, col_max2)
    
    # Vérification si l'intersection est valide
    if intersect_row_min >= intersect_row_max or intersect_col_min >= intersect_col_max:
        raise ValueError("Pas d'intersection valide entre les zones des images.")
    
    # Extraire les zones valides des deux images
    image1_intersect = image1[intersect_row_min:intersect_row_max+1, intersect_col_min:intersect_col_max+1]
    image2_intersect = image2[intersect_row_min:intersect_row_max+1, intersect_col_min:intersect_col_max+1]
    
    image_diff_intersect = image1_intersect-image2_intersect
    
    if np.any(np.isfinite(image_1_intersect))&np.any(np.isfinite(image_2_intersect)): 
    	vmax = max(np.nanmax(abs(image_1_intersect)),np.nanmax(abs(image_2_intersect)))
    	vmin = -vmax
    else:
    	vmin=0
    	vmax=1
    # Afficher les zones valides de chaque image
    
    # Supposons que image1_intersect, image2_intersect, image_diff_intersect sont vos images
    # et que vmin, vmax, annot1, annot2 sont déjà définis
        
    
    # Supposons que image1_intersect, image2_intersect, image_diff_intersect sont vos images
    # et que vmin, vmax, annot1, annot2 sont déjà définis
    
    fig, axes = plt.subplots(1, 3, figsize=(16, 8))
    
    # Affichage des images dans chaque subplot
    im1 = axes[0].imshow(image1_intersect, cmap='seismic', vmin=vmin, vmax=vmax)
    axes[0].set_title("Image 1")
    axes[0].axis('on')
    
    im2 = axes[1].imshow(image2_intersect, cmap='seismic', vmin=vmin, vmax=vmax)
    axes[1].set_title("Image 2")
    axes[1].axis('on')
    
    im_diff = axes[2].imshow(image_diff_intersect, cmap='seismic', vmin=vmin, vmax=vmax)
    axes[2].set_title("Image 1 - Image 2")
    axes[2].axis('on')
    
    # Ajouter du texte sous les subplots
    fig.text(0.02, 0.1, f"Image 1 = {annot1}", ha='left', va='center', fontsize=12)
    fig.text(0.02, 0.05, f"Image 2 = {annot2}", ha='left', va='center', fontsize=12)
    
    # Ajuster l'espace entre les subplots pour faire de la place à la colorbar
    plt.subplots_adjust(bottom=0.2)  # Augmenter l'espace en bas pour la colorbar et le texte
    
    # Ajouter une colorbar horizontale au-dessus des subplots
    fig.colorbar(im1, ax=axes, orientation='horizontal', fraction=0.03, pad=0.1)
    
    # Afficher la figure
#    plt.tight_layout()
#    plt.show()

def plot1image(image1,image2,annot1,annot2):
    # Trouver les zones valides de chaque image
    
    # Calculer l'intersection des zo
    
    # Extraire les zones valides des deux images

    plotim=0
    if image1 is None: 
    	row_min1, row_max1, col_min1, col_max1 = find_valid_data_bounds(image2)
    	if np.any(np.isfinite(image2)): 
    		vmax = np.nanmax(abs(image2))
    		vmin = -vmax
    		plotim=2
    		imageplot=image2
    elif image2 is None:
    	row_min1, row_max1, col_min1, col_max1 = find_valid_data_bounds(image1)
    	if np.any(np.isfinite(image1)): 
    		vmax = np.nanmax(abs(image1))
    		vmin = -vmax
    		plotim=1
    		imageplot=image1
    else :
    	vmin=0
    	vmax=1
    intersect_row_min =row_min1
    intersect_row_max =row_max1
    intersect_col_min =col_min1
    intersect_col_max =col_max1
    image1_intersect = imageplot[intersect_row_min:intersect_row_max+1, intersect_col_min:intersect_col_max+1]

    fig, axes = plt.subplots(1, 3, figsize=(16, 8))
    
    if plotim==1 :      # Affichage des images dans chaque subplot
    	im1 = axes[0].imshow(image1_intersect, cmap='seismic', vmin=vmin, vmax=vmax)
    
    if plotim==2 :
    	im2 = axes[1].imshow(image1_intersect, cmap='seismic', vmin=vmin, vmax=vmax)

    axes[0].set_title("Image 1")
    axes[0].axis('on')
    axes[1].set_title("Image 2")
    axes[1].axis('on')
    axes[2].set_title("Image 1 - Image 2")
    axes[2].axis('on')
    
    # Ajouter du texte sous les subplots
    fig.text(0.02, 0.1, f"Image 1 = {annot1}", ha='left', va='center', fontsize=12)
    fig.text(0.02, 0.05, f"Image 2 = {annot2}", ha='left', va='center', fontsize=12)
    
    # Ajuster l'espace entre les subplots pour faire de la place à la colorbar
    plt.subplots_adjust(bottom=0.2)  # Augmenter l'espace en bas pour la colorbar et le texte
    
    # Ajouter une colorbar horizontale au-dessus des subplots
    if plotim==1 or plotim==3:      # Affichage des images dans chaque subplot
    	fig.colorbar(im1, ax=axes, orientation='horizontal', fraction=0.03, pad=0.1)
    elif plotim==2:      # Affichage des images dans chaque subplot
    	fig.colorbar(im2, ax=axes, orientation='horizontal', fraction=0.03, pad=0.1)


# Load images
annot1 = f"{MSBAS_DIR_1}/zz_EW{LABEL_1}"
annot2 = f"{MSBAS_DIR_2}/zz_EW{LABEL_2}"
annot3 = f"{MSBAS_DIR_1}/zz_UD{LABEL_1}"
annot4 = f"{MSBAS_DIR_2}/zz_UD{LABEL_2}"
annot5 = f"{MSBAS_DIR_1}/zz_NS{LABEL_1}"
annot6 = f"{MSBAS_DIR_2}/zz_NS{LABEL_2}"

image_1, metadata_1 = load_image_data(f"{MSBAS_DIR_1}/zz_EW{LABEL_1}/MSBAS_LINEAR_RATE_EW.bin")
image_2, metadata_2 = load_image_data(f"{MSBAS_DIR_2}/zz_EW{LABEL_2}/MSBAS_LINEAR_RATE_EW.bin")
image_3, metadata_3 = load_image_data(f"{MSBAS_DIR_1}/zz_UD{LABEL_1}/MSBAS_LINEAR_RATE_UD.bin")
image_4, metadata_4 = load_image_data(f"{MSBAS_DIR_2}/zz_UD{LABEL_2}/MSBAS_LINEAR_RATE_UD.bin")

# Align images
image_1_intersect, image_2_intersect, image_1_resamp, image_2_resamp  = align_images(image_1, image_2, metadata_1, metadata_2)
image_3_intersect, image_4_intersect, image_3_resamp, image_4_resamp = align_images(image_3, image_4, metadata_3, metadata_4)

plot_valid_intersection(image_1_resamp, image_2_resamp, annot1, annot2)
plt.savefig(os.path.join(ResultDIR, "mapEW.png"))
plot_valid_intersection(image_3_resamp, image_4_resamp, annot3, annot4)
plt.savefig(os.path.join(ResultDIR, "mapUD.png"))

# Add NS
file_pathNS1 = f"{MSBAS_DIR_1}/zz_NS{LABEL_1}/MSBAS_LINEAR_RATE_NS.bin"
file_pathNS2 = f"{MSBAS_DIR_2}/zz_NS{LABEL_2}/MSBAS_LINEAR_RATE_NS.bin"

if os.path.isfile(file_pathNS1):
    print(f"{file_pathNS1} found ")
    image_5, metadata_5 = load_image_data(file_pathNS1)
else: 
    print(f"{file_pathNS1} not found : probably a 2D processing" )
    image_5 = None
    metadata_5 = None

if os.path.isfile(file_pathNS2):
    print(f"{file_pathNS2} found ")
    image_6, metadata_6 = load_image_data(file_pathNS2)
else: 
    print(f"{file_pathNS1} not found : probably a 2D processing" )
    image_6 = None
    metadata_6 = None

if image_5 is not None and image_6 is not None:
    print("Both Processing in 3D, I can compare NS")
    image_5_intersect, image_6_intersect, image_5_resamp, image_6_resamp = align_images(image_5, image_6, metadata_5, metadata_6)
    plot_valid_intersection(image_5_resamp, image_6_resamp, annot5, annot6)
    plt.savefig(os.path.join(ResultDIR, "mapNS.png"))
else: 
    if image_5 is not None or image_6 is not None:
        print("At least one processing is 3D")
        plot1image(image_5, image_6, annot5, annot6)
        plt.savefig(os.path.join(ResultDIR, "mapNS.png"))

plt.show()

