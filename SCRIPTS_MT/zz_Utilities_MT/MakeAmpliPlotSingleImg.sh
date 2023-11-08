#!/bin/bash
# -----------------------------------------------------------------------------------------
# This script is aiming at creating an amplitude (module) image from a single image. 
# It will be computed in the present directory in subdirectory named SAT_TRK_ML_ZOOM_AMPLI/DATE
#
# Input data MUST be store in a /SAR_CSL/SAT/TRK/NoCrop/image.csl dir as it takes the sat, trk and date from that structure
#
# Parameters :  - path to image
# 				- path to param file in the form of ___V20220719_LaunchParamAmpli
#
# Hard coded:	- 
#
# Dependencies:	 
#		- gsed
#		- grep
#		- cpxfiddle
#
#
# New in Distro V 1.1:	- create fake hdr with module image and clean Data in OUTPUTDATA
# New in Distro V 1.2 (Jul 20, 2022):	- mute overwriting cutAndZoomCSLImage
#										- skip cutAndZoomCSLImage if not needed... 
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

PATHIMG=$1					# PATH TO IMG in .csl format
PARAMFILE=$2				# Path to param file

if [ $# -lt 2 ] ; then 
		echo "Wrong nr of arguments. Please enter: ${PRG} PATH_TO_IMG.csl PATH_TO_PARAM_FILE"
fi

# Function to extract parameters from config file: search for it and remove tab and white space
function GetParam()
	{
	unset PARAM 
	PARAM=$1
	PARAM=`${PATHGNU}/grep -m 1 ${PARAM} ${PARAMFILE} | cut -f1 -d \# | ${PATHGNU}/gsed "s/	//g" | ${PATHGNU}/gsed "s/ //g"`
	eval PARAM=${PARAM}
	echo ${PARAM}
	}
	
	
# extract param from file
ML=`GetParam ML`			# ML, multilooking factor 
ZOOM=`GetParam ZOOM`		# ZOOM, zoom factor
PIXFORM=`GetParam PIXFORM`	# PIXFORM, shape of output pixel (SQUARE or ORIGINAL)
DEM=`GetParam DEM`			# DEM, path to DEM 

CROP=`GetParam CROP`			# CROP, CROPyes or CROPno 

COORDSYST=`GetParam COORDSYST`  # COORDSYST, Coordinate system [SRA if crop given below in pix/ GEO if crop given below in lat long]
LLXC=`GetParam LLXC`            # LLXC, lower left corner X coordinate
LLYC=`GetParam LLYC`            # LLYC, lower left corner Y coordinate 
URXC=`GetParam URXC`            # URXC, upper right corner X coordinate
URYX=`GetParam URYX`            # URYX, upper right corner Y coordinate
KML=`GetParam KML`              # KML, kml file path (.kml polygon saved from Google Earth)

REGION=`GetParam REGION`              # REGION, name of cropped region 


# Extract param from file path
SAT=`echo ${PATHIMG} | ${PATHGNU}/grep -o 'SAR_CSL.*' | cut -d / -f 2`  	# name of satellite. Img is suppose dto be strored in a /SAR_CSL/ dir as usual 
TRK=`echo ${PATHIMG} | ${PATHGNU}/grep -o 'SAR_CSL.*' | cut -d / -f 3`		# track (must be the same as name of dir where data are stored)
DATEIMG=`echo ${PATHIMG} | ${PATHGNU}/grep -o 'SAR_CSL.*' | cut -d / -f 5 |  ${PATHGNU}/grep -Eo "[0-9]{8}" `				# Date of Img

if [ "${DATEIMG}" == "" ] ; then 
	echo "Seems that I can't find a date for the image. Check the path"
	echo "It must be something like: .../SAR_CSL/SAT/TRK/NoCrop/IMG.csl "
	exit 0
fi
SOURCEDIR=$(pwd)

# some fcts

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
	
 function RatioPix()
 	{
 	unset MLTEMP 
 	local MLTEMP=$1 # ML factor to adapt
 	echo "- - - Compute ratio and transform input parameters in Range and Azimuth to get square pix - - -" 
 	# Ratio is not the same for ERS/ENVISAT than S1
 	if [ "${RATIO}" -eq 1 ] 
 		then 
 			echo "Az sampling (${AZSAMP}m) is similar to Range sampling (${RGSAMP}m)." 
 			echo "   Probably processing square pixel data such as RS, CSK or TSX." 
 			echo "Uses following Azimuth and Range factors: ${MLTEMP} and ${MLTEMP}"
 			RGML=${MLTEMP}
 			AZML=${MLTEMP}	
 		else
 			RET=$(echo "$RGSAMP < $AZSAMP" | bc )  # Trick needed for if to compare integer nrs
 			if [ ${RET} -ne 0 ] 
 				then
 					MLTEMP2=`echo "(${MLTEMP}*${RATIOREAL})" | bc` # Integer
 					echo "Az sampling (${AZSAMP}m) is larger than Range sampling (${RGSAMP}m)." 
 					echo "   Probably processing Sentinel data." 
 					echo "Uses following Azimuth and Range factors: ${MLTEMP} and ${MLTEMP2}"
 					RGML=${MLTEMP2}
 					AZML=${MLTEMP}
 				else
 					MLTEMP2=`echo "(${MLTEMP}/${RATIOREAL})" | bc` # Integer
 					echo "Az sampling (${AZSAMP}m) is smaller than Range sampling (${RGSAMP}m)." 
 					echo "   Probably processing ERS or Envisat data." 
 					echo "Uses following Azimuth and Range factors: ${MLTEMP2} and ${MLTEMP}"
 					RGML=${MLTEMP}
 					AZML=${MLTEMP2}	
 			fi	
 			unset RET	
 	fi
 	# round ratio
 	RGML=`echo ${RGML} | xargs printf "%.*f\n" 0`  # rounded
 	AZML=`echo ${AZML} | xargs printf "%.*f\n" 0`  # rounded
 
 	echo "- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -"
 	}
 	
# Some basics
INCIDANGL=`updateParameterFile ${PATHIMG}/Info/SLCImageInfo.txt "Incidence angle at median slant range [deg]"` # not rounded

case ${PIXFORM} in 
	"SQUARE")
		echo "Request squared pixels shape. Shall compute the pixel ratio and adapt ML accordingly"

		RGSAMP=`updateParameterFile ${PATHIMG}/Info/SLCImageInfo.txt "Range sampling [m]"`   # not rounded 
		AZSAMP=`updateParameterFile ${PATHIMG}/Info/SLCImageInfo.txt "Azimuth sampling [m]"` # not rounded
		
		echo "Range sampling : ${RGSAMP}"
		echo "Azimuth sampling : ${AZSAMP}"
		echo "DO NOT considere here the Incidence angle (${INCIDANGL}) because we want to square the pixels in Slant Range !! "
		
		# Do not take incidence angle into account because we intend to display squared pixels in Slant Range 
		#RATIO=`echo "scale=2; ( s((${INCIDANGL} * 3.1415927) / 180) * ${AZSAMP} ) / ${RGSAMP}" | bc -l | xargs printf "%.*f\n" 0` # with two digits and rounded to 0th decimal
		#RATIOREAL=`echo "scale=5; ( s((${INCIDANGL} * 3.1415927) / 180) * ${AZSAMP} ) / ${RGSAMP}" | bc -l` # with 5 digits 
		# MSG="Incidence angle taken into account to square pixels in Ground Range"
		
		RATIO=`echo "scale=2; (  ${AZSAMP} / ${RGSAMP} )" | bc -l | xargs printf "%.*f\n" 0` # with two digits and rounded to 0th decimal
		RATIOREAL=`echo "scale=5; ( ${AZSAMP} / ${RGSAMP} )" | bc -l` # with 5 digits 
		MSG="Incidence angle not taken into account to square pixels in Slant Range"

				echo "--------------------------------"
		echo "Pixel Ratio is ${RATIO}"
		echo "Pixel Ratio as Real is ${RATIOREAL}"
		echo ${MSG}
		echo "--------------------------------"
		echo ""

		RatioPix ${ML}
		MLX=${RGML}
		MLY=${AZML}
		unset RGML
		unset AZML
		;;
	"ORIGINAL")
		echo "Request original pixels shape. Keep same ML in Az and Rge"

		MLX=${ML}
		MLY=${ML}
		;;	
		*)
		echo "I do not understand the pixel shape you want. Please set param PIXFORM as SQUARE or ORIGINAL in Param file"
		exit 0
		;;	
