#!/bin/bash
######################################################################################
# This script remove all dirs from a list and that correspond to a string of format hard coded (for security).
#
# V1.0: 2018/02/023
# New in Distro V 2.0 20231030:	- Rename MasTer Toolbox as AMSTer Software
#								- rename Master and Slave as Primary and Secondary (though not possible in some variables and files)
#
# AMSTer: SAR & InSAR Automated Mass processing Software for Multidimensional Time series
# NdO (c) 2016/03/07 - could make better with more functions... when time.
# -----------------------------------------------------------------------------------------


LISTTOKILL=$1

for stringname in `cat ${LISTTOKILL}`
   do
 		MAS=`echo ${stringname} | cut -d _ -f1`
 		SLV=`echo ${stringname} | cut -d _ -f2`
# 		echo "Kill S1?_174_${MAS}_A_S1?_174_${SLV}_A"
# 		rm -Rf S1?_174_${MAS}_A_S1?_174_${SLV}_A
		echo "mv *${MAS}_*${SLV}* in ../Prblm"
		mv *${MAS}_*${SLV}* ../Prblm
done

echo +++++++++++++++++++++++++++++++++++++++++++++++
echo "ALL FILES COPIED - HOPE IT WORKED"
echo +++++++++++++++++++++++++++++++++++++++++++++++


