#!/opt/local/bin/python
######################################################################################
# This script load a pickle file containing a graph dict  
# then it compute some stats on all nodes(images)
#
# Parameters: -	pickle file full path
#			  - 
#
# Dependencies:	- python3.10 and modules below (see import)
#
# New in Distro V 1.0:	- Based on developpement version 
# New in Distro V 1.1:	- Fix some minor bugs with naming
#
# launch command : python thisscript.py param1 param2
#
# AMSTer: SAR & InSAR Automated Mass processing Software for Multidimensional Time series
# Delphine Smittarello, (c)2016
# Last Modified : 2025-01-09
######################################################################################
import sys
import os
import pickle
import pandas as pd
# Exemple de fonction pour extraire les informations pour chaque mode
def analyze_dates_by_mode(df):
    result_list = []
    
    # Boucler sur chaque mode dans le DataFrame
    for mode, group in df.groupby('Mode'):
        # Convertir les dates en objets datetime (si nécessaire)
        dates = pd.to_datetime(group['date'])
        
        # Trier les dates
        sorted_dates = sorted(dates)
        
        # Calculer la date la plus ancienne et la plus récente
        oldest_date = min(sorted_dates)
        newest_date = max(sorted_dates)
        
        # Calculer les différences entre dates consécutives (en jours)
        time_deltas = [(sorted_dates[i+1] - sorted_dates[i]).days for i in range(len(sorted_dates)-1)]
        
        if time_deltas:  # S'assurer qu'il y a au moins deux dates pour les calculs
            # Calculer le délai moyen
            average_delta = sum(time_deltas) / len(time_deltas)
            
            # Trouver le plus petit et le plus grand délai entre deux dates
            min_delta = min(time_deltas)
            max_delta = max(time_deltas)
        else:
            # Si une seule date est présente, les calculs de délais n'ont pas de sens
            average_delta = None
            min_delta = None
            max_delta = None
        
        # Ajouter les résultats à la liste
        result_list.append({
            'mode': mode,
            'oldest_date': oldest_date,
            'newest_date': newest_date,
            'average_delta_days': average_delta,
            'min_delta_days': min_delta,
            'max_delta_days': max_delta
        })
    
    # Convertir la liste de résultats en DataFrame
    result_df = pd.DataFrame(result_list)
    
    return result_df
    
# ****** MAIN ********

if len(sys.argv) > 2:
	print(f"Running : {sys.argv[0]} {sys.argv[1]} {sys.argv[2]}")
	pkl_filename = sys.argv[1]
	out_filename =  sys.argv[2]
	if os.path.isfile(pkl_filename) and os.path.getsize(pkl_filename) > 0:
		with open(pkl_filename, "rb") as f:
			graphs_by_mode = pickle.load(f)

		print("Image dataframe loaded")
		print(" ")
		result_df = analyze_dates_by_mode(graphs_by_mode)
		print("Compute stats")
		print(result_df)
		print(" ")

		# Sauvegarder les objets dans un fichier pickle
		with open(out_filename, "wb") as f:
			pickle.dump((result_df), f)
	else:
		print(f"Erreur : '{pkl_filename}' not found or empty.")
else:
	print("Error : give full path to picklefile created with Compute_Graphs_From_dfpkl.py and fullpathname to output pickle file")


