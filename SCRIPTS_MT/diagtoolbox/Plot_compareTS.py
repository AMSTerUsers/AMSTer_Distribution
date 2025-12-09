#!/opt/local/amster_python_env/bin/python
# -----------------------------------------------------------------------------------------
# This script aims at displaying a comparison of EW, UD (and NS) timelines computed with multiple MSBAS processings.
# 
# Dependencies: python3
#
# New in 1.0 (20250130 - DS): -
# New in 1.1 (20250205 - DS): - check if reversed pair of point timeline exists + improve robustness
# New in 1.2 (20250210 - DS): - improve to check dir zz_UD_EW_NS* for 3D TS
# New in 1.3 (20250213 - DS): - improve to plot NS when it exists
# New in 2.0 (20250319 - DS): - Change to compare more than 2 dir + ajout plot events
# New in Distro V 3.0 20250813:	- launched from python3 venv
#
#
# This script is part of the AMSTer Toolbox
# AMSTer: SAR & InSAR Automated Mass processing Software for Multidimensional Time series
#
# DS (c) 2025/02/05
# -----------------------------------------------------------------------------------------

import matplotlib.pyplot as plt
from datetime import datetime
import os
import sys
import glob 
import numpy as np
import argparse
import matplotlib.colors as mcolors
import pandas as pd

## Functions 
def parse_arguments():
    # Initialiser l'objet ArgumentParser
    parser = argparse.ArgumentParser(description="Exemple d'utilisation d'argparse")
    
    # Ajouter les arguments
    parser.add_argument('MSBASdirs', type=str, help="Liste des repertoires separee par une virgule")
    parser.add_argument('labels', type=str, help="Liste des labels separee par une virgule")
    parser.add_argument('pointsdif', type=str, help="String Chain Point name")
    parser.add_argument("-events", "-events", help="Event file", required=False)
    # Parser les arguments
    return parser.parse_args()


def format_datetime(date_str, time_str):
    return datetime.strptime(date_str + time_str, "%Y%m%d%H%M%S")


def load_file(filename, opo):
    dates = []
    values = []
    try:
        with open(filename, 'r', encoding='utf-8') as file:
            for line in file:
                parts = line.strip().split()
                if len(parts) >= 6:
                    date1 = format_datetime(parts[0], parts[1])
                    value = float(parts[5]) - float(parts[2])
                    dates.append(date1)
                    values.append(value)
        if opo:
        	values = -np.array(values) 
        else: 
        	values = np.array(values) 	
        return dates, values
    except FileNotFoundError:
        print(f"The file '{filename}' does not exist.")
        return [], []
    except Exception as e:
        print(f"An error occurred: {e}")
        return [], []


def find_file(directory, keyword):
    #print(f"Searching in directory: {directory}")
    #print(f"Initial keyword: {keyword}")
    opposite = False
    # Construct the pattern with the initial keyword
    pattern = os.path.join(directory, f"*{keyword}*")
    found_files = glob.glob(pattern)
    
    # If no files are found with the initial keyword, attempt to reverse the parts and check again
    if not found_files:
        print(f"No file matches '{keyword}' in '{directory}'. Trying alternative structure...")
        
        # Split the keyword into parts based on underscores
        parts = keyword.split('_')
        
        # Ensure the structure is valid (must have at least three parts: _XXXX_YYYY_timeLines_)
        if len(parts) >= 4:
            # Swap the XXXX and YYYY parts (i.e., parts[1] and parts[2])
            parts[1], parts[2] = parts[2], parts[1]
            
            # Rebuild the alternative keyword by joining the parts with underscores
            alternative_keyword = '_'.join(parts)
            print(f"Alternative keyword: {alternative_keyword}")
            
            # Construct the pattern for the alternative structure
            pattern = os.path.join(directory, f"*{alternative_keyword}*")
            found_files = glob.glob(pattern)
        
        if not found_files:
            print(f"No file matches the alternative structure '{alternative_keyword}' in '{directory}' either.")
            return [], [], [], False  # Return empty lists if neither keyword structure matches
        else:
            opposite = True
            print(f"Found files with alternative structure '{alternative_keyword}'.")
    if len(found_files) == 2:
        return found_files[0], found_files[1], 'NoFileNS', opposite
    elif len(found_files) == 3:
        return found_files[0], found_files[2], found_files[1], opposite
    else:
    	return [], [], [], False


def load_or_empty(filename, opo):
    return load_file(filename, opo) if filename else ([], [])


def basename_and_remove_underscore(mystring_ori):
	mystring = os.path.basename(mystring_ori)
	if mystring.startswith('_'):
	    mystring = mystring.lstrip('_')
	return mystring



