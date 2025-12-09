#!/opt/local/amster_python_env/bin/python
#
# Some functions for Check_images.py
#
# New in Distro V 1.1 20250212:   - Make events dfco optional
# New in Distro V 2.0 20250813:	- launched from python3 venv
#
#
#
#
# Description:
# The key functionalities of this script include:
# 1. Reading and parsing files with specific formats (e.g., *_csl_list.txt).
# 2. Loading, filtering, and processing data to build graphs.
# 3. Extracting and calculating graph centralities (e.g., degree, betweenness centrality, etc.).
# 4. Plotting data and results to visualize the temporal evolution and relationships between modes and images.
#
# Functions:
# - read_subdirectories_files: This function reads files from the provided directory and extracts relevant data into a pandas DataFrame. It also handles extracting dates and matching modes from a mapping file.
# - read_modelist: Reads a list of modes from a file and returns it as a dictionary.
# - read_rejectmodelist: Reads a file containing rejected modes and returns them as a set.
# - load_pairs_data_and_return_graphs_by_mode: This function loads data from files and returns a graph representation (in NetworkX) for each mode. It also computes centralities and prepares the data for further analysis.
# - graph_centralities: Computes various centrality measures for a graph (degree centrality, betweenness centrality, etc.).
# - filter_modes: Filters data to remove certain modes that are not used in MSBAS.
# - load_file_coerupt: Loads the file containing master-slave pair data and parses it into a pandas DataFrame.
# - filter_df_by_date_range: Filters a DataFrame based on a date range and returns the rows within the specified range.
# - compare_dataframes: Compares two DataFrames and identifies pairs of dates/modes present in one but not the other.
# - count_dates_per_mode: Counts the number of dates per mode and prints out a summary of discarded images.
# - plot_two_dataframes: Plots two DataFrames on the same graph, where dates are plotted on the x-axis and modes on the y-axis.
# - plot_two_dataframesPFALOS: Similar to plot_two_dataframes, but customized for a specific dataset (ALOS2) and visualizes certain eruption and intrusion dates.
#
# Important Notes:
# 1. The script assumes that the input data files (e.g., *_csl_list.txt, restrictedPairSelection*.txt) follow a specific structure.
# 2. The mode list and rejected modes are provided via external files, and the script reads and filters based on these.
# 3. The plotting functions are designed to help visualize temporal patterns in the data, with support for custom annotations (such as marking eruptions or intrusions).
#
# Dependencies: see modules below
#
# AMSTer: SAR & InSAR Automated Mass Processing Software for Multidimensional Time Series
# DS (c) 2025/02/12

import os
import pandas as pd
from datetime import datetime
import matplotlib.pyplot as plt
import matplotlib.ticker as ticker
import matplotlib.dates as mdates
import glob
import re
import networkx as nx
#import json
import ast  # Pour évaluer les données comme un dictionnaire Python

def read_subdirectories_files(CSL_directory,file_to_mode):
# Make a df from listing_csl text files from List_all_mode.sh
    data = []
    
    # Parcourir tous les fichiers dans le répertoire donné
    for filename in os.listdir(CSL_directory):
        # Vérifier si le fichier correspond au pattern *_csl_list.txt
        if filename.endswith("_csl_list.txt"):
            file_path = os.path.join(CSL_directory, filename)
            print(f"Reading File : {file_path}")
            
            # Extraire le nom de base sans l'extension
            base_name = filename.replace("_csl_list.txt", "")
            
            # Vérifier si le nom de base est dans la liste des modes
            if base_name in file_to_mode:
                mode = file_to_mode[base_name]
            else:
                mode = "Mode_unknown"  # Si le nom de fichier n'est pas trouvé dans la liste

            # Lire le contenu du fichier et ajouter à la liste
            with open(file_path, 'r') as file:
                # Lire toutes les lignes du fichier
                lines = file.readlines()
                # Ajouter les lignes au DataFrame avec le nom du fichier et le mode comme colonnes supplémentaires
                for line in lines:
                    csl = line.strip()
                    # Extraire le nom du fichier (sans le chemin) et obtenir la date
                    csl_file = os.path.basename(csl)
                    match = re.search(r'(\d{8})', csl_file)
                    if match:
                    	date_str = match.group(1)
                    	try:
                        	# Convertir la chaîne en date au format 'YYYYMMDD'
                        	date = datetime.strptime(date_str, '%Y%m%d').date()
                    	except ValueError:
                        	date = None  # Si l'extraction échoue, on met None

                    data.append({
                        "file_name": filename,
                        "csl": csl,
                        "Mode": int(mode),
                        "date": date
                    })
    
    # Créer un DataFrame à partir des données
    df = pd.DataFrame(data)
    
    return df


