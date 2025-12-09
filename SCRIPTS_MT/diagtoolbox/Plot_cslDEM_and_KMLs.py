#!/opt/local/amster_python_env/bin/python
# -----------------------------------------------------------------------------------------
# This script allows you to visualize a Digital Elevation Model (DEM) in AMSTer format and 
# overlay the contours of polygons contained in multiple KML files listed in a text file.
# Parameters: DEMfullpath ,file with list of kml paths, result dir
# Dependencies: python3 and module below
#
# New in 1.0 (20250130 - DS): -
# New in 1.1 (20250212 - DS): - Cosmetic
# New in 1.2 (20250808 - DS): - make kml-list optional
# New in Distro V 3.0 20250813:	- launched from python3 venv
#
#
# This script is part of the AMSTer Toolbox
# AMSTer: SAR & InSAR Automated Mass processing Software for Multidimensional Time series
#
# DS (c) 2025/01/30
# -----------------------------------------------------------------------------------------

import sys
import os
import matplotlib.pyplot as plt
from matplotlib.patches import Polygon as mplPolygon
import xml.etree.ElementTree as ET
from shapely.geometry import Polygon
import numpy as np
import re  

def validate_inputs(dem, kml_list_file=None):
    """
    Validates the provided DEM file and KML list file.
    """
    errors = []

    # Check if the DEM file exists and is a file
    if not os.path.isfile(dem):
        errors.append(f"Error: DEM file '{dem}' does not exist or is not a valid file.")

    # Check if the KML list file exists
    if kml_list_file is not None :
        print(kml_list_file)
        if not os.path.isfile(kml_list_file):
            errors.append(f"Error: KML list file '{kml_list_file}' does not exist or is not a valid file.")
        else:
            # Validate each KML file listed in the KML list file
            with open(kml_list_file, 'r') as file:
                kml_files = [line.strip() for line in file if line.strip()]
                for kml_file in kml_files:
                    if not os.path.isfile(kml_file):
                        errors.append(f"Error: KML file '{kml_file}' listed in '{kml_list_file}' does not exist or is not a valid file.")

    return errors


def plot_kml_files(kml_list_file, apply_zoom=False):
    """
    Plots the contours of all KML files listed in the KML list file onto a single figure, each with a fixed color.
    Optionally zooms to the extent of all KMLs' polygons.

    Parameters:
    - kml_list_file: Path to the text file containing the list of KML files.
    - apply_zoom: Boolean value (default False) to indicate whether the plot should adjust the zoom based on KML extent.
    """
    with open(kml_list_file, 'r') as file:
        kml_files = [line.strip() for line in file if line.strip()]

    ax = plt.gca()
    # Liste de couleurs fixes à utiliser pour chaque fichier KML
    COLOR_LIST = ['blue', 'green', 'red', 'orange', 'purple', 'brown', 'pink', 'cyan', 'magenta', 'yellow']

    # Définir le namespace pour l'analyse KML
    ns = {'kml': 'http://www.opengis.net/kml/2.2'}

    # Variables pour suivre l'étendue des coordonnées
    min_lon, max_lon = float('inf'), float('-inf')
    min_lat, max_lat = float('inf'), float('-inf')

    # Parcourir chaque fichier KML et afficher ses contours
    for idx, kml_file in enumerate(kml_files):
        try:
            # Assigner une couleur à partir de la liste fixe (répéter si plus de KMLs que de couleurs)
            color = COLOR_LIST[idx % len(COLOR_LIST)]

            # Lire le fichier KML
            with open(kml_file, 'r') as f:
                tree = ET.parse(f)
                root = tree.getroot()

                coords = []
                # Trouver tous les polygones dans le fichier KML
                for placemark in root.findall('.//kml:Placemark', ns):
                    for polygon in placemark.findall('.//kml:Polygon', ns):
                        # Extraire les coordonnées de la balise <coordinates> à l'intérieur de <Polygon>
                        coord_text = polygon.find('.//kml:coordinates', ns).text.strip()
                        coord_pairs = coord_text.split()
                        for pair in coord_pairs:
                            lon, lat, *_ = map(float, pair.split(','))
                            coords.append((lon, lat))

                # Si des coordonnées sont trouvées, afficher le contour du polygone
                if coords:
                    polygon = Polygon(coords)
                    mpl_poly = mplPolygon(list(polygon.exterior.coords), closed=True, edgecolor=color, fill=False, lw=2, label=os.path.basename(kml_file))
                    ax.add_patch(mpl_poly)

                    # Mettre à jour les limites des coordonnées
                    lon_vals, lat_vals = zip(*coords)
                    min_lon = min(min_lon, *lon_vals)
                    max_lon = max(max_lon, *lon_vals)
                    min_lat = min(min_lat, *lat_vals)
                    max_lat = max(max_lat, *lat_vals)
                    #print(min_lon,max_lon,min_lat,max_lat)

                else:
                    print(f"Warning: No valid coordinates found in '{kml_file}'.")

        except Exception as e:
            print(f"Error processing '{kml_file}': {e}")

    # Si apply_zoom est True, ajuster le zoom en fonction des coordonnées des KMLs
#    print("apply_zoom:", apply_zoom)
    if apply_zoom:
        ax.set_xlim(min_lon, max_lon)
        ax.set_ylim(min_lat, max_lat)
    else:
        # Si l'argument apply_zoom est False, conserver les limites par défaut
        ax.set_xlim(ax.get_xlim())
        ax.set_ylim(ax.get_ylim())

#    ax.autoscale()
#    ax.set_aspect('equal', adjustable='datalim')
    plt.xlabel("Longitude")
    plt.ylabel("Latitude")
    plt.title("Contours of KML Files")
    plt.legend(loc="best")
#    plt.show()




