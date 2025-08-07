#!/opt/local/bin/python
# """
#Script: Check_images.py
#------------------------
#This script compares data from two directories (CSL and MSBAS) to identify differences in dates and modes within subdirectories. It also loads event information from a file and filters the data based on a date range.
#The filtered data is then compared, and the results are saved as CSV files.
#
#Input Parameters:
#-----------------
#- <DIR_INFO_CSL>: Directory containing CSL data.
#- <DIR_INFO_MSBAS>: Directory containing MSBAS data.
#- <start_date>: Start date for the range to analyze (format: YYYYMMDD).
#- <end_date>: End date for the range to analyze (format: YYYYMMDD).
#- <resultdir>: Directory to store the output results.
#- <modelistfile>: File containing a list of mode to consider (required).
#
#Optional Parameter:
#-------------------
#- <rejected_modesfile>: (Optional) File containing modes to reject from the analysis.
#- <eventsfile>: File containing events dates to plot.
#
#Script Execution:
#-----------------
#Usage: python Check_images.py <DIR_INFO_CSL> <DIR_INFO_MSBAS> <start_date> <end_date> <eventsfile> <resultdir> <modelistfile> [rejected_modesfile]
#
#This script expects 7 or 8 arguments (the last one being optional). It will:
#1. Load CSL and MSBAS data.
#2. Load event data (co-eruptions).
#3. Filter the data based on the provided date range.
#4. Reject modes specified in the rejected_modesfile (if provided).
#5. Compare CSL and MSBAS datasets.
#6. Plot and save the results as CSV files.
#
#Detailed Process:
#-----------------
#1. **Load CSL Data**:
#   - The CSL data is loaded from the directory specified by the first argument (`<DIR_INFO_CSL>`).
#   
#2. **Load MSBAS Data**:
#   - The MSBAS data is loaded from the directory specified by the second argument (`<DIR_INFO_MSBAS>`).
#   
#3. **Load Co-eruption Event Data**:
#   - The co-eruption data from the `<eventsfile>` is loaded to cross-reference event timings.
#
#4. **Filter by Date Range**:
#   - Both CSL and MSBAS data are filtered based on the date range specified by the `<start_date>` and `<end_date>` arguments.
#   
#5. **Reject Modes**:
#   - Any modes specified in the `<rejected_modesfile>` (if provided) are filtered out from the data.
#
#6. **Compare Data**:
#   - The filtered CSL and MSBAS data are compared for discrepancies in dates and modes.
#   
#7. **Generate Plots and Save Results**:
#   - The script generates plots comparing the CSL and MSBAS data and saves the resulting CSV files in the `<resultdir>` directory.
#
#Output Files:
#-------------
#-combined_subdirectories_with_modes_and_dates.csv`: A CSV file containing the combined CSL and MSBAS data with modes and dates.
#-differences_dates_modes.csv`: A CSV file containing the differences between the CSL and MSBAS datasets (if any).
#
#Example Command:
#----------------
#To run the script with the required arguments:
#python Check_images.py /path/to/CSL /path/to/MSBAS 20220101 20221231 /path/to/eventsfile /path/to/results modelist.txt rejected_modes.txt
#
## New in Distro V 1.1 20250212:   - Make events and reject optionnal
##
##
## AMSTer: SAR & InSAR Automated Mass processing Software for Multidimensional Time series
## DS (c) 2025/02/12 
# """

import sys
import os
import argparse

import Check_images_functions as CI

# Vérifier le nombre d'arguments passés
if len(sys.argv) < 7:
    print(len(sys.argv), "arguments donnés, vérifiez l'utilisation")
    print("Usage: python Check_images.py <DIR_INFO_CSL> <DIR_INFO_MSBAS> <start_date> <end_date> <resultdir> [ eventsfile rejected_modesfile (optional)]")
    sys.exit(1)

#########################################################################################
### Inputs :
parser = argparse.ArgumentParser(description="Comapre CSL and MSBAS")

# Arguments obligatoires (positionnels)
parser.add_argument("CSL_directory", help="CSL dir")
parser.add_argument("MSBAS_directory", help="MSBAS dir")
parser.add_argument("start_date", help="start YYYYMMDD")
parser.add_argument("end_date", help="end YYYYMDD")
parser.add_argument("output_dir", help="outputdir")
parser.add_argument("modelistfile", help="All Mode list file")

# Arguments optionnels (avec des options de type -event et -reject)
parser.add_argument("-event", "--filedataco", help="Event file", required=False)
parser.add_argument("-rejected", "--rejected_modesfile", help="reject modes file", required=False)

# Analyser les arguments
args = parser.parse_args()

# Afficher les arguments
print("CSL_directory:", args.CSL_directory)
print("MSBAS_directory:", args.MSBAS_directory)
print("start_date:", args.start_date)
print("end_date:", args.end_date)
print("output_dir:", args.output_dir)
print("modelistfile:", args.modelistfile)
print("Filedataco:", args.filedataco)  # Peut être None si non passé
print("rejected_modesfile:", args.rejected_modesfile)  # Peut être None si non passé

start_date=args.start_date
end_date=args.end_date
output_dir=args.output_dir
# Lire la liste des modèles et les modes rejetés
modelist = CI.read_modelist(args.modelistfile)
rejected_modes = []
if args.rejected_modesfile:
    rejected_modes = CI.read_rejectmodelist(args.rejected_modesfile)

#########################################################################################
### Charger les données
print("Loading CSL data :")
df_CSL = CI.read_subdirectories_files(args.CSL_directory, modelist)
print("CSL loaded")
print(" ")

print("Loading MSBAS data:")
df_alldata, graphs_by_mode, df_MSBAS = CI.load_pairs_data_and_return_graphs_by_mode(args.MSBAS_directory)
print("MSBAS loaded")
print(" ")

if args.filedataco:
	print("Loading events info :", args.filedataco)
	dfco = CI.load_file_coerupt(args.filedataco)
	print("Done")
	print(" ")
else:
	dfco = None	


print("Filtering :")
print("Images CSL")
df_CSL_filtered = CI.filter_df_by_date_range(df_CSL, start_date, end_date)
print(len(rejected_modes), "modes are rejected by user :", sorted(rejected_modes))
df_CSL_filtermodes = CI.filter_modes(df_CSL_filtered, rejected_modes)

print(" ")
print("Images used with MSBAS")
df_MSBAS_filtered = CI.filter_df_by_date_range(df_MSBAS, start_date, end_date)
print(len(rejected_modes), "modes are rejected by user :", sorted(rejected_modes))
df_MSBAS_filtermodes = CI.filter_modes(df_MSBAS_filtered, rejected_modes)

print("Filtering Done")
print(" ")

print("Compare CSL and MSBAS databases :")
df_Diff = CI.compare_dataframes(df_CSL_filtered, df_MSBAS_filtered)
df_mode_count = CI.count_dates_per_mode(df_Diff, rejected_modes)

CI.plot_two_dataframes(df_CSL_filtered, df_MSBAS_filtermodes, dfco, output_dir,modelist)

# Sauvegarder les DataFrames sous forme de fichiers CSV
output_pathname = os.path.join(output_dir, "combined_subdirectories_with_modes_and_dates.csv")
df_CSL.to_csv(output_pathname, index=False)
print("DataFrame saved as", output_pathname)

output_pathname = os.path.join(output_dir, "differences_dates_modes.csv")
df_Diff.to_csv(output_pathname, index=False)
print(" ")
