#!/bin/bash
######################################################################################
# This script launch python3 functions to run the optimization pair selection module    
#
# Parameters:	- fullpath to table_0_BP_0_BT.txt to optimize
#				- fullpath to BaselineCohTable_Area.kml.txt (result of BaselineCohTable.sh)
#				- optimization criteria (3 or 4) 
#				- Day of year when decorrelation is the worse (1-365) 
#				- alpha calib param (exponent of seasonal component)
#				- beta calib param (temporal component)
#				- gamma calib param (spatial component)
#				- Max of expected coherence
#				- Min of expected coherence
#				- coherence proxy threshold for image rejection (0 if not used)
#
# Outputs:	- List of pairs to remove in the form of MasDate_SlvDate : table_0_BP_0_BT_listPR2rm4optim_optimcrit.txt
#			- List of pairs to keep in the form of MasDate	SlvDate	BP	BT : table_0_BP_0_BT_listPR2rm4optim_optimcrit_optimized.txt
#
# For an up to date and detailed list of dependencies (and sub-dependencies), 
#    run the following command (add option -v to also list the commands and calls):
#  		Search_Dependencies /Path/to/This/script 
# 	 (Results are displayed at the Terminal; redirect them to a file with > file.txt if wished)
#
# Depedencies: 	- python3
# 				- gsed
#
# New in Distro V 2.0 20231030:	- Rename MasTer Toolbox as AMSTer Software
#								- rename Master and Slave as Primary and Secondary (though not possible in some variables and files)
# New in Distro V 2.1 20261013:	- Recommend using Search_Dependencies.sh for 
#								  an updated list of dependencies
#									  
#
# AMSTer: SAR & InSAR Automated Mass processing Software for Multidimensional Time series
# DS (c) 2024/01/16 - could make better with more functions... when time.
######################################################################################
PRG=`basename "$0"`
VER="Distro V2.1 AMSTer script utilities" 
AUT="Delphine Smittarello, (c)2016-2019, Last modified on oct 13, 2026"
echo " " 
echo "${PRG} ${VER}, ${AUT}" 
echo "Processing launched on $(date) " 
echo " "

nbrarg=$#
if [ $nbrarg -eq 0 ]; then
	echo "No argument is given"
	exit
elif [ $nbrarg -eq 4 ]; then
	BaselineTableFullPath=$1
	BaselineCohTableFullPath=$2
	OPTIMCRIT=$3
	TH=${4}
	
	echo "Table to optimize is : ${BaselineTableFullPath}"
	echo "Coherence proxy calibration Table is : ${BaselineCohTableFullPath}"
	echo "Optimization run with ${OPTIMCRIT} Arcs In and ${OPTIMCRIT} Arcs Out to keep for each image"
	echo "Threshold for image remove : ${TH}"
	echo "4 arguments are given, Coherence is expected to be known for each pair"
	
elif [ $nbrarg -eq 10 ]; then
	BaselineTableFullPath=$1
	BaselineCohTableFullPath=$2
	OPTIMCRIT=$3
	DOYL=$4
	ALPHA=$5
	BETA=$6
	GAMMA=$7
	MXC=$8
	MNC=$9
	TH=${10}

	echo "Table to optimize is : ${BaselineTableFullPath}"
	echo "Coherence proxy calibration Table is : ${BaselineCohTableFullPath}"
	echo "Optimization run with ${OPTIMCRIT} Arcs In and ${OPTIMCRIT} Arcs Out to keep for each image"
	echo "Threshold for image remove : ${TH}"
	echo "10 arguments are given, I will use a coherence proxy"
	echo "Seasonnal decorrelation criteria used : DOYlow=${DOYL} and alpha=${ALPHA}"
	echo "Temporal decorrelation criteria used : beta=${BETA}"
	echo "Spatial  decorrelation criteria used : gamma=${GAMMA}"
	echo "Expected coherence between Mnc=${MNC} and Mxc=${MXC}"
else
	echo "Wrong list of arguments given"
	exit
fi

echo

BaselineTableFile=`echo ${BaselineTableFullPath} | ${PATHGNU}/gsed 's/.*txt\///' | cut -d . -f1`
echo "${BaselineTableFile}"
LISTPAIR2RMfile="${BaselineTableFile}_listPR2rm4optim_${OPTIMCRIT}_th${TH}.txt"
echo "${LISTPAIR2RMfile}"

if [ $nbrarg -eq 4 ]; then
	creategraphfromtable_realcoh.py ${BaselineTableFullPath} ${BaselineCohTableFullPath} ${LISTPAIR2RMfile} ${OPTIMCRIT} ${TH}
elif [ $nbrarg -eq 10 ]; then
	creategraphfromtable.py ${BaselineTableFullPath} ${BaselineCohTableFullPath} ${LISTPAIR2RMfile} ${OPTIMCRIT} ${DOYL} ${ALPHA} ${BETA} ${GAMMA} ${MXC} ${MNC} ${TH}
fi

RemovePairs_fromtableforOptim_V2.sh ${BaselineTableFullPath} ${LISTPAIR2RMfile}




