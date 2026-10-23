#!/bin/bash
######################################################################################
# This script copy all files in sub dirs that contains a certain string in their name into a given dir.
#
# For an up to date and detailed list of dependencies (and sub-dependencies), 
#    run the following command (add option -v to also list the commands and calls):
#  		Search_Dependencies /Path/to/This/script 
# 	 (Results are displayed at the Terminal; redirect them to a file with > file.txt if wished)
#
# New in Distro V 2.0 20231030:	- Rename MasTer Toolbox as AMSTer Software
#								- rename Master and Slave as Primary and Secondary (though not possible in some variables and files)
# New in Distro V 2.1 20261013:	- Recommend using Search_Dependencies.sh for 
#								  an updated list of dependencies
#									  
#
# AMSTer: SAR & InSAR Automated Mass processing Software for Multidimensional Time series
# NdO (c) 2016/03/07 - could make better with more functions... when time.
# -----------------------------------------------------------------------------------------
PRG=`basename "$0"`
VER="Distro V2.1 AMSTer script utilities"
AUT="Nicolas d'Oreye, (c)2016-2019, Last modified on oct 13, 2026"
echo " "
echo "${PRG} ${VER}, ${AUT}"
echo "Processing launched on $(date) " 
echo " " 


CRITERE=$1

echo "List dates of missing files from prensent dir/subdirs: "

for dir in `ls -d *_${CRITERE}`
   do
 		cd ${dir}/i12/InSARproducts 
 		pair=`echo ${dir} | cut -c 1-18`
 		if [ `ls *.jpg 2> /dev/null | wc -l` -lt 2 ] 
 			then 
				echo "** ${pair} NOT ok "
 		fi
 		cd ..
 		cd ..
 		cd ..
done

echo +++++++++++++++++++++++++++++++++++++++++++++++
echo "ALL FILES CHECKED - HOPE IT WORKED"
echo +++++++++++++++++++++++++++++++++++++++++++++++