# Fonction pour calculer la moyenne de la serie de reference pendant la periode de la serie cible
def calculate_reference_mean(reference_dates, reference_values, target_dates):
    # Trouver les dates qui sont dans la periode de la serie cible
    start_date_target = target_dates[0]
    end_date_target = target_dates[-1]
    
    # Selectionner les valeurs de la serie de reference qui correspondent à cette periode
    selected_values = [
        value for date, value in zip(reference_dates, reference_values)
        if start_date_target <= date <= end_date_target
    ]
    
    # Calculer la moyenne de ces valeurs
    if selected_values:
        return np.mean(selected_values)
    else:
        return np.nan  # Retourner NaN si aucune valeur dans la periode cible

# Appliquer le shift pour aligner les series
def apply_shift(reference_dates, reference_values, target_dates, target_values):
    reference_mean = calculate_reference_mean(reference_dates, reference_values, target_dates)
    
    if not np.isnan(reference_mean):
        # Le decalage à appliquer est la difference entre la moyenne de la serie de reference et la première valeur de la serie cible
        shift_value = reference_mean - target_values[0]
        target_values_shifted = [value + shift_value for value in target_values]
        #print("shift is :", shift_value)
        return target_values_shifted
    else:
        print("Aucune valeur de reference dans la periode de la serie cible.")
        return target_values  # Si aucun decalage n'est applique, renvoyer la serie originale

def load_file_coerupt(Filedataco):
	df = pd.read_csv(Filedataco, delimiter='\t')
	# Convertir les colonnes 'master' et 'slave' en datetime
	df['master'] = pd.to_datetime(df['master'], format='%d/%m/%Y')  # Spécifier le format de date
	df['slave'] = pd.to_datetime(df['slave'], format='%d/%m/%Y')
	
	return df

# MAIN SCRIPT
# Load args
args = parse_arguments()
MSBASdirs = args.MSBASdirs.split(',')
labels = args.labels.split(',')
POINTSDIF = args.pointsdif
if args.events:
	eventstoplot=load_file_coerupt(args.events)
	#print(eventstoplot)
else: 
	eventstoplot = None
fig_name = f"{POINTSDIF}.png"
all_dates_EW = []
all_dates_UD = []
all_dates_NS = []

# Creer des palettes personnalisees
cmap_blue = mcolors.LinearSegmentedColormap.from_list("blue_palette", ["#0000FF", "#00BFFF", "#87CEEB"])
cmap_green = mcolors.LinearSegmentedColormap.from_list("green_palette", ["#006400", "#32CD32", "#98FB98"])
cmap_red = mcolors.LinearSegmentedColormap.from_list("red_palette", ["#8B0000", "#FF6347", "#FF7F50"])

# Nombre de series de donnees (ajustez selon le nombre de repertoires)
num_series = len(MSBASdirs)  # Remplacer avec le nombre reel de repertoires

# Selectionner des couleurs à partir de la palette
blue_colors = [cmap_blue(i / (num_series - 1)) for i in range(num_series)]
green_colors = [cmap_green(i / (num_series - 1)) for i in range(num_series)]
red_colors = [cmap_red(i / (num_series - 1)) for i in range(num_series)]

# Initialisation de la figure
fig, ax = plt.subplots(figsize=(15, 9))

# Charger les series et initialiser les variables
all_series_EW = []
all_series_UD = []
all_series_NS = []

k = 0
for MSBASdir in MSBASdirs:
    label = labels[k]
    k += 1
    MSBAS_DIR = f"{MSBASdir}/zz_UD_E*_TS{label}/_Time_series"
    MSBAS_DIR_00 = basename_and_remove_underscore(MSBAS_DIR)
    filenameEW, filenameUD, filenameNS, opo = find_file(MSBAS_DIR, POINTSDIF)
    
    datesEW, values_EW = load_or_empty(filenameEW, opo)
    datesUD, values_UD = load_or_empty(filenameUD, opo)
    
    if filenameNS != 'NoFileNS':
        datesNS, values_NS = load_or_empty(filenameNS, opo)
    else:
        datesNS = []
        values_NS = []
    
    # Ajouter les series chargees dans les listes
    all_series_EW.append((datesEW, values_EW))
    all_series_UD.append((datesUD, values_UD))
    all_series_NS.append((datesNS, values_NS))
    nserie=k

# Determiner la serie de reference (celle qui commence le plus tôt)
first_dates_EW = min([series[0][0] for series in all_series_EW if series[0]])  # Première date de toutes les series EW
first_dates_UD = min([series[0][0] for series in all_series_UD if series[0]])  # Idem pour UD

