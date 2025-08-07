#!/opt/local/bin/python
# -----------------------------------------------------------------------------------------
# This script aims at displays some stats after a BaselineCohTable
# Parameter : Baseline_Coh_table_{kml}.txt
# Dependencies : python3  and modules see import below 
#
#
# New in 1.1 (20230621 - NdO):	- Rename script with starting capital letter and change shebang
# New in Distro V 2.0 20231030:	- Rename MasTer Toolbox as AMSTer Software
#								- rename Master and Slave as Primary and Secondary (though not possible in some variables and files)
# New in Distro V 2.1 20250130:	- Add Plot saving and make show as an hard coded option
#								- add coh threshold as a parameter and in plots
# New in Distro V2.2 20250306	- Add label to boxplot
# This script is part of the AMSTer Toolbox 
# AMSTer: SAR & InSAR Automated Mass processing Software for Multidimensional Time series
#
# DS (c) 2023/06/01 
# -----------------------------------------------------------------------------------------

import sys
import numpy as np
import pandas as pd
import matplotlib.pyplot as plt
import datetime
import os
from scipy.stats import kurtosis

inputfile_path = sys.argv[1]
coh_th = float(sys.argv[2])

displayplot = 0
plotfig=1

VER="Distro V2.0 AMSTer script utilities"
AUT="Delphine Smittarello (c)2016-2019, Last modified on Jan 30, 2025"
print(VER)
print(AUT)

print(" ")
print("Analyse ", inputfile_path)
print("Coherence Threshold =", coh_th)
df = pd.read_csv(inputfile_path, delimiter='\t', header=None)

image1=df[0]
image2=df[1]
BP=df[2]
BT=abs(df[3])
COH=df[4]

coh_length = len(COH)
COH_keep=len(COH[COH>=coh_th])
COH_reject=len(COH[COH<coh_th])

print(coh_length," pairs available for statistics")
print(f"{COH_keep}, pairs with coherence above {coh_th} ({COH_keep/coh_length*100:.2f}%)")	
print(f"{COH_reject}, pairs with coherence below {coh_th} ({COH_reject/coh_length*100:.2f}%)")	

## Functions
def Stats_distrib(data):
		
	data = np.array(data)
	
	# Description statistique
	mean = np.mean(data)  # Moyenne
	median = np.median(data)  # Médiane
	std_dev = np.std(data)  # Écart-type
	cv = std_dev / mean  # Coefficient de variation
	kurt = kurtosis(data, fisher=True)  # Kurtosis (par défaut méthode de Fisher)
	
	q1 = np.percentile(data, 25)  # 1er quartile
	q3 = np.percentile(data, 75)  # 3e quartile
	iqr = q3 - q1  # Intervalle interquartile (IQR)
	
	# Limites pour détecter les outliers (méthode IQR)
	lower_bound = q1 - 1.5 * iqr
	upper_bound = q3 + 1.5 * iqr
	
	# Détection des outliers
	outliers_iqr = data[(data < lower_bound)]
		
	# Résultats
	print("Mean:", mean)
	print("Median:", median)
	print("Standard deviation:", std_dev)
	print("Q1 (1st quartile):", q1)
	print("Q3 (3rd quartile):", q3)
	print("IQR:", iqr)
	print("IQR Lower Bound:", lower_bound)
	print("IQR upper Bound:", upper_bound)
	print("Outliers number:", len(outliers_iqr))
	
	# Boxplot pour visualisation
	plt.boxplot(data, vert=False,showmeans=True, meanline=True)
	plt.xlabel("Coherence")
	plt.title("Box Plot")
	
	#plt.show()
	
		
	return lower_bound, upper_bound, outliers_iqr, mean, median, std_dev, q1, q3

def scatter_with_filter(ax, x, y, coh, xlabel, ylabel):
    """
    Scatter plot with filled markers for coh >= threshold and empty markers for coh < threshold.
    """
    mask = coh >= coh_th
    ax.scatter(x[mask], y[mask], c=coh[mask], label="Above threshold")
    ax.scatter(x[~mask], y[~mask], facecolors='none', edgecolors='red', label="Below threshold")
    if ylabel.lower() == 'coherence':
        ax.axhline(y=coh_th, color='red', linestyle='--', label=f"Coherence Threshold")
    ax.set_xlabel(xlabel)
    ax.set_ylabel(ylabel)
    ax.legend()



