#!/opt/local/bin/python
# -----------------------------------------------------------------------------------------
# This script aims at displays some stats after a BaselineCohTable
# Parameter : Baseline_Coh_table_{kml}.txt
# Dependencies : python3 in env
#
#
# New in 1.1 (20230621 - NdO):	- Rename script with starting capital letter and change shebang
# New in Distro V 2.0 20231030:	- Rename MasTer Toolbox as AMSTer Software
#								- rename Master and Slave as Primary and Secondary (though not possible in some variables and files)
#
# This script is part of the AMSTer Toolbox 
# AMSTer: SAR & InSAR Automated Mass processing Software for Multidimensional Time series
#
# DS (c) 2023/06/01 # Last modified on June 01, 2023
# -----------------------------------------------------------------------------------------

import sys
import numpy as np
import pandas as pd
import matplotlib.pyplot as plt
import datetime

inputfile_path = sys.argv[1]

VER="Distro V2.0 AMSTer script utilities"
AUT="Delphine Smittarello (c)2016-2019, Last modified on Oct 30, 2023"
print(VER)
print(AUT)

print(" ")
print("Analyse ", inputfile_path)
df = pd.read_csv(inputfile_path, delimiter='\t', header=None)

image1=df[0]
image2=df[1]
BP=df[2]
BT=df[3]
COH=df[4]

pairs=[]
dateimage1=[]
dateimage2=[]
Doy1=[]
Doy2=[]
for k in range(len(image1)):
	pairs.append("_".join([str(image1[k]), str(image2[k])]))

	date1=datetime.date(int(str(image1[k])[0:4]),int(str(image1[k])[4:6]),int(str(image1[k])[6:8]))
	date2=datetime.date(int(str(image2[k])[0:4]),int(str(image2[k])[4:6]),int(str(image2[k])[6:8]))

	doy1=date1.timetuple().tm_yday
	doy2=date2.timetuple().tm_yday
	dateimage1.append(date1)
	dateimage2.append(date2)	
	Doy1.append(doy1)
	Doy2.append(doy2)
PAIRS = pd.Series(pairs)
DATE1 = pd.Series(dateimage1)
DATE2 = pd.Series(dateimage2)
DOY1 =  pd.Series(Doy1)
DOY2 =  pd.Series(Doy2)


plotfig=1
if plotfig==1:
## PLOTS 

	fig1, ((ax1, ax2, ax3), (ax4, ax5, ax6)	, (ax7, ax8, ax9)) = plt.subplots(3, 3)
	ax1.scatter(BT, COH, c=COH)
	ax1.set_xlabel('BT(days)')
	ax1.set_ylabel('Coherence')

	ax2.scatter(BP, COH, c=COH)
	ax2.set_xlabel('BP(m)')
	ax2.set_ylabel('Coherence')

	ax3.scatter(BT,BP,c=COH)
	ax3.set_xlabel('BT(days)')
	ax3.set_ylabel('BP(m)')

	ax4.scatter(DATE1,COH, c=COH)
	ax4.set_xlabel('Date Im1')
	ax4.set_ylabel('Coherence')

	ax5.scatter(DATE2,COH, c=COH)
	ax5.set_xlabel('Date Im2')
	ax5.set_ylabel('Coherence')

	ax6.scatter(DATE1,DATE2,c=COH)
	ax6.set_xlabel('Date Im1')
	ax6.set_ylabel('Date Im2')

	ax7.scatter(DOY1,COH, c=COH)	
	ax7.set_xlabel('Day of Year Im1')
	ax7.set_ylabel('Coherence')

	ax8.scatter(DOY2,COH, c=COH)
	ax8.set_xlabel('Day of Year Im2')
	ax8.set_ylabel('Coherence')

	ax9.scatter(DOY1,DOY2, c=COH)
	ax9.set_xlabel('Day of Year Im1')
	ax9.set_ylabel('Day of Year Im2')

	plt.show() # affiche la figure à l'écran

