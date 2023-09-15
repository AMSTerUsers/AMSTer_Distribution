#!/bin/bash
# -----------------------------------------------------------------------------------------
# This script is aiming at :
#		- copy only the deformation maps that fulfills criteria (ha and Btemp) in given directories
#		- creating the required list_of_InSAR_files.txt with path to defo files, Bperp, MasDate, SlavDate
#		- creating the header.txt required for the msbas processing
#		- creating hdr files for results
#       - check if files are OK or NaN
#		- it also output files with incidence angle, heading and acquisition time  
# Because acquisition time is not included in the name of the geocoded file, this info will be missing in the header.txt file 
#     and must be added manually.
#
#  Script must be launched in the dir where msbas will be run. 
#
# Attention, if one update an existing MSBAS processing after having added new interferograms, 
#            ensure that the new links will be made from the same computer as the first build.
#
# Parameters are : 
#       - mode (that is type of products to use such as DefoInterpolx2Detrend; must be the name of the subdir where data are stored)
# 		- nr of modes
#		- Max Bperp 
#		- Max Btemp
#		- path to each mode
#
# ex: build_header_msbas.sh DefoInterpolx2Detrend 2 150 50 /Volumes/hp-D3600-Data_Share1/SAR_MASSPROCESS/CSK/Bukavu_Asc/Resampled_20160223_Crop_Funu_-2.473_-2.574_28.821_28.904_Zoom1_ML4 /Volumes/hp-D3600-Data_Share1/SAR_MASSPROCESS/CSK/Bukavu_Desc/Resampled_20160111_Crop_Funu_-2.473_-2.574_28.821_28.904_Zoom1_ML4 
#       
# Dependencies:	- python 
#				- checkOnlyNaN.py script
#				- gnu sed and awk for more compatibility. 
#               - espeak or say if Linux or Mac
#
#
###	Header.txt file must be something like 
###		FORMAT = 0 							# use here 0 - small endian, use 1 - big endian if required
###		FILE_SIZE = 1226, 1376  			# lines and columns taken e.g from geocoded defo.hdr 
###		WINDOW_SIZE = 0, 1225, 0, 1375		# can apply crop if required. Attention count start at 0
###		R_FLAG = 2, 0.04					# Rank regularistaion order and Lambda for Thickonov regularisation
###		T_FLAG = 0							# 1= ONLY FOR R_FLAG 0 : remove topo residuals (eg if pix dem >> interfero) ; 0=no
###		C_FLAG = 0							# pixel(s) coordinates of reference region: Nr of ref, line, col of each ref, radius for all ref pix
###												e.g: C_FLAG = 2, 452, 822, 237, 259, 32,32	 
###		I_FLAG = 0							# 0= auto run; 1= ask for coord of pix for time series; 2=taxes coord from par.txt file
###												e.g: I_FLAG = 2, par.txt		
### 	 SET = 034122, -191.72, 42.02074792667776040000, DefoInterpolx2Detrend1.txt    # time of acquisition, Az heading, Incid angle, list_of_InSAR_files
#
#
# New in Distro V 1.0:	- Based on developpement version 3.1 and Beta V1.4
# New in Distro V 1.1:	- Enable updating existing MSBAS files and dir with only new imgs
#						- typo in explanation of starting counting number of mode: from 4 (instead of 3)
# New in Distro V 1.2:	- speed up by making only once the mkdir -p
#						- change ls with find for coping with lots of files in dir
# New in Distro V 1.3:	- bug fix in NaN detection : solved by sourcing the .bashrc
# New in Distro V 2.0:	- Speed up the processing by remebering which pairs are out of range from previous run
# New in Distro V 2.1:	- ignore possible files already checked again coherence threshold in kmz zone that are then stored in MODEi/Checked_For_CohThreshold.txt . 
# New in Distro V 2.2:	- add pathgnu to grep
# New in Distro V 3.0:	- keep pairs out of baseline range but that are forced from 
#						  SAR_SM/MSBAS/region/seti/table_BpMin_BpMax_Btmin_Btmax_AdditionalPairs.txt (also in SAR_MASSPROCESS)
# New in Distro V 3.1:	- Debug avoidance of reprocessing out of coherence threshold pairs
#						- exclude pairs when Bt and Bp exceed max, but not when contained in table_BpMin_BpMax_Btmin_Btmax_AdditionalPairs.txt
#						- rename list of pairs checked against coh threshold to avoid confusion (Checked_For_CohThreshold_To_Be_Ignored_At_Next_Rebuild_msbas_Header.txt instead of Out_Of_Range_CohThreshold.txt)
# New in Distro V 4.0:	- add param to header.txt to cope with only the new version of msbas (after Oct 2020)
# New in Distro V 4.1:	- add some security and check to prevent error in case of former crash
# New in Distro V 4.2:	- space was missing in test of non existance of ln
# New in Distro V 4.3:	- find out original path to file before running python scripts because it does not follow links 
# New in Distro V 4.4:	- accounts for usage with msbasv4 (i.e. that requires additional info in header files) or former ones
# New in Distro V 4.5:	- cosmetic
# New in Distro V 4.6:	- while creating the MODEi.txt file, LINE was not a link, hence no need to search for ORIGINALTARGET
# New in Distro V 4.7:	- revised and simplified
# New in Distro V 4.7.1: - search for img date from file name with 8 digits instead of 6. Should be OK as long as crop is not defined with 8 decimals
# New in Distro V 5.0:  - check if defo file contains ONLY nan using new python script checkOnlyNaN.py (instead of checkNanNpy), which now needs the input file format as parameter
# New in Distro V 5.2:  - remove empty lines from header, incid and acq time files to avoid error when computing average 
# New in Distro V 5.3: - replace if -s as -f -s && -f to be compatible with mac os if 
# New in Distro V 8.0: - jump in V number to be consistennt with the version from pair dirs, i.e. also with acq time 
#					   - add pairs from table_BpMin_BpMax_Btmin_Btmax_AdditionalPairs.txt if any
#					   - ensure that MAS date is before slave date in MODEi.txt
#					   - make parallel computing 
#					   - correct a confusion between FILEONLY and LINENOPATH	
#
# MasTer: InSAR Suite automated Mass processing Toolbox. 
# NdO (c) 2016/03/08 - could make better... when time.
# -----------------------------------------------------------------------------------------
PRG=`basename "$0"`
VER="Distro V8.0 MasTer script utilities"
AUT="Nicolas d'Oreye, (c)2016-2019, Last modified on Sept 14, 2023"
echo " "
echo "${PRG} ${VER}, ${AUT}"
echo "Processing launched on $(date) " 
echo " " 

