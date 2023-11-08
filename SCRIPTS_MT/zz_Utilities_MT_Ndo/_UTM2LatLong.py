#!/opt/local/bin/python
######################################################################################
# This script get the LL zone from UTM coord
#
# To transform a full ENVI file, prefer the command :
#	gdalwarp -of ENVI -t_srs EPSG:4326 file_UTM file_LL
#
# Parameters:	- X and Y UTM in meters
#				- UTM zone nr
#				- northern: True or False
# 
# Dependencies:	- python 3.10
#               - see https://pypi.org/project/utm/#files
#
# New in V1.1 : - add argument check (NdO Jul 8 2022)
# New in V1.2:  - debug nr of argument check (NdO March 7 2023) - watch out, it takes the script name as an argument 
# New in Distro V 2.0 20231030:	- Rename MasTer Toolbox as AMSTer Software
#								- rename Master and Slave as Primary and Secondary (though not possible in some variables and files)
#
# AMSTer: SAR & InSAR Automated Mass processing Software for Multidimensional Time series
# Nicolas d'Oreye, (c)2017-18
######################################################################################

#import numpy as np
import utm
from numpy import *
import sys

XX = sys.argv[1]
YY = sys.argv[2]
ZONE = sys.argv[3]
NORTH = sys.argv[4]

#Check nr of arguments  
if len(sys.argv) != 5:
	print("Bad nr of arguments. Provide Lat and Long in decimal degree to get them in UTM")


#utm.from_latlon((Lat), (Long))

A = utm.to_latlon(float(XX), float(YY), int(ZONE), NORTH )

print (A)
