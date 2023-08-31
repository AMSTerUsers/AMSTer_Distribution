#!/opt/local/bin/python
######################################################################################
# This script build the norm table NORM_LOG.txt during test_lcurve.sh
#
# Parameters: none
# 
# Dependencies:	- python2.7 and modules below (see import)
#
# New in Distro V 1.0:	- Based on developpement version and Beta V1.0
#
# MasTer: InSAR Suite automated Mass processing Toolbox. 
# Nicolas d'Oreye, (c)2017-18
######################################################################################

import numpy as np
import sys
from numpy import *

X = np.fromfile("MSBAS_NORM_X.bin",dtype=float32)
NORMX = nanmean(X)

AXY=np.fromfile("MSBAS_NORM_AXY.bin",dtype=float32)
NORMAXY = nanmean(AXY)

print ("%s%s%s%s" % ("||x||: ",NORMX," ||Ax-Y||: ",NORMAXY))
