#!/bin/bash
# This script aims at splitting a mass process in several parts. 
#
# Attention : processes will be shared between several disks. Check their availability and if sufficient space. 
#
# Beware, this script only works if launched from your computer or from 
#        a remote computer with a graphical interface as it must open new Terminal windows. 
#        It does not work if launched from a ssh session !
# If you want to operate it from a ssh session, you must use ssh -X session instead of ssh and ensure that you have:
#   - On the client side, in the ~/.ssh/config file:
#        Host *
#   		ForwardAgent yes
#   		ForwardX11 yes
#   		ForwardX11Trusted yes
#     If the client is a Mac, you must install XQuartz, which contains Xterm, because Terminal.app is not X11 compatible.  
#   - On the server side, in the /etc/ssh/sshd_config file:
#   	X11Forwarding yes
#   	X11DisplayOffset 10
#   	X11UseLocalhost no
#     You should also have xauth installed on the server side (most probably existing by default).
#   
#
# Parameters are:
#       - Table to be split (in the form of "date	date	Bp	Bt"  or "data_date")
#		- Parameters file (incl path) to be used
#       - Nr of parallel split processes
#		- optional: -list=filename (with path) to use list of pairs or 
#					-f to force checking existing pairs based on Geocoded/DefoInterpolx2Detrend)
#
# Dependencies:	- gnu sed and awk for more compatibility. 
#   			- seq
#               - Appel's osascript for opening terminal windows if OS is Mac
#               - x-termoinal-emulator for opening terminal windows if OS is Linux
#			    - say for Mac or espeak for Linux
#				- scripts LaunchTerminal.sh, MasterDEM.sh and of course SuperMaster_MassProc.sh
#				- __HardCodedLines.sh
#
# Hard coded:	- List and path to available disks (in two places ! See script)
#
# New in Distro V 1.0:	- Based on developpement version and Beta V3.0
# New in Distro V 1.1: - if launched with option -f, it forces to create the list of existing 
#						 pairs based on the files in Geocoded/DefoInterpolx2Detrend 
#						 instead of on the list of pair dirs. 
#					   - do not list _CheckResults dir while building existing pairs list
# New in Distro V 1.2: - if launched with option -list=filename, it forces to compute only pairs 
#						 in provided list (filename MUST be in the form of list of PRM_SCD dates)
#					   - fix find with maxdepth
# New in Distro V 1.3: - add new disks
# New in Distro V 1.4: - path to gnu ${PATHGNU}/grep
# New in Distro V 1.5: - creates MASSPROCESSPATH tree if does not exist
# New in Distro V 1.6: - update path to disks using state variables for 1650-3602
# New in Distro V 1.7: - replace ls by find to avoid "too long argument" error 
# New in Distro V 1.8: - remove stray \ before _ while calling grep to cope with new grep syntax and avoid waring
# New in Distro V 1.9: - launch x-terminal-emulator with current DISPLAY
#					   - SUPERMASTER was read twice 
# New in Distro V 2.0: - check that no SuperMaster_MassProc.sh is running on this computer 
#						 before attempting to clean directories 
#					   - allows splitting last batch in two if at least 10% longer that max length of other batches
#					   - exit if no new pairs to process
#					   - skip batches with empty pair files 
# New in Distro V 2.1: - more robust determination of DISPLAY variable
# New in Distro V 2.2: - even more robust determination of DISPLAY variable
# New in Distro V 3.0: - Use hard coded lines definition from __HardCodedLines.sh
# New in Distro V 3.1: - was not escaping the DISPLAY selection loop
# New in Distro V 3.2: - new way to test DISPLAY for Linux and test only once for all sessions
#					   - clean commented lines 
# New in Distro V 3.3: - replace if -s as -f -s && -f to be compatible with mac os if 
# New in Distro V 3.4: - offer to recompute DEM even for S1 if mode is not IW or EW, i.e. for SM mode 
# New in Distro V 4.0 20230830:	- Rename SCRIPTS_OK directory as SCRIPTS_MT 
#								- Replace CIS by MT in names 
#								- Renamed FUNCTIONS_FOR_MT.sh
# New in Distro V 5.0 20231030:	- Rename MasTer Toolbox as AMSTer Software
#								- rename Master and Slave as Primary and Secondary (though not possible in some variables and files)
# New in Distro V 5.1 20240213:	- FUNCTIONS_FOR_MT.sh was not sourced
# New in Distro V 5.2 20240305:	- Works for other defo mode than only DefoInterpolx2Detrend
# New in Distro V 5.3 20240702:	- add info about format of table to split
#								- take also table like from Prepa_MSBAS.sh, though without header
#
# AMSTer: SAR & InSAR Automated Mass processing Software for Multidimensional Time series
# NdO (c) 2016/03/07 - could make better with more functions... when time.
# -----------------------------------------------------------------------------------------
PRG=`basename "$0"`
VER="Distro V5.3 AMSTer script utilities"
AUT="Nicolas d'Oreye, (c)2016-2019, Last modified on Jul 02, 2024"
echo " "
echo "${PRG} ${VER}, ${AUT}"
echo "Processing launched on $(date) " 
echo " "



# vvv ----- Hard coded lines to check --- vvv 
source ${PATH_SCRIPTS}/SCRIPTS_MT/__HardCodedLines.sh
	# See below :
	# - SplitDiskDef for the list of available disks
	# - SplitDiskList for defining a code for each available disk
	# - SplitDiskSelection for selecting the disks for each session
# ^^^ ----- Hard coded lines to check --- ^^^ 