def read_modelist(modelistfile):
	with open(modelistfile, "r") as file:
	    content = file.read().strip()  # Lire le contenu du fichier
	modelist = ast.literal_eval(content)
	print("modelist =", modelist)

	return modelist

def read_rejectmodelist(rejected_modesfile):
	with open(rejected_modesfile, "r") as file:
	    content = file.read().strip()    
	    rejected_modes = set(map(int, content.split(",")))
	    
	print("rejected_modes =", rejected_modes)

	return rejected_modes

def load_pairs_data_and_return_graphs_by_mode(repertoire):
    # Motif pour capturer tous les fichiers avec un ou deux chiffres
    motif = 'restrictedPairSelection*.txt'

    # Chercher tous les fichiers correspondant au motif
    fichiers = glob.glob(os.path.join(repertoire, motif))

    # Initialiser une liste pour stocker les dataframes
    dataframes = []

    # Colonnes à utiliser dans le dataframe
    colonnes = ['Master date', 'Slave date', 'xm', 'ym', 'xs', 'ys', 'Bp0', 'Bp', 'Dt', 'Ha']

    # Lire le contenu de chaque fichier dans un dataframe
    for fichier in fichiers:
        try:

            match = re.search(r'(Detrend(\d+)|Dem(\d+))\.txt$', fichier)
            if match:
            # Si le fichier correspond, récupérer le chiffre associé
            	if match.group(2):  # Correspondance avec Detrend
            		number = match.group(2)  # Capture le numéro après 'Detrend'
            	elif match.group(3):  # Correspondance avec Dem
            		number = match.group(3)  # Capture le numéro après 'Dem'
            	number_int = int(number)  # Convertit en entier           		
            	print(f"Reading file {fichier} : number - {number_int}")
            else:
                print(f"No file number for {fichier}.")
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
            
                data['Mode'] = number_int
            
                if not data.empty:
                    dataframes.append(data)
                else:
                    print(f" File {fichier} is empty or not valid.")
            else:
                print(f"No header in file {fichier}.")
        except Exception as e:
            print(f"Error while reading file  {fichier}: {e}")

    if dataframes:
        df_combine = pd.concat(dataframes, ignore_index=True)
        df_combine['Master date'] = pd.to_datetime(df_combine['Master date'], format='%Y%m%d')
        df_combine['Slave date'] = pd.to_datetime(df_combine['Slave date'], format='%Y%m%d')

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

        # Calculer les centralités et degrés pour chaque graphe
        combined_results = []
        for mode, G in graphs_by_mode.items():
            centralities_df = graph_centralities(G)
            centralities_df['date'] = list(G.nodes())  # Remplacez par la méthode appropriée pour obtenir les dates
            combined_results.append(centralities_df)

        combined_centralities = pd.concat(combined_results, keys=graphs_by_mode.keys()).reset_index(level=0).rename(columns={'level_0': 'Mode'})

        return df_combine, graphs_by_mode, combined_centralities
    else:
        print("Aucun DataFrame n'a été chargé.")
        return pd.DataFrame(), {}, pd.DataFrame()

# Compute stats on graph
def graph_centralities(G):
    
    undirected_G = G.to_undirected()
    # Calcul des centralités
    degree_centrality = nx.degree_centrality(undirected_G)
    out_degree_centrality = nx.out_degree_centrality(G)
    in_degree_centrality = nx.in_degree_centrality(G)
    closeness_centrality = nx.closeness_centrality(undirected_G)
    
    
    # Centralité d'intermédiarité
    betweenness_centrality = nx.betweenness_centrality(G)
    
    # Calcul des degrés
    degrees = {node: G.degree(node) for node in G.nodes()}
    in_degrees = {node: G.in_degree(node) for node in G.nodes()}
    out_degrees = {node: G.out_degree(node) for node in G.nodes()}
    net_degrees = {node: abs(in_degrees[node] - out_degrees[node]) for node in G.nodes()}

    # Créer un DataFrame avec toutes les centralités et les degrés
    df = pd.DataFrame({
        'Degree Centrality': degree_centrality,
        'Out-Degree Centrality': out_degree_centrality,
        'In-Degree Centrality': in_degree_centrality,
        'Closeness Centrality': closeness_centrality,
        'Betweenness Centrality': betweenness_centrality,
        'Degree': degrees,
        'In-Degree': in_degrees,
        'Out-Degree': out_degrees,
        'Net-Degree': net_degrees
    })
    
    return df

