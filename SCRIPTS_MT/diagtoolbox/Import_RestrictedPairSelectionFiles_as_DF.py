#!/opt/local/amster_python_env/bin/python
######################################################################################
# This script loads all restrictedPairSelection files of a given directory
# as a dataframe and write it as a pickle file
#
# Parameters: -	input directory 
#			  - 
#
# Dependencies:	- python3.10 and modules below (see import)
#
# New in Distro V 1.0:	- Based on developpement version 
# New in Distro V 2.0 20250813:	- launched from python3 venv
#
#
# launch command : python thisscript.py param1 
#
# AMSTer: SAR & InSAR Automated Mass processing Software for Multidimensional Time series
# Delphine Smittarello, (c)2016
# Last Modified : 2024-10-30
######################################################################################
import sys
import os

import glob
import re
import pandas as pd
import pickle



# ****** FUNCTION ********
def load_pairs_data_and_return_graphs_by_mode(repertoire):
    # Look for files  : 
    motif = 'restrictedPairSelection_*.txt'
    fichiers = glob.glob(os.path.join(repertoire, motif))

    # Initialize
    dataframes = []

    # Columns in the dataframe
    colonnes = ['Master date', 'Slave date', 'xm', 'ym', 'xs', 'ys', 'Bp0', 'Bp', 'Dt', 'Ha']

    # Reading files as a dataframe
    for fichier in fichiers:
        try:
        	match = re.search(r'(Detrend(\d+)|Dem(\d+))\.txt$', fichier)
        	if match:
        		if match.group(2):  # Correspondance avec Detrend
        			number = match.group(2)  # Capture le numéro après 'Detrend'
        		elif match.group(3):  # Correspondance avec Dem
        			number = match.group(3)  # Capture le numéro après 'Dem'
        		file_number = int(number)  # Convertit en entier           		
        		print(f"Reading file {fichier} : number {file_number}")
        	else:
        	    print(f"ERROR on File number {fichier}.")
        	    continue
        	
        	with open(fichier, 'r') as f:
        	    lignes = f.readlines()
        	
        	header_index = None
        	for idx, ligne in enumerate(lignes):
        	    if 'Master date' in ligne:
        	        header_index = idx
        	        break
        	
        	if header_index is not None:
        	    data = pd.read_csv(
        	        fichier,
        	        delimiter=r'\s+',
        	        names=colonnes,
        	        skiprows=header_index + 1,
        	        comment='#'
        	    )
        	
        	    data['Mode'] = file_number
        	
        	    if not data.empty:
        	        dataframes.append(data)
        	    else:
        	        print(f"File {fichier} is empty or invalid.")
        	else:
        	    print(f"No header found in file {fichier}.")
        except Exception as e:
            print(f"Error during file {fichier} reading: {e}")

    # if data is successful : 
    if dataframes:
        df_combine = pd.concat(dataframes, ignore_index=True)
        df_combine['Master date'] = pd.to_datetime(df_combine['Master date'], format='%Y%m%d')
        df_combine['Slave date'] = pd.to_datetime(df_combine['Slave date'], format='%Y%m%d')

        return df_combine
    else:
        print("No dataframe loaded.")
        return pd.DataFrame()
        
            
# ****** MAIN ********


if len(sys.argv) > 2:
	print(f"Running : {sys.argv[0]} {sys.argv[1]} {sys.argv[2]}")

	directory_name = sys.argv[1]
	out_filename =  sys.argv[2]
	if os.path.isdir(directory_name) and os.access(directory_name, os.R_OK):
		df_alldata = load_pairs_data_and_return_graphs_by_mode(directory_name)
		print(" ")
		print("pairs data loaded")
		print(df_alldata)

		print("All pairs stored in a dataframe")
		print(" ")
		
		# Sauvegarder les objets dans un fichier pickle
		with open(out_filename, "wb") as f:
			pickle.dump((df_alldata), f)
	else:
		print(f"Erreur : '{directory_name}' is not an accessible directory.")
else:
	print("Error : give directory full path where restrictedPairSelection_DefoInterpolx2Detrend files are stored and fullpathname to output pickl file")