TABLEFILEPATH=$1 	# eg /Users/doris/NAS/hp-1650-Data_Share1/SAR_SM/MSBAS/Limbourg/set1/table_0_450_0_250.txt (i.e. "date	date	Bp	Bt")  or "data_date"
PARAMFILEPATH=$2 	# Usual Parameter file
N=$3 				# eg 5 if you have 100 pairs and want process 5 terminals, each processing 20 pairs
LISTOFPROCESSED=$4	# if -f, it forces to create the list of existing pairs based on the files in Geocoded/DefoInterpolx2Detrend 
					# if -list=filename, it forces to compute only pairs in provided list (filename MUST be in the form of list of PRM_SCD dates)

if [ $# -lt 3 ] 
	then 
		echo “Usage $0 TABLE_FILEPATH PARAM_FILEPATH NUMBER_OF_PARALLEL_PROCESSES”
		echo "That is if you have 100 pairs to process and chose 5 parallel processes, "
		echo "     it will compute 5 sets of 20 pairs in 5 terminal windows."
		exit
fi

if [ $# -eq 4 ]
	then 
		case ${LISTOFPROCESSED} in 
			"-f") # get the list of proecessed pairs from Geocoded/${DEFOMODE}
				LISTOFPROCESSED=YES ;;
			"-list="*)  # Do not compute list of processed pairs to compute wich is still to process because the list of pairs to process is provided instead
			 	LISTOFPROCESSED=FILE
			 	PATHTOPAIRLIST=`echo ${LISTOFPROCESSED} | cut -d = -f2 `
			 	# check that list is of correct form
				PAIRDATE=`head -1 ${PATHTOPAIRLIST} | ${PATHGNU}/grep -Eo "[0-9]{8}_[0-9]{8}"`  # get date_date
				TESTPAIR=`head -1 ${PATHTOPAIRLIST} | ${PATHGNU}/gsed "s/${PAIRDATE}//g" | wc -m` # check that there is nothing esle than PAIRDATE

				if [ `echo "${PAIRDATE}" | wc -m` == 18 ] && [ ${TESTPAIR} == 1 ] 
					then 
						echo "Valid pair files to process"  
					else 
						echo "Invalid pair files to process; must be in the form of DATE_DATE. Exit" 
						exit 0 
				fi
			 	;;
			 	
			*)	# not sure what is wanted hence keep default processing 
				echo "Not sure what your 4th parameter is. "
				echo "  This option must be -f to search for list of processed pairs in Geocoded/DefoMode or "
				echo "                      -file=list to provide a list of pairs to process.  " 
				echo "Since the 4th parameter provided is of none of these forms, let's keep default processing, "
				echo "  i.e. compute the list of preocessed pairs from the pair dirs in SAR_MASSPROCESS" 
				LISTOFPROCESSED=NO ;;	
		esac  
	else 
		LISTOFPROCESSED=NO
fi 


PARAMPATH=`dirname ${PARAMFILEPATH}`
PARAMFILE=`basename ${PARAMFILEPATH}`
PARAMEXT="${PARAMFILEPATH##*.}"

RNDM=`echo $(( $RANDOM % 10000 ))`


# Get the list of disks - see __HardCodedLines.sh
SplitDiskDef	# also get OK from that function

function GetParam()
	{
	unset PARAM 
	PARAM=$1
	PARAM=`${PATHGNU}/grep -m 1 ${PARAM} ${PARAMFILEPATH} | cut -f1 -d \# | ${PATHGNU}/gsed "s/	//g" | ${PATHGNU}/gsed "s/ //g"`
	eval PARAM=${PARAM}
	echo ${PARAM}
	}

function SpeakOut()
	{
	unset MESSAGE 
	local MESSAGE
	MESSAGE=$1
	case ${OS} in 
		"Linux") 
			espeak "${MESSAGE}" ;;
		"Darwin")
			say "${MESSAGE}" 	;;
		*)
			echo "${MESSAGE}" 	;;
	esac			
	}
	
SUPERMASTER=`GetParam SUPERMASTER`			# SUPERMASTER, date of the Global Primary (super master) as selected by Prepa_MSBAS.sh in
											# e.g. /Volumes/hp-1650-Data_Share1/SAR_SUPER_MASTERS/MSBAS/VVP/seti/setParametersFile.txt

PROROOTPATH=`GetParam PROROOTPATH`			# PROROOTPATH, path to dir where data will be processed in sub dir named by the sat name. 
MASSPROCESSPATH=`GetParam MASSPROCESSPATH`	# MASSPROCESSPATH, path to dir where all processed pairs will be stored in sub dir named by the sat/trk name (SATDIR/TRKDIR)

CROP=`GetParam "CROP,"`						# CROP, CROPyes or CROPno 
SATDIR=`GetParam "SATDIR,"`					# Satellite system. E.g. RADARSAT (must be the same as dirname structure)
TRKDIR=`GetParam "TRKDIR,"`					# Processing directory and dir where data are stored E.g. RS2_UF (must be the same as dirname structure)
ZOOM=`GetParam "ZOOM,"`						# ZOOM, zoom factor used while cropping
INTERFML=`GetParam "INTERFML,"`				#  multilook factor for final interferometric products

FIRSTL=`GetParam "FIRSTL,"`					# Crop limits: first line to use
LASTL=`GetParam "LASTL,"`					# Crop limits: last line to use
FIRSTP=`GetParam "FIRSTP,"`					# Crop limits: first point (row) to use
LASTP=`GetParam "LASTP,"`					# Crop limits: last point (row) to use
REGION=`GetParam "REGION,"`					# REGION, Text description of area for dir naming