# Identifier la serie de reference
reference_date = min(first_dates_EW, first_dates_UD)
#print(reference_date)
# Appliquer le decalage base sur la moyenne de la serie de reference
for k, (datesEW, values_EW) in enumerate(all_series_EW):
    if datesEW and datesEW[0] > reference_date:
        # Decalage pour les series EW
        #print("Apply shift EW")
        values_EW = apply_shift(all_series_EW[0][0], all_series_EW[0][1], datesEW, values_EW)
        all_series_EW[k] = (datesEW, values_EW)

for k, (datesUD, values_UD) in enumerate(all_series_UD):
    if datesUD and datesUD[0] > reference_date:
        # Decalage pour les series UD
        #print("Apply shift UD")
        values_UD = apply_shift(all_series_UD[0][0], all_series_UD[0][1], datesUD, values_UD)
        all_series_UD[k] = (datesUD, values_UD)

if all(series[0] for series in all_series_NS):
    for k, (datesNS, values_NS) in enumerate(all_series_NS):
        if datesNS and datesNS[0] > reference_date:
            # Decalage pour les series NS
            values_NS = apply_shift(all_series_NS[0][0], all_series_NS[0][1], datesNS, values_NS)
            all_series_NS[k] = (datesNS, values_NS)

#print("Nbr of series:", nserie)
# Tracer les series avec les decalages appliques
k = 0
for MSBASdir in MSBASdirs:
    MSBASdirname=os.path.basename(MSBASdir).lstrip('_')
    label = labels[k]
    k += 1
    
    # Recuperer les series ajustees
    datesEW, values_EW = all_series_EW[k-1]
    datesUD, values_UD = all_series_UD[k-1]
    datesNS, values_NS = all_series_NS[k-1]
    if nserie>2 and k==1:
    	# Tracer les series
    	if datesEW:
    	    plt.plot(datesEW, values_EW, color='blue', marker='o', linewidth=2,linestyle='-', label=f"{MSBASdirname}/EW_{label}", alpha=0.4)
    	if datesUD:
    	    plt.plot(datesUD, values_UD, color='green', marker='o', linewidth=2, linestyle='-', label=f"{MSBASdirname}/UD_{label}", alpha=0.4)
    	if datesNS:
    	    plt.plot(datesNS, values_NS, color='red', marker='o', linewidth=2, linestyle='-', label=f"{MSBASdirname}/NS_{label}", alpha=0.4)
    elif nserie>2 and k==2:    
    	# Tracer les series
    	if datesEW:
    	    plt.plot(datesEW, values_EW, color=blue_colors[k-1], marker='*', linestyle=':', label=f"{MSBASdirname}/EW_{label}", alpha=0.4)
    	if datesUD:
    	    plt.plot(datesUD, values_UD, color=green_colors[k-1], marker='*', linestyle=':', label=f"{MSBASdirname}/UD_{label}", alpha=0.4)
    	if datesNS:
    	    plt.plot(datesNS, values_NS, color=red_colors[k-1], marker='*', linestyle=':', label=f"{MSBASdirname}/NS_{label}", alpha=0.4)
    else:
    	# Tracer les series
    	if datesEW:
    	    plt.plot(datesEW, values_EW, color=blue_colors[k-1], marker='s', linestyle='-', label=f"{MSBASdirname}/EW_{label}")
    	if datesUD:
    	    plt.plot(datesUD, values_UD, color=green_colors[k-1], marker='s', linestyle='-', label=f"{MSBASdirname}/UD_{label}")
    	if datesNS:
    	    plt.plot(datesNS, values_NS, color=red_colors[k-1], marker='s', linestyle='-', label=f"{MSBASdirname}/NS_{label}")

xmin, xmax = ax.get_xlim()
ymin, ymax = ax.get_ylim()
if eventstoplot is not None and not eventstoplot.empty:
	for index, row in eventstoplot.iterrows():
		#print(row['other_column'])
		ax.vlines(row['master'], ymin=ymin, ymax=ymax, color=row['color'])
		ax.annotate(row['other_column'], 
	            xy=(row['master'], ymin),  # Position de l'annotation (sur la ligne verticale master)
	            color='k', fontsize=12, ha='left', va='bottom',  # Couleur et style de texte
	            rotation=90)  # Faire pivoter le texte pour qu'il soit vertical

# Ajouter des labels et une legende
plt.xlim(xmin,xmax)
plt.xlabel("Date")
plt.ylabel("Displacement (m)")
plt.xticks(rotation=45)
plt.title(POINTSDIF)
plt.legend(loc='upper left', bbox_to_anchor=(0, 1.3), borderaxespad=0)
#plt.legend(loc='upper left', bbox_to_anchor=(0, 1.3), borderaxespad=8)
plt.grid(True)
plt.tight_layout()
# Sauvegarder l'image
plt.savefig(f"{POINTSDIF}.png")
#plt.show()
