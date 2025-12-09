#!/opt/local/amster_python_env/bin/python
######################################################################################
# This script use slope and intercept stored in results.csv created by Load_and_Plot_Output_DEMDefo
# to compute a model based on the DEM correlation and remove it from the deformation map. It will write the result as a binary matrix in float32
#
# Dependencies:	- python3.10 and modules below (see import)
#				- Compute_and_Substract_Defo_Dem.py
#				- mkdir 
#
# Parameters: - Directory where defomaps are strored (i.e. DefoInterpolx2Detrend)
#			  - DEM with same size as defomaps
# 			  - File results.csv created by Load_and_Plot_Output_DEMDefo.py
# launch command : Compute_and_Substract_Defo_Dem.py ${DEM} ${DEFODIR} InputFILE OUTPUTDIR
#
# New in Distro V 1.0 20250121: DS	- save all plots at location of input file
# New in Distro V 2.0 20250813:	- launched from python3 venv
#
#
# AMSTer: SAR & InSAR Automated Mass processing Software for Multidimensional Time series
# DS (c) 2022 - could make better with more functions... when time.
######################################################################################

import sys
import csv
import matplotlib.pyplot as plt
import pandas as pd
import numpy as np
import rasterio
import os
import shutil

demfile=sys.argv[1]
#print(demfile)
defomapfile=sys.argv[2]
#print(defomapfile)
filecorrel=sys.argv[3]
#print(filecorrel)
output_dir=sys.argv[4] 

#Functions
def loadenvifile(filename):
	with rasterio.open(filename) as dataset:
	    # Lire les données
	    data = dataset.read()  # Lire toutes les bandes (par défaut)
	
	    # Afficher les métadonnées du fichier
	    #print("Métadonnées :")
	    #print(dataset.meta)
	
	    # Accéder à la première bande (index 0)
	    band1 = data[0, :, :]  # Extraire la première bande
	    return band1	






# load CSV output
file_path = filecorrel  
df = pd.read_csv(file_path)
#print(df)

defomapname=os.path.basename(defomapfile)
defohdr = defomapfile + '.hdr'
input_dir=os.path.dirname(defomapfile)
output_file = os.path.join(output_dir, 'cor' + defomapname)
header_file = output_file + '.hdr'
img_file =  output_file + '.png'

#print(output_file)
#print(header_file)
#print(img_file)

indices = df[df['Filename'].str.contains(defomapname, case=False, na=False)].index
a=float((df['Slope'].iloc[indices[0]]))
b=float((df['Intercept'].iloc[indices[0]]))

# Load dem and defomaps
dem = loadenvifile(demfile)
defomap = loadenvifile(defomapfile)

# Compute model and reidual defo
print(f'Apply defo = ({a:.4f} * dem + {b:.4f} ) / 1000')
demmodel = (a * dem + b)/1000
defomapcor = defomap - demmodel

# Save residuals as binay matrix and copy hdr from original
defomapcor.astype('float32').tofile(output_file)
try:
    shutil.copy(defohdr, header_file)
#    print(f"Le fichier {defohdr} a été copié vers {header_file}")
except Exception as e:
    print(f"Error during copy : {e}")
    

# Make and save Plots as png
fig, ((ax1, ax2),(ax3, ax4)) = plt.subplots(2, 2, figsize=(15, 10))
im1 = ax1.imshow(dem, cmap='coolwarm')
fig.colorbar(im1, ax=ax1)  # Ajout de la barre de couleur pour 'dem'
ax1.set_title("DEM")  # Titre pour le premier sous-graphique

im2 = ax2.imshow(defomap, cmap='coolwarm', vmin=-np.max(np.abs(defomapcor)) , vmax=np.max(np.abs(defomapcor)) )
fig.colorbar(im2, ax=ax2)  # Ajout de la barre de couleur pour 'defomap'
ax2.set_title("Deformation Map")  # Titre pour le deuxième sous-graphique

im3 = ax3.imshow(demmodel, cmap='coolwarm', vmin=-np.max(np.abs(defomapcor)) , vmax=np.max(np.abs(defomapcor)) )
fig.colorbar(im3, ax=ax3)  # Ajout de la barre de couleur pour 'dem'
ax3.set_title("DEM Model")  # Titre pour le premier sous-graphique

im4 = ax4.imshow(defomapcor, cmap='coolwarm', vmin=-np.max(np.abs(defomapcor)) , vmax=np.max(np.abs(defomapcor)) )
fig.colorbar(im4, ax=ax4)  # Ajout de la barre de couleur pour 'defomap'
ax4.set_title("Corrected Deformation Map")  # Titre pour le deuxième sous-graphique

plt.tight_layout()  
plt.savefig(img_file)
#plt.show()