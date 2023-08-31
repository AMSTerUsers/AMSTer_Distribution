#!/bin/bash
# This script aims at rebuilding amplitude ras and jpg figures from envi files in all
#   pairs directories in current directory (usually SAR_SM/AMPLITUDES/SAT/TRK/REGION/)
# It also add the date as label in the jpg figure at provided position
#
# Parameters are:
#		- flip or flop
#		- position of date label X and Y in jpg fig of mod
#
# Dependencies:	- FLIPproducts.py.sh and FLOPproducts.py.sh Python3 scripts
#
# New in V1.1 :	- parallelised to nr of max CPU -1 
#
# CSL InSAR Suite utilities. 
# NdO (c) 2017/12/29 - could make better with more functions... when time.
# -----------------------------------------------------------------------------------------

PRG=`basename "$0"`
VER="v1.1  CIS script utilities"
AUT="Nicolas d'Oreye, (c)2016-2018, Last modified on March 08, 2023"
echo " "
echo "${PRG} ${VER}, ${AUT}"
echo " "

FLIPFLOP=$1 # flip or flop
LABELX=$2	# e.g. 4050 
LABELY=$3	# e.g. 560

SOURCEDIR=$PWD


# test nr of CPUs
# Check OS
OS=`uname -a | cut -d " " -f 1 `

case ${OS} in 
	"Linux") 
		NCPU=`nproc` 	;;
	"Darwin")
		NCPU=`sysctl -n hw.ncpu` 
		
		# must define a function because old bash on Mac does not know wait -n option
		waitn ()
		{ StartJobs="$(jobs -p)"
		  CurJobs="$(jobs -p)"
		  while diff -q  <(echo -e "$StartJobs") <(echo -e "$CurJobs") >/dev/null
		  do
		    sleep 1
		    CurJobs="$(jobs -p)"
		  done
		}
		
		;;
esac			

CPU=$((NCPU-1))
echo "// Run max ${CPU} processes at a time "




function GetParamFromFile()
	{
	unset CRITERIA FILETYPE
	local CRITERIA
	local FILETYPE
	CRITERIA=$1

	unset parameterFilePath KEY

	local KEY
	local parameterFilePath 

	KEY=`echo ${CRITERIA} | tr ' ' _`

	updateParameterFile ${SOURCEDIR}/${PAIRDIRS}/i12/TextFiles/InSARParameters.txt ${KEY}
	}

function CreateHDR()
	{
	unset SAMPLES LINES TYPE UTMXmin UTMYmin FILE CREADATE
	local SAMPLES=$1
	local LINES=$2
	local FILE=$3
	TYPE=4
	UTMXmin=1
	UTMYmin=1
	
	CREADATE=`date`
	echo -e "ENVI \r" > ${FILE}.hdr
	echo -e "description = {\r" >> ${FILE}.hdr
	echo -e "  Create New File Result ${CREADATE}}\r" >> ${FILE}.hdr
	echo -e "samples = ${SAMPLES}\r" >> ${FILE}.hdr
	echo -e "lines   = ${LINES}\r" >> ${FILE}.hdr
	echo -e "bands   = 1\r" >> ${FILE}.hdr
	echo -e "header offset = 0\r" >> ${FILE}.hdr
	echo -e "file type = ENVI Standard\r" >> ${FILE}.hdr
	echo -e "data type = ${TYPE}\r" >> ${FILE}.hdr
	echo -e "interleave = bsq\r" >> ${FILE}.hdr
	echo -e "sensor type = ${SATDIR}\r" >> ${FILE}.hdr
	echo -e "byte order = 0\r" >> ${FILE}.hdr
	echo -e "map info = {Dummy, ${UTMXmin}, ${UTMYmin}, 0 ,  0 ,  1 , 1 ,  WGS-84, units=Degrees}\r" >> ${FILE}.hdr
	echo -e "data ignore value = -32768\r" >> ${FILE}.hdr

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
		eval FILE=${FILE}
		${PATHTOCPXFIDDLE}/cpxfiddle -w ${WIDTH} -e ${E} -s ${S} -q ${TYPE} -o sunraster -c ${COLOR} -M ${ML} -f ${FORMAT} -l1 ${FILE} > ${FILE}.ras | tee -a ${LOGFILE}
		# create script if one wants to change paramerters of the plot
		#unset FILENOPATH
		#FILENOPATH=`echo ${FILE} | ${PATHGNU}/gawk -F '/' '{print $NF}'`
		rm -f ${FILE}.ras.sh
		echo "cpxfiddle -w ${WIDTH} -e ${E} -s ${S} -q ${TYPE} -o sunraster -c ${COLOR} -M ${ML} -f ${FORMAT} -l1 ${FILE} >  ${FILE}.ras" > ${FILE}.ras.sh		chmod +x ${FILE}.ras.sh
	}

