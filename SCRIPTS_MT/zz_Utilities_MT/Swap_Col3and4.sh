#!/bin/bash
#
# AMSTer: SAR & InSAR Automated Mass processing Software for Multidimensional Time series
#

FILETOSWAP=$1

awk ' { t = $3; $3 = $4; $4 = t; print; } ' ${FILETOSWAP} > ${FILETOSWAP}.inverted.txt

mv ${FILETOSWAP} ${FILETOSWAP}_SLV_MAS.txt
mv ${FILETOSWAP}.inverted.txt ${FILETOSWAP}