# Filtering on Mode    
def filter_modes(dates_df,rejected_modes):
    # Retirer les Modes non utilisés dans MSBAS (=highlight_modes)
    #highlight_data = dates_df[dates_df['file_number'].isin(rejected_modes)]
    dates_df_filtered = dates_df[~dates_df['Mode'].isin(rejected_modes)]
    print(f"Total number of images before mode rejection: {len(dates_df)}")
    print(f"Total number of images after mode rejection: {len(dates_df_filtered)}")
    print(f"Total number of filtered images: {len(dates_df)-len(dates_df_filtered)}")
    return dates_df_filtered


def load_file_coerupt(Filedataco):
	df = pd.read_csv(Filedataco, delimiter='\t')
	# Convertir les colonnes 'master' et 'slave' en datetime
	df['master'] = pd.to_datetime(df['master'], format='%d/%m/%Y')  # Spécifier le format de date
	df['slave'] = pd.to_datetime(df['slave'], format='%d/%m/%Y')
	
	return df


def filter_df_by_date_range(df, start_date, end_date):
    """
    Filtre un DataFrame pour ne garder que les lignes où la colonne 'date' est entre start_date et end_date.
    Parameters:
    df (pd.DataFrame): Le DataFrame à filtrer, avec une colonne 'date' au format datetime
    start_date (str ou pd.Timestamp): La date de début de la plage (exclue)
    end_date (str ou pd.Timestamp): La date de fin de la plage (exclue)
    Returns:
    pd.DataFrame: Le DataFrame filtré contenant uniquement les lignes où 'date' est entre start_date et end_date
    """
    # Convertir les dates en format datetime si elles ne le sont pas déjà
    df['date'] = pd.to_datetime(df['date'], errors='coerce')  # Conversion de la colonne 'date'
    start_date = pd.to_datetime(start_date)
    end_date = pd.to_datetime(end_date)
    # Filtrer le DataFrame pour ne garder que les lignes avec date > start_date et date < end_date
    filtered_df = df[(df['date'] > start_date) & (df['date'] < end_date)]
    before_df = df[(df['date'] < start_date)]
    after_df = df[(df['date'] > end_date)]
    #print(df)
    print(f"Initial number of images: {len(df)}")
    print(f"Number of images rejected before {start_date}: {len(before_df)}")
    print(f"Number of images rejected after {end_date}: {len(after_df)}")
    print(f"Number of images in the range {start_date}-{end_date}:{len(filtered_df)}")

    return filtered_df
    
    
def compare_dataframes(df1, df2):
    """
    Compare deux DataFrames et retourne un DataFrame des paires date/mode présentes dans df1 mais pas dans df2.
    Parameters:
    df1 (pd.DataFrame): Premier DataFrame avec les colonnes 'date' et 'Mode'
    df2 (pd.DataFrame): Deuxième DataFrame avec les colonnes 'date' et 'Mode'
    Returns:
    pd.DataFrame: DataFrame des paires (date, Mode) présentes dans df1 mais pas dans df2, trié par mode
    """
    # S'assurer que les colonnes 'date' et 'Mode' sont présentes dans les deux DataFrames
    if not {'date', 'Mode'}.issubset(df1.columns) or not {'date', 'Mode'}.issubset(df2.columns):
        raise ValueError("Les DataFrames doivent contenir les colonnes 'date' et 'Mode'")

    # Convertir les colonnes 'date' en type datetime dans les deux DataFrames
    #df1['date'] = pd.to_datetime(df1['date'], errors='coerce')
    #df2['date'] = pd.to_datetime(df2['date'], errors='coerce')
    df1.loc[:, 'date'] = pd.to_datetime(df1['date'], errors='coerce')
    df2.loc[:, 'date'] = pd.to_datetime(df2['date'], errors='coerce')
    # Créer un DataFrame avec uniquement les colonnes 'date' et 'Mode'
    df1_subset = df1[['date', 'Mode']].drop_duplicates()
    df2_subset = df2[['date', 'Mode']].drop_duplicates()

    # Effectuer une différence en utilisant un merge (anti-join)
    diff_df = pd.merge(df1_subset, df2_subset, on=['date', 'Mode'], how='left', indicator=True)    
    # Sélectionner uniquement les paires présentes dans df1 mais pas dans df2
    diff_df = diff_df[diff_df['_merge'] == 'left_only'].drop(columns=['_merge'])
    # Trier le DataFrame par 'Mode'
    diff_df = diff_df.sort_values(by='Mode')
    # Afficher le DataFrame trié
