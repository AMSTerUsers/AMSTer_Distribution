#!/bin/bash
######################################################################################
# This script remove all lines containing a given string from all param files in sub dirs.
#
# Better be sure before launching - making backup of dir/subdirs is advised  
#
# New in Distro V 2.0 20230830:	- Rename SCRIPTS_OK directory as SCRIPTS_MT 
#								- Replace CIS by MT in names 
#								- Renamed FUNCTIONS_FOR_MT.sh
#
# I know, it is a bit messy and can be improved.. when time. But it works..
# N.d'Oreye, v 1.0 2016/04/07 -                         
######################################################################################

CRITERE=$1


RUNDATE=`date "+ %m_%d_%Y_%Hh%Mm" | ${PATHGNU}/gsed "s/ //g"`


echo "Remove ${CRITERE} in following files: " > Modification_list_${RUNDATE}.txt  

	
# test first which files satisfies the criteria ? 
# 
# for filename in `find /Users/doris/PROCESS/SCRIPTS_MT/Param_files -type f | ${PATHGNU}/grep LaunchMTparam`
#    do
#   	 echo "in ${filename} :" >> Modification_list_${RUNDATE}.txt 
#   	 ${PATHGNU}/grep "${CRITERE}" ${filename} >> Modification_list_${RUNDATE}.txt
#   	 echo " " >> Modification_list_${RUNDATE}.txt
# done
# 
# echo "And in SuperMaster files: " >> Modification_list_${RUNDATE}.txt 
# echo "-------------------------- " >> Modification_list_${RUNDATE}.txt 
# for filename in `find /Users/doris/PROCESS/SCRIPTS_MT/Param_files_SuperMaster -type f | ${PATHGNU}/grep LaunchMTparam`
#    do
#   	 echo "in ${filename}: " >> Modification_list_${RUNDATE}.txt 
# 	 ${PATHGNU}/grep "${CRITERE}" ${filename} >> Modification_list_${RUNDATE}.txt
#   	 echo " " >> Modification_list_${RUNDATE}.txt
# done

# TO DELETE ALL LINES WITH GIVEN CRITERIA :

for filename in `find /Users/doris/PROCESS/SCRIPTS_MT/Param_files -type f | ${PATHGNU}/grep LaunchMTparam`
   do
   	 echo "in ${filename} :" >> Modification_list_${RUNDATE}.txt 
  	 ${PATHGNU}/grep "${CRITERE}" ${filename} >> Modification_list_${RUNDATE}.txt
  	 echo " " >> Modification_list_${RUNDATE}.txt
	grep -v "${CRITERE}" ${filename} > tmp.txt && mv tmp.txt ${filename}
done

echo "And in SuperMaster files: " >> Modification_list_${RUNDATE}.txt 
echo "-------------------------- " >> Modification_list_${RUNDATE}.txt 

for filename in `find /Users/doris/PROCESS/SCRIPTS_MT/Param_files_SuperMaster -type f | ${PATHGNU}/grep LaunchMTparam`
   do
  	 echo "in ${filename}: " >> Modification_list_${RUNDATE}.txt 
	 ${PATHGNU}/grep "${CRITERE}" ${filename} >> Modification_list_${RUNDATE}.txt
  	 echo " " >> Modification_list_${RUNDATE}.txt
   	grep -v "${CRITERE}" ${filename} > tmp.txt && mv tmp.txt ${filename}
done


echo +++++++++++++++++++++++++++++++++++++++++++++++
echo "ALL FILES MODIFIED - HOPE IT WORKED"
echo +++++++++++++++++++++++++++++++++++++++++++++++


