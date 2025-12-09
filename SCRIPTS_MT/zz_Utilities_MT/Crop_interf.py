#!/opt/local/amster_python_env/bin/python
# -----------------------------------------------------------------------------------------
# This script is aiming at cropping a part of an interferogram
#
# New in Distro V 2.0 20250813:	- launched from python3 venv
#
#
# AMSTer: SAR & InSAR Automated Mass processing Software for Multidimensional Time series
# DS (c) 2022/09/30 - could make better... when time.
# -----------------------------------------------------------------------------------------
import sys
import numpy as np
import os
import matplotlib.pyplot as plt

interfile = sys.argv[1]
numcol =  sys.argv[2]
numlin =  sys.argv[3]
cropxmin = sys.argv[4]
cropxlen = sys.argv[5]
cropymin = sys.argv[6]
cropylen = sys.argv[7]

numcol = int(numcol)
numlin = int(numlin)
cropxmin = int(cropxmin)
cropxlen = int(cropxlen)
cropymin = int(cropymin)
cropylen = int(cropylen)

interf = np.fromfile("%s" % (interfile),dtype='float32')
phi = np.reshape(interf,(numlin,numcol))

phicrop = phi[cropymin:cropymin+cropylen,cropxmin:cropxmin+cropxlen]
plt.imshow(phi)
plt.show()
plt.imshow(phicrop)
plt.show()
print(phicrop.shape)
interfcrop = np.reshape(phicrop,cropxlen*cropylen)



dir_path = os.path.dirname(os.path.realpath(interfile))
output_file = open("%s%s" % (dir_path,'/crop.tmp'), 'wb')
interfcrop.tofile(output_file)
output_file.close()

