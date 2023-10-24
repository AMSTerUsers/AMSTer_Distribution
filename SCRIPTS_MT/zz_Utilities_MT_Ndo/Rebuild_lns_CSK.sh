#!/bin/bash
# This script aims at rebuilding links to CSK images as expected after reading, that is from
# 	../${REGION}_${MODE}/NoCrop/${IMGDATE}.csl 
# to 
#	../${REGION}/${IMGDATE}.csl 
#
# Must be launched in ../${REGION}_${MODE}/NoCrop/ where images are 
#
# Parameters are:
#		- Region 
#
# Dependencies:	- bc, gsed
#
# New in V1.1 :	- 
# CSL InSAR Suite utilities. 
# NdO (c) 2017/12/29 - could make better with more functions... when time.
# -----------------------------------------------------------------------------------------

PRG=`basename "$0"`
VER="v1.0  CIS script utilities"
AUT="Nicolas d'Oreye, (c)2016-2018, Last modified on Oct 17, 2023"
echo " "
echo "${PRG} ${VER}, ${AUT}"
echo " "

REGION=$1  			# e.g. Virunga

SOURCEDIR=$PWD		# e.g. PATH_1650/SAR_CSL/CSK/Virunga_Asc/NoCrop
cd ..
cd .. 

TARGETROOTDIR=$PWD	# e.g. PATH_1650/SAR_CSL/CSK

cd ${SOURCEDIR}

echo "Shall link images from ${SOURCEDIR} to ${TARGETROOTDIR}/${REGION}"

