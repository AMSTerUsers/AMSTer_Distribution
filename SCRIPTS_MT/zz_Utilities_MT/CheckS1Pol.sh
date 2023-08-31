#!/bin/bash
# Check order of polarisation for each burst and ensure it is the same everywhere
#
# Mustbe launched in dir where all the S1 data to check are stored in csl format. 
#
# CSL InSAR Suite utilities. 
# NdO (c) 2019/04/04 - could make better with more functions... when time.
# -----------------------------------------------------------------------------------------
PRG=`basename "$0"`
VER="v1.0.0 Beta CIS script utilities"
AUT="Nicolas d'Oreye, (c)2015-2019, Last modified on Apr 04, 2019"
echo " "
echo "${PRG} ${VER}, ${AUT}"
echo " "

SOURCEDIR=$PWD

function SpeakOut()
	{
	unset MESSAGE 
	local MESSAGE
	MESSAGE=$1

	# Check OS
	OS=`uname -a | cut -d " " -f 1 `

	case ${OS} in 
		"Linux") 
			espeak "${MESSAGE}" ;;
		"Darwin")
			say "${MESSAGE}" 	;;
		*)
			echo "${MESSAGE}" 	;;
	esac			
	}

for IMG in `ls -d *.csl`
do 
	cd ${IMG}/Data
	for FRAMES in `ls -d Frame*.csl`
	do
		# Get polarisation mode for each Frame, swath and burst in one list. 
		# In that list of pol mode, use sed to seach in each line (g) for ":" and remove everything from the beginning of teh file (^) till ":", 
		#    then take only one times each repeated line. Count the number of output: if everything is ok, the number of different modes must be 1 and only one
		#
		NROFMODES=`find ./*/* -name "SLCImageInfo.swath*.burst*.txt" | xargs grep -E 'Polarisation mode' | gsed 's/^[^:]*//g' | uniq | wc -l`
		if [ ${NROFMODES} != "1" ]
			then 
				echo 
				# Get polarisation mode for each Frame, swath and burst in one file
				find ./*/* -name "SLCImageInfo.swath*.burst*.txt" | xargs grep -E 'Polarisation mode'  > ${SOURCEDIR}/${IMG}_PolMode.txt
				
				echo "Not all pol modes are identical and in same order in image ${IMG} "
				echo "   -> check ${SOURCEDIR}/${IMG}_PolMode.txt"
				SpeakOut "Check image ${IMG}"
					
			else 
				echo "All pol modes are identical and in same order in image ${IMG}"
		fi
	done
	cd ${SOURCEDIR}

done 
