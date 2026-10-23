#!/bin/bash
#
# AMSTer: SAR & InSAR Automated Mass processing Software for Multidimensional Time series
#
# For an up to date and detailed list of dependencies (and sub-dependencies), 
#    run the following command (add option -v to also list the commands and calls):
#  		Search_Dependencies /Path/to/This/script 
# 	 (Results are displayed at the Terminal; redirect them to a file with > file.txt if wished)
#
# New in Distro V 1.1 20261013:	- Recommend using Search_Dependencies.sh for 
#								  an updated list of dependencies
#									  
#
# AMSTer: SAR & InSAR Automated Mass processing Software for Multidimensional Time series
# NdO (c) 2016/03/07 - could make better with more functions... when time.
# -----------------------------------------------------------------------------------------
PRG=`basename "$0"`
VER="Distro V1.1 AMSTer script utilities"
AUT="Nicolas d'Oreye, (c)2016-2019, Last modified on oct 13, 2026"
echo " "
echo "${PRG} ${VER}, ${AUT}"
echo "Processing launched on $(date) " 
echo " " 



# Attention : provide the source dir without the /NoCrop
SOURCEDIR=$1 	# eg /Users/doris/NAS/hp-1650-Data_Share1/SAR_CSL/S1/DRC_Funu_A_72/NoCrop
TARGETDIR=$2 	# eg /Users/doris/NAS/hp-1650-Data_Share1/SAR_CSL/S1/DRC_Funu/NoCrop

cd ${SOURCEDIR}

for IMG in *.csl
	do
		S1IMG=`echo ${IMG##*/}` 				# Trick to get only name without path
		if [ ! -h ${TARGETDIR}/${S1IMG} ] 
			then 
				echo "${TARGETDIR}/${S1IMG} does not exist"
				echo " Will copy ${SOURCEDIR}/${S1IMG} in ${TARGETDIR}/ "
				echo ""
				ln -s ${SOURCEDIR}/${S1IMG} ${TARGETDIR}/ 
		fi   # mv and recreate original dir name in place because needed by mass reading to chjeck if already read
done
