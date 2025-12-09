#!/opt/local/amster_python_env/bin/python
# Function to find common time span to both table.txt files
# It add a delay of 30day before the first date and after the last for plot purposes
#
# New in Distro V 1.0.1 20240209:  - Cosmetic
# New in Distro V 1.0.2 20250207:  - replace delimiter \t by r'\s+'
# New in Distro V 2.0 20250813:	- launched from python3 venv
#
#
# AMSTer: SAR & InSAR Automated Mass processing Software for Multidimensional Time series
# Delphine Smittarello (c) 2024/02/09 - could make better with more functions... when time.
# -----------------------------------------------------------------------------------------
 
## import modules
import sys
import pandas as pd
import datetime
from datetime import timedelta

## Parameters
inputfile1 = sys.argv[1]
inputfile2 = sys.argv[2]

## Load data
df = pd.read_csv(inputfile1, delimiter=r'\s+', index_col=False, header=None, skipinitialspace=True)
image11=df.iloc[:,0]	
image12=df.iloc[:,1]

## Load data
df = pd.read_csv(inputfile2, delimiter=r'\s+', index_col=False, header=None, skipinitialspace=True)
image21=df.iloc[:,0]	
image22=df.iloc[:,1]


dateimage1=[]
dateimage2=[]
for k in range(len(image11)):
	date1=datetime.date(int(str(image11[k])[0:4]),int(str(image11[k])[4:6]),int(str(image11[k])[6:8]))
	date2=datetime.date(int(str(image12[k])[0:4]),int(str(image12[k])[4:6]),int(str(image12[k])[6:8]))
	dateimage1.append(date1)
	dateimage1.append(date2)	

for k in range(len(image21)):
	date1=datetime.date(int(str(image21[k])[0:4]),int(str(image21[k])[4:6]),int(str(image21[k])[6:8]))
	date2=datetime.date(int(str(image22[k])[0:4]),int(str(image22[k])[4:6]),int(str(image22[k])[6:8]))
	dateimage1.append(date1)
	dateimage1.append(date2)	

ALLDATEUNIQUE=set(dateimage1)

date_start=min(ALLDATEUNIQUE)-timedelta(days=30)
date_end=max(ALLDATEUNIQUE)+timedelta(days=30)
print(date_start.strftime("%Y%m%d"), date_end.strftime("%Y%m%d"))



