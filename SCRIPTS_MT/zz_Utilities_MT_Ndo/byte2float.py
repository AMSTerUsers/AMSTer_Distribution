#!/opt/local/amster_python_env/bin/python
######################################################################################
# This script convert byte to floats (images can be read with cpxfiddle as -f r4)
#
# Parameters: - name of images to convert
#
# Dependencies : - python3.10 and modules below (see import) 
#
# New in Distro V 2.0:	- exporting without the array size as a header (i.e. not as .npy) 
# New in Distro V 2.1:  - add argument check (NdO Jul 8 2022)
# New in Distro V 2.2:  - debug nr of argument check (NdO March 7 2023) - watch out, it takes the script name as an argument 
# New in Distro V 3.0 20231030:	- Rename MasTer Toolbox as AMSTer Software
#								- rename Master and Slave as Primary and Secondary (though not possible in some variables and files)
# New in Distro V 4.0 20250813:	- launched from python3 venv
#
#
# AMSTer: SAR & InSAR Automated Mass processing Software for Multidimensional Time series
# Nicolas d'Oreye, (c)2016
######################################################################################

import numpy as np
import sys
from numpy import *
import os

bytefile = sys.argv[1]

#Check nr of arguments  
if len(sys.argv) != 2:
	print("Bad nr of arguments. Provide file to convert from bytes to float")

i = np.fromfile("%s" % (bytefile),dtype='B')
i=i.astype('float32')
#np.save("%s%s" % (bytefile,"float"), i)

# without header 
output_file = open("%s%s" % (bytefile,"Float"), 'wb')
i.tofile(output_file)
output_file.close()