#    print(diff_df)
    
    return diff_df

def count_dates_per_mode(df,rejected_modes):
	"""
	Lit un fichier CSV contenant les colonnes 'date' et 'Mode' et renvoie un DataFrame
	comptant le nombre de dates pour chaque mode.
	Parameters:
	file_path (str): Chemin vers le fichier CSV à lire (doit contenir 'date' et 'Mode')
	Returns:
	pd.DataFrame: DataFrame avec deux colonnes: 'Mode' et 'count' où 'count' est le nombre de dates par mode
	"""
	# Lire le fichier CSV
	#    df = pd.read_csv(file_path)

	# Vérifier que les colonnes 'date' et 'Mode' sont présentes dans le fichier
	if not {'date', 'Mode'}.issubset(df.columns):
		raise ValueError("Le fichier doit contenir les colonnes 'date' et 'Mode'")

	# Compter le nombre de dates pour chaque mode
	mode_count_df = df.groupby('Mode')['date'].size().reset_index(name='count')

	# Trier le DataFrame par mode pour un meilleur affichage
	mode_count_df = mode_count_df.sort_values(by='Mode')

	# Étape 1 : Calculer le total des dates
	total_count = mode_count_df['count'].sum()

	# Étape 2 : Créer une nouvelle ligne pour "All Modes"
	all_modes_row = pd.DataFrame({'mode': ['All Modes'], 'count': [total_count]})

	# Étape 3 : Ajouter la nouvelle ligne au DataFrame
	mode_count_df = pd.concat([mode_count_df, all_modes_row], ignore_index=True)
	print(" ")
	print(f"Combining ALL MODES, {total_count} images are DISCARDED during processing: ")
	# Liste des modes à vérifier (vous pouvez adapter selon vos besoins)
#	all_modes = list(range(1, 28))  # Modes de 1 à 27 par exemple
	all_modes = list(range(1, 5))  # Modes de 1 à 27 par exemple

	for mode in all_modes:
		images=[]
		if (mode not in rejected_modes):
			if (mode in mode_count_df['Mode'].values):
			# Récupérer le nombre d'images pour le mode actuel
				modecount = mode_count_df.loc[mode_count_df['Mode'] == mode, 'count'].values[0]
				print(f'Mode {mode}: {modecount} discarded image(s) ')
				filtered_df = df[(df['Mode'] == mode)]
				filtered_df = filtered_df.sort_values(by='date')
				images = list(filtered_df['date'])
				formatted_dates = [ts.strftime('%Y-%m-%d') for ts in images]
				print(formatted_dates)
			else:
				# Si le mode n'est pas dans le DataFrame
				print(f'Mode {mode}: 0 discarded image')
		else:
			print(f'Mode {mode}: rejected by user ')

	print(" ")

	return mode_count_df



