#!/bin/bash
######################################################################################
# This script change all lines containing a given string with another one from all param files in sub dirs.
#
# Better be sure before launching - making backup of dir/subdirs is advised  
#
# For an up to date and detailed list of dependencies (and sub-dependencies), 
#    run the following command (add option -v to also list the commands and calls):
#  		Search_Dependencies /Path/to/This/script 
# 	 (Results are displayed at the Terminal; redirect them to a file with > file.txt if wished)
#
# New in Distro V 2.0 20230830:	- Rename SCRIPTS_OK directory as SCRIPTS_MT 
#								- Replace CIS by MT in names 
#								- Renamed FUNCTIONS_FOR_MT.sh
#								- replace sed separator with % 
#								- set string to search for file name in find instead of grep 
# New in Distro V 3.0 20231030:	- Rename MasTer Toolbox as AMSTer Software
#								- rename Master and Slave as Primary and Secondary (though not possible in some variables and files)
# New in Distro V 3.1 20261013:	- Recommend using Search_Dependencies.sh for 
#								  an updated list of dependencies
#									  
#
# AMSTer: SAR & InSAR Automated Mass processing Software for Multidimensional Time series
# NdO (c) 2016/03/07 - could make better with more functions... when time.
# -----------------------------------------------------------------------------------------
PRG=`basename "$0"`
VER="Distro V3.1 AMSTer script utilities"
AUT="Nicolas d'Oreye, (c)2016-2019, Last modified on oct 13, 2026"
echo " "
echo "${PRG} ${VER}, ${AUT}"
echo "Processing launched on $(date) " 
echo " " 

CRITERE=$1
NEWCRITERE=$2

#RUNDATE=`date "+ %m_%d_%Y_%Hh%Mm" | ${PATHGNU}/gsed "s/ //g"`

#echo "Change ${CRITERE} with ${NEWCRITERE} in following files: " > Modification_list_${RUNDATE}.txt  


# test first which files satisfies the criteria ? 
#
#for filename in `find /Users/doris/PROCESS/SCRIPTS_MT/Param_files -type f | ${PATHGNU}/grep LaunchMTparam`
# for filename in `find . -type f | ${PATHGNU}/grep LaunchMTparam`
#    do
#   	 echo "in ${filename} :" >> Modification_list_${RUNDATE}.txt 
#   	 ${PATHGNU}/grep "${CRITERE}" ${filename} >> Modification_list_${RUNDATE}.txt
#   	 echo " " >> Modification_list_${RUNDATE}.txt
# done

# echo "And in SuperMaster files: " >> Modification_list_${RUNDATE}.txt 
# echo "-------------------------- " >> Modification_list_${RUNDATE}.txt 
# for filename in `find /Users/doris/PROCESS/SCRIPTS_MT/Param_files_SuperMaster -type f | ${PATHGNU}/grep LaunchMTparam`
#    do
#   	 echo "in ${filename}: " >> Modification_list_${RUNDATE}.txt 
# 	 ${PATHGNU}/grep "${CRITERE}" ${filename} >> Modification_list_${RUNDATE}.txt
#   	 echo " " >> Modification_list_${RUNDATE}.txt
# done
# 

# TO REPLACE IN FILE 
# 
#for filename in `find /Users/doris/PROCESS/SCRIPTS_MT/Param_files -type f | ${PATHGNU}/grep LaunchMTparam`
for filename in `find . -type f -name "LaunchMTparam*.txt"`
   do
 	 #echo "in ${filename} :" >> Modification_list_${RUNDATE}.txt 
	 #grep "${CRITERE}" ${filename} >> Modification_list_${RUNDATE}.txt
	 #echo " " >> Modification_list_${RUNDATE}.txt
	${PATHGNU}/gsed -i "s%${CRITERE}%${NEWCRITERE}%" ${filename}
done


#echo "And in SuperMaster files: " >> Modification_list_${RUNDATE}.txt 
#echo "-------------------------- " >> Modification_list_${RUNDATE}.txt 
# for filename in `find /Users/doris/PROCESS/SCRIPTS_MT/Param_files_SuperMaster -type f | ${PATHGNU}/grep LaunchMTparam`
#    do
#  	 echo "in ${filename}: " >> Modification_list_${RUNDATE}.txt 
#	 ${PATHGNU}/grep "${CRITERE}" ${filename} >> Modification_list_${RUNDATE}.txt
#  	 echo " " >> Modification_list_${RUNDATE}.txt
#   	gsed -i "s/${CRITERE}/${NEWCRITERE}/"  ${filename}
# done

echo +++++++++++++++++++++++
echo "ALL FILES MODIFIED For ${CRITERE}"
echo +++++++++++++++++++++++