# vvv ----- Hard coded lines to check --- vvv 
source $HOME/.bashrc 
# ^^^ ----- Hard coded lines to check -- ^^^ 

	
MODE=$1				# eg Defo, DefoInterpolDetrend or DefoInterpolx2Detrend...
NRMODES=$2			# Nr of modes
MAXBP=$3			# Max Bperp
MAXBT=$4			# Max Btemp
# Next parameters are the path to pairs and geocoded defo files, for each mode (eg /Users/doris/NAS/hp-D3600-Data_Share1/SAR_MASSPROCESS/CSK/Bukavu_Desc/Resampled_20160103_Crop_Funu_-2.473_-2.574_28.821_28.904_Zoom1_ML10)

echo ""

RNDM1=`echo $(( $RANDOM % 10000 ))`
# Dump Command line used in CommandLine.txt
echo "$(dirname $0)/${PRG} run with following arguments : \n" > CommandLine_${PRG}_${RNDM1}.txt
index=1 
for arg in $*
do
  echo "$arg" >> CommandLine_${PRG}_${RNDM1}.txt
  let "index+=1"
done 

CHECKMSBASV1=`which msbas | wc -l`
CHECKMSBASV2=`which msbasv2 | wc -l`
CHECKMSBASV3=`which msbasv3 | wc -l`
CHECKMSBASV4=`which msbasv4 | wc -l`

if [ ${CHECKMSBASV1} -gt 0 ] ; then MSBAS="msbas" ; fi  	
if [ ${CHECKMSBASV2} -gt 0 ] ; then MSBAS="msbasv2" ; fi  	
if [ ${CHECKMSBASV3} -gt 0 ] ; then MSBAS="msbasv3" ; fi  		
if [ ${CHECKMSBASV4} -gt 0 ] ; then MSBAS="msbasv4" ; fi  	


# To speed up, make first all dirs
for ((i=1;i<=${NRMODES};i++));
do 
	n=`expr "${i}" + 4`;					# Start counting from 4 because 4 first parameters are not mode paths, i.e. $n = 5th param which is path to 1st mode, $n+1= 2nd mode etc... 
	ROOTPATH[${i}]=${!n}
	PATHMODE=${!n}/Geocoded/${MODE}		# path to dir where defo maps of ith mode are stored : e.g. /Volumes/hp-D3600-Data_Share1/SAR_MASSPROCESS/CSK/Virunga_Asc/Resampled_20120702_Crop_NyigoCrater_-1.520_-1.540_29.200_29.220_Zoom1_ML4/Geocoded/Defo 
	PATHMODE[${i}]=${PATHMODE}			# same as before but named with an index for further call
	HDRMOD=`find ${PATHMODE} -maxdepth 1 -type f -name "*.hdr"  | head -n 1`	# one envi header file for that mode to get some info
	#HDRMOD=`ls ${PATHMODE}/*.hdr | head -n 1`	# one envi header file for that mode to get some info 
	MODETOCP=`echo $MODE${i}` 			# get only the name without path (that is Defo" and with index, i.e. Defo1)

	mkdir -p ${MODETOCP}
	
	cd ${MODETOCP}
	mkdir -p Rasters
	mkdir -p PrblmRasters
	
	cd ..
done

# pseudo parallel by running on all but one CPU (fatser than gnuparallel) 
#-------------------------------------------------------------------------
# test nr of CPUs
# Check OS
OS=`uname -a | cut -d " " -f 1 `

case ${OS} in 
	"Linux") 
		NCPU=`nproc` 	;;
	"Darwin")
		NCPU=`sysctl -n hw.ncpu` 
		
		# must define a function because old bash on Mac does not know wait -n option
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

