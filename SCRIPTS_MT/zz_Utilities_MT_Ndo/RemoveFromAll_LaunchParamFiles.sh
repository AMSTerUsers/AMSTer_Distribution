#!/bin/bash
######################################################################################
# This script remove all lines containing a given string from all param files in sub dirs.
#
# Better be sure before launching - making backup of dir/subdirs is advised  
#
# New in Distro V 2.0 20230830:	- Rename SCRIPTS_OK directory as SCRIPTS_MT 
#								- Replace CIS by MT in names 
#								- Renamed FUNCTIONS_FOR_MT.sh
# New in Distro V 3.0 20231030:	- Rename MasTer Toolbox as AMSTer Software
#								- rename Master and Slave as Primary and Secondary (though not possible in some variables and files)
#
# AMSTer: SAR & InSAR Automated Mass processing Software for Multidimensional Time series
# NdO (c) 2016/03/07 - could make better with more functions... when time.                    
######################################################################################

CRITERE=$1


RUNDATE=`date "+ %m_%d_%Y_%Hh%Mm" | ${PATHGNU}/gsed "s/ //g"`

PATHTOPARAMFILES="/Users/doris/PROCESS/SCRIPTS_MT"

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

for filename in `find ${PATHTOPARAMFILES}/Param_files -type f | ${PATHGNU}/grep LaunchMTparam`
   do
   	 echo "in ${filename} :" >> Modification_list_${RUNDATE}.txt 
  	 ${PATHGNU}/grep "${CRITERE}" ${filename} >> Modification_list_${RUNDATE}.txt
  	 echo " " >> Modification_list_${RUNDATE}.txt
	grep -v "${CRITERE}" ${filename} > tmp.txt && mv tmp.txt ${filename}
done


echo +++++++++++++++++++++++++++++++++++++++++++++++
echo "ALL FILES MODIFIED - HOPE IT WORKED"
echo +++++++++++++++++++++++++++++++++++++++++++++++


