#!/bin/bash
# This script aims at creating sun raster file (.ras) from an envi file.
#
#	Dependencies: - cpxfiddle
# 
# Parameters are:
#		- path to envi image
# 		- type of img: defo, amp, coh, interf
#		- ML factor
#
# New in Distro V 1.0 20240806:	- setup
#
# AMSTer: SAR & InSAR Automated Mass processing Software for Multidimensional Time series
# NdO (c) 2016/03/07 - could make better with more functions... when time.
# -----------------------------------------------------------------------------------------
PRG=`basename "$0"`
VER="Distro V1.0 AMSTer script utilities"
AUT="Nicolas d'Oreye, (c)2016-2019, Last modified on Aug 6, 2024"
echo " "
echo "${PRG} ${VER}, ${AUT}"
echo " "

ENVIIMG=$1		# path to envi image
ML=$2			# e.g. 2
TYPE=$3			# type of fig expected (will influence the color scale and type): defo, amp, coh, interf

SOURCEDIR=$(dirname "${ENVIIMG}")
IMG=$(basename "${ENVIIMG}")

cd ${SOURCEDIR}

WIDTH=$("${PATHGNU}"/grep -oP 'amples = \K[0-9]+' ${ENVIIMG}.hdr)

# Some functions
################

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
		eval FILE=${FILE}
		${PATHTOCPXFIDDLE}/cpxfiddle -w ${WIDTH} -e ${E} -s ${S} -q ${TYPE} -o sunraster -c ${COLOR} -M ${ML} -f ${FORMAT} -l1 ${FILE} > ${FILE}.ras | tee -a ${LOGFILE}
		# create script if one wants to change paramerters of the plot
		unset FILENOPATH
		FILENOPATH=`echo ${FILE} | ${PATHGNU}/gawk -F '/' '{print $NF}'`
		echo "cpxfiddle -w ${WIDTH} -e ${E} -s ${S} -q ${TYPE} -o sunraster -c ${COLOR} -M ${ML} -f ${FORMAT} -l1 ${FILENOPATH} >  ${FILENOPATH}.ras" > ${FILE}.ras.sh
		chmod +x ${FILE}.ras.sh
	}
	
function MakeFigR()
	{
		unset WIDTH R E S TYPE COLOR ML FORMAT FILE
		local WIDTH=$1
		local R=$2
		local E=$3
		local S=$4
		local TYPE=$5
		local COLOR=$6
		local ML=$7
		local FORMAT=$8
		local FILE=$9
		${PATHTOCPXFIDDLE}/cpxfiddle -w ${WIDTH} -r ${R} -e ${E} -s ${S} -q ${TYPE} -o sunraster -c ${COLOR} -M ${ML} -f ${FORMAT} -l1 ${FILE} > ${FILE}.ras | tee -a ${LOGFILE}
		# create script if one wants to change paramerters of the plot
		unset FILENOPATH
		FILENOPATH=`echo ${FILE} | ${PATHGNU}/gawk -F '/' '{print $NF}'`
		echo "cpxfiddle -w ${WIDTH} -r ${R} -e ${E} -s ${S} -q ${TYPE} -o sunraster -c ${COLOR} -M ${ML} -f ${FORMAT} -l1 ${FILENOPATH} > ${FILENOPATH}.ras" > ${FILE}.ras.sh
		chmod +x ${FILE}.ras.sh
	}
function MakeFigRAuto()
	{
		unset WIDTH R E S TYPE COLOR ML FORMAT FILE
		local WIDTH=$1
		local R=$2
		local E=$3
		local S=$4
		local TYPE=$5
		local COLOR=$6
		local ML=$7
		local FORMAT=$8
		local FILE=$9
		local MEANIMG
		local STDVIMG
		local MINIMG
		local MAXFIG
		
		MINIMG=$(gdalinfo -stats ${FILE}  | ${PATHGNU}/grep "Mean" | cut -d , -f1 | cut -d = -f 2)
		MEANIMG=$(gdalinfo -stats ${FILE}  | ${PATHGNU}/grep "Mean" | cut -d , -f3 | cut -d = -f 2)
		STDVIMG=$(gdalinfo -stats ${FILE}  | ${PATHGNU}/grep "Mean" | cut -d , -f4 | cut -d = -f 2)
		
		MAXFIG=$(echo "( ${MEANIMG} + (2 * ${STDVIMG}))" | bc)
		R=${MINIMG},${MAXFIG}
		
		${PATHTOCPXFIDDLE}/cpxfiddle -w ${WIDTH} -r ${R} -e ${E} -s ${S} -q ${TYPE} -o sunraster -c ${COLOR} -M ${ML} -f ${FORMAT} -l1 ${FILE} > ${FILE}.ras | tee -a ${LOGFILE}
		# create script if one wants to change paramerters of the plot
		unset FILENOPATH
		FILENOPATH=`echo ${FILE} | ${PATHGNU}/gawk -F '/' '{print $NF}'`
		echo "cpxfiddle -w ${WIDTH} -r ${R} -e ${E} -s ${S} -q ${TYPE} -o sunraster -c ${COLOR} -M ${ML} -f ${FORMAT} -l1 ${FILENOPATH} > ${FILENOPATH}.ras" > ${FILE}.ras.sh
		chmod +x ${FILE}.ras.sh
	}
