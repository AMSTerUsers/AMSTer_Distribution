#!/opt/local/bin/python
######################################################################################
# This script load and plots stats about the linear regression between DEM and deformation 
# It expect as input file, the output.txt file created with RegLin_DEM_Defo_all_Maps_In_Geocoded.sh 
# It plots r2, slope and intercept vs BT, BP and dates
#
# Dependencies:	- python3.10 and modules below (see import)
#				
#
# Parameters: File Output.txt created by RegLin_DEM_Defo_all_Maps_In_Geocoded.sh
# launch command : Load_and_Plot_Output_DEMDefo.py "${Processdir}/output.txt"
#
# New in Distro V 1.0 20250121: DS	- save all plots at location of input file
#
# AMSTer: SAR & InSAR Automated Mass processing Software for Multidimensional Time series
# DS (c) 2022 - could make better with more functions... when time.
######################################################################################


import re
import matplotlib.pyplot as plt
import numpy as np
from datetime import datetime
import sys
import os
import csv

# LOAD INPUT FILE
fileinput = sys.argv[1]
pathname = os.path.dirname(fileinput)

# FILE NAME PATTERN WHITH ALL INFO STORED
file_pattern = r'([0-9]{8})_([0-9]{8})_Bp([-\d.]+)m_HA([-\d.]+)m_BT([0-9]+)days'

# initialise results 
results = []

# Open and read input file
with open(fileinput, 'r') as file:
    # ship header line
    next(file)
    
    for line in file:
        # remove blanks
        line = line.strip()
        
        # If line not empty
        if line:
            # Split line in parts separated by a comma
            parts = line.split(',')
            
            # first part in filename
            file_name = parts[0].strip()
            
            # extract slope, intercept and r2
            slope = float(parts[1].strip())
            intercept = float(parts[2].strip())
            r2 = float(parts[3].strip())
            
            # search for BP, BT and dates in filename
            match = re.search(file_pattern, file_name)
            if match:
                date1 = match.group(1)  # Première date
                date2 = match.group(2)  # Deuxième date
                bp_value = float(match.group(3))  # Valeur Bp
                bt_value = int(match.group(5))  # Valeur BT (en jours)
                
                # append all infs in results
                results.append([file_name, slope, intercept, r2, date1, date2, bp_value, bt_value])

# Affichage des résultats
#for result in results:
#    print(result)
resultfilename = os.path.join(pathname,'resultats.csv')
#Save all info as csv file in current dir
with open(resultfilename, 'w', newline='') as csvfile:
    csv_writer = csv.writer(csvfile)
    # Écrire l'en-tête
    csv_writer.writerow(['Filename', 'Slope', 'Intercept', 'R2', 'Date1', 'Date2', 'Bp (m)', 'BT (days)'])
    # Écrire les données extraites
    csv_writer.writerows(results)



# Extraire les données pertinentes
slope_values = [result[1] for result in results]  # Slope
r2_values = [result[3] for result in results]  # R²
intercept_values = [result[2] for result in results]  # R²
bt_values = [result[7] for result in results]  # BT (jours)
bp_values = [result[6] for result in results]  # BP (m)
date1_values = [result[4] for result in results]  # Date1
date2_values = [result[5] for result in results]  # Date2

# Convertir les dates de chaînes (YYYYMMDD) en objets datetime
date1_datetime = [datetime.strptime(date, '%Y%m%d') for date in date1_values]
date2_datetime = [datetime.strptime(date, '%Y%m%d') for date in date2_values]

# 1. R² vs BT
plt.figure(figsize=(15, 10))
plt.scatter(bt_values, r2_values, c=r2_values, cmap='coolwarm', edgecolors='black')
plt.colorbar(label='R²')
plt.title('R² vs BT')
plt.xlabel('BT (days)')
plt.ylabel('R²')
plt.grid(True)
plt.savefig(f'{pathname}/R2_BT.png')

