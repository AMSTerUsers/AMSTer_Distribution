#!/bin/bash
######################################################################################
# This script copy all files in sub dirs that contains a certain string in their name into a given dir.
#
# I know, it is a bit messy and can be improved.. when time. But it works..
# N.d'Oreye, v 1.0 2018/02/023 -                         
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


