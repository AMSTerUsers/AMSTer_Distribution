#!/bin/bash

FILETOSWAP=$1

awk ' { t = $3; $3 = $4; $4 = t; print; } ' ${FILETOSWAP} > ${FILETOSWAP}.inverted.txt

mv ${FILETOSWAP} ${FILETOSWAP}_SLV_MAS.txt
mv ${FILETOSWAP}.inverted.txt ${FILETOSWAP}