# 2. R² vs BP
plt.figure(figsize=(15, 10))
plt.scatter(bp_values, r2_values, c=r2_values, cmap='coolwarm', edgecolors='black')
plt.colorbar(label='R²')
plt.title('R² vs BP')
plt.xlabel('BP (m)')
plt.ylabel('R²')
plt.grid(True)
plt.savefig(f'{pathname}/R2_BP.png')


# 3. Affichage avec Date1 sur l'axe des X et Date2 sur l'axe des Y, avec R² en couleur
plt.figure(figsize=(20,15))
plt.scatter(date1_datetime, date2_datetime, c=r2_values, cmap='coolwarm', edgecolors='black', s=100)
plt.colorbar(label='R²')
#plt.title('R² en fonction de Date1 et Date2')
plt.xlabel('Date1 (YYYYMMDD)')
plt.ylabel('Date2 (YYYYMMDD)')
plt.grid(True)
plt.xticks(rotation=45)  # Rotation des dates pour mieux les lire
plt.savefig(f'{pathname}/R2_DATES.png')


# 4. Slope vs BT
plt.figure(figsize=(15, 10))
plt.scatter(bt_values, slope_values, c=slope_values, cmap='coolwarm', edgecolors='black')
plt.colorbar(label='Slope')
plt.title('Slope vs BT')
plt.xlabel('BT (days)')
plt.ylabel('Slope')
plt.grid(True)
plt.savefig(f'{pathname}/Slope_BT.png')

# 5. Slope vs BP
plt.figure(figsize=(15, 10))
plt.scatter(bp_values, slope_values, c=slope_values, cmap='coolwarm', edgecolors='black')
plt.colorbar(label='Slope')
plt.title('Slope vs BP')
plt.xlabel('BP (m)')
plt.ylabel('Slope')
plt.grid(True)
plt.savefig(f'{pathname}/Slope_BP.png')


# 6. Affichage avec Date1 sur l'axe des X et Date2 sur l'axe des Y, avec Slope en couleur
plt.figure(figsize=(20,15))
plt.scatter(date1_datetime, date2_datetime, c=slope_values, cmap='coolwarm', edgecolors='black', s=100)
plt.colorbar(label='Slope')
#plt.title('Slope en fonction de Date1 et Date2')
plt.xlabel('Date1 (YYYYMMDD)')
plt.ylabel('Date2 (YYYYMMDD)')
plt.grid(True)
plt.xticks(rotation=45)  # Rotation des dates pour mieux les lire
plt.savefig(f'{pathname}/Slope_DATES.png')


# 7. intercept vs BT
plt.figure(figsize=(15, 10))
plt.scatter(bt_values, intercept_values, c=intercept_values, cmap='coolwarm', edgecolors='black')
plt.colorbar(label='R²')
plt.title('intercept vs BT')
plt.xlabel('BT (days)')
plt.ylabel('intercept')
plt.grid(True)
plt.savefig(f'{pathname}/intercept_BT.png')

# 8. intercept vs BP
plt.figure(figsize=(15, 10))
plt.scatter(bp_values, slope_values, c=intercept_values, cmap='coolwarm', edgecolors='black')
plt.colorbar(label='intercept')
plt.title('Intercept vs BP')
plt.xlabel('BP (m)')
plt.ylabel('intercept')
plt.grid(True)
plt.savefig(f'{pathname}/intercept_BP.png')


# 9. Affichage avec Date1 sur l'axe des X et Date2 sur l'axe des Y, avec intercept en couleur
plt.figure(figsize=(20,15))
plt.scatter(date1_datetime, date2_datetime, c=intercept_values, cmap='coolwarm', edgecolors='black', s=100)
plt.colorbar(label='intercept')
#plt.title('Slope en fonction de Date1 et Date2')
plt.xlabel('Date1 (YYYYMMDD)')
plt.ylabel('Date2 (YYYYMMDD)')
plt.grid(True)
plt.xticks(rotation=45)  # Rotation des dates pour mieux les lire
plt.savefig(f'{pathname}/intercept_DATES.png')

print(f'All results and plots saved in {pathname}')