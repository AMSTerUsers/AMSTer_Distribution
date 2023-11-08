#!/bin/bash
######################################################################################
# This script copy all files in sub dirs that contains a certain string in their name into a given dir.
#
# New in Distro V 2.0 20231030:	- Rename MasTer Toolbox as AMSTer Software
#								- rename Master and Slave as Primary and Secondary (though not possible in some variables and files)
#
# AMSTer: SAR & InSAR Automated Mass processing Software for Multidimensional Time series
# NdO (c) 2016/03/07 - could make better with more functions... when time.
######################################################################################

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


