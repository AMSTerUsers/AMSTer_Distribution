#!/bin/bash
######################################################################################
# This script aims at detrendind and interpolate SAR_MASSPROCESS/Geocoded/Defo images
#  and store them in SAR_MASSPROCESS/Geocoded/DefoInterpolDetrend and /DefoInterpolx2Detrend
#  although they will be missing the first interpolation (i.e. before geocoding)
#
# Parameters : 	- Source dir where Defo geocoded files are, i.e. SAR_MASSPROCESS/Geocoded/Defo
#
# This script was needed after a mistake that caused the loss of all the  Geocoded Products after Defo
#
# I know, it is a bit messy and can be improved.. when time. But it works..
# N.d'Oreye, v 1.0 2019/10/10 -                         
######################################################################################

SOURCEDIR=$1  # i.e. SAR_MASSPROCESS/Geocoded/Defo

function RemovePlane()
	{

	unset FILETODETREND
	local FILETODETREND=$1 

	bestPlaneRemoval2 ${SOURCEDIR}/bestPlaneRemoval.txt -create
	
	XDIMTODETREND=`cat ${FILETODETREND}.hdr | ${PATHGNU}/grep "Samples" | gsed 's@^[^0-9]*\([0-9]\+\).*@\1@'`
	YDIMTODETREND=`cat ${FILETODETREND}.hdr | ${PATHGNU}/grep "Lines" | gsed 's@^[^0-9]*\([0-9]\+\).*@\1@'`
	updateParameterFile ${SOURCEDIR}/bestPlaneRemoval.txt "File to be corrected" ${SOURCEDIR}/${FILETODETREND}
	updateParameterFile ${SOURCEDIR}/bestPlaneRemoval.txt "X dimension of the file to be corrected" ${XDIMTODETREND}
	updateParameterFile ${SOURCEDIR}/bestPlaneRemoval.txt "Y dimension of the file to be corrected" ${YDIMTODETREND}
	updateParameterFile ${SOURCEDIR}/bestPlaneRemoval.txt "Reference file path or NONE" "NONE"
	updateParameterFile ${SOURCEDIR}/bestPlaneRemoval.txt "Threshold file" "NONE" 
	
	bestPlaneRemoval2 ${SOURCEDIR}/bestPlaneRemoval.txt
	
	# rename according to conventions
	NEWNAME=`echo ${FILETODETREND} | gsed 's/deformationMap/deformationMap.interpolated.flattened/'` 
	mv ${FILETODETREND}.flattened ${SOURCEDIR}InterpolDetrend/${NEWNAME}
	cp ${FILETODETREND}.hdr ${SOURCEDIR}InterpolDetrend/${NEWNAME}.hdr
	gsed -i 's/deformationMap/deformationMap.NOTinterpolated.flattened/' ${SOURCEDIR}InterpolDetrend/${NEWNAME}.hdr 

	fillGapsInImage ${SOURCEDIR}InterpolDetrend/${NEWNAME} ${XDIMTODETREND} ${YDIMTODETREND}   
	
	NEWNAMEFILL=`echo ${NEWNAME}.interpolated | gsed 's/.bil/.bil.interpolated/' | gsed 's/deg.interpolated/deg/'` 

	# make raster
	#MakeFig ${XDIMTODETREND} 1.0 1.2 normal jet 1/1 r4 ${SOURCEDIR}InterpolDetrend/${NEWNAME}
			
	mv ${SOURCEDIR}InterpolDetrend/${NEWNAME}.interpolated ${SOURCEDIR}Interpolx2Detrend/${NEWNAMEFILL}
	cp ${SOURCEDIR}InterpolDetrend/${NEWNAME}.hdr ${SOURCEDIR}Interpolx2Detrend/${NEWNAMEFILL}.hdr
	gsed -i 's/deformationMap.NOTinterpolated.flattened/deformationMap.NOTinterpolated.flattened.interpolatedMANUALLY/' ${SOURCEDIR}Interpolx2Detrend/${NEWNAMEFILL}.hdr

	# make raster
	#MakeFig ${XDIMTODETREND} 1.0 1.2 normal jet 1/1 r4 ${SOURCEDIR}Interpolx2Detrend/${NEWNAMEFILL}

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
	 		RemovePlane ${FILES}
	done



