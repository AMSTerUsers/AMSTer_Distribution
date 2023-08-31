######################################################################################
# This file contains the python3 functions of the optimFunctions module called by creategraphfromtable.py
# 
#Last modif  D. Smittarello April 20, 2021

## Import Modules
import datetime as dt
import math
import numpy as np
from numpy.linalg import inv
import networkx as nx
import statistics as st

# Function computeweightInSARpair
def computeweightInSARpair(Master,Slave,BT,BP,DOYL,ALPHA,BETA,GAMMA,MXC,MNC):
	# Compute the three components : w1, w2 and w3 for coherence proxy 
	# w1 take into account the seasonnality, 
	# w2 take into account the temporal baseline
	# w3 take into account the perpendicular baseline
  	# Master is a list of dates of Master images format 'YYYMMDD'
	# Slave is a list of dates of Slave images format 'YYYMMDD'	
	# BT is the temporal baseline
	# BP is the perpendicular baseline
	# DOYL is the Day of year when decorrelation is the worse (1-365) 
	# alpha is a calib param (exponent of seasonal component)
	# beta is a calib param (temporal component)
	# gamma is a calib param (spatial component)
	# Mxc is the Max of expected coherence
	# Mnc is the Min of expected coherence

	#init
	S1=[]
	S2=[]	

	# Master info
	doymasterlist=[]
	for k in range(len(Master)):
		datemaster = dt.datetime.strptime(Master[k], '%Y%m%d')
		day_of_year = datemaster.timetuple().tm_yday
		doymasterlist.append(day_of_year)
	# Slave info
	doyslavelist=[]
	for k in range(len(Slave)):
		dateslave = dt.datetime.strptime(Slave[k], '%Y%m%d')
		day_of_year = dateslave.timetuple().tm_yday
		doyslavelist.append(day_of_year)

	# compute seasonal criteria elements	
	for k in range(len(doymasterlist)):
		Sm=abs(math.sin((np.dot((doymasterlist[k] + (365-int(DOYL))) / 365.,math.pi))))**float(ALPHA)
		Ss=abs(math.sin((np.dot((doyslavelist[k] + (365-int(DOYL))) / 365.,math.pi))))**float(ALPHA)
		S1.append(Sm)
		S2.append(Ss)
	S1=np.array(S1)
	S2=np.array(S2)
	
	# compute w1, w2 and w3
	w1=np.multiply(S1,S2)
	w2=np.dot((float(MXC)-float(MNC)),np.exp(np.dot(- float(BETA),np.absolute(BT)))) + float(MNC)
	w3=np.dot((float(MXC)-float(MNC)),np.exp(np.dot(- float(GAMMA),np.absolute(BP)))) + float(MNC)

	return w1,w2,w3
        

def invertparampondweightInSARpair(Master,Slave,w1,w2,w3,BScohtable,MXC,MNC):
	# Invert the weighting coefficient a, b and c using a calibration table and compute 'weight' the coherence proxy
	# the calibration set is obtained with Baseline_Coh_Table.sh
  	# Master is a list of dates of Master images format 'YYYMMDD'
	# Slave is a list of dates of Slave images format 'YYYMMDD'
	# w1, w2 and w3 are obtained with python function computeweightInSARpair from module optimFunctions
	# Mxc is the Max of expected coherence
	# Mnc is the Min of expected coherence
	MNC=float(MNC)
	MXC=float(MXC)	
	
	#Load Calibration table	
	header = 0
	Mastercohlist = []	
	Slavecohlist =[]
	BPcohlist = []
	BTcohlist = []
	Coh = []
	with open(BScohtable, 'r') as f:
		for line in f.readlines()[header:]:
			sp=line.split('\t')
			Mastercohlist.append(str(sp[0]))
			Slavecohlist.append(str(sp[1]))
			BPcohlist.append(float(sp[2]))
			BTcohlist.append(float(sp[3]))
			Coh.append(float(sp[4]))

	# init
	pairs=[]
	coh=[]
	W1=[]
	W2=[]
	W3=[]
	# create list of pairs to optim and list of pairs for the calib
	for k in range(len(Master)):
		pair='_'.join([Master[k], Slave[k]])
		pairs.append(pair)
	paircohtable=[]
	for k in range(len(Mastercohlist)):
		paircoh='_'.join([Mastercohlist[k], Slavecohlist[k]])
		paircohtable.append(paircoh)

	# check if the proxy components has been computed for the pairs in the calibration list
	for k in range(len(pairs)):
		try:
			ind=paircohtable.index(pairs[k])
			if Coh[ind]>(MNC+(np.dot(0.1,(MXC-MNC)))):
				coh.append(Coh[ind])
				W1.append(w1[k])
				W2.append(w2[k])
				W3.append(w3[k])
		except ValueError:
			print(pairs[k])

	# scaling 	
	mnw1=min(w1)
	mxw1=max(w1)
	mnw2=min(w2)
	mxw2=max(w2)
	mnw3=min(w3)
	mxw3=max(w3)

	
	W1=MNC+np.dot((W1-mnw1)/(mxw1-mnw1),(MXC-MNC))
	W2=MNC+np.dot((W2-mnw2)/(mxw2-mnw2),(MXC-MNC))
	W3=MNC+np.dot((W3-mnw3)/(mxw3-mnw3),(MXC-MNC))
	
	# invert a, b and c
	W=np.array([W1, W2, W3])
	W=W.T
	print(W.shape)
	WTWinv=inv((np.dot(W.T,W)))
	D=np.dot(np.dot(WTWinv,W.T),coh)
	print(D)
	a=D[0]
	b=D[1]
	c=D[2]
	# compute the weighted sum
	weight=np.dot(a,w1) + np.dot(b,w2) + np.dot(c,w3)
	return weight


