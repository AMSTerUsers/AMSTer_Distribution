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
import pandas as pd


def graph2dfimages(graphs_by_mode): 
	combined_results = []
	for mode, G in graphs_by_mode.items():
		centralities_df = graph_centralities(G)
		centralities_df['date'] = list(G.nodes())  # Remplacez par la méthode appropriée pour obtenir les dates
		combined_results.append(centralities_df)
	
	df_node_stats = pd.concat(combined_results, keys=graphs_by_mode.keys()).reset_index(level=0).rename(columns={'level_0': 'Mode'})
	
	return df_node_stats

def graph_centralities(G):
    
    undirected_G = G.to_undirected()
    # Calcul des centralités
    degree_centrality = nx.degree_centrality(undirected_G)
    out_degree_centrality = nx.out_degree_centrality(G)
    in_degree_centrality = nx.in_degree_centrality(G)
    closeness_centrality = nx.closeness_centrality(undirected_G)
    
    # Conversion en graphe non orienté pour eigenvector_centrality
	#undirected_G = G.to_undirected()
    #eigenvector_centrality = nx.eigenvector_centrality(undirected_G)
    
    # Centralité d'intermédiarité
    betweenness_centrality = nx.betweenness_centrality(G)
    
    # Centralité de Katz
    #katz_centrality = nx.katz_centrality_numpy(undirected_G, alpha=0.1)
    
    # Centralité de PageRank
    #pagerank_centrality = nx.pagerank(undirected_G)

    # Calcul des degrés
    degrees = {node: G.degree(node) for node in G.nodes()}
    in_degrees = {node: G.in_degree(node) for node in G.nodes()}
    out_degrees = {node: G.out_degree(node) for node in G.nodes()}
    net_degrees = {node: abs(in_degrees[node] - out_degrees[node]) for node in G.nodes()}

    # Créer un DataFrame avec toutes les centralités et les degrés
    df = pd.DataFrame({
        'Degree': degrees,
        'In-Degree': in_degrees,
        'Out-Degree': out_degrees,
        'Net-Degree': net_degrees,
        'Degree Centrality': degree_centrality,
        'Out-Degree Centrality': out_degree_centrality,
        'In-Degree Centrality': in_degree_centrality,
        'Closeness Centrality': closeness_centrality,
   #     'Eigenvector Centrality': eigenvector_centrality,
        'Betweenness Centrality': betweenness_centrality
   #     'Katz Centrality': katz_centrality,
   #     'PageRank Centrality': pagerank_centrality,
    })
    
    return df

# ****** MAIN ********

if len(sys.argv) > 2:
	print(f"Running : {sys.argv[0]} {sys.argv[1]} {sys.argv[2]}")
	pkl_filename = sys.argv[1]
	out_filename =  sys.argv[2]
	if os.path.isfile(pkl_filename) and os.path.getsize(pkl_filename) > 0:
		with open(pkl_filename, "rb") as f:
			graphs_by_mode = pickle.load(f)

		print("Graph dict loaded")
		print(" ")
		df_node_stats = graph2dfimages(graphs_by_mode)
		print("Convert graph to dataframe with all images")
		print(df_node_stats)
		print(" ")

		# Sauvegarder les objets dans un fichier pickle
		with open(out_filename, "wb") as f:
			pickle.dump((df_node_stats), f)
	else:
		print(f"Erreur : '{pkl_filename}' not found or empty.")
else:
	print("Error : give full path to picklefile created with Compute_Graphs_From_dfpkl.py and fullpathname to output pickle file")
