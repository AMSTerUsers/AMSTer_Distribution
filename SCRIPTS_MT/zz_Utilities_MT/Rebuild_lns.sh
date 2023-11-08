#!/bin/bash
# This script aims at rebuilding links after the original file was moved. 
#
# Parameters are:
#		- type of file to check (eg deg for results of mass process or hdr, ras etc...)
#		- Path to dir where new location of former file is supposed to be (may be in a sub dir of it)
#
# Dependencies:	- readlink
#
# New in V1.1 :	- make it compatible for Linux
# New in V1.2 :	- happen / before original target path
# New in V1.3 (Nov 30, 2020):	- prefer readlink to get original target of link
# New in Distro V 2.0 20231030:	- Rename MasTer Toolbox as AMSTer Software
#								- rename Master and Slave as Primary and Secondary (though not possible in some variables and files)
#
# AMSTer: SAR & InSAR Automated Mass processing Software for Multidimensional Time series
# NdO (c) 2016/03/07 - could make better with more functions... when time.
# -----------------------------------------------------------------------------------------
PRG=`basename "$0"`
VER="Distro V2.0 AMSTer script utilities"
AUT="Nicolas d'Oreye, (c)2016-2019, Last modified on Oct 30, 2023"

echo " "
echo "${PRG} ${VER}, ${AUT}"
echo " "

TYPEOFLINK=$1 # eg "deg" for results of MASS PROCESSING
TARGETDIR=$2  # 

# Check if all links in dir points toward existing files  
for LKS in `ls *${TYPEOFLINK}`
do
	#ORIGINALTARGET=`ls -l ${LKS} | cut -d ">" -f 2- | cut -d "/" -f 2-` # get  the path and name of file pointed to by the broken link i.e. file tolocate in  TARGETDIR
	#ORIGINALTARGET="/${ORIGINALTARGET}"
	ORIGINALTARGET=`readlink ${LKS}`
	
	if [ ! -s ${ORIGINALTARGET} ] 
		then 
			ORIGINALTARGETFILE=`basename ${ORIGINALTARGET}`
			echo "Link broken : ${LKS}" 
			echo "Will rebuild it supposing that file is in ${TARGETDIR}"
			if [ ! -s ${TARGETDIR}/${ORIGINALTARGETFILE} ] 
				then 
					echo "File does not exist: ${TARGETDIR}/${ORIGINALTARGETFILE}"
					echo "Please check expected path"
				else 
					# remove echo below when you are sure... 
					#echo "ln -s ${TARGETDIR}/${ORIGINALTARGETFILE} ${ORIGINALTARGETFILE}"
					rm ${LKS}
					ln -s ${TARGETDIR}/${ORIGINALTARGETFILE} ${ORIGINALTARGETFILE} 
			fi			
		else 
			echo "Link ok" 
	fi 
done 