def plot_two_dataframes(df1, df2, dfco, output_dir, modelist):
    """
    Cette fonction trace un graphique de deux DataFrames en utilisant 'date' sur l'axe x et 'Mode' sur l'axe y.
    Les deux DataFrames sont tracés avec des couleurs différentes et les modes sont affichés en utilisant le dictionnaire modelist.

    Paramètres :
    df1 : premier DataFrame (tracé en gris)
    df2 : deuxième DataFrame (tracé en bleu)
    dfco : DataFrame ou information supplémentaire liée aux événements, non utilisée ici mais peut-être utile
    output_dir : répertoire où enregistrer le graphique
    modelist : dictionnaire associant des noms de modèles à des numéros de mode
    """
    
    # Créer un dictionnaire inversé pour mapper les numéros de mode aux noms de modèles
    mode_to_name = {v: k for k, v in modelist.items()}
    
    # Remplacer les numéros de mode dans les DataFrames par les noms des modèles
    df1['Mode_name'] = df1['Mode'].map(mode_to_name)
    df2['Mode_name'] = df2['Mode'].map(mode_to_name)

    # Créer la figure et les axes
    fig, ax = plt.subplots(figsize=(16, 10))

    # Tracer le premier DataFrame (en gris)
    ax.plot(df1['date'], df1['Mode'], color='gray', label='Rejected in MSBAS', marker='o', linestyle='None')

    # Tracer le deuxième DataFrame (en bleu clair)
    ax.plot(df2['date'], df2['Mode'], color='skyblue', label='Used in MSBAS', marker='o', linestyle='None')

   # Plot the third DataFrame (green)

    # Personnalisation du titre et des labels des axes
    ax.set_xlabel('Dates', fontsize=20)
    ax.set_ylabel('Modes', fontsize=20)
    ax.set_title('DATABASE', fontsize=24)

    # Personnalisation de l'axe des y pour afficher les noms des modèles
    ax.set_yticks(list(modelist.values()))  # Mettre les numéros de mode comme ticks
    ax.set_yticklabels([mode_to_name[i] for i in modelist.values()])  # Remplacer les numéros par les noms des modèles

    # Personnalisation de l'axe des x pour les dates
    ax.xaxis.set_major_locator(mdates.MonthLocator(interval=4))  # Ticks principaux tous les 4 mois
    ax.xaxis.set_minor_locator(mdates.MonthLocator())  # Ticks mineurs tous les mois
    ax.xaxis.set_major_formatter(mdates.DateFormatter('%Y-%m'))  # Format de date en 'année-mois'

    # Ajouter une grille
    ax.grid(True, which='major', linestyle='--', linewidth=0.7)
    ax.minorticks_on()
    ax.grid(True, which='minor', linestyle=':', linewidth=0.5)

    # Rotation des labels de l'axe des x pour une meilleure lisibilité
    ax.tick_params(axis='both', which='major', labelsize=18)
    ax.tick_params(axis='both', which='minor', labelsize=16)
    ax.tick_params(axis='x', which='major', rotation=45)

    ymin, ymax = ax.get_ylim()
    if dfco is not None and not dfco.empty:
    	for index, row in dfco.iterrows():
    		#print(row['other_column'])
    		ax.vlines(row['master'], ymin=ymin, ymax=ymax, color='green')
    		ax.annotate(row['other_column'], 
    	            xy=(row['master'], 1.3),  # Position de l'annotation (sur la ligne verticale master)
    	            color='k', fontsize=12, ha='left', va='bottom',  # Couleur et style de texte
    	            rotation=90)  # Faire pivoter le texte pour qu'il soit vertical
	
    # Ajouter une légende
    ax.legend(fontsize=14, loc='best')


    # Ajuster la mise en page pour éviter les chevauchements
    plt.tight_layout(rect=[0, 0, 1, 0.95])

    # Créer le répertoire de sortie si nécessaire
    os.makedirs(output_dir, exist_ok=True)

    # Sauvegarder le graphique
    output_path = os.path.join(output_dir, "Plot_database_with_model_names.pdf")
    plt.savefig(output_path)

    # Afficher le graphique
    plt.show()

    
