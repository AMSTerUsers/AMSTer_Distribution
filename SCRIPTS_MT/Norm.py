#!/opt/local/amster_python_env/bin/python
######################################################################################
# This script build the norm table NORM_LOG.txt during test_lcurve.sh
#
# Parameters: none
# 
# For an up to date and detailed list of dependencies (and sub-dependencies), 
#    run the following command (add option -v to also list the commands and calls):
#  		Search_Dependencies /Path/to/This/script 
# 	 (Results are displayed at the Terminal; redirect them to a file with > file.txt if wished)
#
# Dependencies:	- python2.7 and modules below (see import)
#
# New in Distro V 1.0:	- Based on developpement version and Beta V1.0
# New in Distro V 2.0 20231030:	- Rename MasTer Toolbox as AMSTer Software
#								- rename Master and Slave as Primary and Secondary (though not possible in some variables and files)
# New in Distro V 3.0 20250813:	- launched from python3 venv
# New in Distro V 3.1 20261013:	- Recommend using Search_Dependencies.sh for 
#								  an updated list of dependencies
#
#
# AMSTer: SAR & InSAR Automated Mass processing Software for Multidimensional Time series
# NdO (c) 2016/03/07 - could make better with more functions... when time.
######################################################################################

import numpy as np
import sys
from numpy import *

X = np.fromfile("MSBAS_NORM_X.bin",dtype=float32)
NORMX = nanmean(X)

AXY=np.fromfile("MSBAS_NORM_AXY.bin",dtype=float32)
NORMAXY = nanmean(AXY)

print ("%s%s%s%s" % ("||x||: ",NORMX," ||Ax-Y||: ",NORMAXY))
