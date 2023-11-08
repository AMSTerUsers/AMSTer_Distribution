#!/bin/bash
# -----------------------------------------------------------------------------------------
# This script is aiming at launching multiple occurrences of a SinglePair processing 
# 		using a Global Primary (SuperMaster) as Primary image and all other existing images as Secondary. 
# It can be run incrementally and will only compute the new pairs. 
#
# IN THIS VERSION, IT WILL ONLY COMPUTE PAIRS THAT FITS BT AND BP LIMITS.
# BP AND BT MUST BE PROVIDED IN A SM_Approx_baselines.txt file (cfr SAR_SM/MSBAS/region/set dirs)
#
# OR 
#
# IT WILL PROCESS ONLY THE LIST OF PAIRS PROVIDED IN A FILE
#
# This is useful to compute geocoded coherence maps to create a mask for instance
#
# Attention : DO NOT LAUNCH TWO OCCUENCE IN SAME DIR 
#
# Parameters :  - Dir where all original data are in csl format
#					Usually something like ..YourPath.../SAR_CSL/SAT/TRK/NoCrop
#				- Dir where results will be stored 
#					Since it is for mask creation purpose,
#					it might be something like ..YourPath.../SAR_SM/MASK/SAT/TRK/REGION
#				- File (incl path) with the processing parameters 
#               - Max Btemp or a Table with a list of pairs
#               - Max Bperp
#				- path to SAR_SM/MSBAS/region/seti/SM_Approx_baselines.txt  (if use table table_BpMi_BpMax_BtMin_BtMax.txt
# 				  instead, that is ok but computation will be arbitrary limited to the first 10 pairs - check manually if reprensentative) 
#               - Coh threshold for building mask
#
# Dependencies:
# 	- MT and MT Tools, at least V20190716. 	
#	- The FUNCTIONS_FOR_MT.sh file with the function used by the script. Will be called automatically by the script
#	- gnu sed and awk for more compatibility. 
#	- bc for basic computations
#   - functions "say" for Mac or "espeak" for Linux, but might not be mandatory
#   - numpy and OpenCV
#   - MeanCoh.py
#   - gdal
#
# Hard coded:	- SOFTWARE to launch multiple times. Here it is tuned for SinglePair.sh for the needs of mask.
#				    but could work with others. It exists a version tuned for SinglePairNoUnwrap.sh
#				- Path to .bashrc (sourced for safe use in cronjob)
#
# New in Distro V 1.0:	- Based on developpement version 1.0 and Beta V3.0.0
# New in Distro V 1.1:	- output mask in envi lat lon
# New in Distro V 1.2:	- remove hard coded lines
# New in Distro V 1.3:	- trim trailing zero(s) in COHTHRESHOLD to avoid naming problel
# New in Distro V 1.4:	- MeanCoh.py V2.0 does not requires anymore to provide the number of coh file in dir.  
# New in Distro V 1.5: - replace if -s as -f -s && -f to be compatible with mac os if 
# New in Distro V 2.0 20230830:	- Rename SCRIPTS_OK directory as SCRIPTS_MT 
#								- Replace CIS by MT in names 
#								- Renamed FUNCTIONS_FOR_MT.sh
# New in Distro V 3.0 20231030:	- Rename MasTer Toolbox as AMSTer Software
#								- rename Master and Slave as Primary and Secondary (though not possible in some variables and files)
#
# AMSTer: SAR & InSAR Automated Mass processing Software for Multidimensional Time series
# NdO (c) 2016/03/07 - could make better with more functions... when time.
# -----------------------------------------------------------------------------------------
PRG=`basename "$0"`
VER="Distro V3.0 AMSTer script utilities"
AUT="Nicolas d'Oreye, (c)2016-2019, Last modified on Oct 30, 2023"
echo " "
echo "${PRG} ${VER}, ${AUT}"
echo "Processing launched on $(date) " 
echo " "

# vvv ----- Hard coded lines to check --- vvv 
source /$HOME/.bashrc 			
# ^^^ ----- Hard coded lines to check --- ^^^ 

# Check OS
OS=`uname -a | cut -d " " -f 1 `
echo "Running on ${OS}"
echo

SOFT=${PATH_SCRIPTS}/SCRIPTS_MT/SinglePair.sh


SOFTNAME=`basename ${SOFT}`