esac

case ${CROP} in 
	"CROPyes")
		if [ "${LLXC}" == "0" ] && [ "${LLYC}" == "0" ] && [ "${URXC}" == "0" ] && [ "${URYX}" == "0" ] 
			then 
				# crop using kml
				if [ ! -f ${KML} ] 
					then 
						echo "Ask for Crop without providing corners nor kml; please check param file" 
						exit 0 
					else 
						echo "Crop wit kml file" 
						KMLNAME=$(basename ${KML})
						OUTDATA=${SOURCEDIR}/${SAT}_${TRK}_ML${ML}_ZOOM${ZOOM}_AMPLI_${PIXFORM}_Crop_${REGION}_${KMLNAME}/${DATEIMG}.csl
				fi
			else 
				# crop using corners
				OUTDATA=${SOURCEDIR}/${SAT}_${TRK}_ML${ML}_ZOOM${ZOOM}_AMPLI_${PIXFORM}_Crop_${REGION}_${LLXC}_${LLYC}_${URXC}_${URYX}/${DATEIMG}.csl
		fi
		;;
	"CROPno")
		OUTDATA=${SOURCEDIR}/${SAT}_${TRK}_ML${ML}_ZOOM${ZOOM}_AMPLI_${PIXFORM}_NoCrop/${DATEIMG}.csl
		;;	
	*)
		echo "I do not understand the if you want crop or not. Please set CROPYes or CROPNo in Param file"
		exit 0
		;;		
