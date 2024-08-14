#!/bin/bash
# -----------------------------------------------------------------------------------------
# This script is aiming at removing from a prepared msbas data set (eg DefoInterpolx2Detrend2) 
# all the images that would be empty on a selected zone provided by a kml.
# It is intended to run after build_header_msbas_criteria.sh or 
# after build_header_msbas_criteria_From_nvi_name_WithoutAcqTime.sh 
# and before running MSBAS.sh. Wrong images will be deleted.
#
# Run this for each mode to be cleaned. 
#
# Select the kml zone where you know signal must be non zero
#
#  Script must be launched in the dir where msbas will be run, which contains all the Modei and Modei.txt. 
#
# Parameters are : 
#       - mode to clean; beware of index at the end of name (eg DefoInterpolx2Detrend2)
#		- kml of zone where to test the validity
#		- path to defo (from mode) files : SAR_MASSPROCESS/SAT/TRK/REGION_ML/Geocoded/DefoInterpolx2Detrend
#
#       
# Dependencies:	- function getStatForZoneInFile from AMSTer Engine
#    			- bc (for basic computations in scripts)
#
# New in Distro V 1.0:	- Based on developpement version and Beta V1.1
# New in Distro V 1.1:	- compliant with dir with lots of files...
# New in Distro V 1.2:	- change find links becasue find seems to behave differently now... 
# New in Distro V 1.3:	- set proper double quote in some lines 
# New in Distro V 1.4: - remove stray \ before _ while calling grep to cope with new grep syntax and avoid waring
# New in Distro V 2.0: - run as much test in parallel as there are CPUs minus one (to be sure...) using only bash fct
# New in Distro V 3.0 20231030:	- Rename MasTer Toolbox as AMSTer Software
#								- rename Master and Slave as Primary and Secondary (though not possible in some variables and files)
# New in Distro V 3.1 20240813:	- For Mac OSX, use coreutils fct gnproc instead of sysctl -n hw.ncpu 
#
# AMSTer: SAR & InSAR Automated Mass processing Software for Multidimensional Time series
# NdO (c) 2016/03/07 - could make better with more functions... when time.
# -----------------------------------------------------------------------------------------
PRG=`basename "$0"`
VER="Distro V3.1 AMSTer script utilities"
AUT="Nicolas d'Oreye, (c)2016-2019, Last modified on Aug 13, 2024"
echo " "
echo "${PRG} ${VER}, ${AUT}"
echo "Processing launched on $(date) " 
echo " " 

MODETOCLEAN=$1		# Mode to clean, i.e. MODEi as in MSBAS_RESULTS/MODEi
KML=$2				# Zone where to test if signal exist  
PATHTOMOD=$3		# path to mode files : SAR_MASSPROCESS/SAT/TRK/REGION_ML/Geocoded/MODE

echo ""

RNDM1=`echo $(( $RANDOM % 10000 ))`
RUNDATE=`date "+ %m_%d_%Y_%Hh%Mm" | ${PATHGNU}/gsed "s/ //g"`
# Dump Command line used in CommandLine.txt
echo "$(dirname $0)/${PRG} run with following arguments :" > CommandLine_${PRG}_${RUNDATE}_${RNDM1}.txt
echo $@ >> CommandLine_${PRG}_${RUNDATE}_${RNDM1}.txt

RUNDIR=$(pwd)

if [ ! -d ${RUNDIR}/${MODETOCLEAN} ] ; then echo " You seems to be in the wrong dir or there is no mode to clean as claimed" ; exit ; fi
if [ $# -lt 3 ] ; then echo "Usage $0 ModeToClean Kml PathToGeocodedModeFiles"; exit; fi

echo "backup ${MODETOCLEAN}"
cp -R ${RUNDIR}/${MODETOCLEAN} ${RUNDIR}/${MODETOCLEAN}_Full_${RUNDATE}_${RNDM1}
cp ${RUNDIR}/${MODETOCLEAN}.txt ${RUNDIR}/${MODETOCLEAN}_Full_${RUNDATE}_${RNDM1}.txt

cd ${RUNDIR}/${MODETOCLEAN}

rm -rf discarded_pairs.txt

# test nr of CPUs
# Check OS
OS=`uname -a | cut -d " " -f 1 `

case ${OS} in 
	"Linux") 
		NCPU=`nproc` 	;;
	"Darwin")
		#NCPU=`sysctl -n hw.ncpu` 
		NCPU=$(gnproc)
		
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
echo "Run max ${CPU} processes at a time "

#for IMGTOTEST in `ls *deg`
for IMGTOTEST in `${PATHGNU}/gfind . -maxdepth 1 -lname "*deg"`
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
		PAIR=`echo "${IMGTOTEST}" | ${PATHGNU}/grep -Eo "_[0-9]{8}_[0-9]{8}_" ` # select _date_date_ where date is 8 numbers
		SGNLFILE=`ls ${PATHTOMOD} | ${PATHGNU}/grep ${PAIR} | ${PATHGNU}/grep -v .hdr  | ${PATHGNU}/grep -v .ras  | ${PATHGNU}/grep -v .xml` # avoid hdr but also xml if files were open in a gis or ras just in case... 
		CHECKSGNL=`getStatForZoneInFile ${PATHTOMOD}/${SGNLFILE} ${KML}` # gives the mean coh in zone 
		
		TSTREAL=`echo " ${CHECKSGNL} * ${CHECKSGNL} > 0 " | bc -l`   # Test here if |value| > 0 i.e. exists. 
			
		if [ ${TSTREAL} -eq 1 ]
			then 
				echo "Mean signal in kml is at least ${CHECKSGNL} ; Zone is ok in ${PAIR}"
			else 
				echo "${PAIR} seems wrong in kml zone (${CHECKSGNL} )."
				echo "${PAIR} seems wrong in kml zone (${CHECKSGNL} )." >> Pairs_Empty_in_kml.txt
				echo "Discard ${IMGTOTEST}"
				echo 
				echo "${IMGTOTEST}" >> discarded_pairs.txt
				rm -f ${RUNDIR}/${MODETOCLEAN}/${IMGTOTEST}
				grep -v ${PAIR} ${RUNDIR}/${MODETOCLEAN}.txt > ${RUNDIR}/${MODETOCLEAN}_tmp.txt
				rm ${RUNDIR}/${MODETOCLEAN}.txt
				mv ${RUNDIR}/${MODETOCLEAN}_tmp.txt ${RUNDIR}/${MODETOCLEAN}.txt
		fi
	} &
done 
wait 

cp ${KML} ${RUNDIR}/${MODETOCLEAN}

echo "-----------------------------------------------------------------"
echo " You better plot a new baseline plot to check your new data base : "
echo " See PlotBaselineGeocMSBAS.sh"
echo "-----------------------------------------------------------------"


