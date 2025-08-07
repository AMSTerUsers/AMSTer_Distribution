#!/opt/local/bin/python
# -----------------------------------------------------------------------------------------
#This script analyzes pairs of SAR images in the table All_Pairs_listing.txt computed by Prepa_MSBAS.sh
#
# It performs filtering, gap analysis, and generates various statistics
#and plots to assist in the selection of image pairs for further analysis.
#
#Parameters:
#    --input_file   : Path to the input file containing the list of image pairs.
#    --BPmax        : Maximum allowable baseline (BP) in meters.
#    --BTmax        : Maximum allowable temporal baseline (BT) in days.
#    --startdate    : Start date for analysis period (format: YYYY-MM-DD).
#    --enddate      : End date for analysis period (format: YYYY-MM-DD).
#    --gap          : Minimum gap (in days) between consecutive images to check for 
#                     large gaps. Optional.
#    --nbr          : Factor multiplier for BPmax and BTmax. Displays possible pairs 
#                     that may fall outside the main threshold. Optional.
#    --datechange   : Date after which different BP and BT values will be used 
#                     (format: YYYY-MM-DD). Optional.
#    --BP2          : New baseline (BP) value after the datechange. Optional.
#    --BT2          : New temporal baseline (BT) value after the datechange. Optional.
#
# Dependencies : python3 and modules below
#
#
#Usage:
#    python analyze_pairs.py --input_file <path_to_input_file> --BPmax <value> 
#                             --BTmax <value> --startdate <YYYY-MM-DD> 
#                             --enddate <YYYY-MM-DD> [--gap <value>] 
#                             [--nbr <value>] [--datechange <YYYY-MM-DD>] 
#                             [--BP2 <value>] [--BT2 <value>]
#
#Description:
#    This script performs the following functions:
#    - Reads the input file containing image pair details.
#    - Creates a graph based on the image pairs, applying the baseline (BP) and 
#      temporal baseline (BT) thresholds.
#    - Generates statistical summaries about the image pairs and their characteristics.
#    - Identifies and analyzes pairs that are rejected based on the thresholds.
#    - Checks for gaps larger than the specified threshold between consecutive image 
#      pairs.
#    - Creates and saves plots of BP and BT distributions and comparisons.
#
#
# New in 1.1 (20230621 - NdO):	- Rename script with starting capital letter and change shebang
# New in Distro V 2.0 20231030:	- Rename MasTer Toolbox as AMSTer Software
#								- rename Master and Slave as Primary and Secondary (though not possible in some variables and files)
# New in Distro V 2.1 20240214:	- Take new parameters GAPINDAYS and multiplier
# New in Distro V 2.2 20250115:	- Save figure as pdf
#								- ajout startdate/enddate 
# New in Distro V 2.3 20250128: - ajout optionnel date change for BPBT
# New in Distro V 2.4 20250212: - Cosmetic and improve help
#
# This script is part of the AMSTer Toolbox 
# AMSTer: SAR & InSAR Automated Mass processing Software for Multidimensional Time series
#
# DS (c) 2023/06/01 # Last modified on Feb 12, 2025
# -----------------------------------------------------------------------------------------


## import modules
import sys
import pandas as pd
from datetime import datetime
import matplotlib.pyplot as plt
import networkx as nx
import statistics as st
import numpy as np
import matplotlib.dates as dates
import os
import argparse

## Parameters
parser = argparse.ArgumentParser(description="Filter data based on thresholds and a date of change.")
parser.add_argument("--input_file", type=str, required=True, help="Path to the input file")
parser.add_argument("--BPmax", type=float, required=True, help="Maximum threshold for BP")
parser.add_argument("--BTmax", type=float, required=True, help="Maximum threshold for BT")
parser.add_argument("--startdate", type=str, required=True, help="Start date (format YYYY-MM-DD)")
parser.add_argument("--enddate", type=str, required=True, help="End date (format YYYY-MM-DD)")
parser.add_argument("--gap", type=int, default=None, help="Gap (days) threshold to check")
parser.add_argument("--nbr", type=float, default=None, help="Factor criteria to restrict display of possible additional pairs")
parser.add_argument("--datechange", type=str, default=None, help="Optional date of change for BP/BT (format YYYY-MM-DD)")
parser.add_argument("--BP2", type=float, default=None, help="New BP after datechange")
parser.add_argument("--BT2", type=float, default=None, help="New BT after datechange")