esac

mkdir -p ${OUTDATA}

# Let's go.. 
cutAndZoomCSLImage ${OUTDATA}/Crop.txt -create
updateParameterFile ${OUTDATA}/Crop.txt "Input file path in CSL format" ${PATHIMG}
updateParameterFile ${OUTDATA}/Crop.txt "Output file path" ${OUTDATA}
updateParameterFile ${OUTDATA}/Crop.txt "Georeferenced DEM file path" ${DEM}
updateParameterFile ${OUTDATA}/Crop.txt "X zoom factor" ${ZOOM}
updateParameterFile ${OUTDATA}/Crop.txt "Y zoom factor" ${ZOOM}

case ${CROP} in 
	"CROPyes")
		if [ ! -f ${KML} ] || [ "${KML}" == "" ]
			then 
				echo "==> Use ${COORDSYST} coordinates:"
				updateParameterFile ${OUTDATA}/Crop.txt "Coordinate system" ${COORDSYST}
				updateParameterFile ${OUTDATA}/Crop.txt "X0 = lower left corner X coordinate" ${LLXC}
				updateParameterFile ${OUTDATA}/Crop.txt "Y0 = lower left corner Y coordinate" ${LLYC}
				updateParameterFile ${OUTDATA}/Crop.txt "X2 = upper right corner X coordinate" ${URXC}
				updateParameterFile ${OUTDATA}/Crop.txt "Y2 = upper right corner Y coordinate" ${URYX}
			else 
				echo "==> Use kml coordinates:"
				updateParameterFile ${OUTDATA}/Crop.txt "kml file path" ${KML}
		fi
		;;
	"CROPno")
		echo "==> Perform no crop"
		;;	
esac

