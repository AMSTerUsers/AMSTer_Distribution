#!/opt/local/amster_python_env/bin/python
######################################################################################
# This script get the UTM zone from Lat Long coord
#
# Parameters: Lat and Long in decimal degree
# 
# Dependencies:	- python 3.10
#               - see https://pypi.org/project/utm/#files
#
# New in V1.1 : - add argument check (NdO Jul 8 2022)
# New in V1.2:  - debug nr of argument check (NdO March 7 2023) - watch out, it takes the script name as an argument 
# New in Distro V 2.0 20231030:	- Rename MasTer Toolbox as AMSTer Software
#								- rename Master and Slave as Primary and Secondary (though not possible in some variables and files)
# New in Distro V 3.0 20250813:	- launched from python3 venv
#
# AMSTer: SAR & InSAR Automated Mass processing Software for Multidimensional Time series
# Nicolas d'Oreye, (c)2017-18
######################################################################################

#import numpy as np
import utm
from numpy import *
import sys

Lat = sys.argv[1]
Long = sys.argv[2]

#Check nr of arguments  
if len(sys.argv) != 3:
	print("Bad nr of arguments. Provide Lat and Long in decimal degree to get them in UTM")


#utm.from_latlon((Lat), (Long))

A = utm.from_latlon(float(Lat), float(Long))

print (A)
