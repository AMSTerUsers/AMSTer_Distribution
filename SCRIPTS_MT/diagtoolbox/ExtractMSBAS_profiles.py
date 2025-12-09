#!/opt/local/amster_python_env/bin/python
######################################################################################
# This script displays profiles from velocity maps stored 
# in multiple MSBAS directories and aligns them in Y by subtracting the mean.
#
# V 1.0 (20250303)
# New in Distro V1.1 (20250304) -DS - Compute distance in UTM and change sys to argparse 
# New in Distro V1.2 (20250808) -DS - add optional ylim parameter + bug fixes
# New in Distro V 2.0 20250813:	- launched from python3 venv
#
#
# AMSTer: SAR & InSAR Automated Mass processing Software for Multidimensional Time series
# DS
######################################################################################

import numpy as np
import rasterio
import matplotlib.pyplot as plt
from scipy.interpolate import interp1d
#import sys
import os
import argparse

def parse_arguments():
	# Initialiser l'objet ArgumentParser
	parser = argparse.ArgumentParser(description="Exemple d'utilisation d'argparse")
	
	# Ajouter les arguments
	parser.add_argument('MSBASdirs', type=str, help="Liste des répertoires séparée par une virgule")
	parser.add_argument('labels', type=str, help="Liste des labels séparée par une virgule")
	parser.add_argument("--profile", type=float, nargs=4, metavar=("x1", "y1", "x2", "y2"),
                        help="Profile coordinates as four floats: x1 y1 x2 y2 (either in pixels or UTM depending on --utm flag).")
	parser.add_argument("--utm", action='store_true', help="Flag indicating that the profile is in UTM coordinates (default: pixels).")
	parser.add_argument('--mode', type=str, help="Mode d'exécution")
	parser.add_argument('--figname', type=str, help="Nom du fichier de figure")
	parser.add_argument('--align', action='store_true', help="Alignement moyen (optionnel)")
	parser.add_argument('--ylim', type=float,default=None,  help="optionnal ylim for plot")
	
	# Parser les arguments
	return parser.parse_args()


def load_envi(image_file, ignore_value=0):
    """Charge un fichier raster ENVI avec gestion des valeurs ignorées."""
    with rasterio.open(image_file) as src:
        data = src.read(1)
        if ignore_value is not None:
            data[data == ignore_value] = np.nan
        return data, src

def find_msbas_file(base_path, prefix, filename):
    """Search for the specified file in directories matching the prefix."""
    for subdir in os.listdir(base_path):
        if subdir.startswith(prefix):
            file_path = os.path.join(base_path, subdir, filename)
            if os.path.isfile(file_path):
                return file_path
    return None

def convert_utm_to_pixels(x_utm, y_utm, transform):
    """Convert UTM coordinates to pixel indices."""
    col = round((x_utm - transform[2]) / transform[0])
    row = round((y_utm - transform[5]) / transform[4])
    return col, row

def extract_profile(data, src, profilelim, utm=False, min_distance=30):
    """Extrait un profil entre deux points avec interpolation linéaire si nécessaire,
    et calcule num_points à partir de la distance entre (x1, y1) et (x2, y2)."""
    x1, y1, x2, y2 = profilelim
    # Calculer la distance entre (x1, y1) et (x2, y2)
    distance = np.sqrt((x2 - x1)**2 + (y2 - y1)**2)
    
    # Calculer num_points en fonction de la distance et du seuil de distance minimal
    num_points = max(int(distance / min_distance), 2)  # Assurer au moins 2 points
    
    # Générer les coordonnées le long de la ligne
    coords = list(zip(np.linspace(x1, x2, num=num_points), np.linspace(y1, y2, num=num_points)))
    
    values = []
    distcum =[]
    for x, y in coords:
        col, row = convert_utm_to_pixels(x, y, src.transform)
        if 0 <= row < src.height and 0 <= col < src.width:
            values.append(data[row, col])
        else:
            values.append(np.nan)
        distcum.append(np.sqrt((x - x1)**2 + (y - y1)**2))

    
    values = np.array(values)
    valid = ~np.isnan(values)
    
    if np.any(valid):
        interp = interp1d(np.where(valid)[0], values[valid], kind='cubic', fill_value='extrapolate')
#        values = interp(np.arange(num_points))
        
    return distcum, values


def plot_profile(image_file, profilelim, label, meanalign=None,utm=False,ref=0):
    """Affiche le profil extrait, en soustrayant la valeur moyenne pour aligner les profils en Y."""
    data, src = load_envi(image_file)
    distances, profile = extract_profile(data, src, profilelim, utm)
    #print("REF=",ref)
    # Soustraire la valeur moyenne du profil pour l'aligner en Y
    if meanalign:
    	profile_mean = np.nanmean(profile)  # Calculer la moyenne
    	profile -= profile_mean  # Soustraire la moyenne
    
    if ref==1: 
    	plt.plot(distances, profile, linestyle='-', label=label, linewidth=2, color='black')
    elif ref==2: 
    	plt.plot(distances, profile, linestyle='-', label=label, linewidth=2, color='red')
    else:
    	plt.plot(distances, profile, linestyle='-', label=label)

## MAIN

if __name__ == "__main__":
# Récupérer les répertoires depuis les arguments
	args = parse_arguments()
	# Traiter les arguments
	MSBASdirs = args.MSBASdirs.split(',')
	labels = args.labels.split(',')
	mode = args.mode
	figname = args.figname
	meanalign = args.align
	profile = args.profile
	utm = args.utm
	YLIM = args.ylim
	# Initialiser la figure pour afficher les profils
	plt.figure(figsize=(20, 15))
	
	# Boucle sur chaque répertoire pour extraire et afficher les profils
	k=0
	l=0
	for MSBASdir in MSBASdirs:
	    label=labels[k]
	    k+=1 
	    # Recherche du fichier MSBAS correspondant
	    if mode == "EW":
	    	file = find_msbas_file(MSBASdir, f"zz_EW{label}", "MSBAS_LINEAR_RATE_EW.bin")
	    elif mode == "NS":
	        file = find_msbas_file(MSBASdir, f"zz_NS{label}", "MSBAS_LINEAR_RATE_NS.bin")
	    elif mode == "UD":
	        file = find_msbas_file(MSBASdir, f"zz_UD{label}", "MSBAS_LINEAR_RATE_UD.bin")
	    
	    # if file exist 
	    if file:
	        l+=1
	        if l==1:
	        	plot_profile(file, profile, label=f"{MSBASdir}/zz_{mode}{label}", meanalign=meanalign, utm=utm,ref=1)
	        elif l==2:
	        	plot_profile(file, profile, label=f"{MSBASdir}/zz_{mode}{label}", meanalign=meanalign, utm=utm,ref=2)
	        else:
	        	plot_profile(file, profile, label=f"{MSBASdir}/zz_{mode}{label}", meanalign=meanalign, utm=utm,ref=0)
	    else:
	        print(f"File not found in {MSBASdir}/zz_{mode}{label}")
	
	# Ajouter les labels et afficher le graphique
	plt.xlabel('Distance (m)')
	plt.ylabel('Linear Velocity (m/yr)')
	plt.legend(loc='upper left', bbox_to_anchor=(0, 1.15), borderaxespad=0.)
	if YLIM:
		plt.ylim(-YLIM, YLIM)
	
	plt.grid()
	
	plt.savefig(f"{figname}.png", format='png')
	#plt.show()
	