def removenodesfromgraph(G,TH):
# G is a Python weighted digraph which nodes are SAR acquisition dates and Edges are interferograms
# the graph is built with creategraphfromtable.py from a 
#table file : MASTER Slave BP BT produced by PrepaMSBAS.sh
# this function aims at removing nodes of the graph G for which all arcs has weight < TH	
# G_nrm is a subgraph of G with such nodes removed

	# init
	TH=float(TH)
	Node_RM=[]
	Edg_RMn=[]

	# if TH=0 skip	
	if TH==0:
		Node_RM=[]
		Edg_RMn=[]
		G_nrm=G.copy()
		print(TH)
	else :
		# look for the max weight of all arcs in and out of each nodes and store the value in the 'labels' attribute for each node
		labels=0
		nx.set_node_attributes(G,labels,"labels")
		print(nx.get_node_attributes(G,'labels'))
		for N1,N2,W in G.edges(data='weight'):
			WN1=G.node[N1]['labels']
			WN2=G.node[N2]['labels']
			if WN1<W:
				G.add_node(N1,labels=W)
			if WN2<W:
				G.add_node(N2,labels=W)
		# crate copy of G
		G_nrm=G.copy()
		# remove nodes if label < TH	
		for N,Lab in G.nodes(data='labels'):
			if Lab<TH:
				Node_RM.append(N)
				G_nrm.remove_node(N)
		# list and count all edges removed
		L1=[]		
		for N1,N2 in G.edges:
			L1.append([N1+'_'+N2])
		L2=[]
		for N1,N2 in G_nrm.edges:
			L2.append([N1+'_'+N2])
#
		Edg_RMn=np.setdiff1d(L1,L2)
	
	print('Remove',len(Node_RM),'Nodes')
	print('Which correspond to ',len(Edg_RMn),'Edges')
	return(G_nrm)

	
def removeedgesfromgraph(G,OPTIMCRIT):
#removeedgesfromgraph looks for removable pairs in a graph (images,pairs, Weight)
# G is a Python weighted digraph which nodes are SAR acquisition dates and Edges are interferograms
# the graph is built with creategraphfromtable.py from a 
# table file : MASTER Slave BP BT produced by PrepaMSBAS.sh
# OPTIMCRIT is the max nuber of pairs that the optimisation will allow for each image (when possible to keep graph connectivity)
	OPTIMCRIT=int(OPTIMCRIT)
	#init
	edgRM=[]
	Nodein=[]
	Nodeout=[]
	Gopt=G.copy()

	#for each edge store in_degree of endnode and outdegree of startnode in 'In' and 'Out' attributes of the edges
	for (N1,N2,W) in G.edges(data='weight'):
		nodein=G.in_degree(N2)
		nodeout=G.out_degree(N1)
		G.add_edge(N1,N2,In=nodein,Out=nodeout)
		Nodein.append(nodein)
		Nodeout.append(nodeout)	
	
	print('Before optim : ')
	print ('Mean in=', st.mean(Nodein))
	print ('Mean out=', st.mean(Nodeout))
	
	# for each node
	# check if outdegree is > optimcrit
	# if yes AR is the maw number of arcs to remove in order to have outdegree=optimcrit
	for N in G.nodes:
		o=Gopt.out_degree(N)
		if o>OPTIMCRIT:
			AR=o-OPTIMCRIT;
			gr=nx.DiGraph()
			# check if the arcs are removable (i.e. if the end node of each arc has a number of arc in > optimcrit
			# sort removable arcs with weight and NbIn criteria
			for N1,N2,W in Gopt.out_edges(N,'weight'):
				NbIn=(len(Gopt.in_edges(N2)))
				if NbIn>OPTIMCRIT:
					gr.add_edge(N1,N2,weight=round(W,3),NbIn=NbIn)
			listedgesorted=(sorted(sorted(gr.edges(data=True),key=lambda x:x[2]['weight']),key=lambda x:-x[2]['NbIn']))
			# remove as many arcs as possible 
			for k in range(min(AR,len(listedgesorted))):
				N1rm=listedgesorted[k][0]
				N2rm=listedgesorted[k][1]
				edgRM.append([N1rm, N2rm])
				Gopt.remove_edge(N1rm,N2rm)
	# count after optim
	Nodein=[]
	Nodeout=[]
	for (N1,N2,W) in Gopt.edges(data=True):
		nodein=Gopt.in_degree(N2)
		nodeout=Gopt.out_degree(N1)
		Nodein.append(nodein)
		Nodeout.append(nodeout)	
	print('After optim : ')
	print ('Mean in=', st.mean(Nodein))
	print ('Mean out=', st.mean(Nodeout))


	print('Graph optimized')	
	print('Number of nodes: ',Gopt.number_of_nodes())
	print('Number of edges: ',Gopt.number_of_edges())
	Nbedg2rm=G.number_of_edges()-Gopt.number_of_edges()
	print('Number of pairs to remove:',Nbedg2rm)
#	print(edgRM)
#	nx.draw(Gopt)
#	import matplotlib.pyplot as plt
#	plt.show()
	return(Gopt)
	
def writelistpairs2rm(edgRM,LISTPAIR2RMfile):
	# write pairs in edgRM in LISTPAIR2RMfile
	fichier=open(LISTPAIR2RMfile,"w")
	for pair in edgRM:
		fichier.write("%s\n" %(pair))
	fichier.close()
	return(LISTPAIR2RMfile)
	
	