###### MAIN 
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


outputfile_path = inputfile_path.replace("kml.txt", "pdf")
stats_outputfile_path = inputfile_path.replace("kml.txt", "boxplot.pdf")
stats2_outputfile_path = inputfile_path.replace("kml.txt", "stats.pdf")

## PLOTS 1
if plotfig == 1:
    iqr_lower_bound, iqr_upper_bound, outliers_iqr, coh_mean, coh_median, coh_std_dev, q1, q3 = Stats_distrib(COH)
    plt.axvline(x=coh_th, color='red', linestyle='-', label=f"Coherence Threshold ({coh_th:.3f})")
    plt.legend()
    plt.savefig(stats_outputfile_path)


COH_out=COH[COH<iqr_lower_bound]
pairs_out=PAIRS[COH<iqr_lower_bound]
dateimage1_out=DATE1[COH<iqr_lower_bound]
dateimage2_out=DATE2[COH<iqr_lower_bound]
BP_out=BP[COH<iqr_lower_bound]
BT_out=BT[COH<iqr_lower_bound]
for pairdate, coh_val, bp_val, bt_val in zip(pairs_out, COH_out, BP_out, BT_out):
	print(f"Pair : {pairdate} , Coh = {coh_val}, BP={bp_val}m, BT={bt_val}days")


if plotfig == 1:
	## PLOTS 2
    fig1, ((ax1, ax2, ax3), (ax4, ax5, ax6), (ax7, ax8, ax9)) = plt.subplots(3, 3, figsize=(18, 10))
    scatter_with_filter(ax1, BT, COH, COH, 'BT(days)', 'Coherence')
    scatter_with_filter(ax2, BP, COH, COH, 'BP(m)', 'Coherence')
    scatter_with_filter(ax3, BT, BP, COH, 'BT(days)', 'BP(m)')
    scatter_with_filter(ax4, DATE1, COH, COH, 'Date Im1', 'Coherence')
    scatter_with_filter(ax5, DATE2, COH, COH, 'Date Im2', 'Coherence')
    scatter_with_filter(ax6, DATE1, DATE2, COH, 'Date Im1', 'Date Im2')
    scatter_with_filter(ax7, DOY1, COH, COH, 'Day of Year Im1', 'Coherence')
    scatter_with_filter(ax8, DOY2, COH, COH, 'Day of Year Im2', 'Coherence')
    scatter_with_filter(ax9, DOY1, DOY2, COH, 'Day of Year Im1', 'Day of Year Im2')
    plt.tight_layout()
    plt.savefig(outputfile_path)

    if displayplot:
        plt.show()

  
	## PLOTS 3

if plotfig == 1:        
    fig2, ax_stats = plt.subplots(figsize=(8, 6))
    ax_stats.hist(COH, bins=min(int(coh_length/10),200), color='blue', alpha=0.7, edgecolor='black')
    ax_stats.axvline(x=coh_mean, color='green', linestyle='--', label=f"Mean Coherence ({coh_mean:.3f})")
    ax_stats.axvline(x=coh_median, color='orange', linestyle='-', label=f"Median Coherence ({coh_median:.3f})")
    ax_stats.axvline(x=iqr_lower_bound, color='purple', linestyle=':', label=f"IQR Low ({iqr_lower_bound:.3f})")
    ax_stats.axvline(x=iqr_upper_bound, color='brown', linestyle=':', label=f"IQR Up({iqr_upper_bound:.3f})")
    ax_stats.axvline(x=q1, color='cyan', linestyle='--', label=f"25th Percentile ({iqr_lower_bound:.3f})")
    ax_stats.axvline(x=q3, color='magenta', linestyle='--', label=f"75th Percentile ({iqr_upper_bound:.3f})")
    ax_stats.axvline(x=coh_th, color='red', linestyle='-', label=f"Coherence Threshold ({coh_th:.3f})")
    ax_stats.set_title("Coherence Statistics")
    ax_stats.set_xlabel("Coherence")
    ax_stats.set_ylabel("Frequency")
    ax_stats.legend()

    plt.tight_layout()
    plt.savefig(stats2_outputfile_path)

    if displayplot:
        plt.show()