case $# in
	7)
		echo "OK, let's build your mask based on a Global Primary (SuperMaster) and a Max Bt and Bp."
		echo "Ensure that the Global Primary is set in you ParametersFile.txt as SuperMaster"
		INPUTDATA=$1		# Dir where all original data are in csl format: .../SAR_CSL/SAT/TRK/NoCrop
		OUTPUTDATA=$2		# Dir where results will be stored: ../SAR_SM/MASK/SAT/TRK/REGION
		PARAM=$3			# File (incl path) with the processing parameters - MUST contains the date of the supermaster if run with Bt Bp criteria
		MAXBT=$4			# Max Btemp
		MAXBP=$5			# Max Bperp
		PATHSETI=$6			# path to SAR_SM/MSBAS/region/seti/SM_Approx_baselines.txt
		COHTHRESHOLD=$7		# Coh threshold for building mask
		METHOD="BASELINES"
		if [[ "${PATHSETI}" != *".txt" ]]  ; then echo "Path to text file such as SM_Approx_baselines.txt must be provided  as 7th parameter." ; exit 0 ; fi
		 ;;
	5)
		echo "OK, let's build your mask based on a list of pairs."
		INPUTDATA=$1		# Dir where all original data are in csl format: .../SAR_CSL/SAT/TRK/NoCrop
		OUTPUTDATA=$2		# Dir where results will be stored: ../SAR_SM/MASK/SAT/TRK/REGION
		PARAM=$3			# File (incl path) with the processing parameters - MUST contains the date of the supermaster if run with Bt Bp criteria
		PAIRSFILE=$4		# Table with a list of pairs in the form of SAR_SM/MSBAS/REGION/seti/table_BpMin_BpMax_BtMin_BtMax.txt prepared with the script Prepa_MSBAS.sh (with or without header; it does not matter) 
		COHTHRESHOLD=$5		# Coh threshold for building mask
		METHOD="PAIRS"
		if [[ "${PAIRSFILE}" != *".txt" ]]  ; then echo "Path to text file similar to SM_Approx_baselines.txt with pairs to process must be provided  as 4th parameter." ; exit 0 ; fi
		 ;;
	*)
		if [ $# -eq 6 ] || [ $# -lt 5 ] || [ $# -gt 7 ] 
			then 
				echo " Usage $0 INPUTDATA_DIR OUTPUTDATA_DIR PARAM_FILE MaxBtemp MaxBperp PathToSetI/SM_Approx_baselines.txt Coh_threshold" 
				echo "    or $0 INPUTDATA_DIR OUTPUTDATA_DIR PARAM_FILE Path/File_With_List_of_Pairs.txt Coh_threshold"
		fi
		exit 0 ;;
esac

# delete trailing zero(s) from COHTHRESHOLD to avoid name problem
COHTHRESHOLD=$(echo ${COHTHRESHOLD} | ${PATHGNU}/gsed 's/\.*0*$//')

function GetParam()
	{
	unset PARAMETER 
	PARAMETER=$1
	PARAMETER=`grep -m 1 ${PARAMETER} ${PARAM} | cut -f1 -d \# | ${PATHGNU}/gsed "s/	//g" | ${PATHGNU}/gsed "s/ //g"`
	eval PARAMETER=${PARAMETER}
	echo ${PARAMETER}
	}

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

PROROOTPATH=`GetParam PROROOTPATH`			# PROROOTPATH, path to dir where data will be processed in sub dir named by the sat name. 

SATDIR=`GetParam "SATDIR,"`					# Satellite system. E.g. RADARSAT 
TRKDIR=`GetParam "TRKDIR,"`					# Processing directory and dir where data are stored E.g. RS2_UF
REGION=`GetParam "REGION,"`					# Processing directory and dir where data are stored E.g. RS2_UF

SUPERMASTER=`GetParam "SUPERMASTER,"`		# date of the Global Primary (supermaster)

FCTFILE=`GetParam FCTFILE`					# FCTFILE, path to file where all functions are stored

MULTIPLEIMG=`GetParam MULTIPLEIMG`			# MULTIPLEIMG, as long as the stitching of S1 img is not ready, keep NOMULTIPLE to process only the first img (ie _A.csl or _D.csl) in mass processing. 
											#            Other occurences (ie _A.1.csl or _D.1.csl etc) will be ignored. However, for manual single processing, one may want to process both images. 
											#            In such a case, run the first processing with MASBURSTSET (and/or SLVBURSTSET) set to 1 then rerun with set to 2. Not tested... 
ZOOM=`GetParam "ZOOM,"`						# ZOOM, zoom factor used while cropping
INTERFML=`GetParam "INTERFML,"`				#  multilook factor for final interferometric products

source ${FCTFILE}

RUNDATE=`date "+ %m_%d_%Y_%Hh%Mm%Ss" | ${PATHGNU}/gsed "s/ //g"`

# Compatible Pairs (in the form of "date_date"; also for S1):
# If table contains the string "Delay", then remove header 
case ${METHOD} in 
	"BASELINES") 
		 if ${PATHGNU}/grep -q Delay "${PATHSETI}"
 			then
				cat ${PATHSETI} | tail -n+3 > ${PATHSETI}_NoBaselines_${RUNDATE}.txt 
				PATHSETI=${PATHSETI}_NoBaselines_${RUNDATE}.txt
		 fi		 ;;
	"PAIRS")
		 if ${PATHGNU}/grep -q Delay "${PAIRSFILE}"
 			then
				cat ${PAIRSFILE} | tail -n+3 > ${PAIRSFILE}_NoBaselines_${RUNDATE}.txt 
				PAIRSFILE=${PAIRSFILE}_NoBaselines_${RUNDATE}.txt
				
		 fi		;;
