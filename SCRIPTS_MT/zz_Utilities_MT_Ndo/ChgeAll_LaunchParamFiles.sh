#!/bin/bash
######################################################################################
# This script change all lines containing a given string with another one from all param files in sub dirs.
#
# Better be sure before launching - making backup of dir/subdirs is advised  
#
# New in Distro V 2.0 20230830:	- Rename SCRIPTS_OK directory as SCRIPTS_MT 
#								- Replace CIS by MT in names 
#								- Renamed FUNCTIONS_FOR_MT.sh
#								- replace sed separator with % 
#								- set string to search for file name in find instead of grep 
#
# I know, it is a bit messy and can be improved.. when time. But it works..
# N.d'Oreye, v 1.0 2016/04/07 -                         
######################################################################################

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