PrepareModeI()
{
	# Prepare j_th mode
	local HDRMOD
	local MODETOCP
	local MASSPROCESSPATH
	local NRFILES
	local ADDPAIRSFILETMP
	local ADDBP
	local ADDBT
	local ADDPAIRSFILE
	local FILEONLY
	local MASTERDATE
	local SLAVEDATE
	local PAIR
	local INCIDENCE
	local BPERP
	local HEADREAL
	local HEAD
	local ACQTIME
	local MASDATESPLIT
	local SLVDATESPLIT
	local BTEMP
	local ABSBPERP
	local ABSBTEMP
	local PATHRAS
	local NAN
	local PAIRINTABLE

	HDRMOD=`find ${PATHMODE} -maxdepth 1 -type f -name "*.hdr"  | head -n 1`	# one envi header file for that mode to get some info
	#HDRMOD=`ls ${PATHMODE}/*.hdr | head -n 1`	# one envi header file for that mode to get some info 
	MODETOCP=`echo $MODE${i}` 			# get only the name without path (that is Defo" and with index, i.e. Defo1)
	MASSPROCESSPATH="$(dirname "$(dirname "$PATHMODE[${i}]")")"  # two levels up; needed for keeping track of possible pairs in table_BpMin_BpMax_Btmin_Btmax_AdditionalPairs.txt

	# Check table_BpMin_BpMax_Btmin_Btmax_AdditionalPairs.txt
	NRFILES=`ls ${MASSPROCESSPATH}/table_*_AdditionalPairs.txt 2>/dev/null | wc -l `
	if [  ${NRFILES} -ge 1 ] # that file contains 1 col with full path and file name
		then
			echo "${NRFILES} table_0_x_0_x_AdditionalPairs.txt files for ${MODETOCP}"
			if [ ${NRFILES} -eq 1 ]
				then 
					echo "Only one file; take it"
					ADDPAIRSFILETMP=`ls ${MASSPROCESSPATH}/table_*_AdditionalPairs.txt`
					ADDBP=`basename ${ADDPAIRSFILETMP} | cut -d _ -f3`
					ADDBT=`basename ${ADDPAIRSFILETMP} | cut -d _ -f5`

					if [ "${ADDBP}" -le "${MAXBP}" ] &&  [ "${ADDBT}" -le "${MAXBT}" ]
						then 
							echo "		=> OK"
							ADDPAIRSFILE=${ADDPAIRSFILETMP}
						else 
							echo "		=> not OK because one baseline  ${ADDBP} or ${ADDBT} is out of criteria (${MAXBP} or ${MAXBT})"
							touch dummy_empty_file_to_kill.txt
							ADDPAIRSFILE="dummy_empty_file_to_kill.txt"
	
					fi
				else
					echo "More than one file; must take the one that satisfies at least the two criteria"		
					for ((k=1;k<=${NRFILES};k++));
						do 		
							echo "	Test ${k}th file"
 							ADDPAIRSFILE[${k}]=`ls ${MASSPROCESSPATH}/table_*_AdditionalPairs.txt | head -${k} | tail -1`
 							ADDBP=`basename ${ADDPAIRSFILE[${k}]} | cut -d _ -f3`
 							ADDBT=`basename ${ADDPAIRSFILE[${k}]} | cut -d _ -f5`
 							if [ "${ADDBP}" -le "${MAXBP}" ] &&  [ "${ADDBT}" -le "${MAXBT}" ]
 								then 
 									echo "		=> OK"
 									# Not sure how to select wich kth file OK. Suppose that ls sort them by numerical oreder, hence take the last one
 									ADDPAIRSFILE=${ADDPAIRSFILE[${k}]}
 								else 
 									echo "		=> not OK because one baseline  ${ADDBP} or ${ADDBT} is out of criteria (${MAXBP} or ${MAXBT})"
 									touch dummy_empty_file_to_kill.txt
									ADDPAIRSFILE="dummy_empty_file_to_kill.txt"
							fi							
					done
			fi
			echo "ADDPAIRSFILE is ${ADDPAIRSFILE}"
			echo
		else 
			echo "No table_0_x_0_x_AdditionalPairs.txt files for ${MODETOCP}"
			touch dummy_empty_file_to_kill.txt
			ADDPAIRSFILE="dummy_empty_file_to_kill.txt"
	fi


	#mkdir -p ${MODETOCP}
	cd ${MODETOCP}

	find ${PATHMODE} -maxdepth 1 -type f -name "*deg" > ${MODETOCP}.txt 	# File with full path from SAR_MASSPROCESS/.../deformationMap.....deg
	# same as above but without the path
	find ${PATHMODE} -maxdepth 1 -type f -name "*deg" -print | while read filename ; do basename "${filename}" ; done >  ${MODETOCP}_NoPath.txt 	# File without any path or any other info, i.e. only file names deformationMap.....deg

	# Compare ${MODE}i/${MODETOCP}.txt with possibe existing ../${MODETOCP}i.txt (i.e. with only partial path)
	if [ -f ../${MODETOCP}.txt ] 
		then
			# new security in case of previous crash
			sort ../${MODETOCP}.txt | uniq > ../${MODETOCP}_tmp.txt
			${PATHGNU}/gawk 'NF>=4' ../${MODETOCP}_tmp.txt > ../${MODETOCP}.txt	
			rm -f ../${MODETOCP}_tmp.txt

			# previous MSBAS already prepapred. Check only new entries and remove from ${MODETOCP}.txt the entries already processed
			# First trim MODE from beginning of each line in ../${MODETOCP}.txt
			${PATHGNU}/gsed -i "s%.*${MODE}${i}\/%%g" ../${MODETOCP}.txt  # remove all up to /Defo/ included, i.e. with no path but still with Bp and dates

			# keep only what is not in ../${MODETOCP}.txt to which we have removed path and info about dates and baselines
			cp ../${MODETOCP}.txt _tmps_Processes_pairs.txt
			${PATHGNU}/gsed -i "s%deg .*%deg%g" _tmps_Processes_pairs.txt  # remove trailing infos about date and baselines	(was already without path)

			sort _tmps_Processes_pairs.txt | uniq > _tmps_Processes_pairs_sorted.txt 						# i.e. info from existing MODEi.txt

				#Check first that files listed in ../${MODETOCP}.txt cleaned, that is _tmps_Processes_pairs.txt, are the same as those in /MODEi
				#find . -maxdepth 1 -type l -name "*deg" -print | while read filename ; do basename "${filename}" ; done >  _files_in_${MODE}${i}_NoPath.txt 
				ls | ${PATHGNU}/grep "deg" > _files_in_${MODE}${i}_NoPath.txt 
				sort  _files_in_${MODE}${i}_NoPath.txt | uniq >  _files_in_${MODE}${i}_NoPath_sorted.txt 	# i.e. info from existing MODEi dir

				rm _files_in_${MODE}${i}_NoPath.txt
				${PATHGNU}/grep -Fvf _files_in_${MODE}${i}_NoPath_sorted.txt _tmps_Processes_pairs_sorted.txt  > _Files_Not_In_Dir_but_in_${MODE}${i}.txt
				${PATHGNU}/gsed -i "s%^%${PATHMODE}\/%g"  _Files_Not_In_Dir_but_in_${MODE}${i}.txt # add again the path at beginning of each line
				#diff _files_in_${MODE}${i}_NoPath_sorted.txt _tmps_Processes_pairs_sorted.txt | ${PATHGNU}/grep "deg" | ${PATHGNU}/gsed s/\>//g | ${PATHGNU}/gsed s/\<//g
				rm  _tmps_Processes_pairs.txt _files_in_${MODE}${i}_NoPath_sorted.txt

			sort ${MODETOCP}_NoPath.txt | uniq > ${MODETOCP}_NoPath_sorted.txt
			rm 	${MODETOCP}_NoPath.txt 		
			
			${PATHGNU}/grep -Fvf _tmps_Processes_pairs_sorted.txt ${MODETOCP}_NoPath_sorted.txt > ${MODETOCP}_NoPath_only_new.txt
			rm  ${MODETOCP}_NoPath_sorted.txt _tmps_Processes_pairs_sorted.txt 
			
			${PATHGNU}/gsed -i "s%^%${PATHMODE}\/%g"  ${MODETOCP}_NoPath_only_new.txt # add again the path at beginning of each line
			mv -f  ${MODETOCP}_NoPath_only_new.txt ${MODETOCP}.txt
			if [ -f "_Files_Not_In_Dir_but_in_${MODE}${i}.txt" ] && [ -s "_Files_Not_In_Dir_but_in_${MODE}${i}.txt" ] ; then cat _Files_Not_In_Dir_but_in_${MODE}${i}.txt ${MODETOCP}.txt > ${MODETOCP}_tmp.txt ; sort ${MODETOCP}_tmp.txt | uniq > ${MODETOCP}.txt ; rm -f ${MODETOCP}_tmp.txt ; fi
			# hence ${MODETOCP}.txt contains now the Out_of_Range and the new ones to process (with partial path and no tailing info about baselines)
			rm _Files_Not_In_Dir_but_in_${MODE}${i}.txt
		else 
			# No previous MSBAS prepapred. Process all entries in ${MODETOCP}.txt
			echo "First MSBAS preparation for this mode"
			#rm ${MODETOCP}_NoPath.txt
	fi

	# To speed up : 
	# If already checked, some Bp and/or Bt out of range pairs are identified. 
	# Before removing them from the list of pairs to reprocess, one may need to keep some out of range:
	# Remove from Out_Of_Range_${MAXBP}m_${MAXBT}days.txt each line that contains out of range pairs that were however asked to be 
	# maintained because they would for instance complete the baselineplot. 
	# Such a list of out-of-range pairs to keep must be listed in ${MASSPROCESSPATH}/table_0_${MAXBP}_0_${MAXBT}_AdditionalPairs.txt. 
	# Store former ${MODETOCP}.txt (i.e. with new and all out-of-range pairs as ${MODETOCP}_Full.txt) 
	#-----------------------------------------------------------------------------------------------
	if [ -f "Out_Of_Range_${MAXBP}m_${MAXBT}days.txt" ] && [ -s "Out_Of_Range_${MAXBP}m_${MAXBT}days.txt" ] # that file contains 1 col with full path and file name
		then
			mv ${MODETOCP}.txt ${MODETOCP}_FullToCheck.txt
			# remove possible pairs out of range that are in SAR_SM/MSBAS/region/seti/table_BpMin_BpMax_Btmin_Btmax_AdditionalPairs.txt (also in SAR_MASSPROCESS)
			if [ -f "${ADDPAIRSFILE}" ] && [ -s "${ADDPAIRSFILE}" ]   # i.e. table with 4 col MAS SLV BP BT
				then
					# remove pairs from Out_Of_Range_${MAXBP}m_${MAXBT}days.txt
					while read -r MASDATEFORCE SLVDATEFORCE dummy1 dummy2 
						do	
						# remove lines with string ${MASDATE}_${SLVDATE} in out of range
						${PATHGNU}/gsed -i "/${MASDATEFORCE}_${SLVDATEFORCE}/d" Out_Of_Range_${MAXBP}m_${MAXBT}days.txt
					done < ${ADDPAIRSFILE} 
					# i.e. Out_Of_Range_${MAXBP}m_${MAXBT}days.txt contains now only the out-of-range pairs that we do not want to keep
			fi 		
			${PATHGNU}/grep -Fv -f Out_Of_Range_${MAXBP}m_${MAXBT}days.txt ${MODETOCP}_FullToCheck.txt > ${MODETOCP}.txt 
			# hence ${MODETOCP}.txt contains now the only the new pairs and the Out_of_Range that we WANT to keep (with full path and no tailing info about baselines)
			rm -f ${MODETOCP}_FullToCheck.txt
	fi
	# To speed up : 
	# If already checked against Coh threshold, some out of range lines are identified. 
	# Before removing them from the list of pairs to reprocess, one may need to keep some out of range:
	# Remove from Checked_For_CohThreshold_To_Be_Ignored_At_Next_Rebuild_msbas_Header.txt each line that contains out of range pairs that were however asked to be 
	# maintained because they would for instance complete the baselineplot. 
	# Such a list of out-of-range pairs to keep must be listed in ${MASSPROCESSPATH}/table_0_${MAXBP}_0_${MAXBT}_AdditionalPairs.txt. 
	# Not sure it is worth to do this however for coh... 
	# Remove from ${MODETOCP}.txt each line that contains what is in lines of Checked_For_CohThreshold_To_Be_Ignored_At_Next_Rebuild_msbas_Header.txt
	#-----------------------------------------------------------------------------------------------
	
	# Checked_For_CohThreshold_To_Be_Ignored_At_Next_Rebuild_msbas_Header.txt contains 1 col with file name but without any path 
	if [ -f Checked_For_CohThreshold_To_Be_Ignored_At_Next_Rebuild_msbas_Header.txt ] && [ -s Checked_For_CohThreshold_To_Be_Ignored_At_Next_Rebuild_msbas_Header.txt ]    # Do not look at version in MODETOCP_Full because it does not contains the last pairs checked 
		then
			mv ${MODETOCP}.txt ${MODETOCP}_NoChoRestrict.txt
			# remove possible pairs out of range that are in SAR_SM/MSBAS/region/seti/table_BpMin_BpMax_Btmin_Btmax_AdditionalPairs.txt (also in SAR_MASSPROCESS)
			# This may be dangerous though because it would force to keep pairs with low level of coh. Not sure if we shoudl offer that possibility...  May be wise to remove? 
			if [ -f "${ADDPAIRSFILE}" ] && [ -s "${ADDPAIRSFILE}" ]
				then
					# remove pairs from Checked_For_CohThreshold_To_Be_Ignored_At_Next_Rebuild_msbas_Header.txt
					while read -r MASDATEFORCE SLVDATEFORCE dummy1 dummy2 
						do	
						# remove lines with string ${MASDATE}_${SLVDATE} in out of range
						${PATHGNU}/gsed -i "/${MASDATEFORCE}_${SLVDATEFORCE}/d" Checked_For_CohThreshold_To_Be_Ignored_At_Next_Rebuild_msbas_Header.txt
					done < ${ADDPAIRSFILE} 

			fi 		
			${PATHGNU}/grep -Fv -f Checked_For_CohThreshold_To_Be_Ignored_At_Next_Rebuild_msbas_Header.txt ${MODETOCP}_NoChoRestrict.txt > ${MODETOCP}.txt 
			# do not remove ${MODETOCP}_NoChoRestrict.txt
	fi	
	
	# CREATES THE .TXT FILE
 	for LINE in `cat -s ${MODETOCP}.txt`
 	do

		# Proceed if a CPU is free 
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

  		#LINENOPATH=`echo ${LINE} | ${PATHGNU}/gawk -F '/' '{print $NF}'` 	# Line with file name as deformationMap.....deg without path
 		FILEONLY=`echo ${LINE} | ${PATHGNU}/gawk -F '/' '{print $NF}'` 	# Line with file name as deformationMap.....deg without path

  		MASTERDATE=`echo ${LINE} | ${PATHGNU}/grep -oP '\D+\K\d+' | ${PATHGNU}/gsed -n '/[0-9]\{8\}/p' | head -2  | tail -1`
 		SLAVEDATE=`echo ${LINE} | ${PATHGNU}/grep -oP '\D+\K\d+' | ${PATHGNU}/gsed -n '/[0-9]\{8\}/p' | tail -1`
 		#MASTERDATE=`echo ${LINE} | ${PATHGNU}/grep -E -o '\b[0-9]{8}\b' | head -2 | head -1`
 		#SLAVEDATE=`echo ${LINE} | ${PATHGNU}/grep -E -o '\b[0-9]{8}\b' | head -2 | tail -1`
 
#		GetPair ${MASTERDATE} ${SLAVEDATE}
#		if [ "${SATDIR}" != "S1" ]
#			then
#				PAIR=`echo ${ROOTPATH[${i}]}/*${MASTERDATE}*_*${SLAVEDATE}*`	# path up to DateMaster_DateSlave  
#			else 
#				PAIR=`echo ${ROOTPATH[${i}]}/${MASTERDATE}_${SLAVEDATE}`	# path up to DateMaster_DateSlave
#		fi
 
 #		INCIDENCE=`updateParameterFile ${PAIR}/i12/TextFiles/masterSLCImageInfo.txt "Incidence angle at median slant range"`
 # 		BPERP=`updateParameterFile ${PAIR}/i12/TextFiles/InSARParameters.txt "Perpendicular baseline component at image centre"` 
 #		HEADREAL=`updateParameterFile ${PAIR}/i12/TextFiles/masterSLCImageInfo.txt "Azimuth heading"` 

		INCIDENCE=`echo ${FILEONLY} | ${PATHGNU}/gawk -F 'deg' '{print $1}'  | ${PATHGNU}/gawk -F '-' '{print $NF}' | cut -d c -f2` # always > 0, hence OK
		BPERP=`echo ${FILEONLY}  | ${PATHGNU}/gawk -F 'Bp' '{print $NF}' | cut -d _ -f1 | cut -d m -f1`  					# sign is taken into account, hence OK

		HEADREAL=`echo ${FILEONLY} | ${PATHGNU}/gawk -F 'Head' '{print $NF}' | cut -d d -f1`								# should be OK as well 
 		HEAD=`echo ${HEADREAL} | cut -d . -f 1 `

		BTEMP=`echo ${FILEONLY} | ${PATHGNU}/gawk -F 'BT' '{print $NF}' | cut -d d -f1` 									# sign is taken into account, hence OK

 		# Heading in CSL is counted conterclockwize from East. Transform in azimuth from North
 		if [ "${HEAD}" -ge "245" ] 
 			then # hence it is Descending (probably around 257)
 				HEAD=`echo "90 - ${HEAD}" | bc`
 			else # hence it is Ascending, (probably around 100) 
 				HEAD=`echo "360 - ${HEAD} + 90" | bc`
 		fi
 
 		# get AcquisitionTime from file
 		#ACQTIME=`updateParameterFile ${PAIR}/i12/TextFiles/masterSLCImageInfo.txt "Acquisition time" | tr -dc '[0-9]'` 
 		# Will make later a fake acquisition time because it is not available from fle naming

 		# get dates images as yyyy , mm , dd
 		MASDATESPLIT=`echo ${MASTERDATE:0:4} "," ${MASTERDATE:4:2} "," ${MASTERDATE:6:2} | ${PATHGNU}/gawk '{print $1,$2,$3+0,$4,$5+0}'`
 		SLVDATESPLIT=`echo ${SLAVEDATE:0:4} "," ${SLAVEDATE:4:2} "," ${SLAVEDATE:6:2} | ${PATHGNU}/gawk '{print $1,$2,$3+0,$4,$5+0}'`

 		#ABSBPERP=`echo ${BPERP} |  ${PATHGNU}/gsed -e 's%-%%' | cut -d . -f1 ` # truncate at integer
 		#ABSBTEMP=`echo ${BTEMP} |  ${PATHGNU}/gsed -e 's%-%%' | cut -d . -f1 `	# truncate at integer
 		# round instead of truncate
 		ABSBPERP=`echo ${BPERP} |  ${PATHGNU}/gsed -e 's%-%%' | xargs printf "%.*f\n" 0` # rounded
 		ABSBTEMP=`echo ${BTEMP} |  ${PATHGNU}/gsed -e 's%-%%' | xargs printf "%.*f\n" 0`	# rounded
 
 		if [ ${ABSBPERP} -le ${MAXBP} ] && [ ${ABSBTEMP} -le ${MAXBT} ]
 			then
 				# Dump incidence angle if one wants to do some statistics
 				echo  ${INCIDENCE} >> ../IncidenceAngles_${MODETOCP}_Max${MAXBP}m_Max${MAXBT}days.txt
 
 				# Dump heading if one wants to do some statistics
 				echo  ${HEAD} >> ../Heading_${MODETOCP}_Max${MAXBP}m_Max${MAXBT}days.txt
 	
 				# Dump Acquisition time 
# 				echo  ${ACQTIME} >> ../AcquisitionTime_${MODETOCP}_Max${MAXBP}m_Max${MAXBT}days.txt
 
 				# copy also rasters for check
 				#PATHONLY=`echo $PATHMODE${i} | ${PATHGNU}/gsed 's%'"${MODETOCP}"'%'"${MODE}"'%' | ${PATHGNU}/gsed 's%Geocoded%GeocodedRasters%' `
 				#PATHRAS=`echo $PATHMODE${i} | ${PATHGNU}/gsed 's%'"${MODETOCP}"'%'"${MODE}"'%' | ${PATHGNU}/gsed 's%Geocoded%GeocodedRasters%' `
 				
 				PATHRAS=${MASSPROCESSPATH}/GeocodedRasters/${MODE}
 				#FILEONLY=`echo ${LINE} | ${PATHGNU}/gawk -F '/' '{print $NF}' `
 
 				# get the target of link because numpy does not like links...
 				#ORIGINALTARGET=`ls -l ${LINE} | cut -d ">" -f 2- | cut -d "/" -f 2-` # get  the path and name of file pointed to by the broken link i.e. file tolocate in  TARGETDIR
 				#ORIGINALTARGET="/${ORIGINALTARGET}"
 				#ORIGINALTARGET=`readlink ${LINE}`
 				# LINE is not a link 
 				NAN=`checkOnlyNaN.py ${PATHMODE}/${FILEONLY} float32`
 				#NAN=`checkNaN.py ${ORIGINALTARGET}`
 				if [ "${NAN}" == "nan" ]
 					then 
  						ln -s ${PATHRAS}/${FILEONLY}.ras PrblmRasters/${FILEONLY}.ras 
  						ln -s ${PATHMODE}/${FILEONLY} PrblmRasters/${FILEONLY}
  						echo "  // Do not copy ${LINE}"
  						echo "  //   because full of NaN - reprocess if possible."
  					else 
 						if [ ! -f Rasters/${FILEONLY}.ras ] ; then ln -s ${PATHRAS}/${FILEONLY}.ras Rasters/${FILEONLY}.ras ; fi
 						if [ ! -f ${FILEONLY} ] 
 							then 
 								ln -s ${PATHMODE}/${FILEONLY} ${FILEONLY} 
 								echo "${LINE} copied (link)" 
 								# put in file
 								if [ ${MASTERDATE} -lt ${SLAVEDATE} ] 
 									then
 										echo "${LINE} ${BPERP} ${MASTERDATE} ${SLAVEDATE}" >> ../${MODETOCP}.txt
 									else 
										echo "Slave date appears before Master date. I guess you are dealing with non S1 WS and using a pair with the Super Master..."
 										echo "${LINE} ${BPERP} ${SLAVEDATE} ${MASTERDATE}" >> ../${MODETOCP}.txt
 								fi
 							else 
 								echo "${LINE} exist"
 						fi
 						
 				fi
 			else 
 				echo "--------------------" 
 				echo "${LINE} ${BPERP} ${MASTERDATE} ${SLAVEDATE} out of criteria"
 				
 				# Test however that it is not a pair forced from SAR_SM/MSBAS/region/seti/table_BpMin_BpMax_Btmin_Btmax_AdditionalPairs.txt (also in SAR_MASSPROCESS)
 				if [ -f "${ADDPAIRSFILE}" ] && [ -s "${ADDPAIRSFILE}" ]
 					then 
 						# only if pairs is IN that table
 						PAIRINTABLE=`${PATHGNU}/grep ${MASTERDATE} ${ADDPAIRSFILE} | ${PATHGNU}/grep ${SLAVEDATE} | wc -l `
 						if [ ${PAIRINTABLE} -ge 1 ]
 							then
 								echo "But you requested to keep it (see ${ADDPAIRSFILE})"
 								# Dump incidence angle if one wants to do some statistics
 								echo  ${INCIDENCE} >> ../IncidenceAngles_${MODETOCP}_Max${MAXBP}m_Max${MAXBT}days.txt
 
 								# Dump heading if one wants to do some statistics
 								echo  ${HEAD} >> ../Heading_${MODETOCP}_Max${MAXBP}m_Max${MAXBT}days.txt
 	
 								# Dump Acquisition time 
# 								echo  ${ACQTIME} >> ../AcquisitionTime_${MODETOCP}_Max${MAXBP}m_Max${MAXBT}days.txt
 
 								# copy also rasters for check
 								#PATHONLY=`echo $PATHMODE${i} | ${PATHGNU}/gsed 's%'"${MODETOCP}"'%'"${MODE}"'%' | ${PATHGNU}/gsed 's%Geocoded%GeocodedRasters%' `
 								#FILEONLY=`echo ${LINE} | ${PATHGNU}/gawk -F '/' '{print $NF}' `
 								PATHRAS=${MASSPROCESSPATH}/GeocodedRasters/${MODE}
 								# get the target of link because numpy does not like links...
 								#ORIGINALTARGET=`ls -l ${LINE} | cut -d ">" -f 2- | cut -d "/" -f 2-` # get  the path and name of file pointed to by the broken link i.e. file tolocate in  TARGETDIR
 								#ORIGINALTARGET="/${ORIGINALTARGET}"
 								#ORIGINALTARGET=`readlink ${LINE}`
 				
 								#NAN=`checkNaN.py ${ORIGINALTARGET}`
 								NAN=`checkNaN.py  ${PATHMODE}/${FILEONLY} float32`
 								if [ "${NAN}" == "nan" ]
 									then 
 										ln -s ${PATHRAS}/${FILEONLY}.ras PrblmRasters/${FILEONLY}.ras 
 										ln -s ${PATHMODE}/${FILEONLY} PrblmRasters/${FILEONLY}
 
 										echo "  // Do not copy ${LINE}"
 										echo "  //   because full of NaN - reprocess if possible."
 									else 
 										if [ ! -f Rasters/${FILEONLY}.ras ] ; then ln -s ${PATHRAS}/${FILEONLY}.ras Rasters/${FILEONLY}.ras ; fi
 										if [ ! -f ${FILEONLY} ] 
 											then 
 												ln -s ${PATHMODE}/${FILEONLY} ${FILEONLY} 
 												echo "${LINE} copied (link)" 
 												# put in file
 												#echo "${LINE} ${BPERP} ${MASTERDATE} ${SLAVEDATE}" >> ../${MODETOCP}.txt
 												if [ ${MASTERDATE} -lt ${SLAVEDATE} ] 
 													then
 														echo "${LINE} ${BPERP} ${MASTERDATE} ${SLAVEDATE}" >> ../${MODETOCP}.txt
 													else 
														echo "Slave date appears before Master date. I guess you are dealing with non S1 WS and using a pair with the Super Master..."
 														echo "${LINE} ${BPERP} ${SLAVEDATE} ${MASTERDATE}" >> ../${MODETOCP}.txt
 												fi

 											else 
 												echo "${LINE} exist"
 										fi
 
 								fi					
 							else 
 								echo ${LINE} >> Out_Of_Range_${MAXBP}m_${MAXBT}days.txt
 						fi		
 					else 
 						echo ${LINE} >> Out_Of_Range_${MAXBP}m_${MAXBT}days.txt
 				fi		
 				echo "--------------------"
 		fi
		} &
	done 
	wait 	

	rm ${MODETOCP}.txt
	cd ..
	${PATHGNU}/gsed -i "s%.*\/${MODE}\/%%g" ${MODETOCP}.txt  # remove all up to /Defo/ included	
	${PATHGNU}/gsed -i "s%^%${MODE}${i}\/%g" ${MODETOCP}.txt  # add Defo$j/ at beginning of each line
	
	rm -f dummy_empty_file_to_kill.txt 	
}

