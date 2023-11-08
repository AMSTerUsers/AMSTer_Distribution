#!/opt/local/bin/python
######################################################################################
# This is a python3 script to run the optimization pair selection module    
# 
# 
#
# Parameters:	- fullpath to table_0_BP_0_BT.txt to optimize
#		- fullpath to BaselineCohTable_Area.kml.txt (result of BaselineCohTable.sh)
#		- optimization criteria (3 or 4) 
#		- Day of year when decorrelation is the worse (1-365) 
#		- alpha calib param (exponent of seasonal component)
#		- beta calib param (temporal component)
#		- gamma calib param (spatial component)
#		- Max of expected coherence
#		- Min of expected coherence
#		- coherence proxy threshold for image rejection (0 if not used)
#
# Ouputs - List of pairs to remove in the form of MasDate_SlvDate : table_0_BP_0_BT_listPR2rm4optim_optimcrit.txt
#
# Depedencies:  python3 modules 
#			- sys
# 			- numpy
#			- networkx
# 			- optimFunctions 
#
# New in Distro V 2.0 20231030:	- Rename MasTer Toolbox as AMSTer Software
#								- rename Master and Slave as Primary and Secondary (though not possible in some variables and files)
#
# AMSTer: SAR & InSAR Automated Mass processing Software for Multidimensional Time series
# NdO (c) 2016/03/07 - could make better with more functions... when time.
# DS (c) 2020/11/03 - could make better... when time.
# Last modif April 20, 2021 
# -----------------------------------------------------------------------------------------

## import modules
import sys
import numpy as np
import optimFunctions as optf
import networkx as nx

## FUNCTION Coherence Proxy 
def creategraphfromtable(BaselineTableFullPath,BaselineCohTableFullPath,OPTIMCRIT,DOYL,ALPHA,BETA,GAMMA,MXC,MNC):
	#Load table with Master Slave BP BT	
	header = 2
	Master = []	
	Slave =[]
	BP = []
	BT = []
	with open(BaselineTableFullPath, 'r') as f:
		for line in f.readlines()[header:]:
			sp=line.split('\t')
			Master.append(str(sp[0]))
			Slave.append(str(sp[1]))
			BP.append(float(sp[2]))
			BT.append(float(sp[3]))
	BPmax=np.max(BP)
	BTmax=np.max(BT)
	BPmin=np.min(BP)
	BTmin=np.min(BT)
	
	BPMAX=np.max([abs(BPmax),abs(BPmin)])+1
	BTMAX=np.max([abs(BTmax),abs(BTmin)])
	
	# Compute coherence proxy 
	w1,w2,w3=optf.computeweightInSARpair(Master,Slave,BT,BP,DOYL,ALPHA,BETA,GAMMA,MXC,MNC)
	W=optf.invertparampondweightInSARpair(Master,Slave,w1,w2,w3,BaselineCohTableFullPath,MXC,MNC)
	
	# Create Graph to optimize
	G=nx.DiGraph()
	for k in range(len(Master)):
		G.add_edge(Master[k],Slave[k],weight=W[k])
	print('Graph created')	
	print('Number of nodes: ',G.number_of_nodes())
	print('Number of edges: ',G.number_of_edges())
	
	return G

## Arguments and launch
BaselineTableFullPath = sys.argv[1]
BaselineCohTableFullPath = sys.argv[2]
LISTPAIR2RMfile = sys.argv[3]
OPTIMCRIT = sys.argv[4]    
DOYL = sys.argv[5] 
ALPHA = sys.argv[6] 
BETA = sys.argv[7]
GAMMA = sys.argv[8]
MXC = sys.argv[9]
MNC = sys.argv[10]  
TH = sys.argv[11]  
G=creategraphfromtable(BaselineTableFullPath,BaselineCohTableFullPath,OPTIMCRIT,DOYL,ALPHA,BETA,GAMMA,MXC,MNC)

## Graph optimization
# remove images with all arcs having a weight below TH
G_nrm=optf.removenodesfromgraph(G,TH)
# optim to keep OPTIMCRIT arcs in and OPTIMCRIT arcs out of each node
Gopt=optf.removeedgesfromgraph(G_nrm,OPTIMCRIT)
# list pairs to remove
L1=[]		
for N1,N2 in G.edges:
	L1.append([N1+'_'+N2])
L2=[]
for N1,N2 in Gopt.edges:
	L2.append([N1+'_'+N2])
edgRM=np.setdiff1d(L1,L2)
#write output list of pairs to rm
fileout=optf.writelistpairs2rm(edgRM,LISTPAIR2RMfile)
print("List of pair to remove written in file:")
print(fileout)