args = parser.parse_args()

# Parse and validate dates
try:
    startdate = datetime.strptime(args.startdate, "%Y-%m-%d").date()
    enddate = datetime.strptime(args.enddate, "%Y-%m-%d").date()
except ValueError:
    raise ValueError("Start date and end date must be in the format YYYY-MM-DD.")
if startdate > enddate:
    raise ValueError("Start date must be earlier than or equal to end date.")

date_change = None
if args.datechange: 
	if args.datechange is not None and args.datechange.lower() != "none":
		try:
		    date_change = datetime.strptime(args.datechange, "%Y-%m-%d").date()
		except ValueError:
		    raise ValueError("Date of change must be in the format YYYY-MM-DD.")
	
BP2 = None
BT2 = None
if args.BP2:
	BP2=args.BP2
if args.BT2:
	BT2=args.BT2
	
inputfile_path =args.input_file
BPmax = args.BPmax
BTmax = args.BTmax
GAPINDAYS = args.gap
nbr=args.nbr # factor criteria to restrict the display of possible additional pairs

plotfig=1

filename = os.path.basename(inputfile_path)
output_dir = os.path.dirname(inputfile_path)
filename_pdf = filename.replace(".txt", ".pdf")
filename_pdf2 = filename_pdf.replace("all", "restrictdate")
filename_pdf3 = filename_pdf.replace("allPairs", "Nodes")
filename_pdf4 = filename_pdf.replace("allPairs", "Gap")
## Start
print(" ")
print("Analyse ", inputfile_path)
print("BTmax = ", BTmax, "days and BPmax = ", BPmax, "meters")
if args.datechange:
	if args.datechange is not None and args.datechange.lower() != "none":
			print("After ",date_change, "BTmax = ", BT2, "days and BPmax = ", BP2, "meters")
print(" ")

## Load data
df = pd.read_csv(inputfile_path, delimiter=' ', header=6, skipinitialspace=True	)
#print(df)
image1=df.iloc[:,0]	
image2=df.iloc[:,1]
BP=df.iloc[:,7]
BT=df.iloc[:,8]

## convert date format
pairs=[]
dateimage1=[]
dateimage2=[]
for k in range(len(image1)):
	pairs.append("_".join([str(image1[k]), str(image2[k])]))
	date1 = datetime(int(str(image1[k])[0:4]), int(str(image1[k])[4:6]), int(str(image1[k])[6:8])).date()
	date2 = datetime(int(str(image2[k])[0:4]), int(str(image2[k])[4:6]), int(str(image2[k])[6:8])).date()
	dateimage1.append(date1)
	dateimage2.append(date2)	
PAIRS = pd.Series(pairs)
DATE1 = pd.Series(dateimage1)
DATE2 = pd.Series(dateimage2)



## Create Graph with all pairs
G=nx.DiGraph()
for k in range(len(image1)):
	G.add_edge(image1[k],image2[k],bt=BT[k], bp=BP[k])
print('Graph of all pairs created')	
print('Number of nodes: ',G.number_of_nodes())
print('Number of edges: ',G.number_of_edges())
print(" ")

## Create Graph with startdate/enddate
Gdate=nx.DiGraph()
for k in range(len(image1)):
	if (dateimage1[k] >= startdate and dateimage2[k] >= startdate) and (dateimage1[k] <= enddate and dateimage2[k]<= enddate) :
		Gdate.add_edge(image1[k],image2[k],bt=BT[k], bp=BP[k])

print('Graph satifying dates criteria created')	
print('Number of nodes: ',Gdate.number_of_nodes())
print('Number of edges: ',Gdate.number_of_edges())
print(" ")

