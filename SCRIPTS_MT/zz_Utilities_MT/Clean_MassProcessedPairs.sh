#!/bin/bash
######################################################################################
# This script remove all what is in pair dirs as obtained from a mass processing and 
# keep only the TextFiles, i.e. to keep what is required when preparing the MSBAS processing. 
# Pair dirs names are kept as well as it may need to check what is already processed. 
#
# Attention, option to keep some stiffs in the hope of being able to re-geocode or 
# 			re-unwrap later has not been tested. Hope nothing would be missing...
#			Maybe you want to make some tests firsts. 
#
# Dependencies: - none
#
# Parameter:	- PATH to dir that contains all the PAIR_DIRS from a mass processing
#				- level of cleaning: 
#					all : means remove all but /i12/TextFiles/InSARParameters.txt and masterSLCImageInfo.txt 
#					moderate: keeps unwrapped and coh stuffs (if one wants to re-geocode later; not tested though !) 
#					light: keep (filtered) interferogram & unwrapped and coh (if one wants to re-unwrap later; not tested though !) 
#
# I know, it is a bit messy and can be improved.. when time. But it works..
# N.d'Oreye, v 1.0 2018/02/023 -                         
######################################################################################

PAIRDIRS=$1
LEVEL=$2

# check nr of arguments
if [ $# -lt 2 ] 
	then 
		echo “Usage $0 SAR_MASSPROCESS_PATH LEVEL_OF_CLEANING” 
		echo "Must provide with the path to the dir that contains all pair_dirs resulting "
		echo "from a mass processing and the level of cleaning : (all, moderate or light)."
		echo "	all : 		means remove all but /i12/TextFiles/InSARParameters.txt and masterSLCImageInfo.txt "
		echo "	moderate:	keeps unwrapped and coh stuffs (if one wants to re-geocode later; not tested though !) "
		echo "	light: 		keep (filtered) interferogram & unwrapped and coh (if one wants to re-unwrap later; not tested though !) "
		exit
fi



# check that PAIRDIRS contains at least a Geocoded dir, which would prove that it is indeed 
# a dir where mass processing was performed
cd ${PAIRDIRS}
if [ `ls -d "Geocoded" 2> /dev/null | wc -l` -gt 0 ] 
	then
		echo "OK, ${PAIRDIRS} contains at least a dir named Geocoded. "
	else
		echo "Sorry, ${PAIRDIRS} does not contain a dir named Geocoded. "
		echo "It seems you are not in a SAR_MASSPROCESS type dir. Too dangerous to proceed. STOP here "
		exit
fi

for DIRS in `find . -maxdepth 1 -type d -name "*_*"`
	do
		cd ${DIRS}
		if [ `ls -d "i12" 2>/dev/null | wc -l` -gt 0 ] 
			then
				cd i12
				rm -Rf SBInSARProducts
				rm -f TextFiles/slaveSLCImageInfo.txt
				case $LEVEL in 
					"all")
						echo "Clean ${DIRS}"
						rm -Rf GeoProjection
						rm -Rf InSARProducts
						rm -f TextFiles/geoProjectionParameters.txt TextFiles/*.kml TextFiles/snaphu.conf
					;;
					"moderate")
						# keeps unwrapped and coh stuffs (if one wants to re-geocode later)
						echo "Clean ${DIRS}"
						cd InSARProducts
						rm -f deformationMap* firstPhaseComponent* interfero* incidence residualInterferogram* *.mod *.sigma0
						rm -Rf  *.csl 
						cd ..
					;;
					"light")
						# keep (filtered) interferogram & unwrapped and coh
						echo "Clean ${DIRS}"
						cd InSARProducts
						#rm -f *.mod 
						rm -t *.sigma0 
						#rm -Rf  *.csl 
						cd ..
					;;
					*)
						echo "I do not understand the level of cleaning you want. Muste be all, moderate or light. Exit"
						exit
					;;
			 
		
				esac
				cd ..
			else 
				echo "Does not contains i12 dir; Skip this directory"
		fi	
		cd ..
done

echo +++++++++++++++++++++++++++++++++++++++++++++++
echo "ALL DIRS CLEANED - HOPE IT WORKED"
echo +++++++++++++++++++++++++++++++++++++++++++++++