esac	

mkdir -p ${PROROOTPATH}/${SATDIR}/${TRKDIR}
mkdir -p ${OUTPUTDATA}

# Keep track of command line and option used 
touch ${OUTPUTDATA}/Command_Line.txt
echo "Command line used and parameters:" > ${OUTPUTDATA}/Command_Line.txt
echo "$(dirname $0)/${PRG} $@" >> ${OUTPUTDATA}/Command_Line.txt

# Check if option Mask is in Param file for Unwrapping
CHECKUNWP=`GetParam "SKIPUW,"`	
if [ ${CHECKUNWP} != "Mask" ]
	then 
		echo "You seems to want to do the processing for Mask but did not restrict the unwrapping and geocoding accordingly"
		echo " Change param DEFOTHRESHFACTOR as Mask in Param file"

		while true; do
				read -p "Confirm you want to continue anyway with SKIPUW as ${CHECKUNWP} ?"  yn
				case $yn in
					[Yy]* ) 
						echo "OK... you know..." 
						break ;;
					[Nn]* ) 
						EchoTee "OK, modify your parameter file and relaunch."
						exit ;;
					* ) 
						echo "Please answer yes or no.";;
				esac
			done
fi 
CHECKFILT=`GetParam "POWSPECSMOOTFACT,"`
if [ ${CHECKFILT} != "0" ]
	then 
		echo "You seems to want to do the processing with filtering, which is useless for mask."
		echo " Change param POWSPECSMOOTFACT as 0 in Param file"

		while true; do
				read -p "Confirm you want to continue anyway with POWSPECSMOOTFACT as ${CHECKFILT} ?"  yn
				case $yn in
					[Yy]* ) 
						echo "OK... you know..." 
						break ;;
					[Nn]* ) 
						EchoTee "OK, modify your parameter file and relaunch."
						exit ;;
					* ) 
						echo "Please answer yes or no.";;
				esac
			done
fi 

#cd; cd -
cd ${PROROOTPATH}/${SATDIR}/${TRKDIR}

