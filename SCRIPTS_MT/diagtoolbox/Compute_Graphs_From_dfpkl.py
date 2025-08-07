#!/opt/local/bin/python
######################################################################################
# This script load a dataframe of all pairs used in MSBAS contained in a pickle file. 
# then it convert it in graphs for each mode
#
# Parameters: -	pickle file full path
#			  - 
#
# Dependencies:	- python3.10 and modules below (see import)
#
# New in Distro V 1.0:	- Based on developpement version 
#
# launch command : python thisscript.py param1 param2
#
# AMSTer: SAR & InSAR Automated Mass processing Software for Multidimensional Time series
# Delphine Smittarello, (c)2016
# Last Modified : 2024-10-30
######################################################################################

import sys
import os
import pickle
import networkx as nx

def graph_from_dataframe(df_combine): 
	graphs_by_mode = {}
	modes = df_combine['Mode'].unique()
	for mode in modes:
	    mode_df = df_combine[df_combine['Mode'] == mode]
	    G = nx.DiGraph()
	    for _, row in mode_df.iterrows():
	        master_date = row['Master date']
	        slave_date = row['Slave date']
	        G.add_node(master_date)
	        G.add_node(slave_date)
	        G.add_edge(master_date, slave_date)
	
	    graphs_by_mode[mode] = G
	return graphs_by_mode


# ****** MAIN ********

if len(sys.argv) > 2:
	print(f"Running : {sys.argv[0]} {sys.argv[1]} {sys.argv[2]}")
	pkl_filename = sys.argv[1]
	out_filename =  sys.argv[2]
	
	if os.path.isfile(pkl_filename) and os.path.getsize(pkl_filename) > 0:
		with open(pkl_filename, "rb") as f:
			df = pickle.load(f)

		print("dataframe loaded")
		print(" ")
		
		graphs_by_mode = graph_from_dataframe(df)
		print("Convert dataframe to graph")
		#print(graphs_by_mode)
		print(" ")

		# Sauvegarder les objets dans un fichier pickle
		with open(out_filename, "wb") as f:
			pickle.dump((graphs_by_mode), f)
	else:
		print(f"Erreur : '{pkl_filename}' not found or empty.")
else:
	print("Error : give full path to picklefile created with Import_RestrictedPairSelection_as_DF.py and fullpathname to output pickl file")
