#!/opt/local/bin/python
######################################################################################
# This script combines a water body mask (where 0 means keep and 1 means mask) with a coherence mask
# (where 0 means keep and 2 means mask unless coherence is above a given threshold at unwrapping).
# The final mask is named "mask_WT_Coh_012" and is stored in the pwd.
#
# Input masks are supposed to be in LatLong .bil files in bytes of the same size.
# 
# Dependencies:	- python3.10 and modules below (see import)
#
# Parameters:
# - Water Bodies mask (e.g., WaterBody_UTM_Larger.bilzeroByte_LL_mask1)
# - Coherence thresholded mask (e.g., coherence_above_0.3.mean_mask2)
#
# Usage: python thisscript.py <water_mask_file> <coherence_mask_file>
#
# New in Distro V 2.0 20231030:	- Rename MasTer Toolbox as AMSTer Software
#								- rename Master and Slave as Primary and Secondary (though not possible in some variables and files)
#
# AMSTer: SAR & InSAR Automated Mass processing Software for Multidimensional Time series
# Nicolas d'Oreye, (c)2023
######################################################################################

import sys

# Check for the correct number of command-line arguments
if len(sys.argv) != 3:
    print("Usage: python thisscript.py <water_mask_file> <coherence_mask_file>")
    sys.exit(1)

# Get the file paths from command-line arguments
WaterMask = sys.argv[1]
CohMask = sys.argv[2]

# Open the water body mask file in read mode
with open(WaterMask, 'rb') as water_file:
    # Read the contents of the water body mask into a bytes object
    water_data = water_file.read()

# Open the coherence mask file in read mode
with open(CohMask, 'rb') as coh_file:
    # Read the contents of the coherence mask into a bytes object
    coh_data = coh_file.read()

# Check if the two files have the same length
if len(water_data) != len(coh_data):
    print("Files have different lengths. Cannot perform the combination.")
else:
    # Combine the two masks element-wise:
    # - 0 (keep) in water mask + 0 (keep) in coherence mask = 0 (keep)
    # - 0 (keep) in water mask + 2 (mask) in coherence mask = 2 (mask)
    # - 1 (mask) in water mask + 0 (keep) in coherence mask = 1 (mask)
    # - 1 (mask) in water mask + 2 (mask) in coherence mask = 3 (mask) => back as 1
    result = bytes(a + b if a != 1 else a for a, b in zip(water_data, coh_data))

    # Replace all occurrences of 3 with 1
    result = result.replace(b'\x03', b'\x01')

    # Save the result to a new binary file
    with open('mask_WT_Coh_012', 'wb') as result_file:
        result_file.write(result)

    print("Masks combined. Result saved as 'mask_WT_Coh_012.")