case ${METHOD} in 
	"BASELINES") 

			# Listing all existing data in .csl format from DATAPATH, but the Super Master
			##############################################################
			if [ ${SATDIR} == "S1" ] 						
				then
					ls ${INPUTDATA} | ${PATHGNU}/grep -v ${SUPERMASTER} | ${PATHGNU}/grep -v .txt | ${PATHGNU}/gawk -F '/' '{print $NF}' | cut -d_ -f 3 > ${PROROOTPATH}/${SATDIR}/${TRKDIR}/All_Slaves_${RUNDATE}.txt
				else 
					ls ${INPUTDATA} | ${PATHGNU}/grep -v ${SUPERMASTER} | ${PATHGNU}/grep -v .txt | cut -d . -f1 > ${PROROOTPATH}/${SATDIR}/${TRKDIR}/All_Slaves_${RUNDATE}.txt
			fi
			# Compare with what exist already in ${OUTPUTDATA} in order to 
			#  process only the new ones, again without Super Master:
			##################################################################
			if [ ${SATDIR} == "S1" ] 						
				then
					# image names with sat A or B reference in name (from bulk mass processing)
					EchoTeeRed "Suppose processed image names as PRIMARY_S1A/B_TRK_SECONDARY_D(.x)_REGION (from bulk mass processing)"
					EchoTeeRed "If processed images have another form (mostly from manual mass processing), comment/uncomment lines accordingly in ${PRG} script"
					EchoTeeRed "   (cfr lines after # process only the new ones, again without Super Master)"				
					# Check if sub dir with super master exist already to avoid ls error msg
					if [ `ls -d ${OUTPUTDATA}/${SUPERMASTER}* 2> /dev/null | wc -l` -gt 0 ] 
						then 
							# if S1 names instaed of dates:
							ls -d ${OUTPUTDATA}/${SUPERMASTER}* | ${PATHGNU}/gawk -F '/' '{print $NF}' | ${PATHGNU}/gsed "s/'${SUPERMASTER}'_//g"  | cut -d_ -f 2 > Processed_slaves_${RUNDATE}.txt
						else 
							touch Processed_slaves_${RUNDATE}.txt 
					fi
				else 
					# Check if sub dir with super master exist already to avoid ls error msg
					if [ `ls -d ${OUTPUTDATA}/${SUPERMASTER}*  2> /dev/null | wc -l` -gt 0 ] 
						then 
							ls -d ${OUTPUTDATA}/${SUPERMASTER}* | ${PATHGNU}/gawk -F '/' '{print $NF}' | cut -d _ -f 2 | ${PATHGNU}/grep -v ${SUPERMASTER} > Processed_slaves_${RUNDATE}.txt 
						else 
							touch Processed_slaves_${RUNDATE}.txt 
					fi
			fi

			# Get only the new files to porcess
			###################################
			sort All_Slaves_${RUNDATE}.txt Processed_slaves_${RUNDATE}.txt | uniq -u > AllNew_Slaves_to_process_${RUNDATE}.txt 

			# Select here only the pairs that fit the Bperp and Btemp limits that are computed by Prepa_MSBAS.sh in SM_Approx_baselines.txt
			################################################################################################################################ 
			SETI=`basename ${PATHSETI}`
			${PATHGNU}/gawk '(sqrt( $3 * $3 ) < '$MAXBP') && (sqrt( $4 * $4 ) < '$MAXBT')' ${PATHSETI} > ${SETI}_Filtered.txt

			if [ ! -s ${SETI}_Filtered.txt ] ; then echo "No satisfyning baselines found in ${PATHSETI}; you must run ma" ; exit 0 ; fi

			# remove all but the date and add .csl to mimick the file format of New_Slaves_to_process_${RUNDATE}.txt	
			${PATHGNU}/gawk '$1 == '$SUPERMASTER' { print $2".csl" }' ${SETI}_Filtered.txt > ${SETI}_Filtered_slv.txt 
			${PATHGNU}/gawk '$2 == '$SUPERMASTER' { print $1".csl" }' ${SETI}_Filtered.txt > ${SETI}_Filtered_mas.txt 

			cat ${SETI}_Filtered_slv.txt ${SETI}_Filtered_mas.txt > New_Slaves_to_process_${RUNDATE}.txt

			if [ -f "New_Slaves_to_process_${RUNDATE}.txt" ] && [ -s "New_Slaves_to_process_${RUNDATE}.txt" ]
				then
					#cp New_Slaves_to_process_${RUNDATE}.txt New_Slaves_to_process_${RUNDATE}_Max${MAXBT}days_Max${MAXBP}m.txt
					# required for S1
					sed 's/.csl$//' New_Slaves_to_process_${RUNDATE}.txt > New_Slaves_to_process_${RUNDATE}_Max${MAXBT}days_Max${MAXBP}m.txt
					rm ${SETI}_Filtered.txt ${SETI}_Filtered_slv.txt ${SETI}_Filtered_mas.txt #AllNew_Slaves_to_process_${RUNDATE}.txt

					# Compute only the ones in New_Slaves_to_process_${RUNDATE}_Max${MAXBT}days_Max${MAXBP}m.txt that are in AllNew_Slaves_to_process_${RUNDATE}.txt 
					sort New_Slaves_to_process_${RUNDATE}_Max${MAXBT}days_Max${MAXBP}m.txt AllNew_Slaves_to_process_${RUNDATE}.txt | uniq -d > New_Slaves_to_process_${RUNDATE}.txt
					rm ${PROROOTPATH}/${SATDIR}/${TRKDIR}/AllNew_Slaves_to_process_${RUNDATE}.txt ${PROROOTPATH}/${SATDIR}/${TRKDIR}/New_Slaves_to_process_${RUNDATE}_Max${MAXBT}days_Max${MAXBP}m.txt
				else 
					EchoTee "You probably worked with table_BpMi_BpMax_BtMin_BtMax.txt instead of SM_Approx_Baselines.txt" 
					EchoTee "which is fine as well but may contains too many pairs for just a small statistical processing for mask generation."
					EchoTee "I will hence arbitrary keep only the first 10 pairs; check in table_BpMi_BpMax_BtMin_BtMax.txt if this looks representative."
					EchoTee 
					head ${SETI}_Filtered.txt > New_Pairs_to_process_${RUNDATE}.txt
					${PATHGNU}/gsed -i 's/	/ /g'  New_Pairs_to_process_${RUNDATE}.txt # because it mess up sometimes with tabs
					${PATHGNU}/gsed -i 's/  / /g'  New_Pairs_to_process_${RUNDATE}.txt # because it mess up sometimes with multiple white spaces...
					rm New_Slaves_to_process_${RUNDATE}.txt
			fi	 ;;
	"PAIRS")
			cp ${PAIRSFILE} ${PROROOTPATH}/${SATDIR}/${TRKDIR}/New_Pairs_to_process_${RUNDATE}.txt	;;
