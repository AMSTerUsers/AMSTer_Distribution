#!/bin/bash
# -----------------------------------------------------------------------------------------
# This script is aiming at creating a gif animation with the geocoded product (coh, resid interf, defo or ampl) from all pairs in dir
#
# MUST BE LAUNCHED FROM DIR WHERE PAIRS ARE PROCESSED 
#
#
# Parameters :  - product: coh, interf, defo or ampl
#				- remark (optional) for end product naming
#
# Dependencies:	 
#    	- convert (to create/crop jpg images)
#
# Hard coded:	- Path to .bashrc (sourced for safe use in cronjob)
#
#
# New in Distro V 1.0:	- Based on developpement version 2.7 and Beta V1.1.3
#               V 1.0.1: - remove log files older than 30 days
#               V 1.0.2: - Cosmetic... clean header
# 
# MasTer: InSAR Suite automated Mass processing Toolbox. 
# NdO (c) 2016/03/25 - could make better... when time.
# -----------------------------------------------------------------------------------------
PRG=`basename "$0"`
VER="Distro V1.0.2 MasTer script utilities"
AUT="Nicolas d'Oreye, (c)2016-2019, Last modified on Mar 01, 2022"
echo " "
echo "${PRG} ${VER}, ${AUT}"
echo "Processing launched on $(date) " 
echo " " 

# vvv ----- Hard coded lines to check --- vvv 
source ${HOME}/.bashrc
# ^^^ ----- Hard coded lines to check --- ^^^ 

PRODUCT=$1
REM=$2

if [ $# -lt 1 ] ; then echo “Usage $0 PRODUCT   where PRODUCT= coh, interf, defo or ampl” ; exit 0; fi

case ${PRODUCT} in 
	"coh")  
		TAG="coherence*deg.ras" 
		;;
	"defo")  
		TAG="deformationMap.interpolated.UTM.*.bil.interpolated*deg.ras"
		;;		
	"interf")  
		TAG="residualInterferogram.*.f.UTM*deg.ras"
		;;
	"ampl")  
		TAG="*.mod.UTM.*deg.ras" 
		;;
	*)  
		echo "Unknown option. Please select coh, interf, defo or ampl"
		echo
		exit 0;;
esac

# Check OS
OS=`uname -a | cut -d " " -f 1 `
echo "Running on ${OS}"

# list all coh files from 
 find . -maxdepth 4 -name ${TAG} -type f > List.txt 
 
#if [ "${PRODUCT}" == "ampl" ] ; then 
	# Must sort out the mas and slv
#fi
 # create jpg -  - flip for ease of comparison between modes
	DATECELL=" -gravity SouthWest -undercolor white -font Helvetica -pointsize 12 -fill black -annotate +5+10 "

for PAIRFILE in `cat List.txt`
do 
	echo "Processin ${PAIRFILE}"
	PAIR=`echo ${PAIRFILE} | cut -d / -f 2 | cut -d _ -f 1-2`
	if [ "${PRODUCT}" == "ampl" ] 
		then 
			#img to porecess is twice in name
			MAS=`echo ${PAIR} | cut -d _ -f 1`
			SLV=`echo ${PAIR} | cut -d _ -f 2`
			if [ `echo ${PAIRFILE} | ${PATHGNU}/grep -o -i ${MAS}  | wc -l` -gt  `echo ${PAIRFILE} | ${PATHGNU}/grep -o -i ${SLV} | wc -l` ] ; then IMG=${MAS} ; else IMG=${SLV} ; fi
			echo "   for image ${IMG}"
			${PATHCONV}/convert -format jpg -quality 100% -sharpen 0.1 -resize '1640>' ${DATECELL} "${IMG}" ${PAIRFILE} ${IMG}.jpg
		else 
			# S1 are huge and if jpg size is too small, pix are averaged and unusable for quick look
			${PATHCONV}/convert -format jpg -quality 100% -sharpen 0.1 -resize '1640>' ${DATECELL} "${PAIR}" ${PAIRFILE} ${PAIR}.jpg
#			${PATHCONV}/convert -format jpg -quality 100% -sharpen 0.1 -resize '640>' ${DATECELL} "${PAIR}" ${PAIRFILE} ${PAIR}.jpg
	fi
	echo
done

${PATHCONV}/convert -delay 50 *jpg _${PRODUCT}${REM}.gif
rm -f List.txt *.jpg