if [ "${CROP}" == "CROPno" ] && [ "${ML}" == "1" ] && [ "${ZOOM}" == "1" ]
	then 
		echo "Skip Cut and Zoom"
		#cp -Rf ${PATHIMG}/* ${OUTDATA}
		ln -s ${PATHIMG}/* ${SOURCEDIR}/${SAT}_${TRK}_ML${ML}_ZOOM${ZOOM}_AMPLI_${PIXFORM}_NoCrop/${DATEIMG}.csl/
	else 
		echo "Perform cutAndZoomCSLImage"
		echo "Y" | cutAndZoomCSLImage ${OUTDATA}/Crop.txt > /dev/null
fi 

amplitudeImageReduction ${OUTDATA} ${MLX} ${MLY} # PathToImg xReductionFactor yReductionFactor

MODIMG=`updateParameterFile ${OUTDATA}/Info/modImageInfo.txt "Channel 1 outputFilename"`
XSIZE=`updateParameterFile ${OUTDATA}/Info/modImageInfo.txt "SLC X size"`
YSIZE=`updateParameterFile ${OUTDATA}/Info/modImageInfo.txt "SLC Y size"`

XSIZEML=`echo "(${XSIZE} / ${MLX}) " | bc -l | cut -d . -f 1` # truncated as integer
XSIZE=${XSIZEML}

cd ${OUTDATA}


mv -f ${OUTDATA}/Data/${MODIMG} ${OUTDATA}/Data/${DATEIMG}_${MODIMG}
MakeFig ${XSIZE} 1.0 6.0 normal gray ${MLX}/${MLY} r4 ${OUTDATA}/Data/${DATEIMG}_${MODIMG}

mv -f ${OUTDATA}/Data/${DATEIMG}_${MODIMG} ${OUTDATA}/${DATEIMG}_${MODIMG}
mv -f ${OUTDATA}/Info/modImageInfo.txt ${OUTDATA}/${DATEIMG}_modImageInfo.txt
mv -f ${OUTDATA}/Data/${DATEIMG}_${MODIMG}.ras ${OUTDATA}/${DATEIMG}_${MODIMG}.ras
mv -f ${OUTDATA}/Data/${DATEIMG}_${MODIMG}.ras.sh ${OUTDATA}/${DATEIMG}_${MODIMG}.ras.sh

# Create fake .hdr for mod file
echo -e "ENVI \r" > ${OUTDATA}/${DATEIMG}_${MODIMG}.hdr
echo -e "description = {\r" >> ${OUTDATA}/${DATEIMG}_${MODIMG}.hdr
echo -e "  Fake header for amplitude image in slant range with ML ${MLX}/${MLY}, Zoom ${ZOOM} and incidence angle ${INCIDANGL} }\r" >> ${OUTDATA}/${DATEIMG}_${MODIMG}.hdr
echo -e "samples = ${XSIZE}\r" >> ${OUTDATA}/${DATEIMG}_${MODIMG}.hdr
echo -e "lines   = ${YSIZE}\r" >> ${OUTDATA}/${DATEIMG}_${MODIMG}.hdr
echo -e "bands   = 1\r" >> ${OUTDATA}/${DATEIMG}_${MODIMG}.hdr
echo -e "header offset = 0\r" >> ${OUTDATA}/${DATEIMG}_${MODIMG}.hdr
echo -e "file type = ENVI Standard\r" >> ${OUTDATA}/${DATEIMG}_${MODIMG}.hdr
echo -e "data type = 4\r" >> ${OUTDATA}/${DATEIMG}_${MODIMG}.hdr
echo -e "interleave = bsq\r" >> ${OUTDATA}/${DATEIMG}_${MODIMG}.hdr
echo -e "sensor type = ${SAT}\r" >> ${OUTDATA}/${DATEIMG}_${MODIMG}.hdr
echo -e "byte order = 0\r" >> ${OUTDATA}/${DATEIMG}_${MODIMG}.hdr

# Clean data 
if [ -d ${OUTDATA}/${DATEIMG}/Data ] ; then
	rm -rf ${OUTDATA}/${DATEIMG}/Data
	rm -rf ${OUTDATA}/${DATEIMG}/Headers
fi
