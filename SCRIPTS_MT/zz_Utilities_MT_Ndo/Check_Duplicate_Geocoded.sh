#!/bin/bash
######################################################################################
# This script look for duplicated products in Geocoded and GeocodedRasters files. This may happen when a 
# pair is reprocessed e.g. with updated orbit with resulting slightly different Bp.
#
# Must be launched in SAR_MASSPROCESS where /Geocoded and /GeocodedRasters. 
#
# WARNING: for unknown reason, the find function sometimes tooks over 100 times the same step
#          resulting in meaningless list of duplicated files or dates. 
#   REBOOTING the computer usulaly solve it. If not possible, re-running the script usually also works.  
#
# New in Distro V 1.1: - remove stray \ before _ while calling grep to cope with new grep syntax and avoid waring
# New in Distro V 1.2 (Jul 19, 2023): - replace if -s as -f -s && -f to be compatible with mac os if 
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

rm -f MODES.TXT 
# Check available modes
ls Geocoded > MODES.TXT # List all modes 
#NROFALLMODE=`wc -l < MODES.TXT`

for MODE in `cat MODES.TXT` ;  do

  echo "****** Check Geocoded/${MODE}"
	cd Geocoded/${MODE}
	find . -maxdepth 1 -name "*deg" -type f -print > FilesToCheck.txt
	find . -maxdepth 1 -name "*deg.hdr" -type f -print > HeadersToCheck.txt
	
	rm -f _DuplicateFiles.txt DatesDeg.txt
	rm -f _DuplicateHeaders.txt  DatesHdr.txt
	
	# deg files

	# select date of master or dates of pair
	if [ "${MODE}" == "Ampli" ] 
		then # one must check the date at the beginning of line instead of pair
			for lines in `cat FilesToCheck.txt` ; do
					MASMOD=`echo "${lines}" | cut -d m -f 1 ` # select date.POL. at beginning of the line
					#MASDATE=`echo "${lines}" | cut -d. -f 2 | ${PATHGNU}/grep -Eo "[0-9]{8}" ` # select date at beginning of the line, before the first dot which is actually second because of heading ./
					# count occurrence of MAS date in FilesToCheck.txt
					# if more than one => list in file
					if [ `grep ${MASMOD} FilesToCheck.txt | wc -l` -gt 1 ] ; then
						grep ${MASMOD} FilesToCheck.txt >> _DuplicateFiles.txt
					fi 
			done
		else 
			# cut around pair date, sort and uniq then search in FilesToCheck.txt the possible reminaing pairs
			for lines in `cat FilesToCheck.txt` ; do
				echo "${lines}" | ${PATHGNU}/grep -Eo "_[0-9]{8}_[0-9]{8}_" >> DatesDeg.txt
			done
	fi


	# deg.hdr files
	# select date of master or dates of pair
	if [ "${MODE}" == "Ampli" ] 
		then # one must check the date at the beginning of line instead of pair
			for lines in `cat HeadersToCheck.txt` ; do
				MASMOD=`echo "${lines}" | cut -d m -f 1 ` # select date.POL. at beginning of the line
				#MASDATE=`echo "${lines}" | cut -d. -f 2 | ${PATHGNU}/grep -Eo "[0-9]{8}" ` # select date at beginning of the line, before the first dot which is actually second because of heading ./
				# count occurrence of MAS date in FilesToCheck.txt
				# if more than one => list in file
				if [ `grep ${MASMOD} HeadersToCheck.txt | wc -l` -gt 1 ] ; then
					grep ${MASMOD} HeadersToCheck.txt >> _DuplicateHeaders.txt
				fi 
			done
		else 
			for lines in `cat HeadersToCheck.txt` ; do
				echo "${lines}" | ${PATHGNU}/grep -Eo "_[0-9]{8}_[0-9]{8}_" >> DatesHdr.txt
			done
	fi
	
	# deg files
	if [ -f DatesDeg.txt ] ; then sort DatesDeg.txt | uniq -d > _DuplicateDatesDeg.txt ; fi
	if [ -f _DuplicateDatesDeg.txt ] && [ -s _DuplicateDatesDeg.txt ]
		then 
			for pairlines in `cat _DuplicateDatesDeg.txt` ; do
				grep ${pairlines} FilesToCheck.txt >> _DuplicateFiles.txt
			done
		else 
			rm -f _DuplicateDatesDeg.txt 
	fi
	rm -f DatesDeg.txt
	
	# deg.hdr files
	if [ -f DatesHdr.txt ] ; then sort DatesHdr.txt | uniq -d > _DuplicateDatesHdr.txt ; fi
	if [ -f _DuplicateDatesHdr.txt ] && [ -s _DuplicateDatesHdr.txt ]
		then 
			for pairlines in `cat _DuplicateDatesHdr.txt` ; do
				grep ${pairlines} HeadersToCheck.txt >> _DuplicateHeaders.txt
			done
		else 
			rm -f _DuplicateDatesHdr.txt
	fi
	rm -f DatesHdr.txt
	rm -f FilesToCheck.txt HeadersToCheck.txt
	cd ../..	

  echo "****** Check GeocodedRasters/${MODE}"
 	cd GeocodedRasters/${MODE}
 	find . -maxdepth 1 -name "*.ras" -type f > RasToCheck.txt

	rm -f _DuplicateRasters.txt  Dates.txt
 	
 	# select date of master or dates of pair
 	if [ "${MODE}" == "Ampli" ] 
		then # one must check the date at the beginning of line instead of pair
			for lines in `cat RasToCheck.txt` ; do
				MASMOD=`echo "${lines}" | cut -d m -f 1 ` # select date.POL. at beginning of the line
				#MASDATE=`echo "${lines}" | cut -d. -f 2 | ${PATHGNU}/grep -Eo "[0-9]{8}" ` # select date at beginning of the line, before the first dot which is actually second because of heading ./
				# count occurrence of MAS date in FilesToCheck.txt
				# if more than one => list in file
				if [ `grep ${MASMOD} RasToCheck.txt | wc -l` -gt 1 ] ; then
					grep ${MASMOD} RasToCheck.txt >>  _DuplicateRas.tmp.txt
				fi 
			done
		else 
 			for lines in `cat RasToCheck.txt` ; do
				echo "${lines}" | ${PATHGNU}/grep -Eo "_[0-9]{8}_[0-9]{8}_" >> Dates.txt
			done
 	fi
	
	if [ -f Dates.txt ] ; then sort Dates.txt | uniq -d > _DuplicateDates.txt ; fi
	if [ -f _DuplicateDates.txt ] && [ -s _DuplicateDates.txt ]
		then 
			for pairlines in `cat _DuplicateDates.txt` ; do
				grep ${pairlines} RasToCheck.txt >> _DuplicateRasters.txt
			done
		else 
			rm -f _DuplicateDates.txt
	fi
	rm -f Dates.txt
	rm -f RasToCheck.txt
	cd ../..	

done

rm MODES.TXT

echo +++++++++++++++++++++++++++++++++++++++++++++++
echo "ALL FILES CHECKED - HOPE IT WORKED"
echo +++++++++++++++++++++++++++++++++++++++++++++++

