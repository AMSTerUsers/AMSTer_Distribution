#!/bin/bash
######################################################################################
# This script remove all dirs that contains a certain string in their name 
#    and that correspond to a string of format hard coded (for security).
#
# New in V1.1:	- change with a oneliner version...
#
# I know, it is a bit messy and can be improved.. when time. But it works..
# N.d'Oreye, v 1.0 2018/02/023 -                         
######################################################################################

STRINGTOKILL=$1

# for stringname in `ls -d *${STRINGTOKILL}*`
#    do
#  		echo ${stringname}
#  		MAS=`echo ${stringname} | cut -d _ -f3`
#  		SLV=`echo ${stringname} | cut -d _ -f7`
#  		echo "Kill S1?_88_${MAS}_A_S1?_88_${SLV}_A"
#  		rm -Rf S1?_88_${MAS}_A_S1?_88_${SLV}_A
# done

find . -maxdepth 1 -type d -name "*${STRINGTOKILL}*" -exec rm -Rf {} \;


# echo +++++++++++++++++++++++++++++++++++++++++++++++
# echo "ALL FILES COPIED - HOPE IT WORKED"
# echo +++++++++++++++++++++++++++++++++++++++++++++++
# 
# 
# Version from a file with list of string for dir to kill
# 
# DIRTOKILL=$1
# 
# while read -r MASDATE SLVDATE
# do	
# 	DIRTOREMOVE=`ls -d S1*${MASDATE}*${SLVDATE}*A`
# 	echo "rm -Rf ${DIRTOREMOVE}"
# 	rm -Rf ${DIRTOREMOVE}
# done < ${DIRTOKILL} 
# 


echo ++++++++++++++++++++++++++++++++++
echo "ALL DIR CLEANED - HOPE IT WORKED"
echo ++++++++++++++++++++++++++++++++++