def plot_two_dataframesPFALOS(df1, df2,dfco,output_dir):
    """
    Cette fonction trace un graphique de deux DataFrames en utilisant 'date' sur l'axe x et 'Mode' sur l'axe y.
    
    
    Paramètres :
    df1 : premier DataFrame (tracé en gris)
    df2 : deuxième DataFrame (tracé en bleu)
    """
    # Define the lists of dates for different colors
    erupt1 = pd.Timestamp('2021-04-09')
    erupt2 = pd.Timestamp('2021-12-21')
    erupt3 = pd.Timestamp('2022-09-19')
    erupt4 = pd.Timestamp('2023-07-02')
    intrusions_dates = [pd.Timestamp('2021-10-18'), pd.Timestamp('2022-09-07'), pd.Timestamp('2023-04-21')]
    
              
    # Créer la figure et les axes
    fig, ax = plt.subplots(figsize=(16, 10), )

    # Tracer le premier DataFrame (bleu)
    ax.plot(df1['date'], df1['Mode'], color='gray', label='Rejected in MSBAS', marker='o', linestyle='None')

    # Tracer le deuxième DataFrame (rouge)
    ax.plot(df2['date'], df2['Mode'], color='skyblue', label='Used in MSBAS', marker='o', linestyle='None')
    

   # ax.set_title('ALOS2 Dataset used in MSBAS', fontsize=24)
    ax.set_xlabel('Dates', fontsize=20)
    ax.set_ylabel('Modes', fontsize=20)

    # Customize y-axis for file numbers (modes)
    ax.yaxis.set_major_locator(ticker.MultipleLocator(5))  # Major ticks for every 5 modes
    ax.yaxis.set_minor_locator(ticker.MultipleLocator(1))  # Minor ticks for every 1 mode
    ax.yaxis.set_major_formatter(ticker.FuncFormatter(lambda y, _: f'{int(y)}'))  # Format y-axis as integers

    # Customize x-axis for dates
    ax.xaxis.set_major_locator(mdates.MonthLocator(interval=4))  # Major ticks every month
    ax.xaxis.set_minor_locator(mdates.MonthLocator())  # Minor ticks every week
    ax.xaxis.set_major_formatter(mdates.DateFormatter('%Y-%m'))  # Format x-axis to show year-month

    # Add gridlines
    ax.grid(True, which='major', linestyle='--', linewidth=0.7)
    ax.minorticks_on()
    ax.grid(True, which='minor', linestyle=':', linewidth=0.5)

 # Ajouter des barres horizontales à 7.5, 13.5, 20.5
    ax.axhline(y=7.5, color='black', linestyle='--', linewidth=1)
    ax.axhline(y=13.5, color='black', linestyle='--', linewidth=1)
    ax.axhline(y=20.5, color='black', linestyle='--', linewidth=1)

    ax.axvline(x=erupt1, color='orange', linestyle='-', linewidth=2,label='Eruption')
    ax.axvline(x=erupt2, color='orange', linestyle='-', linewidth=2)
    ax.axvline(x=erupt3, color='orange', linestyle='-', linewidth=2)
    ax.axvline(x=erupt4, color='orange', linestyle='-', linewidth=2)
    index=0
    for timing in intrusions_dates:
    	ax.axvline(x=timing, color='blue', linestyle='-', linewidth=2,label='Intrusion'if index == 0 else "")
    	index=1

   # Plot the third DataFrame (green)
    for index, row in dfco.iterrows():
    	ax.plot([row['master'], row['slave']], [row['mode'], row['mode']], marker='.', color='green',label=" Co-erupt. Interf. " if index == 0 else "" )


# Ajouter des annotations pour chaque intervalle
    ax.text(df1['date'].max(), 4, 'Asc. Left', fontsize=20, verticalalignment='center', color='gray',rotation=45)
    ax.text(df1['date'].max(), 10, 'Asc. Right', fontsize=20, verticalalignment='center', color='gray',rotation=45)
    ax.text(df1['date'].max(), 16, 'Desc. Left', fontsize=20, verticalalignment='center', color='gray',rotation=45)
    ax.text(df1['date'].max(), 23, 'Desc. Right', fontsize=20, verticalalignment='center', color='gray',rotation=45)

    # Rotation des labels de l'axe des x pour une meilleure lisibilité
    #plt.xticks(rotation=45)
    ax.tick_params(axis='both', which='major', labelsize=18)
    ax.tick_params(axis='both', which='minor', labelsize=16)
    ax.tick_params(axis='x',which='major', rotation=45)

    # Ajouter une légende
#    ax.legend(fontsize = 14,loc='lower right',bbox_to_anchor=(1.01, 1.0))
    ax.legend(fontsize = 14,loc='lower right',ncol=2, bbox_to_anchor=(1, 1))
    plt.gcf().autofmt_xdate()
    # Ajuster les marges et afficher le graphique
    plt.tight_layout(rect=[0, 0, 1, 0.95])
    
    os.makedirs(output_dir, exist_ok=True)
    output_path = os.path.join(output_dir, "Plot_database.pdf")
    plt.savefig(output_path)

    plt.show()
