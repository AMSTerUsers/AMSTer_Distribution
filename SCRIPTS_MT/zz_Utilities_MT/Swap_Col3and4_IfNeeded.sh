#!/bin/bash
# The script aims at swapping on the values in columns 3 and 4, but only if the value 
# in column 4 is greater than the value in column 3. It keeps other lines untouched. 
# 
# AMSTer: SAR & InSAR Automated Mass processing Software for Multidimensional Time series
#

FILETOSWAP=$1

# output only lines to invert
#awk ' $4 > $3  { t = $3; $3 = $4; $4 = t; print; } ' ${FILETOSWAP} > ${FILETOSWAP}.Conditionnal.inverted.txt

# output inverted lines and untouched lines
awk '{ if ($4 > $3) { t = $3; $3 = $4; $4 = t } print }' ${FILETOSWAP} > ${FILETOSWAP}.Conditionnal.inverted.txt

#mv ${FILETOSWAP} ${FILETOSWAP}_SLV_MAS.txt
#mv ${FILETOSWAP}.inverted.txt ${FILETOSWAP}