esac	

# Lets start
#############

if [ -f "New_Slaves_to_process_${RUNDATE}.txt" ] && [ -s "New_Slaves_to_process_${RUNDATE}.txt" ] 
then
	for PAIR in `cat -s ${PROROOTPATH}/${SATDIR}/${TRKDIR}/New_Slaves_to_process_${RUNDATE}.txt`
	do
		SLV=`GetDateCSL ${PAIR}`
		EchoTeeYellow "// Will process pair : ${SUPERMASTER} ${SLV} "
		EchoTeeYellow "// ***************************************** "

		if [ ! -d ${OUTPUTDATA}/${SUPERMASTER}_${SLV}_${REGION}_Zoom${ZOOM}_ML${INTERFML} ] ; then 
		#   If SinglePair.sh ask if one want to benefit from former processing, answer no automatically
			echo "n" | ${SOFTNAME} ${SUPERMASTER} ${SLV} ${PARAM}

			TOMOVE=`ls -d ${PROROOTPATH}/${SATDIR}/${TRKDIR}/${SUPERMASTER}_${SLV}_*`
			if [ -d ${OUTPUTDATA} ] 						
					then	
						cp -r ${TOMOVE} ${OUTPUTDATA}
						rm -r ${TOMOVE}
					else 
						EchoTeeRed "Can't find ${OUTPUTDATA}. Manually cp then remove ./${SOFTNAME} and ${TOMOVE}"
			fi
			SpeakOut "${SATDIR} ${TRKDIR} : Pair ${SUPERMASTER} ${SLV} done and copied"
			EchoTee "${SATDIR} ${TRKDIR} : Pair ${SUPERMASTER} ${SLV} done  and copied"
			EchoTee "-----------------------------------------------------------------"
		fi
	done
