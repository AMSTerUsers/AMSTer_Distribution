#!/opt/local/bin/python
# -----------------------------------------------------------------------------------------
# This script aims at displays some stats based on the list of pairs provided as 
# Table All_Pairs_listing.txt computed by Prepa_MSBAS.sh
#
# Parameter :  - Pathto/allPairsListing.txt input file
#			   - BPmax (m)
#			   - BTmax (days)
# 			   - GAPINDAYS (days) : script will check if there are gaps larger than GAPINDAYS between two images used
#			   - factor (int) : multiplier for BPmax and BTmax to display possible aditional pairs (could be 2 or 3 )
#
# Dependencies : python3 in env and modules below
#
# New in 1.1 (20230621 - NdO):	- Rename script with starting capital letter and change shebang
# New in Distro V 2.0 20231030:	- Rename MasTer Toolbox as AMSTer Software
#								- rename Master and Slave as Primary and Secondary (though not possible in some variables and files)
# New in Distro V 2.1 20240214:	- Take new parameters GAPINDAYS and multiplier
#
# This script is part of the AMSTer Toolbox 
# AMSTer: SAR & InSAR Automated Mass processing Software for Multidimensional Time series
#
# DS (c) 2023/06/01 # Last modified on Feb 14, 2024
# -----------------------------------------------------------------------------------------

## import modules
import sys
import pandas as pd
import datetime
import matplotlib.pyplot as plt
import networkx as nx
import statistics as st
import numpy as np
import matplotlib.dates as dates


## Script version
VER="Distro V2.1 AMSTer script utilities"
AUT="Delphine Smittarello (c)2016-2019, Last modified on Feb 14, 2024"
print(VER)
print(AUT)


## Parameters
inputfile_path = sys.argv[1]
BPmax = sys.argv[2]
BTmax = sys.argv[3]
GAPINDAYS = int(sys.argv[4])
## hard coded 
nbr=int(sys.argv[5]) # factor criteria to restrict the display of possible additional pairs


## Start
print(" ")
print("Analyse ", inputfile_path)
print("BTmax = ", BTmax, "days and BPmax = ", BPmax, "meters")
print(" ")

## Load data
df = pd.read_csv(inputfile_path, delimiter=' ', header=6, skipinitialspace=True	)
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
	date1=datetime.date(int(str(image1[k])[0:4]),int(str(image1[k])[4:6]),int(str(image1[k])[6:8]))
	date2=datetime.date(int(str(image2[k])[0:4]),int(str(image2[k])[4:6]),int(str(image2[k])[6:8]))
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
	
## Create Graph with BT-BP ok
Greduce=nx.DiGraph()
for k in range(len(image1)):
	if (abs(BT[k]) <= int(BTmax) ) & (abs(BP[k]) <= int(BPmax)):
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
for N in G.nodes():	
	datenode=datetime.date(int(str(N)[0:4]),int(str(N)[4:6]),int(str(N)[6:8]))
	listdateallnodes.append(datenode)
for N in Greduce.nodes():
	nodein=Greduce.in_degree(N)
	nodeout=Greduce.out_degree(N)
	datenode=datetime.date(int(str(N)[0:4]),int(str(N)[4:6]),int(str(N)[6:8]))
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

