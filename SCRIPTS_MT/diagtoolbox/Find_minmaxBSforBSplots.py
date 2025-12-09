#!/opt/local/amster_python_env/bin/python
# Function to find common baseline span to both table.txt files
# It add a delay of 10m before the first value and after the last for plot purposes 
#
# New in Distro V 1.0.1 20240209:  - Cosmetic
# New in Distro V 2.0 20250813:	- launched from python3 venv
#
#
# AMSTer: SAR & InSAR Automated Mass processing Software for Multidimensional Time series
# Delphine Smittarello (c) 2024/02/09 - could make better with more functions... when time.
# -----------------------------------------------------------------------------------------

## import modules
import sys
import pandas as pd
import math

## Parameters
inputfile1 = sys.argv[1]
inputfile2 = sys.argv[2]

## Load data
df = pd.read_csv(inputfile1, delimiter=' ', header=0, skipinitialspace=True)
image1=df.iloc[:,0]	
BP1=df.iloc[:,6]
DBP1=df.iloc[:,7]

## Load data
df = pd.read_csv(inputfile2, delimiter=' ', header=0, skipinitialspace=True)
image2=df.iloc[:,0]	
BP2=df.iloc[:,6]
DBP2=df.iloc[:,7]

BP=[]
for k in range(len(image1)):
	BP.append(BP1[k])	
	BP.append(BP1[k]+DBP1[k])	
for k in range(len(image2)):
	BP.append(BP2[k])	
	BP.append(BP2[k]+DBP2[k])	

ALLBPUNIQUE=set(BP)

BP_min=min(ALLBPUNIQUE)
BP_max=max(ALLBPUNIQUE)
print(math.floor(BP_min)-10,math.ceil(BP_max)+10 )


