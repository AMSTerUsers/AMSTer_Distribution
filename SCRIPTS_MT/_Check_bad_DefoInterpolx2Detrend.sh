#!/bin/bash
######################################################################################
# This script look for bad file names (pointing toward inexistant files) in DefoInterpolx2Detrend.txt.  
# This may result from crashes in msbas preparation or cleaning from update of S1 orbits. 
# It also check now for duplicated lines in DefoInterpolx2Detrend.txt. Indeed, it may happen 
# that after updating Primary and/or Secondary image orbits of S1 data, file name might be the same 
# but col 2 (Bp) might differ while it provides the value with more digits. 
#
# Must be launched in MSBAS/region/ dir, i.e. where DefoInterpolx2Detrend and DefoInterpolx2Detrend.txt is. 
#
# Dependencies:	- readlink
#
# Parameter - mode (with index): DefoInterpolx2Detrendi
#			- Path to SAR_MASSPROCESS,  e.g. ${PATH_3601}/SAR_MASSPROCESS
#
# New in V1.1 : 	- made faster and linux compliant...
# New in V1.2 : 	- debug for mac
# New in V2.0 : 	- check if mode.txt exist before starting check...
#					- before deleting the line from MODEi.txt, it tries to rebulid the link 
#					  It may happen indeed that after updating S1 obits, some files are removed from
#					  DefoInterpolx2Detrend and they are not rebuilt because they were already checked and stored in 
#					  Checked_For_CohThreshold_To_Be_Ignored_At_Next_Rebuild_msbas_Header.txt
# New in V3.0 : 	- more robust for Linux while checking link
#					- also check for diuplicated pairs. If Duplicated lines, remove the ones that 
#				      contains values in col 2 that does not fit with Bp in InSARParameters.txt
#					- also check if link is not broken but if pir dir is missing in SAR_MASSPROCESS
# New in V3.1 :		- revised and also clean list of files from coherence cleaning thresold and Out of Range filtering
# New in V3.2 :		- only search to clean existing list of files if Missing_files.txt exists
#					- some cleaning
#					- prefer readlink to get original target of link
# New in V3.3 :		- wrong path for OUTRANGEFILES
# New in V3.4 : 	- proper cleaning of MODEi.txt
# New in V3.5 : 	- replace if -s as -f -s && -f to be compatible with mac os if 
# New in Distro V 4.0 20231030:	- Rename MasTer Toolbox as AMSTer Software
#								- rename Master and Slave as Primary and Secondary (though not possible in some variables and files)
# New in Distro V 4.1 20250318:	- allow searching for dir name after SAR_MASSPROCESS also when dir is named SAR_MASSPRPCESS_2 in PATHTOGEOCODED and SATTRK
#
# AMSTer: SAR & InSAR Automated Mass processing Software for Multidimensional Time series
# NdO (c) 2019/12/05 - could make better... when time.
# -----------------------------------------------------------------------------------------
PRG=`basename "$0"`
VER="Distro V40 AMSTer script utilities"
AUT="Nicolas d'Oreye, (c)2016-2019, Last modified on Oct 30, 2023"
echo " "
echo "${PRG} ${VER}, ${AUT}"
echo " "

MODE=$1				# e.g. DefoInterpolx2Detrend1 (with index)
MASSPROCESS=$2 		# e.g. ${PATH_3601}/SAR_MASSPROCESS