## Create Graph with BT-BP ok and startdate/enddate
Greduce=nx.DiGraph()
for k in range(len(image1)):
	if args.datechange:
		if args.datechange is not None and args.datechange.lower() != "none":
			if ((abs(BT[k]) <= int(BTmax) ) and (abs(BP[k]) <= int(BPmax)) and (dateimage1[k] >= startdate and dateimage2[k] >= startdate) and (dateimage1[k] <= date_change and dateimage2[k]<= date_change) ) or((abs(BT[k]) <= int(BT2) ) and (abs(BP[k]) <= int(BP2)) and (dateimage1[k] >= date_change and dateimage2[k] >= date_change) and (dateimage1[k] <= enddate and dateimage2[k]<= enddate) ):
				Greduce.add_edge(image1[k],image2[k],bt=BT[k], bp=BP[k])
		else:
			if (abs(BT[k]) <= int(BTmax) ) and (abs(BP[k]) <= int(BPmax)) and (dateimage1[k] >= startdate and dateimage2[k] >= startdate) and (dateimage1[k] <= enddate and dateimage2[k]<= enddate) :
				Greduce.add_edge(image1[k],image2[k],bt=BT[k], bp=BP[k])
		
	else:
		if (abs(BT[k]) <= int(BTmax) ) and (abs(BP[k]) <= int(BPmax)) and (dateimage1[k] >= startdate and dateimage2[k] >= startdate) and (dateimage1[k] <= enddate and dateimage2[k]<= enddate) :
			Greduce.add_edge(image1[k],image2[k],bt=BT[k], bp=BP[k])
print('Graph satifying both criteria created')	
print('Number of nodes: ',Greduce.number_of_nodes())
print('Number of edges: ',Greduce.number_of_edges())
print(" ")
	
## Some Stats
Nodein=[]
Nodeout=[]
Bt=[]
Bp=[]
Bpneg=[]
listnodein0=[]
listnodeout0=[]
listdatenode=[]
listdateallnodes=[]
for N in Gdate.nodes():	
	datenode=datetime(int(str(N)[0:4]),int(str(N)[4:6]),int(str(N)[6:8])).date()
	listdateallnodes.append(datenode)
for N in Greduce.nodes():
	nodein=Greduce.in_degree(N)
	nodeout=Greduce.out_degree(N)
	datenode=datetime(int(str(N)[0:4]),int(str(N)[4:6]),int(str(N)[6:8])).date()
	Nodein.append(nodein)
	Nodeout.append(nodeout)
	listdatenode.append(datenode)
	if nodein == 0:
		listnodein0.append(N)
	if nodeout == 0:
		listnodeout0.append(N)
print("node IN degree =0")
print(listnodein0)
print("node OUT degree =0")
print(listnodeout0)

listdatenode1date=[]
listdatenode2date=[]
Btdate=[]
Bpdate=[]
Bpnegdate=[]

for (N1,N2,W) in Gdate.edges(data=True):		
	bt=G[N1][N2]["bt"]
	bp=G[N1][N2]["bp"]
	datenode1=datetime(int(str(N1)[0:4]),int(str(N1)[4:6]),int(str(N1)[6:8])).date()
	datenode2=datetime(int(str(N2)[0:4]),int(str(N2)[4:6]),int(str(N2)[6:8])).date()
	listdatenode1date.append(datenode1)
	listdatenode2date.append(datenode2)
	Btdate.append(abs(bt))
	Bpdate.append(abs(bp))	
	Bpnegdate.append(bp)

listdatenode1=[]
listdatenode2=[]
for (N1,N2,W) in Greduce.edges(data=True):		
	bt=Gdate[N1][N2]["bt"]
	bp=Gdate[N1][N2]["bp"]
	datenode1=datetime(int(str(N1)[0:4]),int(str(N1)[4:6]),int(str(N1)[6:8])).date()
	datenode2=datetime(int(str(N2)[0:4]),int(str(N2)[4:6]),int(str(N2)[6:8])).date()
	listdatenode1.append(datenode1)
	listdatenode2.append(datenode2)
	Bt.append(abs(bt))
	Bp.append(abs(bp))	
	Bpneg.append(bp)	

print(" ")
print("Stastistics")
print ('Indegree : Mean =', st.mean(Nodein), '; Min =', np.min(Nodein), '; Max =', np.max(Nodein))
print ('Outdegree: Mean =', st.mean(Nodeout), '; Min =', np.min(Nodeout), '; Max =', np.max(Nodeout))
print ('BT : Mean =', st.mean(Bt), '; Min =', np.min(Bt), ' ;Max =', np.max(Bt))
print ('BP : Mean =', st.mean(Bp), '; Min =', np.min(Bp), '; Max =', np.max(Bp))
print(" ")