for ((i=1;i<=${NRMODES};i++));
do 

	n=`expr "${i}" + 4`;					# Start counting from 4 because 4 first parameters are not mode paths, i.e. $n = 5th param which is path to 1st mode, $n+1= 2nd mode etc... 
	PATHMODE=${ROOTPATH[${i}]}/Geocoded/${MODE}		# path to dir where defo maps of ith mode are stored : e.g. /Volumes/hp-D3600-Data_Share1/SAR_MASSPROCESS/CSK/Virunga_Asc/Resampled_20120702_Crop_NyigoCrater_-1.520_-1.540_29.200_29.220_Zoom1_ML4/Geocoded/Defo 
	PATHMODE[${i}]=${PATHMODE}			# same as before but named with an index for further call

	echo "Start mode ${i}"
	PrepareModeI ${i} &

done

wait

# Header.txt 
rm -f header.txt
NRLINES=`${PATHGNU}/grep "Samples" ${HDRMOD} | cut -c 9-30 | tr -dc '[0-9].' `
NRCOLMSS=`${PATHGNU}/grep "Lines" ${HDRMOD} | cut -c 9-30 | tr -dc '[0-9].' `
WINLINES=`expr "$NRLINES" - 1`
WINCOLMS=`expr "$NRCOLMSS" - 1`
echo 	"FORMAT = 0" 	> header.txt 			# Small/Big endian
echo	"FILE_SIZE = ${NRLINES}, ${NRCOLMSS}"  >> header.txt
echo	"WINDOW_SIZE = 0, ${WINLINES}, 0, ${WINCOLMS}"  >> header.txt
echo	"R_FLAG = 2, 0.02"  >> header.txt  		# Lambda for Thickonov regularisation
echo	"T_FLAG = 0"  >> header.txt  	# 1=remove topo residuals (eg if pix dem >> interfero) ; 0=no
echo	"C_FLAG = 10"  >> header.txt  		# pixel(s) coordinates of reference region: Nr of ref, line, col of each ref, radius for all ref pix, e.g: C_FLAG = 2, 452, 822, 237, 259, 32,32
if [ "${MSBAS}" == "msbasv4" ] ; then echo 	"V_FLAG=0"   >> header.txt ; fi		#  V_FLAG=0 - compute displacement time series as before and V_FLAG=1 - compute velocity time series, in this case linear rate is acceleration.
#echo	"TAV_FLAG = 0"  >> header.txt		# Gausian filtering in temporal domain; 0 = off or width of Gauss. Win. (in yrs)
echo	"I_FLAG = 0"  >> header.txt  		# 0= auto run; 1= ask for coord of pix for time series; 2=takes coord from par.txt file, 	e.g: I_FLAG = 2, par.txt	