for DIR in `find . -maxdepth 1 -type d -name "*.csl" -printf "%f\n" ` # list dirs without leading ./
do
	DIRNOEXT=`echo ${DIR} | cut -d . -f 1`	
	cd ${DIR}/Info
	MODE=`grep "Heading direction" SLCImageInfo.txt | cut -d " " -f 1 | ${PATHGNU}/gsed "s/ending//"`

	IMGDATE=`echo "${DIR}" | ${PATHGNU}/grep -Eo "[0-9]{8}" ` # select 8 characters string from dir name 

	echo "Image ${DIR} is orbit ${MODE} " 
	echo "  Shall create link from ${DIR} to ${TARGETROOTDIR}/${REGION}" 
	cd ..	# exit from Info
	cd ..	# exit from DIR

	# add link 
	
	# CHECK IF EXISTS ALREADY 
	NRCSK=`ls -d ${TARGETROOTDIR}/${REGION}/${DIRNOEXT}* 2> /dev/null | wc -l |  ${PATHGNU}/gsed 's/[^0-9]*//g'`
	case ${NRCSK} in
		"0") 
			echo "  because ${NRCSK} image with that name yet"
			# first (or only) image at that date - create simple name 
			ln -s ${SOURCEDIR}/${DIR} ${TARGETROOTDIR}/${REGION}
			;;
		"1") 
			echo "  though ${NRCSK} link to an image with the same date already exists "
			# Check its mode (asc or desc)
			EXISTMODE=`grep "Heading direction" ${TARGETROOTDIR}/${REGION}/${DIR}/Info/SLCImageInfo.txt | cut -d " " -f 1 | ${PATHGNU}/gsed "s/ending//"`
			if [ "${MODE}" == "${EXISTMODE}" ]
				then 
					echo "  with the same heading (${MODE}) => no need to duplicate "
				else 
					echo "  with a different heading (${EXISTMODE} instead of ${MODE}) => need to create a new link with indexes"

					# check if already indexed:
					if [ -e "${TARGETROOTDIR}/${REGION}/${DIR}" ] || [ -L "${TARGETROOTDIR}/${REGION}/${DIR}" ]; then
					    echo "Existing link has no index yet => first index the existing link."
						# Rename existing image.csl as image_1.csl
						mv ${TARGETROOTDIR}/${REGION}/${DIR} ${TARGETROOTDIR}/${REGION}/${DIRNOEXT}_1.csl
					fi
					# name the second image at the same date as image_2.csl
					ln -s ${SOURCEDIR}/${DIR} ${TARGETROOTDIR}/${REGION}/${DIRNOEXT}_2.csl
			fi
			;;
		"2"|"3") 
			echo "  though ${NRCSK} links to a images with the same date already exist."
			echo "  This is uncommon, though I will check that it is a true new image, that is with a different heanding and acquisition timing."
	
			ACQTIME=`grep "Acquisition time" ${SOURCEDIR}/${DIR}/Info/SLCImageInfo.txt | ${PATHGNU}/grep -Eo "[0-9]{2}:[0-9]{2}:[0-9]{2}" `
			INDEX=`echo "${NRCSK} + 1" | bc -l` # i.e. new image will be given index 3 or 4

			# check if index 1 and 2 have the same headings 
			EXISTMODE1=`grep "Heading direction" ${TARGETROOTDIR}/${REGION}/${DIRNOEXT}_1.csl/Info/SLCImageInfo.txt | cut -d " " -f 1 | ${PATHGNU}/gsed "s/ending//"`
			EXISTMODE2=`grep "Heading direction" ${TARGETROOTDIR}/${REGION}/${DIRNOEXT}_2.csl/Info/SLCImageInfo.txt | cut -d " " -f 1 | ${PATHGNU}/gsed "s/ending//"`

			ACQTIMEMODE1=`grep "Acquisition time" ${TARGETROOTDIR}/${REGION}/${DIRNOEXT}_1.csl/Info/SLCImageInfo.txt | ${PATHGNU}/grep -Eo "[0-9]{2}:[0-9]{2}:[0-9]{2}" `
			ACQTIMEMODE2=`grep "Acquisition time" ${TARGETROOTDIR}/${REGION}/${DIRNOEXT}_2.csl/Info/SLCImageInfo.txt | ${PATHGNU}/grep -Eo "[0-9]{2}:[0-9]{2}:[0-9]{2}" `

			if [ "${MODE}" == "${EXISTMODE1}" ] 
				then 
					if [ "${ACQTIME}" == "${ACQTIMEMODE1}" ]
						then 
							echo "  Same heading (${MODE}) and acquisition time (${ACQTIME}) => no need to duplicate "
						else 
							echo "  Same heading (${MODE}) but new acquisition time (${ACQTIMEMODE1} instead of ${ACQTIME}) =>  need to create a new link with indexes"

							# check if already indexed:
							if [ -e "${TARGETROOTDIR}/${REGION}/${DIR}" ] || [ -L "${TARGETROOTDIR}/${REGION}/${DIR}" ]; then
							    echo "Existing link has no index yet => first index the existing link."
								# Rename existing image.csl as image_1.csl
								mv ${TARGETROOTDIR}/${REGION}/${DIR} ${TARGETROOTDIR}/${REGION}/${DIRNOEXT}_1.csl
							fi
							# name the second image at the same date as image_INDEX.csl
							ln -s ${SOURCEDIR}/${DIR} ${TARGETROOTDIR}/${REGION}/${DIRNOEXT}_${INDEX}.csl

					fi
				else 
					if [ "${MODE}" == "${EXISTMODE2}" ] 
						then 
							if [ "${ACQTIME}" == "${ACQTIMEMODE2}" ]
								then 
									echo "  Same heading (${MODE}) and acquisition time (${ACQTIME}) => no need to duplicate "
								else 
									echo "  Same heading (${MODE}) but new acquisition time (${ACQTIMEMODE2} instead of ${ACQTIME}) =>  need to create a new link with indexes"

									# check if already indexed:
									if [ -e "${TARGETROOTDIR}/${REGION}/${DIR}" ] || [ -L "${TARGETROOTDIR}/${REGION}/${DIR}" ]; then
									    echo "Existing link has no index yet => first index the existing link."
										# Rename existing image.csl as image_1.csl
										mv ${TARGETROOTDIR}/${REGION}/${DIR} ${TARGETROOTDIR}/${REGION}/${DIRNOEXT}_1.csl
									fi
									# name the second image at the same date as image_INDEX.csl
									ln -s ${SOURCEDIR}/${DIR} ${TARGETROOTDIR}/${REGION}/${DIRNOEXT}_${INDEX}.csl
									
								fi
						
						else 
							echo "  Mode is none of ${EXISTMODE1} nor ${EXISTMODE2} ? Please check ; Exit "
							exit
					fi
				
			fi
			;;
		*) 
			echo "  though ${NRCSK} links do already exist and pointing toward images with the same date and/or mode and/or acquisition time, which is very unlikely !  "
			echo "  Exiting here. If this was correct though, modify the script  "
			exit 
			;;



	esac
	echo
done


