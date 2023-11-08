#!/bin/bash
######################################################################################
# This script copy all files in sub dirs that contains a certain string in their name into a given dir.
#
# AMSTer: SAR & InSAR Automated Mass processing Software for Multidimensional Time series
#
# N.d'Oreye, v 1.0 2018/02/023 -                         
######################################################################################

CRITERE=$1
PATHDIR=$2

echo "Cp files with ${CRITERE} to ${PATHDIR} from prensent dir/subdirs: "

for filename in `find * -type f | ${PATHGNU}/grep ${CRITERE}`
   do
 		cp ${filename} ${PATHDIR}
done

echo +++++++++++++++++++++++++++++++++++++++++++++++
echo "ALL FILES COPIED - HOPE IT WORKED"
echo +++++++++++++++++++++++++++++++++++++++++++++++


