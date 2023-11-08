#!/bin/bash
######################################################################################
# This script look for duplicated products in dir based on pair of dates that is in the name. 
# Duplicate products may happen in SAR_MASSPROCESS/../Geocoded/Mode (where Mode is e.g. DefoInterpolx2Detrend)
# when a pair is reprocessed with updated orbit with resulting slightly different Bp.
# It then offers to interactively delete the oldest version of ducplicated files (if rm -i in line 62) 
# or delete them without warning if you are brave enough, or move it to ___Duplicated_ToKill.
# USE WITH CARE IF NOT INTERACTIVE 
# For deleting ras in /GeocodedRasters/Mode, see Remove_Duplicate_Pairs_File_ras.sh
#
# DO NOT USE IT ON GEOCODED AMPLITUDE IMAGES because mas and slv can be geocoded within the same pair 
#
# Must be launched in dir where all files ending with deg are present. 
#
# Depedencies: 	- gnu find !! (Macport findutils)
#				- xargs
#
# New in V1.1:	- mode duplicates to ___Duplicated_ToKill
#				- add security to avoid Ampli
#				- remove also the ras
# New in V1.2:	- made faster by using ${PATHGNU}/grep instead of twice find and grep
# New in V1.3:	- remove also Quarantained files
# New in V1.4: 	- count nr of duplic instead of checking if Duplic file is not empty
# New in V1.5 (Sept 21, 2022): - remove stray \ before _ while calling grep to cope with new grep syntax and avoid waring
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

eval SOURCEDIR=$PWD

MODE=`echo ${PWD##*/}`
if [ "${MODE}" == "Ampli" ] 
	then 
		echo "  // Only check for Quanrantained Ampli. "
		echo "  // Do not clean duplicated Ampli because it will delete ampli files of Primary or Secondary image that would be computed from the same pair" 
	else 
		echo "  // Searching for all files containing pair of dates (yyyymmdd_yyyymmdd) and ending with deg... " 
		$PATHGNU/find . -maxdepth 1 -type f -name "*deg" -print0 | xargs -0 echo | ${PATHGNU}/grep -Eo "[0-9]{8}_[0-9]{8}" > List_Pairs_Serached_For_Ducplic.txt
		# count how many duplicated lines 
		NRDUPLIC=`sort List_Pairs_Serached_For_Ducplic.txt | uniq -cd | wc -l`
		# count how many lines in total 
		TOT=`cat List_Pairs_Serached_For_Ducplic.txt | wc -l`

		# show how many times each line is present in file
		#sort List_Pairs_Serached_For_Ducplic.txt | uniq -c
		if [ ${NRDUPLIC} -gt 0 ]
			then 
				# count how many duplicated lines 
				#NRDUPLIC=`sort List_Pairs_Serached_For_Ducplic.txt | uniq -cd | wc -l`


				echo "  //   Directory ${SOURCEDIR} "
				echo "  //   contains ${TOT} ${MODE} files, among which ${NRDUPLIC} are duplicated pairs. "
				echo "  //   See list below (nr_occurrence   date_date):"
				# show only duplicates lines 
				sort List_Pairs_Serached_For_Ducplic.txt | uniq -cd > Duplicated_Files.txt
				echo "  //  Corresponding files are: "
		
				mkdir -p ___Duplicated_ToKill
		
				for DATES in `sort List_Pairs_Serached_For_Ducplic.txt | uniq -d`
				#while read -r NR DATES
					do 
						${PATHGNU}/find . -maxdepth 1 -type f -name "*${DATES}*deg" -printf "%T@ %Tc %p\n" | sort -n
						echo "  //   Search for the oldest: " 
						OLDEST=`${PATHGNU}/find . -maxdepth 1 -type f -name "*${DATES}*deg" -printf "%T@ %Tc %p\n" | sort -n | head -1`
						OLDESTFILE=`echo "${OLDEST}" | cut -d "/" -f2`
						echo "  // remove ${OLDESTFILE} and its hdr:"
						#rm ${OLDESTFILE}
						#rm ${OLDESTFILE}.hdr
						#rm -i ${OLDESTFILE}
						#rm -i ${OLDESTFILE}.hdr
						mv ${OLDESTFILE}* ___Duplicated_ToKill/
				done
				#done < Duplicated_Files.txt
				
				rm -f List_Pairs_Serached_For_Ducplic.txt Duplicated_Files.txt 
			else 
				echo "  //   Directory ${SOURCEDIR} "
				echo "  //   contains ${TOT} ${MODE} files, among which none are duplicated pairs. "
		fi
		
fi

echo ""

# Search for products with Quanrantained data

	# Path to possible Quarantained files for each mode 
	###################################################

	# SAT and TRK are resp. the dir name at 5 and 4 levels below pwd
	SAT=`pwd | rev | cut -f5 -d'/' - | rev`
	TRK=`pwd | rev | cut -f4 -d'/' - | rev`
	QUARANT=${PATH_1650}/SAR_CSL/${SAT}/${TRK}/Quarantained
	
	#could add here a check of Quarantained list and remove products from these pairs
	if [ `ls ${QUARANT}/*.csl 2>/dev/null | wc -l` -ge 1 ] ; then 
		cd ${QUARANT}
		ls -d *.csl | cut -d "_" -f 3 | cut -d "." -f 1 > ${QUARANT}/List_Dates_Quarantained.txt	# should provide the data whatever the sat
		
		cd ${SOURCEDIR}
		mkdir -p ___from_Quanrantained_img/

		for DATEIMG in `cat ${QUARANT}/List_Dates_Quarantained.txt`
			do 
				if [ `ls *${DATEIMG}* 2>/dev/null | wc -l` -ge 1 ] ; then
					mv -f *${DATEIMG}* ${SOURCEDIR}/___from_Quanrantained_img/
				fi
		done 
		rm -f ${QUARANT}/List_Dates_Quarantained.txt
	fi	

echo "+++++++++++++++++++++++++++++++++++++++++++++++"
echo " ALL ${MODE} FILES CHECKED - HOPE IT WORKED"
echo "+++++++++++++++++++++++++++++++++++++++++++++++"