FCTFILE=`GetParam FCTFILE`					# FCTFILE, path to file where all functions are stored

DATAPATH=`GetParam DATAPATH`				# DATAPATH, path to dir where data are stored 

PATHFCTFILE=${FCTFILE%/*}

source ${FCTFILE}

PROPATH=${PROROOTPATH}/${SATDIR}/${TRKDIR}/MASSPROC
mkdir -p ${PROPATH}
cd ${PROPATH}

TABLEPATH=`dirname ${TABLEFILEPATH}`
TABLEFILE=`basename ${TABLEFILEPATH}`
TABLEEXT="${TABLEFILEPATH##*.}"

# Update some infos
	if [ ${CROP} == "CROPyes" ]
		then
			SMCROPDIR=SMCrop_SM_${SUPERMASTER}_${REGION}_${FIRSTL}-${LASTL}_${FIRSTP}-${LASTP}   #_Zoom${ZOOM}_ML${INTERFML}
		else
			SMCROPDIR=SMNoCrop_SM_${SUPERMASTER}  #_Zoom${ZOOM}_ML${INTERFML}
	fi


# First check existing pairs before splitting into sub-lists
	# Existing pairs
# 	if [ -d ${MASSPROCESSPATH}/${SATDIR}/${TRKDIR}/${SMCROPDIR}_Zoom${ZOOM}_ML${INTERFML} ] ; then 
# 		cd ${MASSPROCESSPATH}/${SATDIR}/${TRKDIR}/${SMCROPDIR}_Zoom${ZOOM}_ML${INTERFML}
# 		 if [ "${SATDIR}" == "S1" ]
# 			then 
# 				ls -d * | ${PATHGNU}/grep -v ".txt"  | ${PATHGNU}/grep -v "Geocoded" | cut -d _ -f 3,7 > ${PROPATH}/ExistingPairs_${RNDM}.txt
# 			else 
# 				ls -d * | ${PATHGNU}/grep -v ".txt"  | ${PATHGNU}/grep -v "Geocoded" > ${PROPATH}/ExistingPairs_${RNDM}.txt
# 		fi
# 	fi

mkdir -p ${MASSPROCESSPATH}
mkdir -p ${MASSPROCESSPATH}/${SATDIR}
mkdir -p ${MASSPROCESSPATH}/${SATDIR}/${TRKDIR}
mkdir -p ${MASSPROCESSPATH}/${SATDIR}/${TRKDIR}/${SMCROPDIR}_Zoom${ZOOM}_ML${INTERFML}

cd ${MASSPROCESSPATH}/${SATDIR}/${TRKDIR}/${SMCROPDIR}_Zoom${ZOOM}_ML${INTERFML}

#if [ -d ${MASSPROCESSPATH}/${SATDIR}/${TRKDIR}/${SMCROPDIR}_Zoom${ZOOM}_ML${INTERFML} ] ; then cd ${MASSPROCESSPATH}/${SATDIR}/${TRKDIR}/${SMCROPDIR}_Zoom${ZOOM}_ML${INTERFML} ; fi
case ${LISTOFPROCESSED} in 
			"YES")
				# Search for Defo mode 
				LinkedFile=$(find ${MASSPROCESSPATH}/${SATDIR}/${TRKDIR}/${SMCROPDIR}_Zoom${ZOOM}_ML${INTERFML}/Geocoded/DefoInterpolx2Detrend/ -maxdepth 1 -type f -name "*deg" 2>/dev/null | head -1)
										
				if [ "${LinkedFile}" == "" ] 
					then 
						# There is no file in DefoInterpolx2Detrend, search in DefoInterpolDetrend
						LinkedFile=$(find ${MASSPROCESSPATH}/${SATDIR}/${TRKDIR}/${SMCROPDIR}_Zoom${ZOOM}_ML${INTERFML}/Geocoded/DefoInterpolDetrend/ -maxdepth 1 -type f -name "*deg" 2>/dev/null | head -1) 
						if [ "${LinkedFile}" == "" ] 
							then 
								# There is no file in DefoInterpolDetrend, search in DefoInterpol
								LinkedFile=$(find ${MASSPROCESSPATH}/${SATDIR}/${TRKDIR}/${SMCROPDIR}_Zoom${ZOOM}_ML${INTERFML}/Geocoded/DefoInterpol/ -maxdepth 1 -type f -name "*deg" 2>/dev/null | head -1) 
								if [ "${LinkedFile}" == "" ] 
									then 
										# There is no file in DefoInterpol, search in Defo
										LinkedFile=$(find ${MASSPROCESSPATH}/${SATDIR}/${TRKDIR}/${SMCROPDIR}_Zoom${ZOOM}_ML${INTERFML}/Geocoded/Defo/ -maxdepth 1 -type f -name "*deg" 2>/dev/null | head -1) 
										if [ "${LinkedFile}" == "" ] 
											then 
												# There is no file at all - can't make the fig with amplitude background
												echo "  // I can't find a deformation file in ${MASSPROCESSPATH}/${SATDIR}/${TRKDIR}/${SMCROPDIR}_Zoom${ZOOM}_ML${INTERFML}/Geocoded//Defo[Interpol][x2][Detrend]. "
												echo "  // Hence I can't check computed pairs, which might be fine if it is a first run. In that case, I suppose that mode will be DefoInterpolx2Detrend. " 
												echo "  // If it is a first run but do not want that mode, do not run the script with option -f or change hard coded lines ins script."
												DEFOMODE=DefoInterpolx2Detrend
											else 
												DEFOMODE=Defo
										fi
									else 
										DEFOMODE=DefoInterpol
								fi
							else 
								DEFOMODE=DefoInterpolDetrend
						fi
					else 
						DEFOMODE=DefoInterpolx2Detrend
				fi

				# force to build the list of existing pairs based on the files in Geocoded/${DEFOMODE}
				rm -f ${PROPATH}/ExistingPairs_${RNDM}.txt
				for GEOCODEDPAIR in `find ${MASSPROCESSPATH}/${SATDIR}/${TRKDIR}/${SMCROPDIR}_Zoom${ZOOM}_ML${INTERFML}/Geocoded/${DEFOMODE}/ -maxdepth 1 -type f -name "*deg"` ; do 
					echo "${GEOCODEDPAIR}" | ${PATHGNU}/grep -Eo "[0-9]{8}_[0-9]{8}">> ${PROPATH}/ExistingPairs_${RNDM}.txt # select date_date where date is 8 numbers
				done ;;
			"NO")
				# force to build the list of existing pairs based on the list of pair dirs in MASSPROCESSPATHLONG
				# If MASSPROCESSPATHLONG contains subdir, check pairs already processed (in the form of date_date ; also for S1) :
				if find "${MASSPROCESSPATH}/${SATDIR}/${TRKDIR}/${SMCROPDIR}_Zoom${ZOOM}_ML${INTERFML}" -mindepth 1 -print -quit | ${PATHGNU}/grep -q . ; then 
					if [ "${SATDIR}" == "S1" ]
							then 
								#ls -d * | ${PATHGNU}/grep -v ".txt"  | ${PATHGNU}/grep -v "Geocoded" | ${PATHGNU}/grep -v "_CheckResults" | cut -d _ -f 3,7 > ${PROPATH}/ExistingPairs_${RNDM}.txt
								find -maxdepth 1 -type d -name "*"  | ${PATHGNU}/grep -v ".txt"  | ${PATHGNU}/grep -v "Geocoded" | ${PATHGNU}/grep -v "_CheckResults" | cut -d _ -f 3,7 > ${PROPATH}/ExistingPairs_${RNDM}.txt
							else 
								#ls -d * | ${PATHGNU}/grep -v ".txt"  | ${PATHGNU}/grep -v "Geocoded" | ${PATHGNU}/grep -v "_CheckResults" > ${PROPATH}/ExistingPairs_${RNDM}.txt
								find -maxdepth 1 -type d -name "*"  | ${PATHGNU}/grep -v ".txt"  | ${PATHGNU}/grep -v "Geocoded" | ${PATHGNU}/grep -v "_CheckResults" > ${PROPATH}/ExistingPairs_${RNDM}.txt
					fi
				fi	;;
			"FILE")	
				# will use PATHTOPAIRLIST as PairsToProcess_${RNDM}.txt, hence create dummy ExistingPairs_${RNDM}.txt
				touch ${PROPATH}/ExistingPairs_${RNDM}.txt
				;;
esac

cd ${PROPATH}
if [  ${LISTOFPROCESSED} == "FILE" ]
	then 
		# assign the list of pairs to process as the list provided in 4th param
		cp ${PATHTOPAIRLIST} ${PROPATH}/PairsToProcess_${RNDM}.txt
		TABLEFILE=PairsToProcess_${RNDM}.txt
		TABLEFILEPATH=${PROPATH}/${TABLEFILE}
	else 
		# Compatible Pairs (in the form of "date_date"; also for S1):
		 if ${PATHGNU}/grep -q Delay "${TABLEFILEPATH}"
			then
				# If TABLEFILEPATH = table from Prepa_MSBAS.sh, it contains the string "Delay", then
				# Remove header and extract only the pairs in ${TABLEFILEPATH}
				cat ${TABLEFILEPATH} | tail -n+3 | cut -f 1-2 | ${PATHGNU}/gsed "s/\t/_/g" > ${TABLEFILE}_NoBaselines_${RNDM}.txt 
			else
				## If PAIRFILE = list of images to play, it contains already only the dates
				#cp ${TABLEFILEPATH} ${TABLEFILE}_NoBaselines_${RNDM}.txt
				if cat ${TABLEFILEPATH} | tail -1 | ${PATHGNU}/grep -q _  
					then
						# Pair files contains _ then already ready
						cp ${TABLEFILEPATH} ${TABLEFILE}_NoBaselines_${RNDM}.txt
					else 
						# Pair files does not contains _ and hence need formatting
						cat ${TABLEFILEPATH} | cut -f 1-2 | ${PATHGNU}/gsed "s/\t/_/g" > ${TABLEFILE}_NoBaselines_${RNDM}.txt
				fi


		 fi

		# Search for only the new ones to be processed:
		if [ -f "ExistingPairs_${RNDM}.txt" ] && [ -s "ExistingPairs_${RNDM}.txt" ]
			then
				${PATHGNU}/grep -Fxvf ExistingPairs_${RNDM}.txt ${TABLEFILE}_NoBaselines_${RNDM}.txt > PairsToProcess_${RNDM}.txt
			else
				cp ${TABLEFILE}_NoBaselines_${RNDM}.txt PairsToProcess_${RNDM}.txt
		fi

		TABLEFILE=PairsToProcess_${RNDM}.txt
		TABLEFILEPATH=${PROPATH}/${TABLEFILE}
fi

if [ ! -s PairsToProcess_${RNDM}.txt ] 
	then 
		echo "No new pairs to process; exit" 
		# clean files
		rm -f *_${RNDM}.txt		
		exit 
fi

sort ${TABLEFILE} > ${TABLEFILE}_NOHEAD_${RNDM}.${TABLEEXT} # sort by MASTERS

TABLEFILEPATHNOHEADER=`echo ${PROPATH}/${TABLEFILE}_NOHEAD_${RNDM}.${TABLEEXT}`
PAIRS=`wc -l < ${TABLEFILEPATHNOHEADER}`

# list of number of pairs using a given image as Primary as [nr master]
cat ${PROPATH}/${TABLEFILE}_NOHEAD_${RNDM}.${TABLEEXT} | cut -c 1-8 | sort | uniq -c > ${PROPATH}/${TABLEFILE}_NOHEAD_${RNDM}.${TABLEEXT}_LISTMASTERSCOUNTED.txt

PAIRSPERSET=`echo "(${PAIRS} + ${N} - 1) / ${N}" | bc` # bash solution for ceiling... 

function ChangeProcessPlace()
	{
	unset FILE
	ORIGINAL=`cat ${PARAMFILEPATH} | ${PATHGNU}/grep PROROOTPATH `
	local NEW=$1
	local FILE=$2
   	echo "      Shall process ${i}th set of pairs in  ${NEW}_${RNDM}"
	${PATHGNU}/gsed -i "s%${ORIGINAL}%${NEW}_${RNDM} 			# PROROOTPATH, path to dir where data will be processed in sub dir named by the sat name (SATDIR).%" ${FILE}

	}

# Split Pair file in order to process in several dir by looking for each master and keep all the pairs as long as total < PAIRSPERSET
for i in `seq 1 ${N}`
do
	NEWPAIRFILE=${PROPATH}/${TABLEFILE}_Part${i}_${RNDM}.${TABLEEXT}
	l=0
	cat ${PROPATH}/${TABLEFILE}_NOHEAD_${RNDM}.${TABLEEXT}_LISTMASTERSCOUNTED.txt | while read nandmas
	do
		# nr of pairs for a given master "MASINSET"
		NROFPAIRSWITHMAS=`echo ${nandmas} | cut -d' ' -f1`
		# master date which is present "NROFPAIRSWITHMAS" times
		MASINSET=`echo ${nandmas} | cut -d' ' -f2`	
		# nr of lines in ith NEWPAIRFILE
		l=`echo "( ${l} + ${NROFPAIRSWITHMAS} ) " | bc`
		if [ ${i} -lt ${N} ] 
			then # ensure that set is smaller than total/N
				if [ ${l} -lt ${PAIRSPERSET} ] 
					then 		
						#copy all pairs with starting master 
						echo "Shall write ${NROFPAIRSWITHMAS} pairs starting with Primary image ${MASINSET} in new ${i}th table" 
						cat ${TABLEFILEPATHNOHEADER} | ${PATHGNU}/grep ^${MASINSET} >> ${NEWPAIRFILE} 
						# and remove that master from list to split
						cat ${PROPATH}/${TABLEFILE}_NOHEAD_${RNDM}.${TABLEEXT}_LISTMASTERSCOUNTED.txt | ${PATHGNU}/grep -v ${MASINSET} > ${PROPATH}/${TABLEFILE}_NOHEAD_${RNDM}.${TABLEEXT}_LISTMASTERSCOUNTED.txt.tmp
						rm ${PROPATH}/${TABLEFILE}_NOHEAD_${RNDM}.${TABLEEXT}_LISTMASTERSCOUNTED.txt
						mv ${PROPATH}/${TABLEFILE}_NOHEAD_${RNDM}.${TABLEEXT}_LISTMASTERSCOUNTED.txt.tmp ${PROPATH}/${TABLEFILE}_NOHEAD_${RNDM}.${TABLEEXT}_LISTMASTERSCOUNTED.txt
				fi	
			else # get all the remaining pairs, even if goes beyone max nr of per set
				echo "Shall write ${NROFPAIRSWITHMAS} pairs starting with Primary image ${MASINSET} in the last ${i}th table" 
				cat ${TABLEFILEPATHNOHEADER} | ${PATHGNU}/grep ^${MASINSET} >> ${NEWPAIRFILE} 

		fi
	done
done

# test length of the last batch. If too big (i.e. more than 10% longer), offer to split it in an additional batch
TSTLENGTHLAST=`cat ${PROPATH}/${TABLEFILE}_Part${N}_${RNDM}.${TABLEEXT} | wc -l`
FIRSTHALFLAST=`echo "( ${TSTLENGTHLAST} / 2 ) " | bc ` # rounded by default if not integer
SECONDHALFLAST=`echo "( ${TSTLENGTHLAST} - ${FIRSTHALFLAST} ) " | bc `
LONGERPAIRSPERSET=`echo "( ${PAIRSPERSET} + (${PAIRSPERSET} * 0.10) ) " | bc | cut -d . -f 1` # Not rounded by default if not integer because of 0.10 hence must cut at dot
if [ ${TSTLENGTHLAST} -gt ${LONGERPAIRSPERSET} ] && [ ${TSTLENGTHLAST} -gt 0 ] && [ ${LONGERPAIRSPERSET} -gt 0 ]
	then 
		echo "Each batch will process ${PAIRSPERSET} pairs at the maximum, because all pairs using a same Primary Image are not spread over two batches. "
		echo "The last batch is however ${TSTLENGTHLAST} pairs long, that is more than 10% longer than max length of other batches."
		while true; do
			read -p "Do you want to split it in two batches to avoid delaying the results because of that otherwise much longer last batch [y/n]? "  yn
			case $yn in
				[Yy]* ) 
					head -${FIRSTHALFLAST} ${PROPATH}/${TABLEFILE}_Part${N}_${RNDM}.${TABLEEXT}  > ${PROPATH}/${TABLEFILE}_Part${N}_${RNDM}.${TABLEEXT}_PART1
					tail -${SECONDHALFLAST} ${PROPATH}/${TABLEFILE}_Part${N}_${RNDM}.${TABLEEXT}  > ${PROPATH}/${TABLEFILE}_Part${N}_${RNDM}.${TABLEEXT}_PART2
					
					# check master of the last pair in first half and of first pair in second half
					MASINFIRSTHALF=`tail -1 ${PROPATH}/${TABLEFILE}_Part${N}_${RNDM}.${TABLEEXT}_PART1 | cut -d _ -f 1`
					MASINSECONDHALF=`head -1 ${PROPATH}/${TABLEFILE}_Part${N}_${RNDM}.${TABLEEXT}_PART2 | cut -d _ -f 1`					

					# If they are the same, copy all pairs from part where less pairs use that master to the other part
					if [ ${MASINFIRSTHALF} -eq ${MASINSECONDHALF} ] 
						then 
							echo " Both parts of the last batch share a same Primary Image. Let's copy all pairs from part where less pairs use that Primary Image to the other part "
							# nr of occurrence of MASINFIRSTHALF in both parts
							MASINPART1=`grep -c "^${MASINFIRSTHALF}_" ${PROPATH}/${TABLEFILE}_Part${N}_${RNDM}.${TABLEEXT}_PART1`
							MASINPART2=`grep -c "^${MASINFIRSTHALF}_" ${PROPATH}/${TABLEFILE}_Part${N}_${RNDM}.${TABLEEXT}_PART2`
							
							if [ ${MASINPART1} -gt ${MASINPART2} ] 
								then 
									# more pairs with that master in part 1. Let's move pairs using that master from part2 to part 1
									grep "^${MASINFIRSTHALF}_" ${PROPATH}/${TABLEFILE}_Part${N}_${RNDM}.${TABLEEXT}_PART2 >> ${PROPATH}/${TABLEFILE}_Part${N}_${RNDM}.${TABLEEXT}_PART1
									grep -v "^${MASINFIRSTHALF}_" ${PROPATH}/${TABLEFILE}_Part${N}_${RNDM}.${TABLEEXT}_PART2 >> ${PROPATH}/${TABLEFILE}_Part${N}_${RNDM}.${TABLEEXT}_PART2_TMP
									mv -f ${PROPATH}/${TABLEFILE}_Part${N}_${RNDM}.${TABLEEXT}_PART2_TMP ${PROPATH}/${TABLEFILE}_Part${N}_${RNDM}.${TABLEEXT}_PART2
								else 
									# more pairs with that master in part 2. Let's move pairs using that master from part1 to part 2								
									grep "^${MASINFIRSTHALF}_" ${PROPATH}/${TABLEFILE}_Part${N}_${RNDM}.${TABLEEXT}_PART1 >> ${PROPATH}/${TABLEFILE}_Part${N}_${RNDM}.${TABLEEXT}_PART2
									grep -v "^${MASINFIRSTHALF}_" ${PROPATH}/${TABLEFILE}_Part${N}_${RNDM}.${TABLEEXT}_PART1 >> ${PROPATH}/${TABLEFILE}_Part${N}_${RNDM}.${TABLEEXT}_PART1_TMP
									mv -f ${PROPATH}/${TABLEFILE}_Part${N}_${RNDM}.${TABLEEXT}_PART1_TMP ${PROPATH}/${TABLEFILE}_Part${N}_${RNDM}.${TABLEEXT}_PART1
							fi
						else 
							echo " Both parts of the last batch do not share same Primary Image."
					fi
					OLDN=${N}
					N=`echo "( ${N} + 1 ) " | bc ` 
					
					mv -f ${PROPATH}/${TABLEFILE}_Part${OLDN}_${RNDM}.${TABLEEXT}_PART1 ${PROPATH}/${TABLEFILE}_Part${OLDN}_${RNDM}.${TABLEEXT}
					mv -f ${PROPATH}/${TABLEFILE}_Part${OLDN}_${RNDM}.${TABLEEXT}_PART2 ${PROPATH}/${TABLEFILE}_Part${N}_${RNDM}.${TABLEEXT}
					
					break
					;;
				[Nn]* ) 
					echo "OK, the run of that last batch will just last longer than the others batches, but that's fine. "
					break 
					;;
				* ) 
					echo "Please answer yes or no."
					break ;;
			esac
		done
fi


rm ${PROPATH}/${TABLEFILE}_NOHEAD_${RNDM}.${TABLEEXT}_LISTMASTERSCOUNTED.txt ${PROPATH}/${TABLEFILE}_NOHEAD_${RNDM}.${TABLEEXT}
echo ""

# Check the DISPLAY for Linux
if [ "${OS}" == "Linux" ] ; then 

		# All DISPLAYS
		ps -u $(id -u) -o pid=     | xargs -I PID -r cat /proc/PID/environ 2> /dev/null     | tr '\0' '\n'     | grep ^DISPLAY=:     | sort -u | cut -d = -f2 | grep -v "tty" > all_displays.tmp

		NRMYDISPLAYWHO=`who -m | grep -v tty | cut -d "(" -f 2  | cut -d ")" -f 1 | wc -l`
		case ${NRMYDISPLAYWHO} in 
			1) 
				# only one DISPLAY; I guess it is the good one
				eval MYDISPLAY=`who -m | grep -v tty | cut -d "(" -f 2  | cut -d ")" -f 1 ` 
				# Test if it is listed in all the displays though; if not, ask manually
				if [ `grep "${MYDISPLAY}" all_displays.tmp | wc -l` -ne 1 ] 
					then 
						ASKDISPLAY="YES"
				fi
				;;
			0) 
				# no DISPLAY; try with who without -m
				NRMYDISPLAYWHO=`who | grep -v tty | cut -d "(" -f 2  | cut -d ")" -f 1 | wc -l`
				if [ ${NRMYDISPLAYWHO} -eq 1 ]
					then 
						# only one DISPLAY; I guess it is the good one
						eval MYDISPLAY=`who | grep -v tty | cut -d "(" -f 2  | cut -d ")" -f 1 ` 
						# Test if it is listed in all the displays though; if not, ask manually
						if [ `grep "${MYDISPLAY}" all_displays.tmp | wc -l` -ne 1 ] 
							then 
								ASKDISPLAY="YES"
						fi
					else 
						ASKDISPLAY="YES"
				fi
				;;
			*) 
				# more than one DISPLAY
				ASKDISPLAY="YES"
				;;
		esac

		if [ "${ASKDISPLAY}" == "YES" ]
			then 
				echo "I can't find out which is your current DISPLAY value. "
				echo "I can however see that you have the following DISPLAYs on your server:"
				# The following line list all the DISPLAYs:
				ps -u $(id -u) -o pid=     | xargs -I PID -r cat /proc/PID/environ 2> /dev/null     | tr '\0' '\n'     | grep ^DISPLAY=:     | sort -u
				
				while true; do
					read -p "Which one do you want to use (answer someting like \":0.0\" without the quotes) ? "  MYDISPLAY
					echo "If no Terminal pops up here after, cancel the current script and start again with another DISPLAY"
					break
				done
				eval MYDISPLAY=`echo ${MYDISPLAY}`
		fi 

		echo "  // Your current session runs on DISPLAY ${MYDISPLAY}"
		rm -f all_displays.tmp
fi


if [ "${SATDIR}" != "S1" ] 
	then

		MASDIR=`ls ${DATAPATH}/${SATDIR}/${TRKDIR}/NoCrop | ${PATHGNU}/grep ${SUPERMASTER}` 		 # i.e. if S1 is given in the form of date, MASNAME is now the full name of the image anyway

		S1ID=`GetParamFromFile "Scene ID" SAR_CSL_SLCImageInfo.txt`
		S1MODE=`echo ${S1ID} | cut -d _ -f 2`	
		if [ ${S1MODE} != "IW" ] && [ ${S1MODE} != "EW" ]
			then 
				SpeakOut "For processing other than S1 IW or EW, better first compute the DEM (and mask) anyway; mass processes should be start after. Do you want to run DEM first?" 
					while true; do
						read -p "For processing other than S1, better first compute the DEM (and mask) anyway; mass processes should be start after. Do you want to run DEM first?"  yn
						case $yn in
							[Yy]* ) 
								echo 
								echo "********************************************************************"
								echo "DO NOT START NEXT STEPS OF _SPILTSESSIONS.SH BEFORE DEM IS FINISHED"
								echo "********************************************************************"
								case ${OS} in 
									"Linux") 
										export DISPLAY=${MYDISPLAY} ; x-terminal-emulator -e ${PATHFCTFILE}/LaunchTerminal.sh ${PATHFCTFILE}/MasterDEM.sh ${SUPERMASTER} ${PARAMPATH}/${PARAMFILE} &
										;;
									"Darwin")
										osascript -e 'tell app "Terminal"
										do script "MasterDEM.sh '"${SUPERMASTER} ${PARAMPATH}/${PARAMFILE}"'"
										end tell'		;;
									*)
										echo "I can't figure out what is you opeating system. Please check"
										exit 0
										;;
								esac						
								break ;;
							[Nn]* ) break ;;
							* ) 
								echo "Please answer yes or no.";;
						esac
					done
		fi
	else 
		echo "For S1 processing, ensure you ran SuperMasterCoreg.sh first to ensure proper DEM (and mask). "
fi

# Now one can put it safely to KEEP.   
ORIGINALMODE=`cat ${PARAMFILEPATH} | ${PATHGNU}/grep RECOMPDEM `
${PATHGNU}/gsed "s%${ORIGINALMODE}%KEEP		# RECOMPDEM, recompute DEM or mask in slant range even if already there (FORCE), or check the one that would exist (KEEP). %" ${PARAMFILEPATH} > ${PROPATH}/${PARAMFILE}
echo ""

# Split Parameter file i order to process in several dir
echo "-------------------------------------------"
echo "Disk space available on your drives are : "
df -h
echo "-------------------------------------------"
echo "Where do you want to process the ${i} set of ${PAIRSPERSET} pairs: "
# List disks and their nr -  see __HardCodedLines.sh
SplitDiskList

for i in `seq 1 ${N}`
do
	NEWPARAMFILE=${PROPATH}/${PARAMFILE}_Part${i}_${RNDM}.${PARAMEXT}
	cp ${PROPATH}/${PARAMFILE} ${NEWPARAMFILE}

		while true; do
			read -p "Provide the number of disk from list above and ensure there is enough space: "  DISK
			# Select disk by their nrs -  see __HardCodedLines.sh
			SplitDiskSelection
			break
		done
		ChangeProcessPlace ${DISKPATH} ${NEWPARAMFILE}
		DISKPATH[$i]=${DISKPATH}
		echo "	${i}th processing will be on ${DISKPATH[$i]} "
done

echo ""

echo "-------------------------------------------"
while true ; do
	read -p "Do you want to run the Mass Processing in separate Terminal windows ? "  yn
	case $yn in
		[Yy]* ) 
			# launch the processing in separate Terminal windows
			echo "OK, I launch them for you now..."
			for i in `seq 1 ${N}`
 			do
 				sleep 5
 				case ${OS} in 
					"Linux") 
 						if [ -f "${PROPATH}/${TABLEFILE}_Part${i}_${RNDM}.${TABLEEXT}" ] && [ -s "${PROPATH}/${TABLEFILE}_Part${i}_${RNDM}.${TABLEEXT}" ] 
 							then 
								export DISPLAY=${MYDISPLAY} ; x-terminal-emulator -e ${PATHFCTFILE}/LaunchTerminal.sh ${PATHFCTFILE}/SuperMaster_MassProc.sh ${PROPATH}/${TABLEFILE}_Part${i}_${RNDM}.${TABLEEXT} ${PROPATH}/${PARAMFILE}_Part${i}_${RNDM}.${PARAMEXT} &
								# without terminals
								#${PATHFCTFILE}/SuperMaster_MassProc.sh ${PROPATH}/${TABLEFILE}_Part${i}_${RNDM}.${TABLEEXT} ${PROPATH}/${PARAMFILE}_Part${i}_${RNDM}.${PARAMEXT} &
 							else 
 								echo
 								echo "${PROPATH}/${TABLEFILE}_Part${i}_${RNDM}.${TABLEEXT} is emplty ; skip that ${i}th batch. "
 								echo
						fi
						;;
					"Darwin")
 						if [ -f "${PROPATH}/${TABLEFILE}_Part${i}_${RNDM}.${TABLEEXT}" ] && [ -s "${PROPATH}/${TABLEFILE}_Part${i}_${RNDM}.${TABLEEXT}" ]
 							then 
								osascript -e 'tell app "Terminal"
 								do script "SuperMaster_MassProc.sh '"${PROPATH}/${TABLEFILE}_Part${i}_${RNDM}.${TABLEEXT} ${PROPATH}/${PARAMFILE}_Part${i}_${RNDM}.${PARAMEXT}"'"
 								end tell'
 							else 
  								echo
 								echo "${PROPATH}/${TABLEFILE}_Part${i}_${RNDM}.${TABLEEXT} is emplty ; skip that ${i}th batch. "
 								echo
 						fi
 						;;
					*)
						echo "I can't figure out what is you opeating system. Please check"
						exit 0
						;;
				esac	
 			done 
			break ;;
		[Nn]* ) 
			echo ""
			echo "OK, launch them manually when you are ready"    
			break ;;
    	* ) echo "Please answer yes or no." ;;	
    esac	
done

echo
echo "WAIT FOR FINISHING WORK IN ALL TERMINALS BEFORE ATTEMPTING CLEANING THE DIRECTORIES." 

# Check what is running 
while true ; do
	read -p "All process are finished and you want to try cleaning the working directories [y/n] ? : "  yn
		case $yn in
		[Yy]* ) 
			if [ `ps -eaf | grep SuperMaster_MassProc.sh | grep -v grep | wc -l ` -eq 0 ] 
				then 
					echo "Indeed, no more SuperMaster_MassProc.sh  are running on this computer. You can proceed : "
					break 
				else 
					echo "Sorry, not finished yet."
					while true ; do
						read -p "Do you want to force the cleaning anyway ? Beware that it will cause the running processes to crash [y/n] ? : "  yn
							case $yn in
							[Yy]* ) 
								echo "OK, I guess you checked that the running SuperMaster_MassProc.sh is not part of the __SplitSession.sh run... "
								echo "Proceed to cleaning :"
								break 
								;;
							[Nn]* ) 
								echo "OK, then I wait..."    
								;;
					    	* ) echo "Please answer yes [Yy] or no [Nn]." ;;	
					    esac	
					done
			fi 
			break ;;
		[Nn]* ) 
			echo "OK, then I wait..."    
			;;
    	* ) echo "Please answer yes [Yy] or no [Nn]." ;;	
    esac	
done

# Some cleaning 
while true ; do
	read -p "	Do you want to clean ${PROPATH} ? "  yn
		case $yn in
		[Yy]* ) 
			echo "	Remove this: "
			ls -l ${PROPATH}
			rm -Rf ${PROPATH}
			break ;;
		[Nn]* ) 
			echo "	OK, clean manually this:"    
			ls -l ${PROPATH}
			break ;;
    	* ) echo "	Please answer yes [Yy] or no [Nn]." ;;	
    esac	
done
	
echo 
		
# Some cleaning 
while true ; do
	read -p "	Do you want to clean Processing dirs ? "  yn
		case $yn in
		[Yy]* ) 
			for i in `seq 1 ${N}`
				do
					echo "	Removing  ${DISKPATH[$i]}*"
					rm -Rf ${DISKPATH[$i]}*
					echo
			done
			break ;;
		[Nn]* ) 
			echo "	OK, clean manually this:"    
			for i in `seq 1 ${N}`
				do
					echo "	${DISKPATH[$i]}*"
			done
			break ;;
    	* ) echo "	Please answer yes [Yy] or no [Nn]." ;;	
    esac	
done