## Check rejected images 
if Greduce.number_of_nodes() < Gdate.number_of_nodes() :
	list_1=Gdate.nodes()
	list_2=Greduce.nodes()
	imagesnotintableBTBP=list(set(list_1).difference(list_2))
	print(len(imagesnotintableBTBP), "images are discarded due to too restrictive baselines criteria:", imagesnotintableBTBP)
	print ("Consider adding pairs satifying one of both criteria and less than", nbr ,"times the second to a table of additional pairs to avoid discarding thoses images")
	print ("Such possible pairs are :")
	for k in range(len(imagesnotintableBTBP)):
		print(" ")
		print("Image ",imagesnotintableBTBP[k])
		listpred=list(Gdate.predecessors (imagesnotintableBTBP[k]))
		listsucc=list(Gdate.successors (imagesnotintableBTBP[k]))
		imagesBTok=[]
		imagesBPok=[]
		for l in range(len(listpred)):
			bt=(Gdate[listpred[l]][imagesnotintableBTBP[k]]["bt"])
			bp=(Gdate[listpred[l]][imagesnotintableBTBP[k]]["bp"])
			if (abs(bt) < int(BTmax)) & (abs(bp) < int(BPmax)*nbr):
				imagesBTok.append(Gdate[listpred[l]]) 
				print("pair with ",listpred[l],"has BT=",Gdate[listpred[l]][imagesnotintableBTBP[k]]["bt"],"<",BTmax," days and BP=" ,Gdate[listpred[l]][imagesnotintableBTBP[k]]["bp"]," meters")
			if (abs(bp) < int(BPmax)) &  (abs(bt) < int(BTmax)*nbr):
				imagesBPok.append(Gdate[listpred[l]]) 
				print("pair with ",listpred[l],"has BT=",Gdate[listpred[l]][imagesnotintableBTBP[k]]["bt"],"days and BP=",Gdate[listpred[l]][imagesnotintableBTBP[k]]["bp"],"<",BPmax," meters")
		for l in range(len(listsucc)):
			bt=Gdate[imagesnotintableBTBP[k]][listsucc[l]]["bt"]
			bp=Gdate[imagesnotintableBTBP[k]][listsucc[l]]["bp"]
			if (abs(bt) < int(BTmax)) & (abs(bp) < int(BPmax)*nbr):
				imagesBTok.append(Gdate[listsucc[l]]) 
				print("pair with ",listsucc[l],"has BT=",Gdate[imagesnotintableBTBP[k]][listsucc[l]]["bt"],"<",BTmax," days and BP=" ,Gdate[imagesnotintableBTBP[k]][listsucc[l]]["bp"]," meters")
			if (abs(bp) < int(BPmax)) &  (abs(bt) < int(BTmax)*nbr):
				imagesBPok.append(Gdate[listsucc[l]]) 
				print("pair with ",listsucc[l],"has BT=",Gdate[imagesnotintableBTBP[k]][listsucc[l]]["bt"],"days and BP" ,Gdate[imagesnotintableBTBP[k]][listsucc[l]]["bp"],"<", BPmax," meters")

## Check gaps in BT
listdatenodesorted = sorted(listdatenode)
timedeltas = [listdatenodesorted[i] - listdatenodesorted[i-1] for i in range(1, len(listdatenodesorted))]
td=[]
for x in range(0,len(timedeltas)):
	td.append(timedeltas[x].total_seconds()/(24*60*60) )
print(" ")
print("Searching for the largest gap between consecutive images")
print("Max BT between consecutive images is ", np.max(td),"between ", listdatenodesorted[timedeltas.index(np.max(timedeltas))],"and ",listdatenodesorted[timedeltas.index(np.max(timedeltas))+1] )

listdatenodesortedall = sorted(listdateallnodes)
timedeltasall = [listdatenodesortedall[i] - listdatenodesortedall[i-1] for i in range(1, len(listdatenodesortedall))]
tdall=[]
for x in range(0,len(timedeltasall)):
	tdall.append(timedeltasall[x].total_seconds()/(24*60*60) )
print(" ")
print("Searching for gaps over", GAPINDAYS," days between consecutive images")

countgap=0
for  x in range(0, len(tdall)):
	if tdall[x]>GAPINDAYS	:
		print("BT between consecutive images is",tdall[x], "days between ", listdatenodesortedall[x],"and ",listdatenodesortedall[x+1] )
		countgap=countgap+1
if countgap == 0:
	print("No GAP bigger than",GAPINDAYS," days found")

## PLOTS 