function MakeFigR3()
	{
		unset WIDTH LENGTH R E S TYPE COLOR ML FORMAT FILE
		local WIDTH=$1
		local LENGTH=$2
		local R=$3
		local E=$4
		local S=$5
		local TYPE=$6
		local COLOR=$7
		local ML=$8
		local FORMAT=$9
		local FILE=${10}
		${PATHTOCPXFIDDLE}/cpxfiddle -w ${WIDTH} -r ${R} -e ${E} -s ${S} -q ${TYPE} -o sunraster -c ${COLOR} -M ${ML} -f ${FORMAT} -l1 -L${LENGTH} ${FILE} > ${FILE}.ras | tee -a ${LOGFILE}
		# create script if one wants to change paramerters of the plot
		unset FILENOPATH
		FILENOPATH=`echo ${FILE} | ${PATHGNU}/gawk -F '/' '{print $NF}'`
		echo "cpxfiddle -w ${WIDTH} -r ${R} -e ${E} -s ${S} -q ${TYPE} -o sunraster -c ${COLOR} -M ${ML} -f ${FORMAT} -l1 -L${LENGTH} ${FILENOPATH} > ${FILENOPATH}.ras" > ${FILE}.ras.sh
		chmod +x ${FILE}.ras.sh
	}
function MakeFigR3Auto()
	{
		unset WIDTH LENGTH R E S TYPE COLOR ML FORMAT FILE
		local WIDTH=$1
		local LENGTH=$2
		local R=$3
		local E=$4
		local S=$5
		local TYPE=$6
		local COLOR=$7
		local ML=$8
		local FORMAT=$9
		local FILE=${10}
		${PATHTOCPXFIDDLE}/cpxfiddle -w ${WIDTH} -r ${R} -e ${E} -s ${S} -q ${TYPE} -o sunraster -c ${COLOR} -M ${ML} -f ${FORMAT} -l1 -L${LENGTH} ${FILE} > ${FILE}.ras | tee -a ${LOGFILE}
		# create script if one wants to change paramerters of the plot
		unset FILENOPATH
		FILENOPATH=`echo ${FILE} | ${PATHGNU}/gawk -F '/' '{print $NF}'`
		echo "cpxfiddle -w ${WIDTH} -r ${R} -e ${E} -s ${S} -q ${TYPE} -o sunraster -c ${COLOR} -M ${ML} -f ${FORMAT} -l1 -L${LENGTH} ${FILENOPATH} > ${FILENOPATH}.ras" > ${FILE}.ras.sh
		chmod +x ${FILE}.ras.sh
	}
function MakeFigNoNorm()
	{
		unset WIDTH TYPE COLOR ML FORMAT FILE
		local WIDTH=$1
		local TYPE=$2
		local COLOR=$3
		local ML=$4
		local FORMAT=$5
		local FILE=$6
		${PATHTOCPXFIDDLE}/cpxfiddle -w ${WIDTH} -q ${TYPE} -o sunraster -c ${COLOR} -M ${ML} -f ${FORMAT} -l1 ${FILE} > ${FILE}.ras | tee -a ${LOGFILE}
		# create script if one wants to change paramerters of the plot
		unset FILENOPATH
		FILENOPATH=`echo ${FILE} | ${PATHGNU}/gawk -F '/' '{print $NF}'`
		echo "cpxfiddle -w ${WIDTH} -q ${TYPE} -o sunraster -c ${COLOR} -M ${ML} -f ${FORMAT} -l1 ${FILENOPATH} >  ${FILENOPATH}.ras" > ${FILE}.ras.sh
		chmod +x ${FILE}.ras.sh
	}

function MakeFigR2()
	{
		unset WIDTH TYPE COLOR ML FORMAT FILE WIDTH2
		local WIDTH=$1
		local TYPE=$2
		local COLOR=$3
		local ML=$4
		local FORMAT=$5
		local FILE=$6
		WIDTH2=`echo "${WIDTH} / 2" | bc`
		${PATHTOCPXFIDDLE}/cpxfiddle -w ${WIDTH} -q ${TYPE} -o sunraster -c ${COLOR} -M ${ML} -f ${FORMAT} -l1 ${FILE} -p1 -P${WIDTH2} > ${FILE}.ras | tee -a ${LOGFILE}
		# create script if one wants to change paramerters of the plot
		unset FILENOPATH
		FILENOPATH=`echo ${FILE} | ${PATHGNU}/gawk -F '/' '{print $NF}'`
		echo "cpxfiddle -w ${WIDTH} -q ${TYPE} -o sunraster -c ${COLOR} -M ${ML} -f ${FORMAT} -l1 ${FILE} -p1 -P${WIDTH2} ${FILENOPATH} > ${FILENOPATH}.ras" > ${FILE}.ras.sh
		chmod +x ${FILE}.ras.sh
	}


rm -f ${IMG}.ras 2>/dev/null

case ${TYPE} in 
				"defo")
					MakeFigNoNorm ${WIDTH} normal jet ${ML}/${ML} r4 ${ENVIIMG} 
				;;		
				"amp")
					MakeFigRAuto ${WIDTH} 0,1000 2 5 normal gray ${ML}/${ML} r4 ${ENVIIMG} 
				;;
				"coh")
					MakeFigR ${WIDTH} 0,1 1.5 1.5 normal gray ${ML}/${ML} r4 ${ENVIIMG} 
				;;
				"interf")
					MakeFig ${WIDTH} 1.0 1.2 normal jet ${ML}/${ML} r4 ${ENVIIMG}
				;;
				 

esac