else 
	# I guess you work with the first 10 pairs of table_BpMi_BpMax_BtMin_BtMax.txt
	#for PAIRS in `cat -s ${PROROOTPATH}/${SATDIR}/${TRKDIR}/New_Pairs_to_process_${RUNDATE}.txt`
	#do
	# For unknow reason the for crashes sometimes... Prefer while
	if [ -f "${PROROOTPATH}/${SATDIR}/${TRKDIR}/New_Pairs_to_process_${RUNDATE}.txt" ] && [ -s "${PROROOTPATH}/${SATDIR}/${TRKDIR}/New_Pairs_to_process_${RUNDATE}.txt" ] ; then 
		cat -s ${PROROOTPATH}/${SATDIR}/${TRKDIR}/New_Pairs_to_process_${RUNDATE}.txt | while read PAIRS; do 	
			MASTER=`echo ${PAIRS} | cut -d " " -f1 `
			SLAVE=`echo ${PAIRS} | cut -d " " -f2 `
			MAS=`GetDateCSL ${MASTER}`
			SLV=`GetDateCSL ${SLAVE}`

			EchoTeeYellow "// Will process pair : ${MAS} ${SLV} "
			EchoTeeYellow "// ***************************************** "
			if [ ! -d ${OUTPUTDATA}/${MAS}_${SLV}_${REGION}_Zoom${ZOOM}_ML${INTERFML} ] ; then 
				#   If SinglePair.sh ask if one want to benefit from former processing, answer no automatically
				echo "n" | ${SOFTNAME} ${MAS} ${SLV} ${PARAM}

				TOMOVE=`ls -d ${PROROOTPATH}/${SATDIR}/${TRKDIR}/${MAS}_${SLV}_*`
				if [ -d ${OUTPUTDATA} ] 						
						then	
							cp -r ${TOMOVE} ${OUTPUTDATA}
							rm -r ${TOMOVE}
						else 
							EchoTeeRed "Can't find ${OUTPUTDATA}. Manually cp then remove ./${SOFTNAME} and ${TOMOVE}"
				fi
				SpeakOut "${SATDIR} ${TRKDIR} : Pair ${MAS} ${SLV} done and copied"
				EchoTee "${SATDIR} ${TRKDIR} : Pair ${MAS} ${SLV} done  and copied"
				EchoTee "-----------------------------------------------------------------"
			fi
		done
	fi

fi

mv *.txt ${OUTPUTDATA}

# Copy all geocoded Coh files in MASK subdir
cd  ${OUTPUTDATA}
mkdir -p  ${OUTPUTDATA}/_MASK

for filename in `find * -type f | ${PATHGNU}/grep coherence | ${PATHGNU}/grep ${SATDIR}`
   do
 		# Do not overwrite existing files
 		cp -n ${filename} ${OUTPUTDATA}/_MASK/ 	>/dev/null 2>&1
done

# Create mask by computing mean with threshold 
cd ${OUTPUTDATA}/_MASK/
i=`ls coherence.*.hdr | wc -w`

# Get image size
HDRFILE=`ls *.hdr | head -1 `
LINES=`cat ${HDRFILE} | ${PATHGNU}/grep ines | tr -dc '0-9'`
PIXELS=`cat ${HDRFILE} | ${PATHGNU}/grep amples | tr -dc '0-9'`

echo "In case of crash using Python script here, check if version is 3 or above. "
echo "  In such a case, update first line of MeanCoh.py with correct path/version and change function xrange in range"
MeanCoh.py ${COHTHRESHOLD}

cp ${HDRFILE} coherence_above_${COHTHRESHOLD}.mean_tmp.hdr
${PATHGNU}/gsed "s%Data type = 4%Data type = 1%" coherence_above_${COHTHRESHOLD}.mean_tmp.hdr > coherence_above_${COHTHRESHOLD}.mean.hdr
rm coherence_above_${COHTHRESHOLD}.mean_tmp.hdr

# raster of filter
#convert -depth 32 -equalize -size ${PIXELS}x${LINES} gray:coherence_above_${COHTHRESHOLD}.mean coherence_above_${COHTHRESHOLD}.mean.gif
convert -depth 8 -equalize -size ${PIXELS}x${LINES} gray:coherence_above_${COHTHRESHOLD}.mean coherence_above_${COHTHRESHOLD}.mean.gif

#rm -f coherence*.hdr 

# Convert to ENVI file format in LatLon (as required by MT)
if [ -f "coherence_above_${COHTHRESHOLD}.mean_LL" ] && [ -s "coherence_above_${COHTHRESHOLD}.mean_LL" ] ; then mv -f coherence_above_${COHTHRESHOLD}.mean_LL coherence_above_${COHTHRESHOLD}.mean_LL.bak ; fi

gdalwarp -of ENVI -t_srs EPSG:4326 coherence_above_${COHTHRESHOLD}.mean coherence_above_${COHTHRESHOLD}.mean_LL
if [ -f "coherence_above_${COHTHRESHOLD}.hdr" ] && [ -s "coherence_above_${COHTHRESHOLD}.hdr" ] ; then mv coherence_above_${COHTHRESHOLD}.hdr coherence_above_${COHTHRESHOLD}.mean_LL.hdr ; fi 