if plotfig==1:

	fig, ((ax1, ax2, ax3)) = plt.subplots(3, 1, figsize=(18, 10))
	ax1.plot(BT, BP ,'ko', label='All possible pairs')
	ax1.plot(Btdate, Bpnegdate,'go', label='restrict to start/end')
	ax1.plot(Bt, Bpneg,'bo', label='restrict to BTmax,BPmax')
	ax1.axvline(x=int(BTmax), color='red', linestyle='--')
	ax1.axhline(y=int(BPmax), color='red', linestyle='--')
	ax1.axhline(y=-int(BPmax), color='red', linestyle='--')
	if args.datechange:
		if args.datechange is not None and args.datechange.lower() != "none":
			ax1.axvline(x=int(BT2), color='orange', linestyle='--')
			ax1.axhline(y=int(BP2), color='orange', linestyle='--')
			ax1.axhline(y=-int(BP2), color='orange', linestyle='--')	
	ax1.set_xlabel('BT(days)')
	ax1.set_ylabel('BP(m)')
	ax1.legend()

	ax2.plot(DATE1,BT,'ko')
	ax2.plot(listdatenode1date,Btdate,'go', label='restrict to start/end')
	ax2.plot(listdatenode1,Bt,'bo')	
	ax2.axhline(y=int(BTmax), color='red', linestyle='--')
	ax2.axvline(x=startdate, color='red', linestyle='--', label=f"Start Date: {startdate.strftime('%Y-%m-%d')}")
	ax2.axvline(x=enddate, color='red', linestyle='--', label=f"End Date: {enddate.strftime('%Y-%m-%d')}")
	if args.datechange:
		if args.datechange is not None and args.datechange.lower() != "none":
			ax2.axhline(y=int(BT2), color='orange', linestyle='--')
			ax2.axvline(x=date_change, color='orange', linestyle='--', label=f"Change Date: {date_change.strftime('%Y-%m-%d')}")
	ax2.set_xlabel('Date')
	ax2.set_ylabel('BT(days)')

	ax3.plot(DATE1,BP,'ko')
	ax3.plot(listdatenode1date,Bpnegdate,'go')
	ax3.plot(listdatenode1,Bpneg,'bo')
	ax3.axvline(x=startdate, color='red', linestyle='--', label=f"Start Date: {startdate.strftime('%Y-%m-%d')}")
	ax3.axvline(x=enddate, color='red', linestyle='--', label=f"End Date: {enddate.strftime('%Y-%m-%d')}")
	ax3.axhline(y=int(BPmax), color='red', linestyle='--')
	ax3.axhline(y=-int(BPmax), color='red', linestyle='--')
	if args.datechange:
		if args.datechange is not None and args.datechange.lower() != "none":
			ax3.axvline(x=date_change, color='orange', linestyle='--', label=f"Change Date: {date_change.strftime('%Y-%m-%d')}")
			ax3.axhline(y=int(BP2), color='orange', linestyle='--')
			ax3.axhline(y=-int(BP2), color='orange', linestyle='--')
	
	ax3.set_xlabel('Date')
	ax3.set_ylabel('BP(m)')

	os.makedirs(output_dir, exist_ok=True)
	output_path = os.path.join(output_dir,filename_pdf)
	plt.savefig(output_path)



	fig, ((ax1, ax2, ax3)) = plt.subplots(3, 1, figsize=(18, 10))
	ax1.plot(Btdate, Bpnegdate,'go', label='restrict to start/end')
	ax1.plot(Bt, Bpneg,'bo', label='restrict to BTmax,BPmax')
	ax1.axvline(x=int(BTmax), color='red', linestyle='--')
	ax1.axhline(y=int(BPmax), color='red', linestyle='--')
	ax1.axhline(y=-int(BPmax), color='red', linestyle='--')
	if args.datechange:
		if args.datechange is not None and args.datechange.lower() != "none":
			ax1.axvline(x=int(BT2), color='orange', linestyle='--')
			ax1.axhline(y=int(BP2), color='orange', linestyle='--')
			ax1.axhline(y=-int(BP2), color='orange', linestyle='--')
	ax1.set_xlabel('BT(days)')
	ax1.set_ylabel('BP(m)')
	ax1.legend()

	ax2.plot(listdatenode1date,Btdate,'go', label='restrict to start/end')
	ax2.plot(listdatenode1,Bt,'bo')
	ax2.axvline(x=startdate, color='red', linestyle='--', label=f"Start Date: {startdate.strftime('%Y-%m-%d')}")
	ax2.axvline(x=enddate, color='red', linestyle='--', label=f"End Date: {enddate.strftime('%Y-%m-%d')}")
	ax2.axhline(y=int(BTmax), color='red', linestyle='--')
	if args.datechange:
		if args.datechange is not None and args.datechange.lower() != "none":
			ax2.axhline(y=int(BT2), color='orange', linestyle='--')
			ax2.axvline(x=date_change, color='orange', linestyle='--', label=f"Change Date: {date_change.strftime('%Y-%m-%d')}")
	ax2.set_xlabel('Date')
	ax2.set_ylabel('BT(days)')
	
	ax3.plot(listdatenode1date,Bpnegdate,'go')
	ax3.plot(listdatenode1,Bpneg,'bo')
	ax3.axvline(x=startdate, color='red', linestyle='--', label=f"Start Date: {startdate.strftime('%Y-%m-%d')}")
	ax3.axvline(x=enddate, color='red', linestyle='--', label=f"End Date: {enddate.strftime('%Y-%m-%d')}")
	ax3.axhline(y=int(BPmax), color='red', linestyle='--')
	ax3.axhline(y=-int(BPmax), color='red', linestyle='--')
	if args.datechange:
		if args.datechange is not None and args.datechange.lower() != "none":
			ax3.axvline(x=date_change, color='orange', linestyle='--', label=f"Change Date: {date_change.strftime('%Y-%m-%d')}")
			ax3.axhline(y=int(BP2), color='orange', linestyle='--')
			ax3.axhline(y=-int(BP2), color='orange', linestyle='--')
	ax3.set_xlabel('Date')
	ax3.set_ylabel('BP(m)')
	
	os.makedirs(output_dir, exist_ok=True)
	output_path = os.path.join(output_dir,filename_pdf2)
	plt.savefig(output_path)
	#plt.show() # affiche la figure  l'cran



