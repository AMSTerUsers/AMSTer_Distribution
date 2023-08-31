#!/bin/bash
######################################################################################
# This script remove all dirs from a list and that correspond to a string of format hard coded (for security).
#
# I know, it is a bit messy and can be improved.. when time. But it works..
# N.d'Oreye, v 1.0 2018/02/023 -                         
######################################################################################

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