listdatenode1=[]
listdatenode2=[]
for (N1,N2,W) in Greduce.edges(data=True):		
	bt=G[N1][N2]["bt"]
	bp=G[N1][N2]["bp"]
	datenode1=datetime.date(int(str(N1)[0:4]),int(str(N1)[4:6]),int(str(N1)[6:8]))
	datenode2=datetime.date(int(str(N2)[0:4]),int(str(N2)[4:6]),int(str(N2)[6:8]))
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
if Greduce.number_of_nodes() < G.number_of_nodes() :
	list_1=G.nodes()
	list_2=Greduce.nodes()
	imagesnotintableBTBP=list(set(list_1).difference(list_2))
	print(len(imagesnotintableBTBP), "images are discarded due to too restrictive baselines criteria:", imagesnotintableBTBP)
	print ("Consider adding pairs satifying one of both criteria and less than", nbr ,"times the second to a table of additional pairs to avoid discarding thoses images")
	print ("Such possible pairs are :")
	for k in range(len(imagesnotintableBTBP)):
		print(" ")
		print("Image ",imagesnotintableBTBP[k])
		listpred=list(G.predecessors (imagesnotintableBTBP[k]))
		listsucc=list(G.successors (imagesnotintableBTBP[k]))
		imagesBTok=[]
		imagesBPok=[]
		for l in range(len(listpred)):
			bt=(G[listpred[l]][imagesnotintableBTBP[k]]["bt"])
			bp=(G[listpred[l]][imagesnotintableBTBP[k]]["bp"])
			if (abs(bt) < int(BTmax)) & (abs(bp) < int(BPmax)*nbr):
				imagesBTok.append(G[listpred[l]]) 
				print("pair with ",listpred[l],"has BT=",G[listpred[l]][imagesnotintableBTBP[k]]["bt"],"<",BTmax," days and BP=" ,G[listpred[l]][imagesnotintableBTBP[k]]["bp"]," meters")
			if (abs(bp) < int(BPmax)) &  (abs(bt) < int(BTmax)*nbr):
				imagesBPok.append(G[listpred[l]]) 
				print("pair with ",listpred[l],"has BT=",G[listpred[l]][imagesnotintableBTBP[k]]["bt"],"days and BP=",G[listpred[l]][imagesnotintableBTBP[k]]["bp"],"<",BPmax," meters")
		for l in range(len(listsucc)):
			bt=G[imagesnotintableBTBP[k]][listsucc[l]]["bt"]
			bp=G[imagesnotintableBTBP[k]][listsucc[l]]["bp"]
			if (abs(bt) < int(BTmax)) & (abs(bp) < int(BPmax)*nbr):
				imagesBTok.append(G[listsucc[l]]) 
				print("pair with ",listsucc[l],"has BT=",G[imagesnotintableBTBP[k]][listsucc[l]]["bt"],"<",BTmax," days and BP=" ,G[imagesnotintableBTBP[k]][listsucc[l]]["bp"]," meters")
			if (abs(bp) < int(BPmax)) &  (abs(bt) < int(BTmax)*nbr):
				imagesBPok.append(G[listsucc[l]]) 
				print("pair with ",listsucc[l],"has BT=",G[imagesnotintableBTBP[k]][listsucc[l]]["bt"],"days and BP" ,G[imagesnotintableBTBP[k]][listsucc[l]]["bp"],"<", BPmax," meters")

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

for  x in range(0, len(tdall)):
	if tdall[x]>GAPINDAYS	:
		print("BT between consecutive images is",tdall[x], "days between ", listdatenodesortedall[x],"and ",listdatenodesortedall[x+1] )
## PLOTS 
plotfig=1
if plotfig==1:

	fig, ((ax1, ax2, ax3),(ax4, ax5, ax6),(ax7, ax8, ax9)) = plt.subplots(3, 3)
	ax1.plot(BT, BP ,'ko', label='All possible pairs')
	ax1.plot(Bt, Bpneg,'bo', label='restrict to BTmax,BPmax')
	ax1.set_xlabel('BT(days)')
	ax1.set_ylabel('BP(m)')
	ax1.legend()

	ax3.plot(listdatenode,Nodein,'ro', label='In')
	ax3.set_xlabel('Date')
	ax3.set_ylabel('InDegree')

	ax6.plot(listdatenode,Nodeout,'go', label='Out')
	ax6.set_xlabel('Date')
	ax6.set_ylabel('OutDegree')

	 
	ax4.plot(DATE1,BT,'ko')
	ax4.plot(listdatenode1,Bt,'bo')
	ax4.set_xlabel('Date')
	ax4.set_ylabel('BT(days)')
	
	ax5.plot(DATE1,BP,'ko')
	ax5.plot(listdatenode1,Bpneg,'bo')
	ax5.set_xlabel('Date')
	ax5.set_ylabel('BP(m)')

	ax2.scatter(listdatenodesortedall[1::],tdall)
	ax2.set_xlabel('Date')
	ax2.set_ylabel('Delta T between consecutive images (days)')

	ax7.plot(listdatenode1,Bt,'bo')
	ax7.set_xlabel('Date')
	ax7.set_ylabel('BT(days)')
	
	ax8.plot(listdatenode1,Bpneg,'bo')
	ax8.set_xlabel('Date')
	ax8.set_ylabel('BP(m)')

	ax9.plot(listdatenode,Nodein,'ro', label='In')
	ax9.plot(listdatenode,Nodeout,'go', label='Out')
	ax9.set_xlabel('Date')
	ax9.set_ylabel('Degree')
	ax9.legend()
	
	plt.show() # affiche la figure à l'écran