# For each mode, set Az heading, Incid angle, list_of_InSAR_files
for ((i=1;i<=${NRMODES};i++));
do 
	# Remove white lines before computing average
	${PATHGNU}/gsed -i ' /^$/d' IncidenceAngles_$MODE${i}_Max${MAXBP}m_Max${MAXBT}days.txt
	${PATHGNU}/gsed -i ' /^$/d' Heading_$MODE${i}_Max${MAXBP}m_Max${MAXBT}days.txt
#	${PATHGNU}/gsed -i ' /^$/d' AcquisitionTime_$MODE${i}_Max${MAXBP}m_Max${MAXBT}days.txt
	
	AVGINCID[${i}]=`${PATHGNU}/gawk '{ total += $1 } END { print total/NR }' IncidenceAngles_$MODE${i}_Max${MAXBP}m_Max${MAXBT}days.txt`
	AVGHEAD[${i}]=`${PATHGNU}/gawk '{ total += $1 } END { print total/NR }' Heading_$MODE${i}_Max${MAXBP}m_Max${MAXBT}days.txt `

	# Change time in sec for average computation
	#cat AcquisitionTime_$MODE${i}_Max${MAXBP}m_Max${MAXBT}days.txt | ${PATHGNU}/gawk '{gsub(/../, "& ",$1); split($1, a, FS); print (a[1] * 3600) + (a[2] *60) + a[3]}' > AcquisitionTime_$MODE${i}_Max${MAXBP}m_Max${MAXBT}days_InSec.txt
	# Get average time in sec
	#ACQTIMESEC[${i}]=`${PATHGNU}/gawk '{ total += $1 } END { print total/NR }' AcquisitionTime_$MODE${i}_Max${MAXBP}m_Max${MAXBT}days_InSec.txt`
	# back in hhmmss
	#ACQTIME[${i}]=`echo "${ACQTIMESEC[${i}]}" | awk  '{ h = int($1 / 3600) ; m = int((($1 / 3600)-h ) * 60) ; sec = int($1 - ((3600 * h ) + ( 60 * m))) ; printf("%02d%02d%02d\n", h, m, sec) }'`  # ensure that all a integer and 2 digits long

	#rm -f AcquisitionTime_$MODE${i}_Max${MAXBP}m_Max${MAXBT}days_InSec.txt


