#!/bin/bash
######################################################################################
# This script aims at interpolating SAR_MASSPROCESS/Geocoded/DefoInterpolDetrend images
#  and store them in SAR_MASSPROCESS/Geocoded/DefoInterpolx2Detrend
#
# Parameters : 	- Source dir where DefoInterpolDetrend geocoded files are, i.e. SAR_MASSPROCESS/Geocoded/DefoInterpolDetrend
#
# This script was needed after a mistake that caused the loss of all the DefoInterpolDetrend
#
# New in Distro V 2.0 20231030:	- Rename MasTer Toolbox as AMSTer Software
#								- rename Master and Slave as Primary and Secondary (though not possible in some variables and files)
# New in Distro V 2.1 20240305:	- Works for other defo mode than only DefoInterpolx2Detrend
#
# AMSTer: SAR & InSAR Automated Mass processing Software for Multidimensional Time series
# NdO (c) 2016/03/07 - could make better with more functions... when time.
# -----------------------------------------------------------------------------------------

SOURCEDIR=$1  # i.e. SAR_MASSPROCESS/Geocoded/DefoInterpolDetrend

DEFOMODE=$(basename ${SOURCEDIR})

function Interpol()
	{

	unset FILETOINTERPOL
	local FILETOINTERPOL=$1 

	XDIMTODETREND=`cat ${FILETOINTERPOL}.hdr | ${PATHGNU}/grep "Samples" | gsed 's@^[^0-9]*\([0-9]\+\).*@\1@'`
	YDIMTODETREND=`cat ${FILETOINTERPOL}.hdr | ${PATHGNU}/grep "Lines" | gsed 's@^[^0-9]*\([0-9]\+\).*@\1@'`

	fillGapsInImage ${SOURCEDIR}/${FILETOINTERPOL} ${XDIMTODETREND} ${YDIMTODETREND}   


	# rename according to conventions
	NEWNAMEFILL=`echo ${FILETOINTERPOL} | gsed 's/.bil/.bil.interpolated/' | gsed 's/deg.interpolated/deg/'` 
	NEWDIR=`echo ${SOURCEDIR} | gsed 's/DefoInterpolDetrend/${DEFOMODE}/'`
	mv ${FILETOINTERPOL}.interpolated ${NEWDIR}/${NEWNAMEFILL}
	cp ${FILETOINTERPOL}.hdr ${NEWDIR}/${NEWNAMEFILL}.hdr

	# header must contains	deformationMap.interpolated.flattened.UTM.50x50.bil.interpolated
	# instead of			deformationMap.interpolated.flattened.UTM.50x50
	gsed -i 's/deformationMap.interpolated.flattened/deformationMap.interpolated.flattened.MANUALLYinterpolated/' ${NEWDIR}/${NEWNAMEFILL}.hdr 

	# make raster
	#MakeFig ${XDIMTODETREND} 1.0 1.2 normal jet 1/1 r4 ${NEWDIR}/${NEWNAMEFILL}


	}	

function MakeFig()
	{
		unset WIDTH E S TYPE COLOR ML FORMAT FILE
		local WIDTH=$1
		local E=$2
		local S=$3
		local TYPE=$4
		local COLOR=$5
		local ML=$6
		local FORMAT=$7
		local FILE=$8
		cpxfiddle -w ${WIDTH} -e ${E} -s ${S} -q ${TYPE} -o sunraster -c ${COLOR} -M ${ML} -f ${FORMAT} -l1 ${FILE} > ${FILE}.ras
		# create script if one wants to change paramerters of the plot
		unset FILENOPATH
		FILENOPATH=`echo ${FILE} | ${PATHGNU}/gawk -F '/' '{print $NF}'`
		echo "cpxfiddle -w ${WIDTH} -e ${E} -s ${S} -q ${TYPE} -o sunraster -c ${COLOR} -M ${ML} -f ${FORMAT} -l1 ${FILENOPATH} >  ${FILENOPATH}.ras" > ${FILE}.ras.sh
		chmod +x ${FILE}.ras.sh
	}
	

cd ${SOURCEDIR}
	for FILES in `ls *deg`
	   do
	 		Interpol ${FILES}
	done