# Check if all links in dir points toward existing files  
for PAIRDIRS in `ls | ${PATHGNU}/grep -v txt | ${PATHGNU}/grep -v _AMPLI`
do
	if test "$(jobs | wc -l)" -ge ${CPU} 
		then
			case ${OS} in 
				"Linux") 
					wait -n 	;;
				"Darwin")
					waitn		;;
			esac	
	fi
	# Run tests in pseudo parallelism
	{


	echo " // Check ${PAIRDIRS}"
	cd ${PAIRDIRS}/i12/InSARProducts

	for IMG in `ls *.mod *.sigma0 2>/dev/null`
	do 
		echo "${FLIPFLOP} images ${IMG}"
		MASX=`GetParamFromFile "Reduced master amplitude image range dimension [pix]" `
		MASY=`GetParamFromFile "Reduced master amplitude image azimuth dimension [pix]" `
		
		DATECELL=" -gravity SouthWest -undercolor white -font Helvetica -pointsize 12 -fill black -annotate"
		POSDATECELL=" +${LABELX}+${LABELY} "
		
		DATEVAL=`echo "${IMG}" | ${PATHGNU}/grep -Eo "[0-9]{8}"`
		
		case ${FLIPFLOP} in 
			"flip"|"FLIP")
				rm -f ${IMG}.flip 2>/dev/null
				FLIPproducts.py.sh ${IMG} ${MASY}
				rm -f ${IMG}.flip.hdr 2>/dev/null
				CreateHDR ${MASX} ${MASY} "${IMG}.flip"

				echo "Create raster"
				MLS1FIG=4 # 4 for S1 WS; 1 for others
				rm -f ${IMG}.flip.ras 2>/dev/null
				MakeFig ${MASX} 1.0 1.5 normal gray ${MLS1FIG}/1 r4 ${IMG}.flip

				echo "Create jpg"
				rm -f ${IMG}.flip.jpg 2>/dev/null
				${PATHCONV}/convert -format jpg -quality 100% -sharpen 0.1 -contrast-stretch 0.15x0.5% -resize '10640>' ${IMG}.flip.ras ${IMG}.flip_temp.jpg 2> /dev/null
				${PATHCONV}/convert ${DATECELL}${POSDATECELL} "${DATEVAL}" ${IMG}.flip_temp.jpg ${IMG}.flip.jpg 2> /dev/null
				rm -f ${IMG}.flip_temp.jpg
				;;
			"flop"|"FLOP")
				rm -f ${IMG}.flop 2>/dev/null
				FLOPproducts.py.sh ${IMG} ${MASY}
				rm -f ${IMG}.flop.hdr 2>/dev/null
				CreateHDR ${MASX} ${MASY} "${IMG}.flop"

				echo "Create raster"
				MLS1FIG=4 # 4 for S1 WS; 1 for others
				rm -f ${IMG}.flop.ras 2>/dev/null
				MakeFig ${MASX} 1.0 1.5 normal gray ${MLS1FIG}/1 r4 ${IMG}.flop
	
				echo "Create jpg"
				rm -f ${IMG}.flop.jpg 2>/dev/null
				${PATHCONV}/convert -format jpg -quality 100% -sharpen 0.1 -contrast-stretch 0.15x0.5% -resize '10640>' ${IMG}.flop.ras ${IMG}.flop_temp.jpg 2> /dev/null
				${PATHCONV}/convert ${DATECELL}${POSDATECELL} "${DATEVAL}" ${IMG}.flop_temp.jpg ${IMG}.flop.jpg 2> /dev/null
				rm -f ${IMG}.flop_temp.jpg
				;;
			*)
				echo "Enter flip or flop as first parameter. Can't work; exit"
				exit
				;;
		esac

	done

	cd ${SOURCEDIR} 
	echo
	} &
done
wait
 

