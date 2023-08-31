#!/bin/bash
# Check polarisation for each Frame/Swath/burst and remove all that are not the same as the one in Parameter
# It will first start by checking if an image exists (with all assembled bursts) in main IMG/Data dir and will clean it as well. 
#
#  Parameter: - expected mode (e.g. VV) 
#
# Mustbe launched in dir where all the S1 data to check are stored in csl format. 
#
# CSL InSAR Suite utilities. 
# NdO (c) 2019/04/04 - could make better with more functions... when time.
# -----------------------------------------------------------------------------------------
PRG=`basename "$0"`
VER="v1.0.0 Beta CIS script utilities"
AUT="Nicolas d'Oreye, (c)2015-2019, Last modified on Apr 26, 2019"
echo " "
echo "${PRG} ${VER}, ${AUT}"
echo " "

EXPECTEDMODE=$1 # eg VV

if [ $# -lt 1 ] ; then echo "Usage $0 EXPECTED_POL (e.g. VV)"; exit; fi

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


SOURCEDIR=$PWD
SpeakOut "Are you sure of your expected polarization ? Beware that all the other pol will be deleted from all the sub directories." 
while true; do
	read -p "Are you sure of your expected polarisation ? Beware that all the other pol wil be deleted from all the sub dir in ${SOURCEDIR}. y/n ?"  yn
	case $yn in
		[Yy]* ) 
			echo "OK let's go for cleaning "
			break ;;
		[Nn]* ) 
			echo "OK, let's get out of this script."
			exit 0
			break ;;
		* ) 
			echo "Please answer yes or no.";;
	esac
done

rm -f ${SOURCEDIR}/Modes_Deleted.txt ${SOURCEDIR}/Modes_Missing.txt