if [ ! -s ${MODE}.txt ] ; then echo "${MODE}.txt is empty - quitting" ; exit 0 ; fi
if [ $# -lt 2 ] ; then echo “Usage $0 MODEi PATH_TO_SAR_MASSPROCESS”; exit; fi

RNDM1=`echo $(( $RANDOM % 10000 ))`

cp -f ${MODE}.txt ${MODE}_back.txt

FIRSTFILE=`find ${MODE} -maxdepth 1 -name "*deg" | head -1`
#ORIGINALTARGET=`ls -l ${FIRSTFILE} | cut -d \> -f 2`  # suppose that there is at least one file already in ${MODE}
#ORIGINALTARGET=`ls -l ${FIRSTFILE} | cut -d ">" -f 2- | cut -d "/" -f 2-`
#ORIGINALTARGET="/${ORIGINALTARGET}"			# Full path and name of one of the defo map in SAR_MASSPROCESS. Attention it is dependant of the disk mounting  
ORIGINALTARGET=`readlink ${FIRSTFILE}`

PATHTOGEOCODEDMOUNTPT=`dirname ${ORIGINALTARGET}`	# dir where original geocoded defo maps are stored in SAR_MASSPROCESS.
# because the script may be launched on a computer with another OS let's get rid of disk mounting path 
# For that, one must replace everything until SAR_MASSPROCESS by ${MASSPROCESS}
#PATHTOGEOCODED=`echo ${PATHTOGEOCODEDMOUNTPT} | ${PATHGNU}/gawk -F"SAR_MASSPROCESS" '/SAR_MASSPROCESS/{print "'${MASSPROCESS}'" $2}' `
# more robust (eg for SAR_MASSPROCESS and SAR_MASSPROCESS_2) though without pattern matching 
#PATHTOGEOCODED=$(echo "${PATHTOGEOCODEDMOUNTPT}" | ${PATHGNU}/gawk -F"SAR_MASSPROCESS[^/]*" '{print "'${MASSPROCESS}'" $2}')
PATHTOGEOCODED=$(echo "${PATHTOGEOCODEDMOUNTPT}" | ${PATHGNU}/gawk -F"SAR_MASSPROCESS[^/]*" '/SAR_MASSPROCESS/{print "'${MASSPROCESS}'" $2}')

#get SAT/TRK/Region without trailing /Geocoded/Mode
#SATTRK=`echo ${PATHTOGEOCODED} | awk -F"SAR_MASSPROCESS" '/SAR_MASSPROCESS/{print "" $2}' | ${PATHGNU}/gsed 's/\/Geocoded.*//' `
# more robust (eg for SAR_MASSPROCESS and SAR_MASSPROCESS_2) though without pattern matching 
SATTRK=$(echo ${PATHTOGEOCODED} | ${PATHGNU}/gawk -F"SAR_MASSPROCESS[^/]*" '/SAR_MASSPROCESS/{print "" $2}' | ${PATHGNU}/gsed 's/\/Geocoded.*//')

# First check that no lines contains the same file name with different Bp
# Cut first col only (file name), sort and display only duplicated lines
for DUPLICATED in `cat ${MODE}.txt | ${PATHGNU}/gawk -F " " '{print $1}' | sort | uniq -d`
do
	grep ${DUPLICATED} ${MODE}.txt > Duplic_${RNDM1}.txt
	while read PATHFILETOCHECK BP MAS SLV
		do
			parameterFilePath=`find ${MASSPROCESS}/${SATTRK}/ -maxdepth 1 -type d -name "*${MAS}*${SLV}*"`
			parameterFilePath=${parameterFilePath}/i12/TextFiles/InSARParameters.txt
			BPINTXTFILE=`updateParameterFile ${parameterFilePath} "Perpendicular baseline component at image centre"`
			#	if [ `echo "${BP} != ${BPINTXTFILE}" | bc` -eq 1  ] # float testing 
			if [ "${BP}" != "${BPINTXTFILE}" ]
				then 
					# remove that line 
					${PATHGNU}/gsed -i.trash "/${BP}/d" ${MODE}.txt 
					# do not remove the line in Checked_For_CohThreshold_To_Be_Ignored_At_Next_Rebuild_msbas_Header.txt because 
					# one of the file is ok and hence can be ignored at next rebuild
			fi 
	done < Duplic_${RNDM1}.txt
	rm -f ${MODE}.txt.trash  Duplic_${RNDM1}.txt
done 

# search for line in MODEi.txt file that points toward no file in MODEi dir
while read PATHFILETOCHECK BP MAS SLV
	do	
		FILETOCHECK=`basename ${PATHFILETOCHECK}`
		if [ ! -e ./${PATHFILETOCHECK} ]  # if file Modei/file (what ever type of file) does not exist in MSBAS/region 
			then 
				# list files that does not exist
				echo ${FILETOCHECK} >> Missing_files_${RNDM1}_tmp.txt
		
		fi  
done < ${MODE}.txt

if [ -f "Missing_files_${RNDM1}_tmp.txt" ] && [ -s "Missing_files_${RNDM1}_tmp.txt" ] 
	then 
		sort Missing_files_${RNDM1}_tmp.txt | uniq > Missing_files_${RNDM1}.txt

		# Clean MODEi.txt 
			mv -f ${MODE}.txt ${MODE}_Inclunding_Missing_Files_tmp.txt
			sort ${MODE}_Inclunding_Missing_Files_tmp.txt | uniq > ${MODE}_Inclunding_Missing_Files.txt
			rm -f ${MODE}_Inclunding_Missing_Files_tmp.txt
			${PATHGNU}/grep -Fv -f Missing_files_${RNDM1}.txt ${MODE}_Inclunding_Missing_Files.txt > ${MODE}.txt  
 
		# Clean possisble _Full text file which would result from restiction of msbas to coh threshol 
		# Run that here even if one rune also the present script on _Full dir because here it cleans the right _Full.txt
			if [ -d ${MODE}_Full ] && [ -f "${MODE}_Full/${MODE}_Full.txt" ] && [ -s "${MODE}_Full/${MODE}_Full.txt" ] ; then
				mv -f ${MODE}_Full/${MODE}_Full.txt ${MODE}_Full/${MODE}_Full_Inclunding_Missing_Files_tmp.txt
				sort ${MODE}_Full/${MODE}_Full_Inclunding_Missing_Files_tmp.txt | uniq > ${MODE}_Full/${MODE}_Full_Inclunding_Missing_Files.txt
				rm -f ${MODE}_Full/${MODE}_Full_Inclunding_Missing_Files_tmp.txt
				${PATHGNU}/grep -Fv -f Missing_files_${RNDM1}.txt ${MODE}_Full/${MODE}_Full_Inclunding_Missing_Files.txt > ${MODE}_Full/${MODE}_Full.txt  # remove from ${PATHMODE}_Inclunding_Broken_Links.txt each line that contains what is in lines of CleanedLinks.txt
			fi
  
		# remove missing files from Checked_For_CohThreshold_To_Be_Ignored_At_Next_Rebuild_msbas_Header.txt if any
		COHIGNORE=Checked_For_CohThreshold_To_Be_Ignored_At_Next_Rebuild_msbas_Header.txt
		 if [ -f "${MODE}/${COHIGNORE}" ] && [ -s "${MODE}/${COHIGNORE}" ] ; then
			mv -f ${MODE}/${COHIGNORE} ${MODE}/${COHIGNORE}_Inclunding_Missing_Files_tmp.txt
			sort ${MODE}/${COHIGNORE}_Inclunding_Missing_Files_tmp.txt | uniq > ${MODE}/${COHIGNORE}_Inclunding_Missing_Files.txt
			rm -f ${MODE}/${COHIGNORE}_Inclunding_Missing_Files_tmp.txt
			 ${PATHGNU}/grep -Fv -f Missing_files_${RNDM1}.txt ${MODE}/${COHIGNORE}_Inclunding_Missing_Files.txt > ${COHIGNORE}  # remove from ${COHIGNORE}_Inclunding_Missing_Files.txt each line that contains what is in lines of Missing_files_${RNDM1}.txt
		 fi
  
		# remove missing files from all Out or Range files (e.g. Out_Of_Range_20m_400days.txt) if any
		if [ `ls ${MODE}/Out_Of_Range_*.txt 2>/dev/null | wc -l` -ge 1 ] 
			then 
				for OUTRANGEFILES in `ls ${MODE}/Out_Of_Range_*.txt`
					do 
						if [ -f "${OUTRANGEFILES}" ] && [ -s "${OUTRANGEFILES}" ] ; then
							mv -f ${OUTRANGEFILES} ${OUTRANGEFILES}_Inclunding_Missing_Files_tmp.txt
							sort ${OUTRANGEFILES}_Inclunding_Missing_Files_tmp.txt | uniq > ${OUTRANGEFILES}_Inclunding_Missing_Files.txt
							rm -f ${OUTRANGEFILES}_Inclunding_Missing_Files_tmp.txt
							${PATHGNU}/grep -Fv -f Missing_files_${RNDM1}.txt ${OUTRANGEFILES}_Inclunding_Missing_Files.txt > ${OUTRANGEFILES}  # remove from ${COHIGNORE}_Inclunding_Missing_Files.txt each line that contains what is in lines of CleanedLinks.txt
							rm -f ${OUTRANGEFILES}_Inclunding_Missing_Files.txt
						fi   	
				done
		fi

		rm -f Missing_files_${RNDM1}_tmp.txt Missing_files_${RNDM1}.txt 
fi


echo +++++++++++++++++++++++++++++++++++++++++++++++
echo "ALL DefoInterpolx2Detrend's .txt CHECKED - HOPE IT WORKED"
echo +++++++++++++++++++++++++++++++++++++++++++++++