#	ACQTIME[${i}]=`cat AcquisitionTime_$MODE${i}_Max${MAXBP}m_Max${MAXBT}days.txt | head -1`
	ACQTIME[${i}]=123400
	
	case ${MSBAS} in 
		msbasv4)
			#msbasv4 (> Oct 2020) needs	
			#	SET=0, ${ACQTIME[${i}]}, ${AVGHEAD[${i}]}, ${AVGINCID[${i}]}, ${MODE}${i}.txt - for insar range measurements
			#   SET=1, ${ACQTIME[${i}]}, ${AVGHEAD[${i}]}, ${AVGINCID[${i}]}, ${MODE}${i}.txt - for insar azimuth measurements
			echo "SET = 0, ${ACQTIME[${i}]}, ${AVGHEAD[${i}]}, ${AVGINCID[${i}]}, ${MODE}${i}.txt"  >> header.txt 
			;;
		*)
			echo "SET = ${ACQTIME[${i}]}, ${AVGHEAD[${i}]}, ${AVGINCID[${i}]}, ${MODE}${i}.txt"  >> header.txt
			;;
	esac
done

# Dump a header file for further uses : 
cp ${HDRMOD} HDR.hdr

# Check OS
OS=`uname -a | cut -d " " -f 1 `

case ${OS} in 
	"Linux") 
		espeak "Do not forget to change acquisition time in header file." ;;
	"Darwin")
		say "Do not forget to change acquisition time in header file." 	;;
	*)
		echo "Do not forget to change acquisition time in header file." 	;;
esac			