for IMG in `ls -d *.csl`
do 
	echo ""
	echo "Image ${IMG} with expected mode ${EXPECTEDMODE} :"
	cd ${IMG}/Data
	# Clean polarisation of possible assembled images in IMG/Data. 
	###############################################################
	for ASSEMBLEDIMGS in `ls -f ${SOURCEDIR}/${IMG}/Data/SLCData.* 2> /dev/null`	
	do
		# get pol 
		POL="${ASSEMBLEDIMGS##*.}"
		echo ${POL}
		if [ ${POL} != ${EXPECTEDMODE} ]
			then
				# replace ls by rm when sure 
				rm -f ${SOURCEDIR}/${IMG}/Data/SLCData.${POL}
				
				# change SLCImageinfo.txt
				# list the pol as in Info file 
				INFOPOLSIMG=`updateParameterFile ${SOURCEDIR}/${IMG}/Info/SLCImageInfo.txt "Polarisation mode"`
 				echo "info pol is ${INFOPOLSIMG}  "
 				if [[ ${INFOPOLSIMG[*]} =~ ${POL}, ]]
 					then 
 						# Bad pol is not the last in list => remove with comma after
 						NEWINFOPOLSIMG=`echo "${INFOPOLSIMG}" | ${PATHGNU}/gsed "s/${POL},//" `
 
 					else 
 						# Bad pol is the last in list => remove with comma before
 						if [[ ${INFOPOLSIMG[*]} =~ ${POL} ]] ; then 
 							NEWINFOPOLSIMG=`echo "${INFOPOLSIMG}" | ${PATHGNU}/gsed "s/, ${POL}//" `
 						fi
 				fi
 				echo "new info pol is ${NEWINFOPOLSIMG}  "
  				#Keep backup - only for first run
  				if [ ! -s ${SOURCEDIR}/${IMG}/Info/SLCImageInfo.txt.bak ] 
  					then 
  						cp -f ${SOURCEDIR}/${IMG}/Info/SLCImageInfo.txt  ${SOURCEDIR}/${IMG}/Info/SLCImageInfo.txt.bak
  				fi
  				updateParameterFile ${SOURCEDIR}/${IMG}/Info/SLCImageInfo.txt "Polarisation mode" ${NEWINFOPOLSIMG}
			fi
			# Also change SLCImageinfo.txt if only the good pol was present
			# list the pol as in Info file 
			INFOPOLSIMG=`updateParameterFile ${SOURCEDIR}/${IMG}/Info/SLCImageInfo.txt "Polarisation mode"`
 			echo "info pol of general image is ${INFOPOLSIMG}  "
 			echo "new info pol of general image is ${EXPECTEDMODE}  "
  			#Keep backup - only for first run
  			if [ ! -s ${SOURCEDIR}/${IMG}/Info/SLCImageInfo.txt.bak ] 
  				then 
  					cp -f ${SOURCEDIR}/${IMG}/Info/SLCImageInfo.txt  ${SOURCEDIR}/${IMG}/Info/SLCImageInfo.txt.bak
  			fi
  			updateParameterFile ${SOURCEDIR}/${IMG}/Info/SLCImageInfo.txt "Polarisation mode" ${EXPECTEDMODE}
	done 
 	# Clean polarisation for each Frame/Swath/burst
	###############################################
	# List all pol for each Frame, swath and burst
	find ./*/* -name "SLCImageInfo.swath*.burst*.txt" | xargs ${PATHGNU}/grep -E 'Polarisation mode' | ${PATHGNU}/gsed s'%\/\* Polarisation mode \*\/%%g' | ${PATHGNU}/gsed 's/ //g' | ${PATHGNU}/gsed 's/	//g' > ${SOURCEDIR}/${IMG}_PolMode.txt

	# Check Pol for each Frame, swath and burst if contains EXPECTED MODE
	for FRAMESWATHBURSTMODES in `cat ${SOURCEDIR}/${IMG}_PolMode.txt`	
	do 
		#MODES=`echo "${FRAMESWATHBURSTMODES}" | cut -d : -f2 | cut -d / -f1`   # eg VV, VH
		MODES=`echo "${FRAMESWATHBURSTMODES}"  | ${PATHGNU}/gsed -n -e 's/^.*://p'`   # eg VV, VH
		FRAME=`echo "${FRAMESWATHBURSTMODES}" | cut -d. -f2 | cut -d / -f2`   # eg Frame0
		SWATH=`echo "${FRAMESWATHBURSTMODES}" | cut -d . -f4`   # eg swath0
		NSWATH=`echo "${SWATH}" | ${PATHGNU}/grep -Eo "[0-9]*"`
		BURST=`echo "${FRAMESWATHBURSTMODES}" | cut -d . -f5`   # eg burst1
		
		NBURST=`echo "${BURST}" | ${PATHGNU}/grep -Eo "[0-9]*"`
		# ensure that EXPECTED MODE IS IN MODES
		if [[ ${MODES[*]} =~ ${EXPECTEDMODE} ]]  # if list of MODES contains EXPECTEDMODE
			then
   				# if yes : delete all other files and info
   				echo " - in ${FRAME}, ${SWATH}, ${BURST} has the mode(s) ${MODES}"
   				MODES=`echo ${MODES}  | ${PATHGNU}/gsed 's/,/ /g'`
   				for POL in ${MODES} ; do 
					if [ ${POL} != ${EXPECTEDMODE} ]
						then 
							
   							echo "    => Kill uneeded pol ${POL} !!!!!"
   							echo "image ${IMG} in ${FRAME}, ${SWATH}, ${BURST} had unecessary ${POL} polarisation => deleted (expected only ${EXPECTEDMODE})" >> ${SOURCEDIR}/Modes_Deleted.txt
 							# Delete Data
 							# uncomment below when sure and when S1 reader does not read all the 
 							rm -f ${SOURCEDIR}/${IMG}/Data/${FRAME}.csl/Data/SW${NSWATH}.b${NBURST}.${POL}

							
  							# Change Info.txt
  							# list the pol as in Info file 
   							INFOPOLS=`updateParameterFile ${SOURCEDIR}/${IMG}/Data/${FRAME}.csl/Info/SLCImageInfo.swath${NSWATH}.burst${NBURST}.txt "Polarisation mode"`
 							echo "info pol is ${INFOPOLS}  "
 							if [[ ${INFOPOLS[*]} =~ ${POL}, ]]
 								then 
 									# Bad pol is not the last in list => remove with comma after
 									NEWINFOPOLS=`echo "${INFOPOLS}" | ${PATHGNU}/gsed "s/${POL},//" `
 
 								else 
 									# Bad pol is the last in list => remove with comma before
 									if [[ ${INFOPOLS[*]} =~ ${POL} ]] ; then 
 										NEWINFOPOLS=`echo "${INFOPOLS}" | ${PATHGNU}/gsed "s/, ${POL}//" `
 									fi
 							fi
 							echo "new info pol is ${NEWINFOPOLS}  "
  							#Keep backup - only for first run
  							if [ ! -s ${SOURCEDIR}/${IMG}/Data/${FRAME}.csl/Info/SLCImageInfo.swath${NSWATH}.burst${NBURST}.txt.bak ] 
  								then 
  									cp -f ${SOURCEDIR}/${IMG}/Data/${FRAME}.csl/Info/SLCImageInfo.swath${NSWATH}.burst${NBURST}.txt  ${SOURCEDIR}/${IMG}/Data/${FRAME}.csl/Info/SLCImageInfo.swath${NSWATH}.burst${NBURST}.txt.bak
  							fi
  							updateParameterFile ${SOURCEDIR}/${IMG}/Data/${FRAME}.csl/Info/SLCImageInfo.swath${NSWATH}.burst${NBURST}.txt "Polarisation mode" ${NEWINFOPOLS}
						else
   							echo "    => Keep expected pol ${POL}"	
					fi
				done 
			else
   				# if no: send allert and do nothing
   				echo " - in ${FRAME}, ${SWATH}, ${BURST} has NOT the mode(s) ${EXPECTEDMODE} in ${MODES}"
   				echo "image ${IMG} in ${FRAME}, ${SWATH}, ${BURST} had not the expected polarisation : ${EXPECTEDMODE}" >> ${SOURCEDIR}/Modes_Missing.txt

		fi		
	done
	cd ..
	cd ..
	rm -f ${SOURCEDIR}/${IMG}_PolMode.txt
done 

