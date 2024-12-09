#!/bin/bash
# The script aims at swapping on the values in columns 1 and 2, but only if the value 
# in column 2 is smaller than the value in column 1. It keeps other lines untouched. 
# 
# AMSTer: SAR & InSAR Automated Mass processing Software for Multidimensional Time series
#

FILETOSWAP=$1


# output inverted lines and untouched lines
awk '{ if ($2 < $1) { t = $1; $1 = $2; $2 = t } print }' ${FILETOSWAP} > ${FILETOSWAP}.Conditionnal.inverted.txt
