#!/opt/local/bin/python
######################################################################################
# This script computes the linear regression between DEM and deformation and 
# save plot in current directory. DEM and DEFO must be of the same size.  
#
# Dependencies:	- python3.10 and modules below (see import)
#
# Parameters: DEM DEFO 
# launch command : RegLin_DEM_Defo.py  "$DEM" "$deg_file"
#
#
# V 1.0 (2022)
# New in Distro V 2.0 20231030:	- Rename MasTer Toolbox as AMSTer Software
#								- rename Master and Slave as Primary and Secondary (though not possible in some variables and files)
# New in Distro V 2.1 20250121: DS	- Append file name, coefficients and r2 to output file name output.txt in current dir
# 								DS	- Comment figure display and save as png 
# New in Distro V 2.2 20250218: DS	- Reading dem data type from hdr
#
# AMSTer: SAR & InSAR Automated Mass processing Software for Multidimensional Time series
# NdO (c) 2022 - could make better with more functions... when time.
######################################################################################

import numpy as np
from matplotlib import pyplot as plt
import sys
from numpy import *
import os

## functions
def get_data_type_from_hdr(hdr_file):
    with open(hdr_file, "r") as f:
        for line in f:
            if "data type" in line:
                return int(line.split("=")[1].strip())

    return None  # Si on ne trouve pas la ligne "data type"


## MAIN 

#import files
dem = sys.argv[1]
defo = sys.argv[2]

filename = os.path.basename(defo)

dem_dirname = os.path.splitext(os.path.dirname(dem))[0]
basename_without_ext = os.path.splitext(os.path.basename(dem))[0]
#print(basename_without_ext)

hdr_file = f"{dem_dirname}/{basename_without_ext}.hdr" # Adapter selon l'extension réelle
data_type = get_data_type_from_hdr(hdr_file)

if data_type == 2:
    dtype = 'int16'
elif data_type == 4:
    dtype = 'float32'
elif data_type == 5:
    dtype = 'float64'
else:
    raise ValueError(f"Type de données non pris en charge: {data_type}")

print(f"DEM data type from {hdr_file} is {dtype}")




#print(defo)
# Import Files and make arrays
A = np.fromfile("%s" % (dem),dtype=dtype)
B = np.fromfile("%s" % (defo),dtype=float32)

#print(A.shape)
#print(B.shape)

x = np.array(A[~np.isnan(A)&~np.isnan(B)]) 			#faster than  np.asarray ?
y = np.array(B[~np.isnan(B)&~np.isnan(A)]*1000)		# transform defo in mm

# compute r2
correl_matrix = np.corrcoef(x, y)
corrxy = correl_matrix[0,1]
rsquared = corrxy**2

# search of ^y = kx + d
k, d = np.polyfit(x, y, 1)	# 1 stands for the 
y_pred = k*x + d


output_filename = "output.txt"
with open(output_filename, 'a') as f:
    # Écrire une ligne avec les valeurs de defo, k, d et rsquared
    f.write(f"{defo}, {k:.5f}, {d:.3f}, {rsquared:.5f}\n")


# plot
plt.plot(x, y, '.', linestyle="None")
plt.plot(x, y_pred)
plt.plot(x, y_pred)
plt.title(f'slope = {round (k,5)}mm/m, intercept = {round (d,3)}, r2 = {round (rsquared,5)}')

plt.xlabel('dem [m]')
plt.ylabel('defo [mm]')

plt.savefig(f'{filename}.png')

#plt.show()