# Lecture des informations du fichier txt
def read_txt_file(txt_file_path):
    with open(txt_file_path, 'r') as f:
        lines = f.readlines()

    # Filtrer les lignes qui ne contiennent pas de commentaires (lignes qui ne commencent pas par '/*')
    lines = [line.strip() for line in lines if not line.strip().startswith('/*')]

    # Extraire les valeurs numériques en utilisant des expressions régulières
    def extract_value(line):
        # Nettoyer la ligne des espaces et des caractères non nécessaires
        cleaned_line = line.strip()

        # Rechercher la première valeur numérique avec un signe (+ ou -)
        match = re.search(r"[-+]?\d*\.?\d+", cleaned_line)
        if match:
            return match.group(0)  # Retourne la valeur trouvée
        return None

    # Récupérer les informations du fichier texte
    def safe_extract_value(line):
        value = extract_value(line)
        if value is None:
            return float('nan')  # Retourne NaN si aucune valeur n'est trouvée
        return float(value)

    # Extraction des informations du fichier texte
    dem_info = {
        'dem_file': lines[0],  # Chemin du fichier DEM
        'x_dim': int(extract_value(lines[1])),  # Nombre de pixels en longitude
        'y_dim': int(extract_value(lines[2])),  # Nombre de pixels en latitude
        'lower_left_lon': safe_extract_value(lines[3]),  # Longitude du coin inférieur gauche
        'lower_left_lat': safe_extract_value(lines[4]),  # Latitude du coin inférieur gauche
        'lon_res': safe_extract_value(lines[5]),  # Résolution en longitude
        'lat_res': safe_extract_value(lines[6]),  # Résolution en latitude
        'nodata_value': safe_extract_value(lines[7])  # Valeur NaN
    }

    return dem_info






# Charger la matrice binaire (fichier .bil)
def load_bil(dem_file_path, dem_info, flip_up_down=False):
    # Ouverture du fichier binaire en mode lecture
    with open(dem_file_path, 'rb') as f:
        # Le fichier .bil contient des floats, donc on peut lire le fichier binaire comme suit :
        # Lire les données en tant que flotants 4 bytes (float32)
        data = np.fromfile(f, dtype=np.float32)

    # Reshape la matrice selon les dimensions x_dim et y_dim
    dem_matrix = data.reshape(dem_info['y_dim'], dem_info['x_dim'])

    # Si flip_up_down est True, inverser l'axe vertical (flip up-down)
    if flip_up_down:
        dem_matrix = np.flipud(dem_matrix)

    return dem_matrix


# Affichage du DEM
def plot_dem(dem_matrix, dem_info):
    # Calcul des coordonnées géographiques pour chaque pixel
    lon_grid = np.linspace(dem_info['lower_left_lon'], dem_info['lower_left_lon'] + dem_info['x_dim'] * dem_info['lon_res'], dem_info['x_dim'])
    lat_grid = np.linspace(dem_info['lower_left_lat'], dem_info['lower_left_lat'] + dem_info['y_dim'] * dem_info['lat_res'], dem_info['y_dim'])
    
    lon, lat = np.meshgrid(lon_grid, lat_grid)

    # Limiter l'affichage aux dimensions du DEM
    lon_min, lon_max = lon.min(), lon.max()
    lat_min, lat_max = lat.min(), lat.max()

    # Affichage avec imshow
    plt.figure(figsize=(10, 10))
    plt.imshow(dem_matrix, extent=(lon_min, lon_max, lat_min, lat_max), cmap='Greys_r', origin='lower')
    plt.colorbar(label='Altitude (m)')
    plt.xlabel('Longitude')
    plt.ylabel('Latitude')
    plt.title('Digital Elevation Model (DEM) - Guadeloupe')
    #plt.show()
    
def main():
    # Ensure the correct number of arguments is provided
    if len(sys.argv) != 4:
        print("Usage: script.py <dem> <kml_list_file> <resultdir>")
        sys.exit(1)

    dem_file_path = sys.argv[1]
    kml_list_file = None if sys.argv[2] == "None" else sys.argv[2]
    resultdir = sys.argv[3]
    # Informations provenant du fichier txt
    txt_file_path = txt_file_path = dem_file_path + '.txt' # Remplace par le chemin réel du fichier .txt
    dem_name=os.path.basename(dem_file_path)
    
    
    # Validate the inputs
    errors = validate_inputs(dem_file_path, kml_list_file)
    if errors:
        for error in errors:
            print(error)
        sys.exit(1)

    # Print the validated inputs
    print("Plot DEM file:", dem_file_path)
    print("Plot KML in list file:", kml_list_file)

    # Lecture du fichier txt et chargement du DEM
    dem_info = read_txt_file(txt_file_path)
    dem_matrix = load_bil(dem_file_path, dem_info)
    
    # Affichage du DEM
    plot_dem(dem_matrix, dem_info)
    # Plot the KML files
    if kml_list_file is not None :
        kml_list_file_name=os.path.basename(kml_list_file)
        plot_kml_files(kml_list_file)
    else : 
        kml_list_file_name=""
    os.makedirs(resultdir, exist_ok=True)
    outputname = dem_name + '_' + kml_list_file_name + '_kmlplot.pdf'
    output_path = os.path.join(resultdir,outputname)
    plt.savefig(output_path)
    
    
    # Affichage du DEM
    plot_dem(dem_matrix, dem_info)
    # Plot the KML files
    if kml_list_file is not None :
        plot_kml_files(kml_list_file, apply_zoom=True)
    outputname_zoom = dem_name + '_' + kml_list_file_name + '_kmlplot_ZOOM.pdf'
    output_path_zoom = os.path.join(resultdir,outputname_zoom)
    plt.savefig(output_path_zoom)
    
if __name__ == "__main__":
    main()
