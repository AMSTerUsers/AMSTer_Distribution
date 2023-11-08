#!/bin/bash
# Create file with dates inverted if master date is after slave date in list.
# Dates are supposed to be provided as Mas in col1 and Slv in col 2
# Col 3 and 4 are set to 0 for comp
#
# New in Distro V 2.0 20231030:	- Rename MasTer Toolbox as AMSTer Software
#								- rename Master and Slave as Primary and Secondary (though not possible in some variables and files)
#
# AMSTer: SAR & InSAR Automated Mass processing Software for Multidimensional Time series
# NdO (c) 2016/03/07 - could make better with more functions... when time.
# -----------------------------------------------------------------------------------------
FILETOCHECK=$1

tail -n +3 ${FILETOCHECK}  > ${FILETOCHECK}.Unsorted_tmp.txt

awk ' {$1; $2 ; $3 = 0 ; $4 = 0 ; print; } ' ${FILETOCHECK}.Unsorted_tmp.txt > ${FILETOCHECK}.Unsorted.txt
awk ' $1>$2{x=$2;$2=$1;$1=x;0;0}1' ${FILETOCHECK}.Unsorted.txt > ${FILETOCHECK}.Sorted.txt
rm ${FILETOCHECK}.Unsorted_tmp.txt

diff ${FILETOCHECK}.Unsorted.txt ${FILETOCHECK}.Sorted.txt