# First figure
fig1, ax1 = plt.subplots(figsize=(10, 6))  # Set the size for the first figure
bar_width = 3.6
ax1.bar(listdatenode, Nodein, color='cyan', label='In Degree', width=bar_width)
ax1.bar(listdatenode, Nodeout, bottom=Nodein, color='purple', label='Out Degree', width=bar_width)

ax1.axvline(x=startdate, color='red', linestyle='--', label=f"Start Date: {startdate.strftime('%Y-%m-%d')}")
ax1.axvline(x=enddate, color='red', linestyle='--', label=f"End Date: {enddate.strftime('%Y-%m-%d')}")
if args.datechange:
    if args.datechange is not None and args.datechange.lower() != "none":
        ax1.axvline(x=date_change, color='orange', linestyle='--', label=f"Change Date: {date_change.strftime('%Y-%m-%d')}")

# Set axis labels and title with increased font size
ax1.set_xlabel('Date', fontsize=14)  # Increase font size for x-axis label
ax1.set_ylabel('Degree', fontsize=14)  # Increase font size for y-axis label
ax1.legend(loc='best', fontsize=12)  # Increase font size for legend

# Increase font size for axis ticks
ax1.tick_params(axis='both', labelsize=12)  # Increase font size for axis ticks (numbers)

# Save the first figure
os.makedirs(output_dir, exist_ok=True)
output_path1 = os.path.join(output_dir, filename_pdf3)
fig1.savefig(output_path1)

# Second figure
fig2, ax4 = plt.subplots(figsize=(10, 6))  # Set the size for the second figure
ax4.scatter(listdatenodesortedall[1::], tdall)
ax4.axvline(x=startdate, color='red', linestyle='--', label=f"Start Date: {startdate.strftime('%Y-%m-%d')}")
if args.datechange:
    if args.datechange is not None and args.datechange.lower() != "none":
        ax4.axvline(x=date_change, color='orange', linestyle='--', label=f"Change Date: {date_change.strftime('%Y-%m-%d')}")
ax4.axvline(x=enddate, color='red', linestyle='--', label=f"End Date: {enddate.strftime('%Y-%m-%d')}")
ax4.set_xlabel('Date', fontsize=14)  # Increase font size for x-axis label
ax4.set_ylabel('Delta T between consecutive images (days)', fontsize=14)  # Increase font size for y-axis label
ax4.legend(loc='upper right', fontsize=12)  # Increase font size for legend

# Increase font size for axis ticks
ax4.tick_params(axis='both', labelsize=12)  # Increase font size for axis ticks (numbers)

# Save the second figure
output_path2 = os.path.join(output_dir, filename_pdf4)
fig2.savefig(output_path2)
#plt.show()

