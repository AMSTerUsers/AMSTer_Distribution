#!/bin/bash
#
# AMSTer: SAR & InSAR Automated Mass processing Software for Multidimensional Time series
#

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
