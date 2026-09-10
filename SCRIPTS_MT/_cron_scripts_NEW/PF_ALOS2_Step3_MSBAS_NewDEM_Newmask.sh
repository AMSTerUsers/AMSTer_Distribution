#!/bin/bash
# Script intends to run in a cronjob an automatic systematic (re)processing of msbas time 
# series when new images were made available. If orbits were updated, corresponding products 
# will be taken into account at the time of processing with new images. 
# 
# It will prepare and run MSBAS only if no other mass process is in progress.
# It also plots several time series and double differences based on provided list of points. 
#
# Optional : perform a selection of pairs based on a mean coh computed on a provided footprint.
#			This might be useful for regions known to be affected by strong seasonal decorrelation. 
#			For instance, ensuring a mean coh of at least 0.235 on the Laguna_Maule area (Chile) 
#			ensured a proper estimation of the deformation. Not performing that selection based 
#			on the coh underestimated the defo up to 60%.
#
# NOTE: - MSBAS Calibration is disabled because deformation maps are detrended at processing. 
#
# WARNING: 	Because build_header_msbas_criteria.sh requires all table files with the same Bp and Bt names, 
#			which is not the case here, we  use build_header_msbas_Tables.sh 
#
# Parameters: - none 
#
# Hardcoded: - a lot... se below paragraph named HARD CODED but also adapt below depending on the number of modes 
#			 - suppose everywhere that modes are DefoInterpolx2Detrend
#
# Dependencies:	- 
#
# New in Distro V 1.1 20240404:	- restrict to data after 20210331
#								- reject modes with problems of coregistration, that is 
#									6778, 4020 and 4034 
# New in Distro V 1.2 20240925:	- store results in UD_EW_NS dir
#								- set DEFOMODE param 
#								- force inversion with msbasv4_3D 
#									(must be compiled with carea.pp line 334 (?), ie. close 
# 									to comment "//no azimuth offsets, no DEM", set as 
#									DIM=3 instead of DIM=2
#									and stored accordingly in AMSTer/MSBAS as msbasv4_3D)
# New in Distro V 1.3 20241009:	- also perform 2D
# New in Distro V 1.4 20241230 :	- replace ${PATH_1650}/SAR_SM/MSBAS/PF_oldDEM with ${PATH_1650}/SAR_SM/MSBAS/PF
# New in Distro V 1.5 20250106 :	- cd MSBASDIR before running 2D LOS
# New in Distro V 1.6 20250109 :	- quote many things
#									- define TIMESERIESPTS for EW_UD in 2D 
# New in Distro V 1.7 20250410:	- change SM for mode 4041 (13D)
# New in Distro V 1.7.1 20250424 :	- check if correct termination in MSBAS_LOG.txt at right place
# New in Distro V 1.8.0 20250603 :	- change inversion order to 3
#									- change C_FLAG back to 10 
#									- reject some pairs in 11D and 13D
#									- corr bug in mkdir ghost LOS dir that contained tabs and spaces at the end of name
# New in Distro V 2.0.0 20251209 :	- always limited to 128 threads (see MAXTHREADS) to prevent problems with openblas, which is compiled by default for 128 threads 
# New in Distro V 2.1.0 20260730 :	- force msbasv4		
# New in Distro V 2.2.0 20260909 :	- assign MAXTHREADS		
#									- remove some processing of unused modes 		
# New in Distro V 2.3.0 20260909 :	- MODELIST is now the ONLY place where the modes to invert are 
#									  selected. The modes that are not in MODELIST are skipped 
#									  everywhere by looping with ModeUsed() and USEDSETS instead of 
#									  hard coding (and hand commenting) each of the 27 modes. 
#									- the 27 tables and the 27 SET lines in header.txt are still 
#									  always built, to preserve the numbering of the modes  
#									- _Last_MassProcessed_Pairs_Time.txt always keeps its 27 lines; 
#									  unused modes are stored as 0 
#									- no more error msg from find/stat/test on missing dir or file, 
#									  neither at first run nor for the unused modes 
#
# AMSTer: SAR & InSAR Automated Mass processing Software for Multidimensional Time series
# NdO (c) 2016/03/07 - could make better with more functions... when time.
# -----------------------------------------------------------------------------------------
PRG=`basename "$0"`
VER="Distro V2.3.0 AMSTer script utilities"
AUT="Nicolas d'Oreye, (c)2016-2019, Last modified on Sept 09, 2026"

echo " "
echo "${PRG} ${VER}, ${AUT}"
echo " "

source $HOME/.bashrc

cd

TODAY=`date`
MMDDYYYY=$(date +'%m_%d_%Y') # Needed to restrict pairs after give date

# vvvvvvvvv Hard coded lines vvvvvvvvvvvvvv
	# set the max number of threads to be used by MSBAS. 
	####################################################

	MAXTHREADS=128

	#Remember that OPENBLAS is pre-compiled for Ubuntu with max 128 threads
		# Check OS
		OS=`uname -a | cut -d " " -f 1 `
	
		case ${OS} in 
			"Linux") 
				NTHR=$(nproc --all)	 ;;
			"Darwin")
				NTHR=$(sysctl -n hw.ncpu) 	;;
			*)
				echo "${MESSAGE}" 	;;
		esac			
	
		# get the number frm your hardware 
		if [ ${NTHR} -gt ${MAXTHREADS} ] ; then NTHR=${MAXTHREADS} ; fi


	# some parameters
	#################

		# Path to dir where list of compatible pairs files are computed (need one for each mode)
		SET01="${PATH_1650}/SAR_SM/MSBAS/PF/set5"
		SET02="${PATH_1650}/SAR_SM/MSBAS/PF/set6"
		SET03="${PATH_1650}/SAR_SM/MSBAS/PF/set7"
		SET04="${PATH_1650}/SAR_SM/MSBAS/PF/set8"
		SET05="${PATH_1650}/SAR_SM/MSBAS/PF/set9"
		SET06="${PATH_1650}/SAR_SM/MSBAS/PF/set10"
		SET07="${PATH_1650}/SAR_SM/MSBAS/PF/set11"
		SET08="${PATH_1650}/SAR_SM/MSBAS/PF/set12"
		SET09="${PATH_1650}/SAR_SM/MSBAS/PF/set13"
		SET10="${PATH_1650}/SAR_SM/MSBAS/PF/set14"
		SET11="${PATH_1650}/SAR_SM/MSBAS/PF/set15"
		SET12="${PATH_1650}/SAR_SM/MSBAS/PF/set16"
		SET13="${PATH_1650}/SAR_SM/MSBAS/PF/set17"
		SET14="${PATH_1650}/SAR_SM/MSBAS/PF/set18"
		SET15="${PATH_1650}/SAR_SM/MSBAS/PF/set19"
		SET16="${PATH_1650}/SAR_SM/MSBAS/PF/set20"
		SET17="${PATH_1650}/SAR_SM/MSBAS/PF/set21"
		SET18="${PATH_1650}/SAR_SM/MSBAS/PF/set22"
		SET19="${PATH_1650}/SAR_SM/MSBAS/PF/set23"
		SET20="${PATH_1650}/SAR_SM/MSBAS/PF/set24"
		SET21="${PATH_1650}/SAR_SM/MSBAS/PF/set25"
		SET22="${PATH_1650}/SAR_SM/MSBAS/PF/set26"
		SET23="${PATH_1650}/SAR_SM/MSBAS/PF/set27"
		SET24="${PATH_1650}/SAR_SM/MSBAS/PF/set28"
		SET25="${PATH_1650}/SAR_SM/MSBAS/PF/set29"
		SET26="${PATH_1650}/SAR_SM/MSBAS/PF/set30"
		SET27="${PATH_1650}/SAR_SM/MSBAS/PF/set31"


		## Modes:
		# Ascending modes 
		MODE01A="6811_L_A"	# SET01, that is set5
		MODE02A="6806_L_A"	# SET02, that is set6; make 6807_L_A as well
		MODE03A="6801_L_A"	# SET03, that is set7; make 6802_L_A as well
		MODE04A="6796_L_A"	# SET04, that is set8
		MODE05A="6790_L_A"	# SET05, that is set9
		MODE06A="6784_L_A"	# SET06, that is set10
		MODE07A="6778_L_A"	# SET07, that is set11
		MODE08A="6764_R_A"	# SET08, that is set12
		MODE09A="6757_R_A"	# SET09, that is set13
		MODE10A="6749_R_A"	# SET10, that is set14; make 6750_R_A as well
		MODE11A="6742_R_A"	# SET11, that is set15; make 6741_R_A as well
		MODE12A="6733_R_A"	# SET12, that is set16
		MODE13A="6724_R_A"	# SET13, that is set17
		
		# Descending modes 
		MODE01D="4020_L_D"	# SET14, that is set18
		MODE02D="4014_L_D"	# SET15, that is set19
		MODE03D="4008_L_D"	# SET16, that is set20
		MODE04D="4002_L_D"	# SET17, that is set21
		MODE05D="3997_L_D"	# SET18, that is set22
		MODE06D="3992_L_D"	# SET19, that is set23
		MODE07D="3987_L_D"	# SET20, that is set24
		MODE08D="4082_R_D"	# SET21, that is set25
		MODE09D="4073_R_D"	# SET22, that is set26
		MODE10D="4064_R_D"	# SET23, that is set27
		MODE11D="4056_R_D"	# SET24, that is set28
		MODE12D="4048_R_D"	# SET25, that is set29
		MODE13D="4041_R_D"	# SET26, that is set30
		MODE14D="4034_R_D"	# SET27, that is set31; make 4033_R_D as well
		
		# List of all numbers of modes 
		# cause rejet:  A = low angle ; N = not enough data  ; 0 = 0 data
		#		                                          A                                          A                       0           N                                        A    
		# modes   	6811  6806  6801  6796  6790  6784  6778  6764  6757   6749  6742  6733  6724   4020  4014 4008  4002   3997  3992 3987  4082 	4073  4064  4056  4048  4041 4034  
		# SET		   1    2      3    4     5     6      7    8     9     10    11     12    13    14    15   16    17     18    19   20    21    22     23    24    25   26   27 
		# seti:		   5    6      7    8     9    10     11    12    13    14    15     16    17    18    19   20    21     22    23   24    25    26     27    28    29   30   31
		ALLMODELIST=("01A" "02A" "03A" "04A" "05A" "06A" "07A" "08A" "09A" "10A" "11A" "12A" "13A" "01D" "02D" "03D" "04D" "05D" "06D" "07D" "08D" "09D" "10D" "11D" "12D" "13D" "14D")

		# List of nr of modes to invert using MSBAS
		# All 
		#MODELIST=(01A 02A 03A 04A 05A 06A 07A 08A 09A 10A 11A 12A 13A 01D 02D 03D 04D 05D 06D 07D 08D 09D 10D 11D 12D 13D 14D)
		# All but 07A=6778_L_A (SET07, that is set11),   01D=4020_L_D (SET14, that is set18),   05D=3997_L_D (SET18, that is set22)   and   07D=3987_L_D (SET20, that is set24)     14D=4034_R_D (SET27, that is set31)
		MODELIST=("01A" "02A" "03A" "04A" "05A" "06A" "08A" "09A" "10A" "11A" "12A" "13A" "02D" "03D" "04D" "06D" "08D" "09D" "10D" "11D" "12D" "13D")
		
		# search for position of missing modes: 
		if [ "${#ALLMODELIST[@]}" -ne "${#MODELIST[@]}" ]  # i.e. if the two list have not the same length
			then
				missing_positions=()
				
				# Iterate over ALLMODELIST
				for ((i=0; i<"${#ALLMODELIST[@]}"; i++)); do
				    found=false
				    # Check if the element exists in MODELIST
				    for elem in "${MODELIST[@]}"; do
				        if [[ "${ALLMODELIST[i]}" == "$elem" ]]; then
				            found=true
				            break
				        fi
				    done
				    # If the element doesn't exist in MODELIST record its position
				    if [ "$found" == false ]; then
				    	# must add one to position because counting was done from zero
				    	j=`echo "$i + 1"| bc`
				        missing_positions+=("$j")
				        missing_element+=("${ALLMODELIST[i]}")
				        missing_positions_in_header+=("$i") 	# start counting from 0
				    fi
				done
				
				# Print the positions of missing elements
				echo "// Request to invert only some modes:"
				echo "// Value of elements that are in ALLMODELIST but not in MODELIST:	 ${missing_element[@]}"
				echo "// Positions of elements that are in ALLMODELIST but not in MODELIST: ${missing_positions[@]}"

			else 
				echo "// Request to invert all modes"
			
		fi
		# Test if a mode must be processed, i.e. if it is in MODELIST. 
		# It accepts either the name of a mode (e.g. 07A) or its position in ALLMODELIST, that is 
		# the set number i as used in SETi, in ${DEFOMODE}i and in the ith SET line of header.txt. 
		# Usage:  if ModeUsed "07A" ; then ... ; fi 	or 	if ModeUsed 7 ; then ... ; fi
		ModeUsed()
			{
			MODEASKED="$1"
			case "${MODEASKED}" in
				[0-9]|[0-9][0-9]) 	MODEASKED="${ALLMODELIST[$(( MODEASKED - 1 ))]}" ;;
			esac
			for MODEINLIST in "${MODELIST[@]}" ; do
				if [ "${MODEINLIST}" = "${MODEASKED}" ] ; then return 0 ; fi
			done
			return 1
			}

		# List of the set numbers (i.e. the i in SETi and in ${DEFOMODE}i) of the modes to process. 
		# Used to loop on the modes to process instead of hard coding the 27 modes everywhere. 
		USEDSETS=""
		SETNR=1
		for MODE in "${ALLMODELIST[@]}" ; do
			if ModeUsed "${MODE}" ; then USEDSETS="${USEDSETS} ${SETNR}" ; fi
			SETNR=$(( SETNR + 1 ))
		done
		echo "// Set numbers of the modes to process: ${USEDSETS}"
		echo ""
		
		#SM Asc
		SM01A=20230506	# 6811_L_A
		SM02A=20231207	# 6806_L_A
		SM03A=20221018	# 6801_L_A
		SM04A=20230827	# 6796_L_A
		SM05A=20211210	# 6790_L_A
		SM06A=20230614	# 6784_L_A
		SM07A=20230227	# 6778_L_A
		SM08A=20210603	# 6764_R_A
		SM09A=20230131	# 6757_R_A
		SM10A=20230806	# 6749_R_A
		SM11A=20230825	# 6742_R_A
		SM12A=20211013	# 6733_R_A
		SM13A=20221017	# 6724_R_A
		
		#SM Desc
		SM01D=20210917	# 4020_L_D
		SM02D=20221102	# 4014_L_D
		SM03D=20220411	# 4008_L_D
		SM04D=20221001	# 4002_L_D
		SM05D=20150820	# 3997_L_D
		SM06D=20211026	# 3992_L_D
		SM07D=20210530	# 3987_L_D
		SM08D=20220807	# 4082_R_D
		SM09D=20230728	# 4073_R_D
		SM10D=20230816	# 4064_R_D
		SM11D=20211018	# 4056_R_D
		SM12D=20190831	# 4048_R_D
		#SM13D=20211028	# 4041_R_D
		SM13D=20211125	# 4041_R_D
		SM14D=20220809	# 4034_R_D
		
		# Baselines Asc
		BP01A=150	# 6811
		BT01A=150
		
		BP02A=150	# 6806
		BT02A=150
		
		BP03A=100	# 6801
		BT03A=100
		
		BP04A=150	# 6796
		BT04A=150
		
		BP05A=150	# 6790
		BT05A=150
		
		BP06A=150	# 6784
		BT06A=150
		
		BP07A=150	# 6778
		BT07A=150
		
		BP08A=200	# 6764
		BT08A=200
		
		BP09A=250	# 6757
		BT09A=280
		
		BP10A=200	# 6749
		BT10A=200
		
		BP11A=150	# 6742
		BT11A=150
		
		BP12A=200	# 6733
		BT12A=200
		
		BP13A=200	# 6724
		BT13A=200
		
		# Baselines Desc
		BP01D=150	# 4020
		BT01D=150
		
		BP02D=200	# 4014
		BT02D=200
		
		BP03D=150	# 4008
		BT03D=150
		
		BP04D=200	# 4002
		BT04D=200
		
		BP05D=200	# 3997
		BT05D=200
		
		BP06D=200	# 3992
		BT06D=200
		
		BP07D=150	# 3987
		BT07D=150
		
		BP08D=150	# 4082
		BT08D=150
		
		BP09D=200	# 4073
		BT09D=200
		
		BP10D=200	# 4064
		BT10D=200
		
		BP11D=200	# 4056
		BT11D=200
		
		BP12D=150	# 4048
		BT12D=150
		
		BP13D=200	# 4041
		BT13D=200
		
		BP14D=150	# 4034
		BT14D=150
		
		
		#BP2=90
		#BT2=70
		#DATECHG=20220501
		
		# some files
		############
	
		# Path to Seti
		PATHSETI="$PATH_1650/SAR_SM/MSBAS"
	
		# Pair files
		TABLE01A="${PATHSETI}/PF/set5/table_0_${BP01A}_0_${BT01A}.txt"
		TABLE02A="${PATHSETI}/PF/set6/table_0_${BP02A}_0_${BT02A}.txt"
		TABLE03A="${PATHSETI}/PF/set7/table_0_${BP03A}_0_${BT03A}.txt"
		TABLE04A="${PATHSETI}/PF/set8/table_0_${BP04A}_0_${BT04A}.txt"
		TABLE05A="${PATHSETI}/PF/set9/table_0_${BP05A}_0_${BT05A}.txt"
		TABLE06A="${PATHSETI}/PF/set10/table_0_${BP06A}_0_${BT06A}.txt"
		TABLE07A="${PATHSETI}/PF/set11/table_0_${BP07A}_0_${BT07A}.txt"
		TABLE08A="${PATHSETI}/PF/set12/table_0_${BP08A}_0_${BT08A}.txt"
		TABLE09A="${PATHSETI}/PF/set13/table_0_${BP09A}_0_${BT09A}.txt"
		TABLE10A="${PATHSETI}/PF/set14/table_0_${BP10A}_0_${BT10A}.txt"
		TABLE11A="${PATHSETI}/PF/set15/table_0_${BP11A}_0_${BT11A}.txt"
		TABLE12A="${PATHSETI}/PF/set16/table_0_${BP12A}_0_${BT12A}.txt"
		TABLE13A="${PATHSETI}/PF/set17/table_0_${BP13A}_0_${BT13A}.txt"
		
		TABLE01D="${PATHSETI}/PF/set18/table_0_${BP01D}_0_${BT01D}.txt"
		TABLE02D="${PATHSETI}/PF/set19/table_0_${BP02D}_0_${BT02D}.txt"
		TABLE03D="${PATHSETI}/PF/set20/table_0_${BP03D}_0_${BT03D}.txt"
		TABLE04D="${PATHSETI}/PF/set21/table_0_${BP04D}_0_${BT04D}.txt"
		TABLE05D="${PATHSETI}/PF/set22/table_0_${BP05D}_0_${BT05D}.txt"
		TABLE06D="${PATHSETI}/PF/set23/table_0_${BP06D}_0_${BT06D}.txt"
		TABLE07D="${PATHSETI}/PF/set24/table_0_${BP07D}_0_${BT07D}.txt"
		TABLE08D="${PATHSETI}/PF/set25/table_0_${BP08D}_0_${BT08D}.txt"
		TABLE09D="${PATHSETI}/PF/set26/table_0_${BP09D}_0_${BT09D}.txt"
		TABLE10D="${PATHSETI}/PF/set27/table_0_${BP10D}_0_${BT10D}.txt"
		TABLE11D="${PATHSETI}/PF/set28/table_0_${BP11D}_0_${BT11D}.txt"
		TABLE12D="${PATHSETI}/PF/set29/table_0_${BP12D}_0_${BT12D}.txt"
		TABLE13D="${PATHSETI}/PF/set30/table_0_${BP13D}_0_${BT13D}.txt"
		TABLE14D="${PATHSETI}/PF/set31/table_0_${BP14D}_0_${BT14D}.txt"
				
		# Date from which to start the time series 
		STARTDATE=20210331
		STARTFROM="YES"		# If set to YES, build_header_msbas_Tables.sh will operate with tables starting after  STARTDATE
		
		if [ ${STARTFROM} == "YES" ] && [ "${STARTDATE}" != "" ] ; then 
			#Recreate the table from that start date  
			function StartTableFrom()
				{
					TABLE=$1		# table file e.g. ${TABLE01A}
					# Restric pair table to data after March 2021 (i.e. from April)
					RemovePairsFromFlist_WithImagesBefore.sh "${TABLE}" "${STARTDATE}"
					## To avoid new table at each run
					mv "${TABLE}_After${STARTDATE}_WithBaselines_${MMDDYYYY}.txt" "${TABLE}_After${STARTDATE}_WithBaselines.txt"
				}
			# Note: this is done for ALL the 27 modes, even those that are not inverted, because 
			# build_header_msbas_Tables.sh below needs the 27 tables to keep the numbering of the 
			# sets in header.txt. It is cheap anyway since it only filters a list of pairs. 
			for MODE in "${ALLMODELIST[@]}" ; do
				eval TABLE=\"\$TABLE${MODE}\"
				StartTableFrom "${TABLE}"
			done
		fi
				
		LABEL="PF" 	# Label for file naming (used for naming zz_ dirs with results and figs etc)

		#R_FLAG
		# Order
		ORDER=3
		# Lambda
		LAMBDA=0.04
		
		# Mode
		DEFOMODE="DefoInterpolx2Detrend"
		#DEFOMODE=DefoInterpol
	
		
	# some files and PATH for each mode
	###################################
		# Path to SAR_MASSPROCESS
		PATHMASSPROCESS="$PATH_1660/SAR_MASSPROCESS"


		# Path to Pair Dirs and Geocoded files to use (need one for each mode)
	
		MASSPROCDIR01A="${PATHMASSPROCESS}/ALOS2/PF_${MODE01A}/SMNoCrop_SM_${SM01A}_Zoom1_ML8"
		MASSPROCDIR02A="${PATHMASSPROCESS}/ALOS2/PF_${MODE02A}/SMNoCrop_SM_${SM02A}_Zoom1_ML8"
		MASSPROCDIR03A="${PATHMASSPROCESS}/ALOS2/PF_${MODE03A}/SMNoCrop_SM_${SM03A}_Zoom1_ML8"
		MASSPROCDIR04A="${PATHMASSPROCESS}/ALOS2/PF_${MODE04A}/SMNoCrop_SM_${SM04A}_Zoom1_ML8"
		MASSPROCDIR05A="${PATHMASSPROCESS}/ALOS2/PF_${MODE05A}/SMNoCrop_SM_${SM05A}_Zoom1_ML8"
		MASSPROCDIR06A="${PATHMASSPROCESS}/ALOS2/PF_${MODE06A}/SMNoCrop_SM_${SM06A}_Zoom1_ML8"
		MASSPROCDIR07A="${PATHMASSPROCESS}/ALOS2/PF_${MODE07A}/SMNoCrop_SM_${SM07A}_Zoom1_ML8"		# unused because low angle 
		MASSPROCDIR08A="${PATHMASSPROCESS}/ALOS2/PF_${MODE08A}/SMNoCrop_SM_${SM08A}_Zoom1_ML8"
		MASSPROCDIR09A="${PATHMASSPROCESS}/ALOS2/PF_${MODE09A}/SMNoCrop_SM_${SM09A}_Zoom1_ML8"
		MASSPROCDIR10A="${PATHMASSPROCESS}/ALOS2/PF_${MODE10A}/SMNoCrop_SM_${SM10A}_Zoom1_ML8"
		MASSPROCDIR11A="${PATHMASSPROCESS}/ALOS2/PF_${MODE11A}/SMNoCrop_SM_${SM11A}_Zoom1_ML8"
		MASSPROCDIR12A="${PATHMASSPROCESS}/ALOS2/PF_${MODE12A}/SMNoCrop_SM_${SM12A}_Zoom1_ML8"
		MASSPROCDIR13A="${PATHMASSPROCESS}/ALOS2/PF_${MODE13A}/SMNoCrop_SM_${SM13A}_Zoom1_ML8"
		
		MASSPROCDIR01D="${PATHMASSPROCESS}/ALOS2/PF_${MODE01D}/SMNoCrop_SM_${SM01D}_Zoom1_ML8"		# unused because low angle 
		MASSPROCDIR02D="${PATHMASSPROCESS}/ALOS2/PF_${MODE02D}/SMNoCrop_SM_${SM02D}_Zoom1_ML8"
		MASSPROCDIR03D="${PATHMASSPROCESS}/ALOS2/PF_${MODE03D}/SMNoCrop_SM_${SM03D}_Zoom1_ML8"
		MASSPROCDIR04D="${PATHMASSPROCESS}/ALOS2/PF_${MODE04D}/SMNoCrop_SM_${SM04D}_Zoom1_ML8"
		MASSPROCDIR05D="${PATHMASSPROCESS}/ALOS2/PF_${MODE05D}/SMNoCrop_SM_${SM05D}_Zoom1_ML8"		# empty table
		MASSPROCDIR06D="${PATHMASSPROCESS}/ALOS2/PF_${MODE06D}/SMNoCrop_SM_${SM06D}_Zoom1_ML8"
		MASSPROCDIR07D="${PATHMASSPROCESS}/ALOS2/PF_${MODE07D}/SMNoCrop_SM_${SM07D}_Zoom1_ML8"		# not much data 
		MASSPROCDIR08D="${PATHMASSPROCESS}/ALOS2/PF_${MODE08D}/SMNoCrop_SM_${SM08D}_Zoom1_ML8"
		MASSPROCDIR09D="${PATHMASSPROCESS}/ALOS2/PF_${MODE09D}/SMNoCrop_SM_${SM09D}_Zoom1_ML8"
		MASSPROCDIR10D="${PATHMASSPROCESS}/ALOS2/PF_${MODE10D}/SMNoCrop_SM_${SM10D}_Zoom1_ML8"
		MASSPROCDIR11D="${PATHMASSPROCESS}/ALOS2/PF_${MODE11D}/SMNoCrop_SM_${SM11D}_Zoom1_ML8"
		MASSPROCDIR12D="${PATHMASSPROCESS}/ALOS2/PF_${MODE12D}/SMNoCrop_SM_${SM12D}_Zoom1_ML8"
		MASSPROCDIR13D="${PATHMASSPROCESS}/ALOS2/PF_${MODE13D}/SMNoCrop_SM_${SM13D}_Zoom1_ML8"
		MASSPROCDIR14D="${PATHMASSPROCESS}/ALOS2/PF_${MODE14D}/SMNoCrop_SM_${SM14D}_Zoom1_ML8"		# unused because low angle 


		# Parameters files  - needed only to check if mass processes are running - not used here
		PARAMPROCESS01A="$PATH_1650/Param_files/ALOS2/PF/${MODE01A}/LaunchMTparam_ALOS2_${MODE01A}_Full_Zoom1_ML8_MassProc_NewDEM_Newmask.txt"
		PARAMPROCESS02A="$PATH_1650/Param_files/ALOS2/PF/${MODE02A}/LaunchMTparam_ALOS2_${MODE02A}_Full_Zoom1_ML8_MassProc_NewDEM_Newmask.txt"
		PARAMPROCESS03A="$PATH_1650/Param_files/ALOS2/PF/${MODE03A}/LaunchMTparam_ALOS2_${MODE03A}_Full_Zoom1_ML8_MassProc_NewDEM_Newmask.txt"
		PARAMPROCESS04A="$PATH_1650/Param_files/ALOS2/PF/${MODE04A}/LaunchMTparam_ALOS2_${MODE04A}_Full_Zoom1_ML8_MassProc_NewDEM_Newmask.txt"
		PARAMPROCESS05A="$PATH_1650/Param_files/ALOS2/PF/${MODE05A}/LaunchMTparam_ALOS2_${MODE05A}_Full_Zoom1_ML8_MassProc_NewDEM_Newmask.txt"
		PARAMPROCESS06A="$PATH_1650/Param_files/ALOS2/PF/${MODE06A}/LaunchMTparam_ALOS2_${MODE06A}_Full_Zoom1_ML8_MassProc_NewDEM_Newmask.txt"
		PARAMPROCESS07A="$PATH_1650/Param_files/ALOS2/PF/${MODE07A}/LaunchMTparam_ALOS2_${MODE07A}_Full_Zoom1_ML8_MassProc_NewDEM_Newmask.txt"		# unused because low angle 
		PARAMPROCESS08A="$PATH_1650/Param_files/ALOS2/PF/${MODE08A}/LaunchMTparam_ALOS2_${MODE08A}_Full_Zoom1_ML8_MassProc_NewDEM_Newmask.txt"
		PARAMPROCESS09A="$PATH_1650/Param_files/ALOS2/PF/${MODE09A}/LaunchMTparam_ALOS2_${MODE09A}_Full_Zoom1_ML8_MassProc_NewDEM_Newmask.txt"
		PARAMPROCESS10A="$PATH_1650/Param_files/ALOS2/PF/${MODE10A}/LaunchMTparam_ALOS2_${MODE10A}_Full_Zoom1_ML8_MassProc_NewDEM_Newmask.txt"
		PARAMPROCESS11A="$PATH_1650/Param_files/ALOS2/PF/${MODE11A}/LaunchMTparam_ALOS2_${MODE11A}_Full_Zoom1_ML8_MassProc_NewDEM_Newmask.txt"
		PARAMPROCESS12A="$PATH_1650/Param_files/ALOS2/PF/${MODE12A}/LaunchMTparam_ALOS2_${MODE12A}_Full_Zoom1_ML8_MassProc_NewDEM_Newmask.txt"
		PARAMPROCESS13A="$PATH_1650/Param_files/ALOS2/PF/${MODE13A}/LaunchMTparam_ALOS2_${MODE13A}_Full_Zoom1_ML8_MassProc_NewDEM_Newmask.txt"
		
		PARAMPROCESS01D="$PATH_1650/Param_files/ALOS2/PF/${MODE01D}/LaunchMTparam_ALOS2_${MODE01D}_Full_Zoom1_ML8_MassProc_NewDEM_Newmask.txt"		# unused because low angle 
		PARAMPROCESS02D="$PATH_1650/Param_files/ALOS2/PF/${MODE02D}/LaunchMTparam_ALOS2_${MODE02D}_Full_Zoom1_ML8_MassProc_NewDEM_Newmask.txt"
		PARAMPROCESS03D="$PATH_1650/Param_files/ALOS2/PF/${MODE03D}/LaunchMTparam_ALOS2_${MODE03D}_Full_Zoom1_ML8_MassProc_NewDEM_Newmask.txt"
		PARAMPROCESS04D="$PATH_1650/Param_files/ALOS2/PF/${MODE04D}/LaunchMTparam_ALOS2_${MODE04D}_Full_Zoom1_ML8_MassProc_NewDEM_Newmask.txt"
		PARAMPROCESS05D="$PATH_1650/Param_files/ALOS2/PF/${MODE05D}/LaunchMTparam_ALOS2_${MODE05D}_Full_Zoom1_ML8_MassProc_NewDEM_Newmask.txt"		# empty table
		PARAMPROCESS06D="$PATH_1650/Param_files/ALOS2/PF/${MODE06D}/LaunchMTparam_ALOS2_${MODE06D}_Full_Zoom1_ML8_MassProc_NewDEM_Newmask.txt"
		PARAMPROCESS07D="$PATH_1650/Param_files/ALOS2/PF/${MODE07D}/LaunchMTparam_ALOS2_${MODE07D}_Full_Zoom1_ML8_MassProc_NewDEM_Newmask.txt"		# not much data 
		PARAMPROCESS08D="$PATH_1650/Param_files/ALOS2/PF/${MODE08D}/LaunchMTparam_ALOS2_${MODE08D}_Full_Zoom1_ML8_MassProc_NewDEM_Newmask.txt"
		PARAMPROCESS09D="$PATH_1650/Param_files/ALOS2/PF/${MODE09D}/LaunchMTparam_ALOS2_${MODE09D}_Full_Zoom1_ML8_MassProc_NewDEM_Newmask.txt"
		PARAMPROCESS10D="$PATH_1650/Param_files/ALOS2/PF/${MODE10D}/LaunchMTparam_ALOS2_${MODE10D}_Full_Zoom1_ML8_MassProc_NewDEM_Newmask.txt"
		PARAMPROCESS11D="$PATH_1650/Param_files/ALOS2/PF/${MODE11D}/LaunchMTparam_ALOS2_${MODE11D}_Full_Zoom1_ML8_MassProc_NewDEM_Newmask.txt"
		PARAMPROCESS12D="$PATH_1650/Param_files/ALOS2/PF/${MODE12D}/LaunchMTparam_ALOS2_${MODE12D}_Full_Zoom1_ML8_MassProc_NewDEM_Newmask.txt"
		PARAMPROCESS13D="$PATH_1650/Param_files/ALOS2/PF/${MODE13D}/LaunchMTparam_ALOS2_${MODE13D}_Full_Zoom1_ML8_MassProc_NewDEM_Newmask.txt"
		PARAMPROCESS14D="$PATH_1650/Param_files/ALOS2/PF/${MODE14D}/LaunchMTparam_ALOS2_${MODE14D}_Full_Zoom1_ML8_MassProc_NewDEM_Newmask.txt"		# unused because low angle 	
		
	# Events tables
	###############
		EVENTS="${PATH_1650}/EVENTS_TABLES/${LABEL}"

	# Path to dir where MSBAS will be computed
	###########################################
		MSBASDIR="${PATH_3602}/MSBAS/_${LABEL}_ALOS2_ManuelRaw"
		
	# Coherence restriction
	########################		
		IFCOH="NO"		# YES or NO

		if [ ${IFCOH} == "YES" ] 
			then 

				# Path to kml zone used to check coherence
				KMLCOH="${PATH_1650}/kml/YOUR_PATH.kml"	

				# Coherence restriction threshold (to be compared to mean coh computed on KMLCOH)
				COHRESTRICT=0.235

				# Exclude pairs from modes: If pairs are incidentally above Coh Threshold, 
				# they can be excluded if they are stored as DATE_DATE in a list named 
				# ${MSBASDIR}/${DEFOMODE}i/_EXCLUDE_PAIRS_ALTHOUGH_CRITERIA_OK.txt
				# and parameter below set to YES 
				EXCLUDE01A="NO"	# YES or NO
				EXCLUDE02A="NO"	# YES or NO
				EXCLUDE03A="NO"	# YES or NO
				EXCLUDE04A="NO"	# YES or NO
				EXCLUDE05A="NO"	# YES or NO
				EXCLUDE06A="NO"	# YES or NO
				EXCLUDE07A="NO"	# YES or NO		 unused because low angle 
				EXCLUDE08A="NO"	# YES or NO
				EXCLUDE09A="NO"	# YES or NO
				EXCLUDE10A="NO"	# YES or NO
				EXCLUDE11A="NO"	# YES or NO
				EXCLUDE12A="NO"	# YES or NO
				EXCLUDE13A="NO"	# YES or NO
				
				EXCLUDE01D="NO"	# YES or NO		 unused because low angle 
				EXCLUDE02D="NO"	# YES or NO
				EXCLUDE03D="NO"	# YES or NO
				EXCLUDE04D="NO"	# YES or NO
				EXCLUDE05D="NO"	# YES or NO		 empty table
				EXCLUDE06D="NO"	# YES or NO
				EXCLUDE07D="NO"	# YES or NO		 not much data 
				EXCLUDE08D="NO"	# YES or NO
				EXCLUDE09D="NO"	# YES or NO
				EXCLUDE10D="NO"	# YES or NO
				EXCLUDE11D="NO"	# YES or NO
				EXCLUDE12D="NO"	# YES or NO
				EXCLUDE13D="NO"	# YES or NO
				EXCLUDE14D="NO"	# YES or NO		 unused because low angle 

				if [ ! -s "${KMLCOH}" ] ; then echo "Missing kml for coherence estimation. Please Check" ; exit ; fi
			
			else 
				EXCLUDE01A="NO"	# YES or NO
				EXCLUDE02A="NO"	# YES or NO
				EXCLUDE03A="NO"	# YES or NO
				EXCLUDE04A="NO"	# YES or NO
				EXCLUDE05A="NO"	# YES or NO
				EXCLUDE06A="NO"	# YES or NO
				EXCLUDE07A="NO"	# YES or NO		 unused because low angle 
				EXCLUDE08A="NO"	# YES or NO
				EXCLUDE09A="NO"	# YES or NO
				EXCLUDE10A="NO"	# YES or NO
				EXCLUDE11A="NO"	# YES or NO
				EXCLUDE12A="NO"	# YES or NO
				EXCLUDE13A="NO"	# YES or NO
				
				EXCLUDE01D="NO"	# YES or NO		 unused because low angle 
				EXCLUDE02D="NO"	# YES or NO
				EXCLUDE03D="NO"	# YES or NO
				EXCLUDE04D="NO"	# YES or NO
				EXCLUDE05D="NO"	# YES or NO		 empty table
				EXCLUDE06D="NO"	# YES or NO
				EXCLUDE07D="NO"	# YES or NO		 not much data 
				EXCLUDE08D="NO"	# YES or NO
				EXCLUDE09D="NO"	# YES or NO
				EXCLUDE10D="NO"	# YES or NO
				EXCLUDE11D="YES"	# YES or NO
				EXCLUDE12D="NO"	# YES or NO
				EXCLUDE13D="YES"	# YES or NO
				EXCLUDE14D="NO"	# YES or NO		 unused because low angle 
		fi

	# Path to list of points for plotting time series
	#################################################
		# List of SINGLE points for plotting time series with error bars  
		TIMESERIESPTSDESCR="${PATH_1650}/Data_Points/Points_TS_${LABEL}.txt"

		# List of PAIRS of points for plotting double difference (i.e. without error bar) in EW and UD, ASC and Desc... 
		# 	Note: if pixels are coherent in all modes, these can be the same list
		DOUBLEDIFFPAIRSEWUD="${PATH_1650}/Data_Points/List_DoubleDiff_EW_UD_${LABEL}.txt"
		DOUBLEDIFFPAIRSASC="${PATH_1650}/Data_Points/List_DoubleDiff_EW_UD_${LABEL}.txt"
		DOUBLEDIFFPAIRSDESC="${PATH_1650}/Data_Points/List_DoubleDiff_EW_UD_${LABEL}.txt"
		
		
	# Name of previous cron jobs for the automatic processing of that target (used to check that no other process is runing)
	#########################################################################
	CRONJOB2="PF_ALOS2_Step2_MassProc.sh"
	
	# All components
	ALLCOMP="UD_EW_NS"
	ALLCOMP2D="UD_EW"

# ^^^^^^^^^^ Hard coded lines ^^^^^^^^^^^^

# Prepare directories
#####################
	mkdir -p "${MSBASDIR}"

	mkdir -p "${MSBASDIR}/zz_${ALLCOMP}_TS_Auto_${ORDER}_${LAMBDA}_${LABEL}"
	mkdir -p "${MSBASDIR}/zz_${ALLCOMP}_TS_Auto_${ORDER}_${LAMBDA}_${LABEL}/_Time_series"
	mkdir -p "${MSBASDIR}/zz_${ALLCOMP}_TS_Auto_${ORDER}_${LAMBDA}_${LABEL}/__Combi/"

	mkdir -p "${MSBASDIR}/zz_${ALLCOMP2D}_TS_Auto_${ORDER}_${LAMBDA}_${LABEL}_2D"
	mkdir -p "${MSBASDIR}/zz_${ALLCOMP2D}_TS_Auto_${ORDER}_${LAMBDA}_${LABEL}_2D/_Time_series"
	mkdir -p "${MSBASDIR}/zz_${ALLCOMP2D}_TS_Auto_${ORDER}_${LAMBDA}_${LABEL}_2D/__Combi/"


	# Only the modes to process need their zz_LOS_TS_ dirs 
	for MODE in "${MODELIST[@]}" ; do
		eval MODENAME=\"\$MODE${MODE}\"
		mkdir -p "${MSBASDIR}/zz_LOS_TS_${MODENAME}_Auto_${ORDER}_${LAMBDA}_${LABEL}"
		mkdir -p "${MSBASDIR}/zz_LOS_TS_${MODENAME}_Auto_${ORDER}_${LAMBDA}_${LABEL}/__Combi"
		mkdir -p "${MSBASDIR}/zz_LOS_TS_${MODENAME}_Auto_${ORDER}_${LAMBDA}_${LABEL}/_Time_series"
	done

#	mkdir -p ${MSBASDIR}/zz_LOS_TS_AllAsc_Auto_${ORDER}_${LAMBDA}_${LABEL}
#	mkdir -p ${MSBASDIR}/zz_LOS_TS_AllAsc_Auto_${ORDER}_${LAMBDA}_${LABEL}/__Combi/


#	mkdir -p ${MSBASDIR}/zz_LOS_TS_AllDesc_Auto_${ORDER}_${LAMBDA}_${LABEL}
#	mkdir -p ${MSBASDIR}/zz_LOS_TS_AllDesc_Auto_${ORDER}_${LAMBDA}_${LABEL}/__Combi/

	# in Coh threshold restriction
	if [ "${IFCOH}" == "YES" ] ; then 
		mkdir -p "${MSBASDIR}/zz_${ALLCOMP}_TS_Auto_${ORDER}_${LAMBDA}_${LABEL}_NoCohThresh/"
		mkdir -p "${MSBASDIR}/zz_${ALLCOMP}_TS_Auto_${ORDER}_${LAMBDA}_${LABEL}_NoCohThresh/__Combi/"
		mkdir -p "${MSBASDIR}/zz_${ALLCOMP}_TS_Auto_${ORDER}_${LAMBDA}_${LABEL}_NoCohThresh/_Time_series"
	fi
	
	cd "${MSBASDIR}"

# prepare points lists
######################
	TIMESERIESPTNAME=$(basename "${TIMESERIESPTSDESCR}")
	cp -f "${TIMESERIESPTSDESCR}"  "${MSBASDIR}"/"${TIMESERIESPTNAME}"
	TIMESERIESPTSDESCR="${MSBASDIR}"/"${TIMESERIESPTNAME}"
	#cp -f ${TIMESERIESPTSDESCR} ${MSBASDIR}/${TIMESERIESPTNAME}.tmp  #.tmp is now as the original; the original will be cut from first line (title)
	# Remove header and naming in 1st col from Pts list
	${PATHGNU}/gsed '1d' "${TIMESERIESPTSDESCR}" > "${MSBASDIR}/Cln_${TIMESERIESPTNAME}"
	${PATHGNU}/gsed  -i -r 's/(\s+)?\S+//1' "${MSBASDIR}/Cln_${TIMESERIESPTNAME}"
	# remove 3rd col
	#${PATHGNU}/gsed  -i -r 's/(\s+)?\S+//3' /Users/doris/PROCESS/SCRIPTS_MT/_cron_scripts/Cln_${LABEL}.txt
	TIMESERIESPTS="${MSBASDIR}/Cln_${TIMESERIESPTNAME}"
	
# functions
###########
	function PlotAll()
		{
		unset X1 Y1 X2 Y2 DESCRIPTION
		local X1=$1
		local Y1=$2
		local X2=$3
		local Y2=$4
		local DESCRIPTION=$5
	
		if [ "${EVENTS}" == "" ]
			then
				${PATH_SCRIPTS}/SCRIPTS_MT/PlotTS_all_comp.sh "_Auto_${ORDER}_${LAMBDA}_${LABEL}" ${X1} ${Y1} ${X2} ${Y2} -f -r -t -g  # remove -f if does not want the linear fit
			else
				${PATH_SCRIPTS}/SCRIPTS_MT/PlotTS_all_comp.sh "_Auto_${ORDER}_${LAMBDA}_${LABEL}" ${X1} ${Y1} ${X2} ${Y2} -f -r -t -g -events="${EVENTS}"  # remove -f if does not want the linear fit			
		fi
		OLL="${ORDER}_${LAMBDA}_${LABEL}"
		COORDLABELNAME1="${X1}_${Y1}_Auto_${ORDER}_${LAMBDA}_${LABEL}"
		COORDLABELNAME2="${X2}_${Y2}_Auto_${ORDER}_${LAMBDA}_${LABEL}"
        COORDLABELNAME12="${X1}_${Y1}_${X2}_${Y2}_Auto_${ORDER}_${LAMBDA}_${LABEL}"	
		
		mv "${MSBASDIR}"/"timeLines_${COORDLABELNAME1}.eps" "${MSBASDIR}"/"zz_${ALLCOMP}_TS_Auto_${OLL}/${DESCRIPTION}_timeLines_${COORDLABELNAME1}.eps" 2>/dev/null
		mv "${MSBASDIR}"/"timeLines_${COORDLABELNAME2}.eps" "${MSBASDIR}"/"zz_${ALLCOMP}_TS_Auto_${OLL}/${DESCRIPTION}_timeLines_${COORDLABELNAME2}.eps" 2>/dev/null

		mv "${MSBASDIR}/timeLines_${COORDLABELNAME12}.eps" "${MSBASDIR}/zz_${ALLCOMP}_TS_Auto_${OLL}/${DESCRIPTION}_timeLines_${COORDLABELNAME12}.eps" 2>/dev/null
	
#		# add map tag in fig
#		convert -density 300 -rotate 90 -trim ${MSBASDIR}/zz_${ALLCOMP}_TS_Auto_${ORDER}_${LAMBDA}_${LABEL}/${DESCRIPTION}_timeLines_${X1}_${Y1}_${X2}_${Y2}_Auto_${ORDER}_${LAMBDA}_${LABEL}.eps ${MSBASDIR}/zz_${ALLCOMP}_TS_Auto_${ORDER}_${LAMBDA}_${LABEL}/${DESCRIPTION}_timeLines_${X1}_${Y1}_${X2}_${Y2}_Auto_${ORDER}_${LAMBDA}_${LABEL}.jpg
#		convert ${MSBASDIR}/zz_${ALLCOMP}_TS_Auto_${ORDER}_${LAMBDA}_${LABEL}/${DESCRIPTION}_timeLines_${X1}_${Y1}_${X2}_${Y2}_Auto_${ORDER}_${LAMBDA}_${LABEL}.jpg ${PATHLOCA}/Loca_${X1}_${Y1}_${X2}_${Y2}.jpg -gravity northwest -geometry +250+150 -composite ${MSBASDIR}/zz_${ALLCOMP}_TS_Auto_${ORDER}_${LAMBDA}_${LABEL}/${DESCRIPTION}_timeLines_${X1}_${Y1}_${X2}_${Y2}_Auto_${ORDER}_${LAMBDA}_${LABEL}_Combi.jpg
 
        rm -f "${MSBASDIR}/zz_${ALLCOMP}_TS_Auto_${OLL}/${DESCRIPTION}_timeLines_${COORDLABELNAME12}_Combi.jpg"
		mv "${MSBASDIR}/timeLines_${COORDLABELNAME12}_Combi.jpg" "${MSBASDIR}/zz_${ALLCOMP}_TS_Auto_${OLL}/${DESCRIPTION}_timeLines_${COORDLABELNAME12}_Combi.jpg" 2>/dev/null
		
		mv "${MSBASDIR}/timeLine_UD_${COORDLABELNAME12}.txt" "${MSBASDIR}/zz_${ALLCOMP}_TS_Auto_${OLL}/${DESCRIPTION}_timeLines_UD_${COORDLABELNAME12}.txt" 2>/dev/null
		mv "${MSBASDIR}/timeLine_EW_${COORDLABELNAME12}.txt" "${MSBASDIR}/zz_${ALLCOMP}_TS_Auto_${OLL}/${DESCRIPTION}_timeLines_EW_${COORDLABELNAME12}.txt" 2>/dev/null

		if [ "${ALLCOMP}" == "UD_EW_NS" ] ; then 
			mv "${MSBASDIR}/timeLine_NS_${COORDLABELNAME12}.txt" "${MSBASDIR}/zz_${ALLCOMP}_TS_Auto_${OLL}/${DESCRIPTION}_timeLines_NS_${COORDLABELNAME12}.txt"
		fi
	
		}

	function PlotAllNoCoh()
		{
		unset X1 Y1 X2 Y2 DESCRIPTION
		local X1=$1
		local Y1=$2
		local X2=$3
		local Y2=$4
		local DESCRIPTION=$5

		if [ "${EVENTS}" == "" ]
			then
				${PATH_SCRIPTS}/SCRIPTS_MT/PlotTS_all_comp.sh "_Auto_${ORDER}_${LAMBDA}_${LABEL}_NoCohThresh" ${X1} ${Y1} ${X2} ${Y2} -f -r -t -g   # remove -f if does not want the linear fit etc..
			else
				${PATH_SCRIPTS}/SCRIPTS_MT/PlotTS_all_comp.sh "_Auto_${ORDER}_${LAMBDA}_${LABEL}_NoCohThresh" ${X1} ${Y1} ${X2} ${Y2} -f -r -t -g -events="${EVENTS}"  # remove -f if does not want the linear fit etc..		
		fi
	
#		rm plotTS*.gnu timeLines_*.png 
		OLL="${ORDER}_${LAMBDA}_${LABEL}"
		COORDLABELNAME1="${X1}_${Y1}_Auto_${ORDER}_${LAMBDA}_${LABEL}"
		COORDLABELNAME2="${X2}_${Y2}_Auto_${ORDER}_${LAMBDA}_${LABEL}"
        COORDLABELNAME12="${X1}_${Y1}_${X2}_${Y2}_Auto_${ORDER}_${LAMBDA}_${LABEL}"		
	
		if [ -f "${MSBASDIR}/timeLines_${COORDLABELNAME1}_NoCohThresh.eps" ] && [ -s "${MSBASDIR}/timeLines_${COORDLABELNAME1}_NoCohThresh.eps" ] ; then 
			mv "${MSBASDIR}/timeLines_${COORDLABELNAME1}_NoCohThresh.eps" "${MSBASDIR}/zz_${ALLCOMP}_TS_Auto_${OLL}_NoCohThresh/${DESCRIPTION}_timeLines_${COORDLABELNAME1}_NoCohThresh.eps"
		fi
		if [ -f "${MSBASDIR}/timeLines_${COORDLABELNAME2}_NoCohThresh.eps" ] && [ -s "${MSBASDIR}/timeLines_${COORDLABELNAME2}_NoCohThresh.eps" ] ; then
			mv "${MSBASDIR}/timeLines_${COORDLABELNAME2}_NoCohThresh.eps" "${MSBASDIR}/zz_${ALLCOMP}_TS_Auto_${OLL}_NoCohThresh/${DESCRIPTION}_timeLines_${COORDLABELNAME2}_NoCohThresh.eps"
		fi 
 
		if [ -f "${MSBASDIR}/timeLines_${COORDLABELNAME12}_NoCohThresh.eps" ] && [ -s "${MSBASDIR}/timeLines_${COORDLABELNAME12}_NoCohThresh.eps" ] ; then
			mv "${MSBASDIR}/timeLines_${COORDLABELNAME12}_NoCohThresh.eps" "${MSBASDIR}/zz_${ALLCOMP}_TS_Auto_${OLL}_NoCohThresh/${DESCRIPTION}_timeLines_${COORDLABELNAME12}_NoCohThresh.eps"

#			# add map tag in fig
#			convert -density 300 -rotate 90 -trim ${MSBASDIR}/zz_${ALLCOMP}_TS_Auto_${ORDER}_${LAMBDA}_${LABEL}_NoCohThresh/${DESCRIPTION}_timeLines_${X1}_${Y1}_${X2}_${Y2}_Auto_${ORDER}_${LAMBDA}_${LABEL}_NoCohThresh.eps ${MSBASDIR}/zz_${ALLCOMP}_TS_Auto_${ORDER}_${LAMBDA}_${LABEL}_NoCohThresh/${DESCRIPTION}_timeLines_${X1}_${Y1}_${X2}_${Y2}_Auto_${ORDER}_${LAMBDA}_${LABEL}_NoCohThresh.jpg
#			# get location from dir with coh threshold (where it was added manually)
#			convert ${MSBASDIR}/zz_${ALLCOMP}_TS_Auto_${ORDER}_${LAMBDA}_${LABEL}_NoCohThresh/${DESCRIPTION}_timeLines_${X1}_${Y1}_${X2}_${Y2}_Auto_${ORDER}_${LAMBDA}_${LABEL}_NoCohThresh.jpg ${PATHLOCA}/Loca_${X1}_${Y1}_${X2}_${Y2}.jpg -gravity northwest -geometry +250+150 -composite ${MSBASDIR}/zz_${ALLCOMP}_TS_Auto_${ORDER}_${LAMBDA}_${LABEL}_NoCohThresh/${DESCRIPTION}_timeLines_${X1}_${Y1}_${X2}_${Y2}_Auto_${ORDER}_${LAMBDA}_${LABEL}_Combi_NoCohThresh.jpg

            rm -f "${MSBASDIR}/zz_${ALLCOMP}_TS_Auto_${OLL}_NoCohThresh/${DESCRIPTION}_timeLines_${COORDLABELNAME12}_NoCohThresh_Combi.jpg"
			mv "${MSBASDIR}/timeLines_${COORDLABELNAME12}_NoCohThresh_Combi.jpg" "${MSBASDIR}/zz_${ALLCOMP}_TS_Auto_${OLL}_NoCohThresh/${DESCRIPTION}_timeLines_${COORDLABELNAME12}_NoCohThresh_Combi.jpg"

			mv "${MSBASDIR}/timeLine_UD_${COORDLABELNAME12}_NoCohThresh.txt" "${MSBASDIR}/zz_${ALLCOMP}_TS_Auto_${OLL}_NoCohThresh/${DESCRIPTION}_timeLines_UD_${COORDLABELNAME12}_NoCohThresh.txt"
			mv "${MSBASDIR}/timeLine_EW_${COORDLABELNAME12}_NoCohThresh.txt" "${MSBASDIR}/zz_${ALLCOMP}_TS_Auto_${OLL}_NoCohThresh/${DESCRIPTION}_timeLines_EW_${COORDLABELNAME12}_NoCohThresh.txt"

			if [ "${ALLCOMP}" == "UD_EW_NS" ] ; then 
				mv "${MSBASDIR}/timeLine_NS_${COORDLABELNAME12}_NoCohThresh.txt" "${MSBASDIR}/zz_${ALLCOMP}_TS_Auto_${OLL}_NoCohThresh/${DESCRIPTION}_timeLines_NS_${COORDLABELNAME12}_NoCohThresh.txt"
			fi

		fi
		}

	function PlotAllLOS()
		{
		unset X1 Y1 X2 Y2 DESCRIPTION 
		local X1=$1
		local Y1=$2
		local X2=$3
		local Y2=$4
		local DESCRIPTION=$5
	
		cd "${MSBASDIR}/zz_LOS_${MODE}_Auto_${ORDER}_${LAMBDA}_${LABEL}/"
		mkdir -p "${MSBASDIR}/zz_LOS_TS_${MODE}_Auto_${ORDER}_${LAMBDA}_${LABEL}/_Time_series"

		if [ "${EVENTS}" == "" ]
			then
				${PATH_SCRIPTS}/SCRIPTS_MT/PlotTS.sh ${X1} ${Y1} ${X2} ${Y2} -f -r -t -g # remove -f if does not want the linear fit
			else
				${PATH_SCRIPTS}/SCRIPTS_MT/PlotTS.sh ${X1} ${Y1} ${X2} ${Y2} -f -r -t -g -events="${EVENTS}"  # remove -f if does not want the linear fit etc..		
		fi
	
#		rm plotTS*.gnu timeLine*.png 
		OLL="${ORDER}_${LAMBDA}_${LABEL}"
		COORDLABELNAME1="${X1}_${Y1}_Auto_${ORDER}_${LAMBDA}_${LABEL}"
		COORDLABELNAME2="${X2}_${Y2}_Auto_${ORDER}_${LAMBDA}_${LABEL}"
        COORDLABELNAME12="${X1}_${Y1}_${X2}_${Y2}_Auto_${ORDER}_${LAMBDA}_${LABEL}"		

		mv "${MSBASDIR}/zz_LOS_${MODE}_Auto_${OLL}/timeLine${X1}_${Y1}.eps" "${MSBASDIR}/zz_LOS_TS_${MODE}_Auto_${OLL}/${DESCRIPTION}_timeLine_${COORDLABELNAME1}.eps" 2>/dev/null
		mv "${MSBASDIR}/zz_LOS_${MODE}_Auto_${OLL}/timeLine${X2}_${Y2}.eps" "${MSBASDIR}/zz_LOS_TS_${MODE}_Auto_${OLL}/${DESCRIPTION}_timeLine_${COORDLABELNAME2}.eps" 2>/dev/null
		mv "${MSBASDIR}/zz_LOS_${MODE}_Auto_${OLL}/timeLine${X1}_${Y1}_${X2}_${Y2}.eps" "${MSBASDIR}/zz_LOS_TS_${MODE}_Auto_${OLL}/${DESCRIPTION}_timeLine_${COORDLABELNAME12}.eps" 2>/dev/null

		mv "${MSBASDIR}/zz_LOS_${MODE}_Auto_${OLL}/timeLine${X1}_${Y1}.txt" "${MSBASDIR}/zz_LOS_TS_${MODE}_Auto_${OLL}/_Time_series/" 2>/dev/null
		mv "${MSBASDIR}/zz_LOS_${MODE}_Auto_${OLL}/timeLine${X2}_${Y2}.txt" "${MSBASDIR}/zz_LOS_TS_${MODE}_Auto_${OLL}/_Time_series/" 2>/dev/null
		mv "${MSBASDIR}/zz_LOS_${MODE}_Auto_${OLL}/timeLine${X1}_${Y1}_${X2}_${Y2}.txt" "${MSBASDIR}/zz_LOS_TS_${MODE}_Auto_${OLL}/_Time_series/" 2>/dev/null
	
#		# add map tag in fig
#		convert -density 300 -rotate 90 -trim ${MSBASDIR}/zz_LOS_TS_${MODE}_Auto_${ORDER}_${LAMBDA}_${LABEL}/${DESCRIPTION}_timeLine_${X1}_${Y1}_${X2}_${Y2}_Auto_${ORDER}_${LAMBDA}_${LABEL}.eps ${MSBASDIR}/zz_LOS_TS_${MODE}_Auto_${ORDER}_${LAMBDA}_${LABEL}/${DESCRIPTION}_timeLine_${X1}_${Y1}_${X2}_${Y2}_Auto_${ORDER}_${LAMBDA}_${LABEL}.jpg
#		convert ${MSBASDIR}/zz_LOS_TS_${MODE}_Auto_${ORDER}_${LAMBDA}_${LABEL}/${DESCRIPTION}_timeLine_${X1}_${Y1}_${X2}_${Y2}_Auto_${ORDER}_${LAMBDA}_${LABEL}.jpg ${PATHLOCA}/Loca_${X1}_${Y1}_${X2}_${Y2}.jpg -gravity northwest -geometry +250+150 -composite ${MSBASDIR}/zz_LOS_TS_${MODE}_Auto_${ORDER}_${LAMBDA}_${LABEL}/${DESCRIPTION}_timeLine_${X1}_${Y1}_${X2}_${Y2}_Auto_${ORDER}_${LAMBDA}_${LABEL}_Combi_${MODE}.jpg

        rm -f "${MSBASDIR}/zz_LOS_TS_${MODE}_Auto_${OLL}/${DESCRIPTION}_timeLine_${COORDLABELNAME12}_Combi_${MODE}.jpg"
		mv "${MSBASDIR}/zz_LOS_${MODE}_Auto_${OLL}/timeLine${X1}_${Y1}_${X2}_${Y2}_Combi.jpg" "${MSBASDIR}/zz_LOS_TS_${MODE}_Auto_${OLL}/${DESCRIPTION}_timeLine_${COORDLABELNAME12}_Combi_${MODE}.jpg" 2>/dev/null

		#mv ${MSBASDIR}/timeLine_UD_${X1}_${Y1}_${X2}_${Y2}_Auto_${ORDER}_${LAMBDA}_${LABEL}.txt ${MSBASDIR}/zz_${ALLCOMP}_TS_Auto_${ORDER}_${LAMBDA}_${LABEL}/${DESCRIPTION}_timeLines_UD_${X1}_${Y1}_${X2}_${Y2}_Auto_${ORDER}_${LAMBDA}_${LABEL}.txt
		#mv ${MSBASDIR}/timeLine_EW_${X1}_${Y1}_${X2}_${Y2}_Auto_${ORDER}_${LAMBDA}_${LABEL}.txt ${MSBASDIR}/zz_${ALLCOMP}_TS_Auto_${ORDER}_${LAMBDA}_${LABEL}/${DESCRIPTION}_timeLines_EW_${X1}_${Y1}_${X2}_${Y2}_Auto_${ORDER}_${LAMBDA}_${LABEL}.txt
	
#		rm -f ${MSBASDIR}/zz_LOS_TS_${MODE}_Auto_${ORDER}_${LAMBDA}_${LABEL}/${DESCRIPTION}_timeLine_${X1}_${Y1}_${X2}_${Y2}_Auto_${ORDER}_${LAMBDA}_${LABEL}.jpg

		}

	function MSBASmode()
		{
		unset MODE # e.g. 6811_L_A ...
		unset FORMERLASTTIME # e.g. FORMERLAST01ATIME
		unset LASTTIME 	# e.g. LAST01ATIME
		local MODE=$1
		local FORMERLASTTIME=$2
		local LASTTIME=$3
		
		# may be empty at first run or if the mode was not processed yet 
		if [ "${FORMERLASTTIME}" = "" ] ; then FORMERLASTTIME=0 ; fi
		if [ "${LASTTIME}" = "" ] ; then LASTTIME=0 ; fi
		
		echo ""
		echo "// Processing ${MODE}"
		echo "/////////////////////"
		
		if [ "${FORMERLASTTIME}" -eq "${LASTTIME}" ] 
			then 
				echo "No new data for mode  ${MODE}, hence skip (m)sbas for that LoS"
			else
				cd "${MSBASDIR}"
				cp -f "${MSBASDIR}/header_${MODE}.txt"  header.txt 
				NUM_THREADS=${NTHR} ${PATH_SCRIPTS}/SCRIPTS_MT/MSBAS.sh "_${MODE}_Auto_${ORDER}_${LAMBDA}_${LABEL}" "${TIMESERIESPTS}" --msbasv4
		
				cp "${TIMESERIESPTSDESCR}" "${MSBASDIR}/zz_LOS_TS_${MODE}_Auto_${ORDER}_${LAMBDA}_${LABEL}/"
				# remove header line to avoid error message 
				#TIMESERIESPTSDESCRNOHEADER=`tail -n +2 ${TIMESERIESPTSDESCR}`
				while read -r DESCR X Y RX RY
					do	
						echo "Rename time series of ${X}_${Y} as ${X}_${Y}_${RX}_${RY}_${DESCR}"
						mv "${MSBASDIR}/zz_LOS_TS_${MODE}_Auto_${ORDER}_${LAMBDA}_${LABEL}/MSBAS_${X}_${Y}_${RX}_${RY}.txt" "${MSBASDIR}/zz_LOS_TS_${MODE}_Auto_${ORDER}_${LAMBDA}_${LABEL}/_Time_series/MSBAS_${X}_${Y}_${RX}_${RY}_${DESCR}.txt"
						mv "${MSBASDIR}/zz_LOS_TS_${MODE}_Auto_${ORDER}_${LAMBDA}_${LABEL}/MSBAS_${X}_${Y}_${RX}_${RY}.pdf" "${MSBASDIR}/zz_LOS_TS_${MODE}_Auto_${ORDER}_${LAMBDA}_${LABEL}/MSBAS_${X}_${Y}_${RX}_${RY}_${DESCR}.pdf"
						# there is no automatic plotting by msbas when only in LOS 
				done < "${TIMESERIESPTSDESCR}" | tail -n +2  # ignore header
 		
				# Why not some double difference plotting
				while read -r X1 Y1 X2 Y2 DESCR
					do	
						PlotAllLOS ${X1} ${Y1} ${X2} ${Y2} ${DESCR} ${MODE}
				done < "${FILEPAIRS}"						
			
				# move all plots in same dir 
		
				OLL="${ORDER}_${LAMBDA}_${LABEL}"
				
				rm -f "${MSBASDIR}/zz_LOS_TS_${MODE}_Auto_${OLL}"/__Combi/*.jpg
				mv "${MSBASDIR}/zz_LOS_TS_${MODE}_Auto_${OLL}"/*_Combi*.jpg "${MSBASDIR}/zz_LOS_TS_${MODE}_Auto_${OLL}"/__Combi/
		
				# move all time series in dir 
				#mv ${MSBASDIR}/zz_LOS_TS_${MODE}_Auto_${ORDER}_${LAMBDA}_${LABEL}/*.txt ${MSBASDIR}/zz_LOS_TS_${MODE}_Auto_${ORDER}_${LAMBDA}_${LABEL}/_Time_series/
		fi
		}

	# Ensure that a ${DEFOMODE}i.txt (or ${DEFOMODE}i_Full.txt) file has at least 4 columns and 
	# keep track of the possible faulty lines in ${DEFOMODE}i_MissingCol.txt. 
	# Missing or empty files are skipped, which occurs at first run and for the unused modes.
	Keep4Columns()
		{
		FILETOCHECK="$1"
		if [ ! -s "${FILETOCHECK}" ] 
			then 
				echo "// ${FILETOCHECK} is missing or empty; skipped"
				return 
		fi
		mv "${FILETOCHECK}" "${FILETOCHECK%.txt}_all4col.txt"
		${PATHGNU}/gawk 'NF>=4' "${FILETOCHECK%.txt}_all4col.txt" > "${FILETOCHECK}"
		${PATHGNU}/gawk 'NF<4' "${FILETOCHECK%.txt}_all4col.txt" > "${FILETOCHECK%.txt}_MissingCol.txt"
		rm -f "${FILETOCHECK%.txt}_all4col.txt"
		}

	# Run a script on the ${DEFOMODE}i of each mode to process, NRPARALLEL of them at a time. 
	# Usage: RunOnUsedSets NRPARALLEL SCRIPT MODEPREFIX MODESUFFIX [EXTRAARG] 
	#        where the script is called with "${MODEPREFIX}${DEFOMODE}i${MODESUFFIX}" [EXTRAARG]
	# e.g. : RunOnUsedSets 4 Remove_BrokenLinks_and_Clean_txt_file.sh "${MSBASDIR}/" ""
	#        RunOnUsedSets 4 _Check_bad_DefoInterpolx2Detrend.sh "" "_Full" "${PATHMASSPROCESS}"
	RunOnUsedSets()
		{
		NRPARALLEL="$1"
		SCRIPTTORUN="$2"
		MODEPREFIX="$3"
		MODESUFFIX="$4"
		EXTRAARG="$5"
		NRJOBS=0
		for SETNR in ${USEDSETS} ; do
			if [ "${EXTRAARG}" = "" ] 
				then 	"${SCRIPTTORUN}" "${MODEPREFIX}${DEFOMODE}${SETNR}${MODESUFFIX}" &
				else 	"${SCRIPTTORUN}" "${MODEPREFIX}${DEFOMODE}${SETNR}${MODESUFFIX}" "${EXTRAARG}" &
			fi
			NRJOBS=$(( NRJOBS + 1 ))
			if [ ${NRJOBS} -ge ${NRPARALLEL} ] ; then wait ; NRJOBS=0 ; fi
		done
		wait
		}


# Check that there is no other cron (Step 2 or 3) or manual SuperMaster_MassProc.sh running
###########################################################################################
	# Check that no other cron job step 3 (MSBAS) or manual SuperMaster_MassProc.sh is running
	CHECKMB=`ps -Af | ${PATHGNU}/grep ${PRG} | ${PATHGNU}/grep -v "grep " | ${PATHGNU}/grep -v "kate" | ${PATHGNU}/grep -v "/dev/null"  | wc -l`
		#### For Debugging
		# echo "ps -Af | ${PATHGNU}/grep ${PRG} | ${PATHGNU}/grep -v ${PATHGNU}/grep | ${PATHGNU}/grep -v /dev/null | wc -l" > CheckRun.txt
		# echo ${CHECKMB} >> CheckRun.txt
		# ps -Af | ${PATHGNU}/grep ${PRG} | ${PATHGNU}/grep -v "grep " | ${PATHGNU}/grep -v "/dev/null" >> CheckRun.txt

	if [ ${CHECKMB} -gt 3 ] ; then # use ${PATHGNU}/grep -v "grep "  instead of ${PATHGNU}/grep -v "grep ${PRG}" because depending on environment, it may miss the second version
			REASON=" another ${PRG} is running" 
			STOPRUN="YES"
#		else
#			# Check that no other SuperMaster automatic Ascending and Desc mass processing uses the LaunchMTparam_.txt yet
#			CHECKASCSM=`ps -eaf | ${PATHGNU}/grep SuperMaster_MassProc.sh | ${PATHGNU}/grep -v "grep "  | ${PATHGNU}/grep ${LAUNCHPARAMASCSM} | ${PATHGNU}/grep -v "kate" | ${PATHGNU}/grep -v "/dev/null" | wc -l` 
#			CHECKDESCSM=`ps -eaf | ${PATHGNU}/grep SuperMaster_MassProc.sh | ${PATHGNU}/grep -v "grep " | ${PATHGNU}/grep ${LAUNCHPARAMDESCSM} | ${PATHGNU}/grep -v "kate" | ${PATHGNU}/grep -v "/dev/null" | wc -l` 
#			CHECKASCIW=`ps -eaf | ${PATHGNU}/grep SuperMaster_MassProc.sh | ${PATHGNU}/grep -v "grep "  | ${PATHGNU}/grep ${LAUNCHPARAMASCIW} | ${PATHGNU}/grep -v "kate" | ${PATHGNU}/grep -v "/dev/null" | wc -l` 
#			CHECKDESCIW=`ps -eaf | ${PATHGNU}/grep SuperMaster_MassProc.sh | ${PATHGNU}/grep -v "grep " | ${PATHGNU}/grep ${LAUNCHPARAMDESCIW} | ${PATHGNU}/grep -v "kate" | ${PATHGNU}/grep -v "/dev/null" | wc -l` 
#	
#	
#			# For unknown reason it counts 1 even when no process is running
#			if [ ${CHECKASCSM} -ne 0 ] || [ ${CHECKDESCSM} -ne 0 ] || [ ${CHECKASCIW} -ne 0 ] || [ ${CHECKDESCIW} -ne 0 ]; then REASON="  SuperMaster_MassProc.sh in progress (probably manual)" ; STOPRUN="YES" ; else STOPRUN="NO" ; fi  	
	fi 

	# Check that no other cron job step 2 (SuperMaster_MassProc.sh) is running
	CHECKMPIW=`ps -eaf | ${PATHGNU}/grep ${CRONJOB2} | ${PATHGNU}/grep -v "grep " | ${PATHGNU}/grep -v "kate" | ${PATHGNU}/grep -v "/dev/null" | wc -l`
	if [ ${CHECKMPIW} -ne 0 ] ; then REASON=" SuperMaster_MassProc.sh in progress (from ${CRONJOB2})" ; STOPRUN="YES" ; else STOPRUN="NO" ; fi 

	if [ "${STOPRUN}" == "YES" ] 
		then 
			echo "MSBAS attempt aborted on ${TODAY} because ${REASON}" >>  "${MSBASDIR}/_last_MSBAS_process.txt"
			echo "MSBAS attempt aborted on ${TODAY} because ${REASON}"
			#mv -f  ${MSBASDIR}/${TIMESERIESPTSDESCR}.tmp  ${MSBASDIR}/${TIMESERIESPTSDESCR}
			exit
	fi

# Check defo maps in SAR_MASSPROCESS
####################################
# Remove possible duplicate geocoded products in SAR_MASSPROCESS/.../Geocoded/... 
# i.e. remove in each MODE (but Ampl) possible products from same pair of dates but with different Bp, Ha etc.. that would results from 
# reprocessing with updated orbits. If duplicated product detected, it keeps only the most recent product.  

	function RemoveDuplic()
		{
		MASSDIR=$1
		if [ ! -d "${MASSDIR}" ] 
			then 
				echo "// No ${MASSDIR}; skipped"
				return 
		fi
		cd "${MASSDIR}" || return 	# never run the cleaning in the wrong dir 
		Remove_Duplicate_Pairs_File_All_Modes_But_Ampl.sh
		}
		
	NRJOBS=0
	for MODE in "${MODELIST[@]}" ; do
		eval MASSPROCDIR=\"\$MASSPROCDIR${MODE}\"
		RemoveDuplic "${MASSPROCDIR}" &
		NRJOBS=$(( NRJOBS + 1 ))
		if [ ${NRJOBS} -ge 7 ] ; then wait ; NRJOBS=0 ; fi
	done
	wait
	
# Get date (in sec) of last available processed pairs in each MODE
##################################################################
	# LAST${MODE}TIME is set to 0 for the modes that are not processed, in order to keep the 
	# numbering of the 27 modes in _Last_MassProcessed_Pairs_Time.txt 
	for MODE in "${ALLMODELIST[@]}" ; do
		LASTTIME=0
		if ModeUsed "${MODE}" 
			then 
				eval MASSPROCDIR=\"\$MASSPROCDIR${MODE}\"
				# name of the last available processed pair in that MODE
				LAST=$(find "${MASSPROCDIR}/Geocoded/${DEFOMODE}/" -maxdepth 1 -type f -name "*deg" -printf "%T+ %p\n" 2>/dev/null | sort -r | head -1 | ${PATHGNU}/gawk '{print $2}')
				if [ -f "${LAST}" ] 
					then 	LASTTIME=$(stat -c %Y "${LAST}")
					else 	echo "// No processed pair found for mode ${MODE}; check ${MASSPROCDIR}"
				fi
		fi
		eval LAST${MODE}TIME=\"\${LASTTIME}\"
	done


# Check if first run and if  appropriate, get time of last images in time series
################################################################################
	if [ -f "${MSBASDIR}/_Last_MassProcessed_Pairs_Time.txt" ] && [ -s "${MSBASDIR}/_Last_MassProcessed_Pairs_Time.txt" ] 
		then   
			echo "Existing ${MSBASDIR}/_Last_MassProcessed_Pairs_Time.txt, hence not the first run"
			FIRSTRUN=NO
			# _Last_MassProcessed_Pairs_Time.txt holds one line per mode, in the order of 
			# ALLMODELIST, that is always 27 lines. Only the modes to process are checked for 
			# new pairs. 
			NEWPAIRS="NO"
			MODELINE=1
			for MODE in "${ALLMODELIST[@]}" ; do
				FORMERLASTTIME=$(${PATHGNU}/sed -n "${MODELINE}p" "${MSBASDIR}/_Last_MassProcessed_Pairs_Time.txt")
				if [ "${FORMERLASTTIME}" = "" ] ; then FORMERLASTTIME=0 ; fi
				eval FORMERLAST${MODE}TIME=\"\${FORMERLASTTIME}\"
				eval LASTTIME=\"\$LAST${MODE}TIME\"
				if ModeUsed "${MODE}" && [ "${FORMERLASTTIME}" -ne "${LASTTIME}" ] ; then NEWPAIRS="YES" ; fi
				MODELINE=$(( MODELINE + 1 ))
			done
			
			if [ "${NEWPAIRS}" == "NO" ] 	# no more recent file since the last cron processing
				then
					echo "MSBAS finished on ${TODAY} without new pairs to process"  >>  ${MSBASDIR}/_last_MSBAS_process.txt
					echo "MSBAS finished on ${TODAY} without new pairs to process"
					exit
			fi
		else  
			echo "No ${MSBASDIR}/_Last_MassProcessed_Pairs_Time.txt, hence first run"
			FIRSTRUN=YES
	fi

# Remove possible broken links in MSBAS/.../MODEi and clean corresponding files 
################################################################################
# (clean if required MODEi.txt and Checked_For_CohThreshold_To_Be_Ignored_At_Next_Rebuild_msbas_Header.txt if any)
	if [ "${FIRSTRUN}" == "NO" ] ; then 
		echo "Remove Broken Links and Clean txt file in existing ${MSBASDIR}/${DEFOMODE}"
		RunOnUsedSets 4 Remove_BrokenLinks_and_Clean_txt_file.sh "${MSBASDIR}/" ""

		echo "Possible broken links in former existing MODEi dir are cleaned"
		echo ""

		#Need also for the _Full ones (that is without coh threshold)	
		if [ ${IFCOH} == "YES" ] ; then 
			RunOnUsedSets 4 Remove_BrokenLinks_and_Clean_txt_file.sh "${MSBASDIR}/" "_Full"
			echo "Possible broken links in former existing MODEi_Full dir are cleaned"
			echo ""
		fi
	fi

# Check MSBAS/.../MODEi.txt file
################################
cd ${MSBASDIR}

# Remove possible lines with less that 4 columns
	if [ "${FIRSTRUN}" == "NO" ] ; then 
		for SETNR in ${USEDSETS} ; do
			Keep4Columns "${MSBASDIR}/${DEFOMODE}${SETNR}.txt"
		done
	
		echo "All lines in former existing MODEi.txt have 4 columns"
		echo ""

		#Need also for the _Full ones (that is without coh threshold)
		if [ ${IFCOH} == "YES" ] ; then 
			for SETNR in ${USEDSETS} ; do
				Keep4Columns "${MSBASDIR}/${DEFOMODE}${SETNR}_Full/${DEFOMODE}${SETNR}_Full.txt"
			done

			echo "All lines in former existing MODEi_Full.txt have 4 columns"
			echo ""
		fi
	
# Remove lines in MSBAS/MODEi.txt file associated to possible broken links or duplicated lines with same name though wrong BP (e.g. after S1 orb update) 
		cd ${MSBASDIR}
		echo "Remove lines in existing MSBAS/MODEi.txt file associated to possible broken links or duplicated lines"
		RunOnUsedSets 4 _Check_bad_DefoInterpolx2Detrend.sh "" "" "${PATHMASSPROCESS}"

		echo "All lines in former existing MODEi.txt are ok"
		echo ""

		#Need also for the _Full ones (that is without coh threshold)
		if [ ${IFCOH} == "YES" ] ; then 
			RunOnUsedSets 4 _Check_bad_DefoInterpolx2Detrend.sh "" "_Full" "${PATHMASSPROCESS}"
			echo "All lines in former existing MODEi_Full.txt are ok"
			echo ""	
		fi
	
	fi

# Prepare MSBAS
###############

	# All 27 modes must be prepared to keep the same numbering
	if [ ${STARTFROM} == "YES" ] && [ ${STARTDATE} != "" ] 
		then 
			# From STARTDATE only 	
			${PATH_SCRIPTS}/SCRIPTS_MT/build_header_msbas_Tables.sh "${DEFOMODE}" 27 \
				"${TABLE01A}_After${STARTDATE}_WithBaselines.txt" "${TABLE02A}_After${STARTDATE}_WithBaselines.txt" "${TABLE03A}_After${STARTDATE}_WithBaselines.txt" "${TABLE04A}_After${STARTDATE}_WithBaselines.txt" "${TABLE05A}_After${STARTDATE}_WithBaselines.txt" "${TABLE06A}_After${STARTDATE}_WithBaselines.txt" "${TABLE07A}_After${STARTDATE}_WithBaselines.txt"  \
				"${TABLE08A}_After${STARTDATE}_WithBaselines.txt" "${TABLE09A}_After${STARTDATE}_WithBaselines.txt" "${TABLE10A}_After${STARTDATE}_WithBaselines.txt" "${TABLE11A}_After${STARTDATE}_WithBaselines.txt" "${TABLE12A}_After${STARTDATE}_WithBaselines.txt" "${TABLE13A}_After${STARTDATE}_WithBaselines.txt"  \
				"${TABLE01D}_After${STARTDATE}_WithBaselines.txt" "${TABLE02D}_After${STARTDATE}_WithBaselines.txt" "${TABLE03D}_After${STARTDATE}_WithBaselines.txt" "${TABLE04D}_After${STARTDATE}_WithBaselines.txt" "${TABLE05D}_After${STARTDATE}_WithBaselines.txt" "${TABLE06D}_After${STARTDATE}_WithBaselines.txt" "${TABLE07D}_After${STARTDATE}_WithBaselines.txt"  \
				"${TABLE08D}_After${STARTDATE}_WithBaselines.txt" "${TABLE09D}_After${STARTDATE}_WithBaselines.txt" "${TABLE10D}_After${STARTDATE}_WithBaselines.txt" "${TABLE11D}_After${STARTDATE}_WithBaselines.txt" "${TABLE12D}_After${STARTDATE}_WithBaselines.txt" "${TABLE13D}_After${STARTDATE}_WithBaselines.txt" "${TABLE14D}_After${STARTDATE}_WithBaselines.txt"  \
				"${MASSPROCDIR01A}" "${MASSPROCDIR02A}" "${MASSPROCDIR03A}" "${MASSPROCDIR04A}" "${MASSPROCDIR05A}" "${MASSPROCDIR06A}" "${MASSPROCDIR07A}" "${MASSPROCDIR08A}" "${MASSPROCDIR09A}" "${MASSPROCDIR10A}" "${MASSPROCDIR11A}" "${MASSPROCDIR12A}" "${MASSPROCDIR13A}" \
				"${MASSPROCDIR01D}" "${MASSPROCDIR02D}" "${MASSPROCDIR03D}" "${MASSPROCDIR04D}" "${MASSPROCDIR05D}" "${MASSPROCDIR06D}" "${MASSPROCDIR07D}" "${MASSPROCDIR08D}" "${MASSPROCDIR09D}" "${MASSPROCDIR10D}" "${MASSPROCDIR11D}" "${MASSPROCDIR12D}" "${MASSPROCDIR13D}" "${MASSPROCDIR14D}"
		else 
			# Full tables
			${PATH_SCRIPTS}/SCRIPTS_MT/build_header_msbas_Tables.sh "${DEFOMODE}" 27 \
				"${TABLE01A}" "${TABLE02A}" "${TABLE03A}" "${TABLE04A}" "${TABLE05A}" "${TABLE06A}" "${TABLE07A}" "${TABLE08A}" "${TABLE09A}" "${TABLE10A}" "${TABLE11A}" "${TABLE12A}" "${TABLE13A}" \
				"${TABLE01D}" "${TABLE02D}" "${TABLE03D}" "${TABLE04D}" "${TABLE05D}" "${TABLE06D}" "${TABLE07D}" "${TABLE08D}" "${TABLE09D}" "${TABLE10D}" "${TABLE11D}" "${TABLE12D}" "${TABLE13D}" "${TABLE14D}" \
				"${MASSPROCDIR01A}" "${MASSPROCDIR02A}" "${MASSPROCDIR03A}" "${MASSPROCDIR04A}" "${MASSPROCDIR05A}" "${MASSPROCDIR06A}" "${MASSPROCDIR07A}" "${MASSPROCDIR08A}" "${MASSPROCDIR09A}" "${MASSPROCDIR10A}" "${MASSPROCDIR11A}" "${MASSPROCDIR12A}" "${MASSPROCDIR13A}" \
				"${MASSPROCDIR01D}" "${MASSPROCDIR02D}" "${MASSPROCDIR03D}" "${MASSPROCDIR04D}" "${MASSPROCDIR05D}" "${MASSPROCDIR06D}" "${MASSPROCDIR07D}" "${MASSPROCDIR08D}" "${MASSPROCDIR09D}" "${MASSPROCDIR10D}" "${MASSPROCDIR11D}" "${MASSPROCDIR12D}" "${MASSPROCDIR13D}" "${MASSPROCDIR14D}"
	fi

	# update here the R_FLAG if needed
	#${PATHGNU}/gsed -i "s/R_FLAG = 2, 0.02/R_FLAG = ${ORDER}, ${LAMBDA}/"  ${MSBASDIR}/header.txt
	"${PATHGNU}"/gsed -i "s/^R_FLAG.*/R_FLAG = ${ORDER}, ${LAMBDA}/"  "${MSBASDIR}/header.txt"

	# If interferos are detreneded, i.e. averaged to zero, there is no need to calibrate again 
	#"${PATHGNU}"/gsed -i 's/^C_FLAG.*/C_FLAG = 0/' "${MSBASDIR}/header.txt"
	"${PATHGNU}"/gsed -i 's/^C_FLAG.*/C_FLAG = 10/' "${MSBASDIR}/header.txt"
	# If not, hence chose calibration pixel(s)
	#${PATHGNU}/gsed -i 's/^C_FLAG.*/C_FLAG = 1, 45, 197, 5, 5/' ${MSBASDIR}/header.txt

	# Crop the region to invert
	${PATHGNU}/gsed -i 's/WINDOW_SIZE = 0, 2267, 0, 1984/WINDOW_SIZE = 1600, 2150, 1100, 1750/' ${MSBASDIR}/header.txt


	# Check again that files are OK
		# ensure that format is ok, that is with 4 columns 
		for SETNR in ${USEDSETS} ; do
			Keep4Columns "${MSBASDIR}/${DEFOMODE}${SETNR}.txt"
		done
		
		# Need again to check for duplicated lines with different Bp in Col 2 resulting from orbit update 
		if [ "${IFCOH}" == "YES" ] ; then 
			echo "Remove lines in newly created MSBAS/MODEi.txt file associated to possible broken links or duplicated lines"
			RunOnUsedSets 4 _Check_bad_DefoInterpolx2Detrend.sh "" "" "${PATHMASSPROCESS}"

			echo "All lines in new MODEi.txt should be ok"
			echo ""	
		fi

# Let's go
##########
	cd ${MSBASDIR}
	cp -f header.txt header_back.txt 

	#   search for line nr of each SET mode definition - needed also later for computing SBAS of each LoS
 	LINENR01A=$(cat ${MSBASDIR}/header.txt | ${PATHGNU}/grep -n "SET =" | head -1 | cut -d: -f1)
 	LINENR02A=$(cat ${MSBASDIR}/header.txt | ${PATHGNU}/grep -n "SET =" | head -2 | tail -1 | cut -d: -f1)
 	LINENR03A=$(cat ${MSBASDIR}/header.txt | ${PATHGNU}/grep -n "SET =" | head -3 | tail -1 | cut -d: -f1)
 	LINENR04A=$(cat ${MSBASDIR}/header.txt | ${PATHGNU}/grep -n "SET =" | head -4 | tail -1 | cut -d: -f1)
 	LINENR05A=$(cat ${MSBASDIR}/header.txt | ${PATHGNU}/grep -n "SET =" | head -5 | tail -1 | cut -d: -f1)
 	LINENR06A=$(cat ${MSBASDIR}/header.txt | ${PATHGNU}/grep -n "SET =" | head -6 | tail -1 | cut -d: -f1)
 	LINENR07A=$(cat ${MSBASDIR}/header.txt | ${PATHGNU}/grep -n "SET =" | head -7 | tail -1 | cut -d: -f1)
 	LINENR08A=$(cat ${MSBASDIR}/header.txt | ${PATHGNU}/grep -n "SET =" | head -8 | tail -1 | cut -d: -f1)
 	LINENR09A=$(cat ${MSBASDIR}/header.txt | ${PATHGNU}/grep -n "SET =" | head -9 | tail -1 | cut -d: -f1)
 	LINENR10A=$(cat ${MSBASDIR}/header.txt | ${PATHGNU}/grep -n "SET =" | head -10 | tail -1 | cut -d: -f1)
 	LINENR11A=$(cat ${MSBASDIR}/header.txt | ${PATHGNU}/grep -n "SET =" | head -11 | tail -1 | cut -d: -f1)
 	LINENR12A=$(cat ${MSBASDIR}/header.txt | ${PATHGNU}/grep -n "SET =" | head -12 | tail -1 | cut -d: -f1)
 	LINENR13A=$(cat ${MSBASDIR}/header.txt | ${PATHGNU}/grep -n "SET =" | head -13 | tail -1 | cut -d: -f1)

 	LINENR01D=$(cat ${MSBASDIR}/header.txt | ${PATHGNU}/grep -n "SET =" | head -14 | tail -1 | cut -d: -f1)
 	LINENR02D=$(cat ${MSBASDIR}/header.txt | ${PATHGNU}/grep -n "SET =" | head -15 | tail -1 | cut -d: -f1)
 	LINENR03D=$(cat ${MSBASDIR}/header.txt | ${PATHGNU}/grep -n "SET =" | head -16 | tail -1 | cut -d: -f1)
 	LINENR04D=$(cat ${MSBASDIR}/header.txt | ${PATHGNU}/grep -n "SET =" | head -17 | tail -1 | cut -d: -f1)
 	LINENR05D=$(cat ${MSBASDIR}/header.txt | ${PATHGNU}/grep -n "SET =" | head -18 | tail -1 | cut -d: -f1)
 	LINENR06D=$(cat ${MSBASDIR}/header.txt | ${PATHGNU}/grep -n "SET =" | head -19 | tail -1 | cut -d: -f1)
 	LINENR07D=$(cat ${MSBASDIR}/header.txt | ${PATHGNU}/grep -n "SET =" | head -20 | tail -1 | cut -d: -f1)
 	LINENR08D=$(cat ${MSBASDIR}/header.txt | ${PATHGNU}/grep -n "SET =" | head -21 | tail -1 | cut -d: -f1)
 	LINENR09D=$(cat ${MSBASDIR}/header.txt | ${PATHGNU}/grep -n "SET =" | head -22 | tail -1 | cut -d: -f1)
 	LINENR10D=$(cat ${MSBASDIR}/header.txt | ${PATHGNU}/grep -n "SET =" | head -23 | tail -1 | cut -d: -f1)
 	LINENR11D=$(cat ${MSBASDIR}/header.txt | ${PATHGNU}/grep -n "SET =" | head -24 | tail -1 | cut -d: -f1)
 	LINENR12D=$(cat ${MSBASDIR}/header.txt | ${PATHGNU}/grep -n "SET =" | head -25 | tail -1 | cut -d: -f1)
 	LINENR13D=$(cat ${MSBASDIR}/header.txt | ${PATHGNU}/grep -n "SET =" | head -26 | tail -1 | cut -d: -f1)
 	LINENR14D=$(cat ${MSBASDIR}/header.txt | ${PATHGNU}/grep -n "SET =" | tail -1 | cut -d: -f1)

	SETLINENRS=("${LINENR01A}" "${LINENR02A}" "${LINENR03A}" "${LINENR04A}" "${LINENR05A}" "${LINENR06A}" "${LINENR07A}" "${LINENR08A}" "${LINENR09A}" "${LINENR10A}" "${LINENR11A}" "${LINENR12A}" "${LINENR13A}" "${LINENR01D}" "${LINENR02D}" "${LINENR03D}" "${LINENR04D}" "${LINENR05D}" "${LINENR06D}" "${LINENR07D}" "${LINENR08D}" "${LINENR09D}" "${LINENR10D}" "${LINENR11D}" "${LINENR12D}" "${LINENR13D}" "${LINENR14D}")
	echo "// List of line numbers for all sets in header.txt: ${SETLINENRS[@]}"	

	cp header.txt header_all_modes.txt # to be kept all time		
	# If not all the modes are wanted, one must comment them here
	if [ "${#ALLMODELIST[@]}" -ne "${#MODELIST[@]}" ]  # i.e. if the two list have not the same length
		then
			cp header.txt header_tmp.txt 
			# list the line numbers in the header file of modes to reject
			SETTOREJECT=()
			for pos in "${missing_positions_in_header[@]}"; do
    			SETTOREJECT+=("${SETLINENRS[pos]}")
			done
			
			# Print the new list
			echo "// List of line numbers in header.txt of sets to reject : ${SETTOREJECT[@]}"
	
			#   Change "SET = " with "#SET = " for only the mode one wants to reject 
			for pos in "${SETTOREJECT[@]}"; do
    			cat ${MSBASDIR}/header_tmp.txt | ${PATHGNU}/gsed "${pos}"' s/SET = /#SET = /' > "${MSBASDIR}/header.txt"
    			cp -f "${MSBASDIR}/header.txt" "${MSBASDIR}/header_tmp.txt"  
			done
			rm -f "${MSBASDIR}/header_tmp.txt"
	
	fi

	# EW-UD without coh threshold restriction 
	#----------------------------------------
# 		case ${FIRSTRUN} in 
# 			"YES") 
# 				# one have only the newly created MODEi dir and MODEi.txt
# 				cp -R ${MSBASDIR}/DefoInterpolx2Detrend1 ${MSBASDIR}/DefoInterpolx2Detrend1_Full
# 				cp -f ${MSBASDIR}/DefoInterpolx2Detrend1.txt ${MSBASDIR}/DefoInterpolx2Detrend1_Full/DefoInterpolx2Detrend1_Full.txt
# 				cp -f ${MSBASDIR}/DefoInterpolx2Detrend1.txt ${MSBASDIR}/DefoInterpolx2Detrend1_Full.txt
# 				
# 				cp -R ${MSBASDIR}/DefoInterpolx2Detrend2 ${MSBASDIR}/DefoInterpolx2Detrend2_Full
# 				cp -f ${MSBASDIR}/DefoInterpolx2Detrend2.txt ${MSBASDIR}/DefoInterpolx2Detrend2_Full/DefoInterpolx2Detrend2_Full.txt
# 				cp -f ${MSBASDIR}/DefoInterpolx2Detrend2.txt ${MSBASDIR}/DefoInterpolx2Detrend2_Full.txt
# 				;;
# 			"NO")
# 				# one must merge the newly created MODEi dir and MODEi.txt with former _Full ones
# 				sort ${MSBASDIR}/DefoInterpolx2Detrend1.txt | uniq > ${MSBASDIR}/DefoInterpolx2Detrend1_tmp.txt
# 				sort ${MSBASDIR}/DefoInterpolx2Detrend2.txt | uniq > ${MSBASDIR}/DefoInterpolx2Detrend2_tmp.txt
# 				
# 				sort ${MSBASDIR}/DefoInterpolx2Detrend1_Full/DefoInterpolx2Detrend1_Full.txt | uniq > ${MSBASDIR}/DefoInterpolx2Detrend1_Full_tmp.txt
# 				sort ${MSBASDIR}/DefoInterpolx2Detrend2_Full/DefoInterpolx2Detrend2_Full.txt | uniq > ${MSBASDIR}/DefoInterpolx2Detrend2_Full_tmp.txt
# 				
# 				cat ${MSBASDIR}/DefoInterpolx2Detrend1_tmp.txt ${MSBASDIR}/DefoInterpolx2Detrend1_Full_tmp.txt | sort | uniq >  ${MSBASDIR}/DefoInterpolx2Detrend1_Full.txt
# 				cat ${MSBASDIR}/DefoInterpolx2Detrend2_tmp.txt ${MSBASDIR}/DefoInterpolx2Detrend2_Full_tmp.txt | sort | uniq >  ${MSBASDIR}/DefoInterpolx2Detrend2_Full.txt
# 				
# 				cp -R -n ${MSBASDIR}/DefoInterpolx2Detrend1 ${MSBASDIR}/DefoInterpolx2Detrend1_Full
# 				cp -R -n ${MSBASDIR}/DefoInterpolx2Detrend2 ${MSBASDIR}/DefoInterpolx2Detrend2_Full
# 				cp -f ${MSBASDIR}/DefoInterpolx2Detrend1_Full.txt ${MSBASDIR}/DefoInterpolx2Detrend1_Full/DefoInterpolx2Detrend1_Full.txt
# 				cp -f ${MSBASDIR}/DefoInterpolx2Detrend2_Full.txt ${MSBASDIR}/DefoInterpolx2Detrend2_Full/DefoInterpolx2Detrend2_Full.txt
# 				
# 				rm -f ${MSBASDIR}/DefoInterpolx2Detrend1_tmp.txt ${MSBASDIR}/DefoInterpolx2Detrend1_Full_tmp.txt 
# 				rm -f ${MSBASDIR}/DefoInterpolx2Detrend2_tmp.txt ${MSBASDIR}/DefoInterpolx2Detrend2_Full_tmp.txt
# 				;;	
# 		esac
# 		# trick the header file						
# 		${PATHGNU}/gsed -i 's/DefoInterpolx2Detrend1.txt/DefoInterpolx2Detrend1_Full.txt/' ${MSBASDIR}/header.txt
# 		${PATHGNU}/gsed -i 's/DefoInterpolx2Detrend2.txt/DefoInterpolx2Detrend2_Full.txt/' ${MSBASDIR}/header.txt
# 
# 		NUM_THREADS=${NTHR} ${PATH_SCRIPTS}/SCRIPTS_MT/MSBAS.sh _Auto_${ORDER}_${LAMBDA}_${LABEL}_NoCohThresh ${TIMESERIESPTS} --msbasv4
# 
# 		# Make baseline plot 
# 		PlotBaselineGeocMSBASmodeTXT.sh ${SET1} ${MSBASDIR}/DefoInterpolx2Detrend1_Full/DefoInterpolx2Detrend1_Full.txt
# 		PlotBaselineGeocMSBASmodeTXT.sh ${SET2} ${MSBASDIR}/DefoInterpolx2Detrend2_Full/DefoInterpolx2Detrend2_Full.txt
# 
# 		# Now msbas single points (with error bars) times series and plots are in dir. Let's add the description to the naming
# 		cp ${TIMESERIESPTSDESCR} ${MSBASDIR}/zz_UD_EW_TS_Auto_${ORDER}_${LAMBDA}_${LABEL}_NoCohThresh/
# 		# remove header line to avoid error message 
# 		#TIMESERIESPTSDESCRNOHEADER=`tail -n +2 ${TIMESERIESPTSDESCR}`
# 		while read -r DESCR X Y RX RY
# 			do	
# 				echo "Rename time series of ${X}_${Y} as ${X}_${Y}_${RX}_${RY}_${DESCR}"
# 				mv ${MSBASDIR}/zz_UD_EW_TS_Auto_${ORDER}_${LAMBDA}_${LABEL}_NoCohThresh/MSBAS_${X}_${Y}_${RX}_${RY}.txt ${MSBASDIR}/zz_UD_EW_TS_Auto_${ORDER}_${LAMBDA}_${LABEL}_NoCohThresh/MSBAS_${X}_${Y}_${RX}_${RY}_${DESCR}.txt
# 				mv ${MSBASDIR}/zz_UD_EW_TS_Auto_${ORDER}_${LAMBDA}_${LABEL}_NoCohThresh/MSBAS_${X}_${Y}_${RX}_${RY}.pdf ${MSBASDIR}/zz_UD_EW_TS_Auto_${ORDER}_${LAMBDA}_${LABEL}_NoCohThresh/MSBAS_${X}_${Y}_${RX}_${RY}_${DESCR}.pdf
# 		done < ${TIMESERIESPTSDESCRNOHEADER}
# 
# 		# Why not some double difference plotting
# 		while read -r X1 Y1 X2 Y2 DESCR
# 			do	
# 				PlotAllNoCoh ${X1} ${Y1} ${X2} ${Y2} ${DESCR}
# 		done < ${DOUBLEDIFFPAIRSEWUD}
# 			
#  		# move all plots in same dir 
#  		mv ${MSBASDIR}/zz_UD_EW_TS_Auto_${ORDER}_${LAMBDA}_${LABEL}_NoCohThresh/*_NoCohThresh_Combi.jpg ${MSBASDIR}/zz_UD_EW_TS_Auto_${ORDER}_${LAMBDA}_${LABEL}_NoCohThresh/__Combi/
#  
#  		# move all time series in dir 
# 		mv ${MSBASDIR}/zz_UD_EW_TS_Auto_${ORDER}_${LAMBDA}_${LABEL}_NoCohThresh/*.txt ${MSBASDIR}/zz_UD_EW_TS_Auto_${ORDER}_${LAMBDA}_${LABEL}_NoCohThresh/_Time_series/

	# EW-UD with coh threshold restriction 
 	#--------------------------------------
         cd "${MSBASDIR}"
         #cp -f header_back.txt header.txt

        # run restrict_msbas_to_Coh.sh         
#         restrict_msbas_to_Coh.sh ${DEFOMODE}1 ${COHRESTRICT} ${KMLCOH} ${S1ASC}/Geocoded/Coh
 #        restrict_msbas_to_Coh.sh ${DEFOMODE}2 ${COHRESTRICT} ${KMLCOH} ${S1DESC}/Geocoded/Coh
		
		# Force pair exclusion 
			if [ "${EXCLUDE01A}" == "YES" ] ; then ${PATH_SCRIPTS}/SCRIPTS_MT/zz_Utilities_MT/Exclude_Pairs_From_Mode.txt.sh "${MSBASDIR}/${DEFOMODE}1" ; fi 
			if [ "${EXCLUDE02A}" == "YES" ] ; then ${PATH_SCRIPTS}/SCRIPTS_MT/zz_Utilities_MT/Exclude_Pairs_From_Mode.txt.sh "${MSBASDIR}/${DEFOMODE}2" ; fi 
			if [ "${EXCLUDE03A}" == "YES" ] ; then ${PATH_SCRIPTS}/SCRIPTS_MT/zz_Utilities_MT/Exclude_Pairs_From_Mode.txt.sh "${MSBASDIR}/${DEFOMODE}3" ; fi 
			if [ "${EXCLUDE04A}" == "YES" ] ; then ${PATH_SCRIPTS}/SCRIPTS_MT/zz_Utilities_MT/Exclude_Pairs_From_Mode.txt.sh "${MSBASDIR}/${DEFOMODE}4" ; fi 
			if [ "${EXCLUDE05A}" == "YES" ] ; then ${PATH_SCRIPTS}/SCRIPTS_MT/zz_Utilities_MT/Exclude_Pairs_From_Mode.txt.sh "${MSBASDIR}/${DEFOMODE}5" ; fi 
			if [ "${EXCLUDE06A}" == "YES" ] ; then ${PATH_SCRIPTS}/SCRIPTS_MT/zz_Utilities_MT/Exclude_Pairs_From_Mode.txt.sh "${MSBASDIR}/${DEFOMODE}6" ; fi 
			if [ "${EXCLUDE07A}" == "YES" ] ; then ${PATH_SCRIPTS}/SCRIPTS_MT/zz_Utilities_MT/Exclude_Pairs_From_Mode.txt.sh "${MSBASDIR}/${DEFOMODE}7" ; fi 
			if [ "${EXCLUDE08A}" == "YES" ] ; then ${PATH_SCRIPTS}/SCRIPTS_MT/zz_Utilities_MT/Exclude_Pairs_From_Mode.txt.sh "${MSBASDIR}/${DEFOMODE}8" ; fi 
			if [ "${EXCLUDE09A}" == "YES" ] ; then ${PATH_SCRIPTS}/SCRIPTS_MT/zz_Utilities_MT/Exclude_Pairs_From_Mode.txt.sh "${MSBASDIR}/${DEFOMODE}9" ; fi 
			if [ "${EXCLUDE10A}" == "YES" ] ; then ${PATH_SCRIPTS}/SCRIPTS_MT/zz_Utilities_MT/Exclude_Pairs_From_Mode.txt.sh "${MSBASDIR}/${DEFOMODE}10" ; fi 
			if [ "${EXCLUDE11A}" == "YES" ] ; then ${PATH_SCRIPTS}/SCRIPTS_MT/zz_Utilities_MT/Exclude_Pairs_From_Mode.txt.sh "${MSBASDIR}/${DEFOMODE}11" ; fi 
			if [ "${EXCLUDE12A}" == "YES" ] ; then ${PATH_SCRIPTS}/SCRIPTS_MT/zz_Utilities_MT/Exclude_Pairs_From_Mode.txt.sh "${MSBASDIR}/${DEFOMODE}12" ; fi 
			if [ "${EXCLUDE13A}" == "YES" ] ; then ${PATH_SCRIPTS}/SCRIPTS_MT/zz_Utilities_MT/Exclude_Pairs_From_Mode.txt.sh "${MSBASDIR}/${DEFOMODE}13" ; fi 
 
			if [ "${EXCLUDE01D}" == "YES" ] ; then ${PATH_SCRIPTS}/SCRIPTS_MT/zz_Utilities_MT/Exclude_Pairs_From_Mode.txt.sh "${MSBASDIR}/${DEFOMODE}14" ; fi 
			if [ "${EXCLUDE02D}" == "YES" ] ; then ${PATH_SCRIPTS}/SCRIPTS_MT/zz_Utilities_MT/Exclude_Pairs_From_Mode.txt.sh "${MSBASDIR}/${DEFOMODE}15" ; fi 
			if [ "${EXCLUDE03D}" == "YES" ] ; then ${PATH_SCRIPTS}/SCRIPTS_MT/zz_Utilities_MT/Exclude_Pairs_From_Mode.txt.sh "${MSBASDIR}/${DEFOMODE}16" ; fi 
			if [ "${EXCLUDE04D}" == "YES" ] ; then ${PATH_SCRIPTS}/SCRIPTS_MT/zz_Utilities_MT/Exclude_Pairs_From_Mode.txt.sh "${MSBASDIR}/${DEFOMODE}17" ; fi 
			if [ "${EXCLUDE05D}" == "YES" ] ; then ${PATH_SCRIPTS}/SCRIPTS_MT/zz_Utilities_MT/Exclude_Pairs_From_Mode.txt.sh "${MSBASDIR}/${DEFOMODE}18" ; fi 
			if [ "${EXCLUDE06D}" == "YES" ] ; then ${PATH_SCRIPTS}/SCRIPTS_MT/zz_Utilities_MT/Exclude_Pairs_From_Mode.txt.sh "${MSBASDIR}/${DEFOMODE}19" ; fi 
			if [ "${EXCLUDE07D}" == "YES" ] ; then ${PATH_SCRIPTS}/SCRIPTS_MT/zz_Utilities_MT/Exclude_Pairs_From_Mode.txt.sh "${MSBASDIR}/${DEFOMODE}20" ; fi 
			if [ "${EXCLUDE08D}" == "YES" ] ; then ${PATH_SCRIPTS}/SCRIPTS_MT/zz_Utilities_MT/Exclude_Pairs_From_Mode.txt.sh "${MSBASDIR}/${DEFOMODE}21" ; fi 
			if [ "${EXCLUDE09D}" == "YES" ] ; then ${PATH_SCRIPTS}/SCRIPTS_MT/zz_Utilities_MT/Exclude_Pairs_From_Mode.txt.sh "${MSBASDIR}/${DEFOMODE}22" ; fi 
			if [ "${EXCLUDE10D}" == "YES" ] ; then ${PATH_SCRIPTS}/SCRIPTS_MT/zz_Utilities_MT/Exclude_Pairs_From_Mode.txt.sh "${MSBASDIR}/${DEFOMODE}23" ; fi 
			if [ "${EXCLUDE11D}" == "YES" ] ; then ${PATH_SCRIPTS}/SCRIPTS_MT/zz_Utilities_MT/Exclude_Pairs_From_Mode.txt.sh "${MSBASDIR}/${DEFOMODE}24" ; fi 
			if [ "${EXCLUDE12D}" == "YES" ] ; then ${PATH_SCRIPTS}/SCRIPTS_MT/zz_Utilities_MT/Exclude_Pairs_From_Mode.txt.sh "${MSBASDIR}/${DEFOMODE}25" ; fi 
			if [ "${EXCLUDE13D}" == "YES" ] ; then ${PATH_SCRIPTS}/SCRIPTS_MT/zz_Utilities_MT/Exclude_Pairs_From_Mode.txt.sh "${MSBASDIR}/${DEFOMODE}26" ; fi 
			if [ "${EXCLUDE14D}" == "YES" ] ; then ${PATH_SCRIPTS}/SCRIPTS_MT/zz_Utilities_MT/Exclude_Pairs_From_Mode.txt.sh "${MSBASDIR}/${DEFOMODE}27" ; fi 

		cd "${MSBASDIR}"

		NUM_THREADS=${NTHR} ${PATH_SCRIPTS}/SCRIPTS_MT/MSBAS.sh "_Auto_${ORDER}_${LAMBDA}_${LABEL}" "${TIMESERIESPTS}" --msbasv4_3D

		# test if MSBAS_log.txt contains "completed 100%" ; if not log error 
#		if ${PATHGNU}/grep -q "writing results to a disk" ${MSBASDIR}/zz_EW_Auto_${ORDER}_${LAMBDA}_${LABEL}/MSBAS_LOG.txt 
#	 		then 
# 				echo "MSBAS ok" 
# 			else 
# 				# try again after cleaning DefoInterpolx2Detrendi.txt
# 				_Check_bad_DefoInterpolx2Detrend.sh DefoInterpolx2Detrend1 ${PATHMASSPROCESS} &
# 				_Check_bad_DefoInterpolx2Detrend.sh DefoInterpolx2Detrend2 ${PATHMASSPROCESS} &
# 				wait 
# 				
# 				NUM_THREADS=${NTHR} ${PATH_SCRIPTS}/SCRIPTS_MT/MSBAS.sh _Auto_${ORDER}_${LAMBDA}_${LABEL} ${TIMESERIESPTS} --msbasv4
# 				if ${PATHGNU}/grep -q "writing results to a disk" ${MSBASDIR}/zz_EW_Auto_${ORDER}_${LAMBDA}_${LABEL}/MSBAS_LOG.txt ; then echo "Solved after cleaning DefoInterpolx2Detrend's txt"; else  echo "!! MSBAS crashed on ${TODAY}"  >>  ${MSBASDIR}/_last_MSBAS_process.txt ; fi
# 		fi

		# Make baseline plot  
		for SETNR in ${USEDSETS} ; do
			eval SETDIR=\"\$SET$(printf "%02d" "${SETNR}")\"
			PlotBaselineGeocMSBASmodeTXT.sh "${SETDIR}" "${MSBASDIR}/${DEFOMODE}${SETNR}.txt" 
		done
		
		# Now msbas single points (with error bars) times series and plots are in dir. Let's add the description to the naming
		cp "${TIMESERIESPTSDESCR}" "${MSBASDIR}/zz_${ALLCOMP}_TS_Auto_${ORDER}_${LAMBDA}_${LABEL}/"

		while read -r DESCR X Y RX RY
			do	
				echo "Rename time series of ${X}_${Y} as ${X}_${Y}_${RX}_${RY}_${DESCR}"
				
				OLL="${ORDER}_${LAMBDA}_${LABEL}"
				mv "${MSBASDIR}/MSBAS_${X}_${Y}_${RX}_${RY}.txt" "${MSBASDIR}/zz_${ALLCOMP}_TS_Auto_${OLL}/MSBAS_${X}_${Y}_${RX}_${RY}_${DESCR}.txt"
				mv "${MSBASDIR}/MSBAS_${X}_${Y}_${RX}_${RY}.pdf" "${MSBASDIR}/zz_${ALLCOMP}_TS_Auto_${OLL}/MSBAS_${X}_${Y}_${RX}_${RY}_${DESCR}.pdf"
		done < "${TIMESERIESPTSDESCR}" | tail -n +2  # ignore header

		# Why not some double difference plotting
		#WhichPlots
		while read -r X1 Y1 X2 Y2 DESCR
			do	
				PlotAll ${X1} ${Y1} ${X2} ${Y2} "${DESCR}"
		done < "${DOUBLEDIFFPAIRSEWUD}"	
						
 		# move all plots in same dir 
 		rm -f "${MSBASDIR}/zz_${ALLCOMP}_TS_Auto_${OLL}/__Combi/"*.jpg
 		mv "${MSBASDIR}/zz_${ALLCOMP}_TS_Auto_${OLL}/"*_Combi.jpg "${MSBASDIR}/zz_${ALLCOMP}_TS_Auto_${OLL}/__Combi/"

		# move all time series in dir 
		mv "${MSBASDIR}/zz_${ALLCOMP}_TS_Auto_${OLL}/"*.txt "${MSBASDIR}/zz_${ALLCOMP}_TS_Auto_${OLL}/_Time_series/"

		
	# Asc and Desc 
 	#--------------
 		# Prepare header files
		#   backup header
		cp -f "${MSBASDIR}/header.txt" "${MSBASDIR}/header_${ALLCOMP}.txt" 

 		#   Change "SET = " with "#SET = " in each line of header
		#cat ${MSBASDIR}/header.txt | ${PATHGNU}/gsed "s/SET = /#SET = /g" > ${MSBASDIR}/header_none.txt	 		# This preserves the exclusion of modes here above because excluded ones wil be set as ##SET= here, then back to #SET below
		cat "${MSBASDIR}/header_all_modes.txt" | ${PATHGNU}/gsed "s/SET = /#SET = /g" > "${MSBASDIR}/header_none.txt"	# This allows computing LoS of rejected modes as well
		
		#   Change "#SET = " with "SET = " for only the mode one wants to keep 
		for MODE in "${MODELIST[@]}" ; do
			eval MODENAME=\"\$MODE${MODE}\"
			eval MODELINENR=\"\$LINENR${MODE}\"
			cat "${MSBASDIR}/header_none.txt" | ${PATHGNU}/gsed "${MODELINENR}"' s/#SET = /SET = /' > "${MSBASDIR}/header_${MODENAME}.txt"
		done

		# Several Asc or Desc modes ? 
		# All Asc 
		#cp ${MSBASDIR}/header_all_modes.txt ${MSBASDIR}/header_tmp.txt
		#cat ${MSBASDIR}/header_tmp.txt | ${PATHGNU}/gsed ${LINENR01A}' s/#SET = /SET = /' > ${MSBASDIR}/header_AllAsc.txt
		#cat ${MSBASDIR}/header_AllAsc.txt | ${PATHGNU}/gsed ${LINENR02A}' s/#SET = /SET = /' > ${MSBASDIR}/header_tmp.txt
		#cat ${MSBASDIR}/header_tmp.txt | ${PATHGNU}/gsed ${LINENR03A}' s/#SET = /SET = /' > ${MSBASDIR}/header_AllAsc.txt
		#cat ${MSBASDIR}/header_AllAsc.txt | ${PATHGNU}/gsed ${LINENR04A}' s/#SET = /SET = /' > ${MSBASDIR}/header_tmp.txt
		#cat ${MSBASDIR}/header_tmp.txt | ${PATHGNU}/gsed ${LINENR05A}' s/#SET = /SET = /' > ${MSBASDIR}/header_AllAsc.txt
		#cat ${MSBASDIR}/header_AllAsc.txt | ${PATHGNU}/gsed ${LINENR06A}' s/#SET = /SET = /' > ${MSBASDIR}/header_tmp.txt
		#cat ${MSBASDIR}/header_tmp.txt | ${PATHGNU}/gsed ${LINENR07A}' s/#SET = /SET = /' > ${MSBASDIR}/header_AllAsc.txt
		#cat ${MSBASDIR}/header_AllAsc.txt | ${PATHGNU}/gsed ${LINENR08A}' s/#SET = /SET = /' > ${MSBASDIR}/header_tmp.txt
		#cat ${MSBASDIR}/header_tmp.txt | ${PATHGNU}/gsed ${LINENR09A}' s/#SET = /SET = /' > ${MSBASDIR}/header_AllAsc.txt
		#cat ${MSBASDIR}/header_AllAsc.txt | ${PATHGNU}/gsed ${LINENR10A}' s/#SET = /SET = /' > ${MSBASDIR}/header_tmp.txt
		#cat ${MSBASDIR}/header_tmp.txt | ${PATHGNU}/gsed ${LINENR11A}' s/#SET = /SET = /' > ${MSBASDIR}/header_AllAsc.txt
		#cat ${MSBASDIR}/header_AllAsc.txt | ${PATHGNU}/gsed ${LINENR12A}' s/#SET = /SET = /' > ${MSBASDIR}/header_tmp.txt
		#cat ${MSBASDIR}/header_tmp.txt | ${PATHGNU}/gsed ${LINENR13A}' s/#SET = /SET = /' > ${MSBASDIR}/header_AllAsc.txt
		#cp ${MSBASDIR}/header_AllAsc.txt ${MSBASDIR}/header_AllAsc_full.txt
		# Reject if needed some modes
		#if [ ${#ALLMODELIST[@]} -ne ${#MODELIST[@]} ]  # i.e. if the two list have not the same length
		#	then
		#		echo "// Reject some Asc modes "
		#		#   Change "SET = " with "#SET = " for only the mode one wants to reject 
		#		for pos in "${SETTOREJECT[@]}"; do
    	#			cat ${MSBASDIR}/header_AllAsc.txt | ${PATHGNU}/gsed ${pos}' s/SET = /#SET = /' > header_tst.txt
    	#			cp -f header_tst.txt ${MSBASDIR}/header_AllAsc.txt  
		#		done
		#fi

		# All Desc (beware it would mixe several look angles and az ! => would produce UD/EW decomposition ! DO NOT RUN)
		#cp ${MSBASDIR}/header_all_modes.txt ${MSBASDIR}/header_tmp.txt
		#cat ${MSBASDIR}/header_tmp.txt | ${PATHGNU}/gsed ${LINENR01D}' s/#SET = /SET = /' > ${MSBASDIR}/header_AllDesc.txt
		#cat ${MSBASDIR}/header_AllDesc.txt | ${PATHGNU}/gsed ${LINENR02D}' s/#SET = /SET = /' > ${MSBASDIR}/header_tmp.txt
		#cat ${MSBASDIR}/header_tmp.txt | ${PATHGNU}/gsed ${LINENR03D}' s/#SET = /SET = /' > ${MSBASDIR}/header_AllDesc.txt
		#cat ${MSBASDIR}/header_AllDesc.txt | ${PATHGNU}/gsed ${LINENR04D}' s/#SET = /SET = /' > ${MSBASDIR}/header_tmp.txt
		#cat ${MSBASDIR}/header_tmp.txt | ${PATHGNU}/gsed ${LINENR05D}' s/#SET = /SET = /' > ${MSBASDIR}/header_AllDesc.txt
		#cat ${MSBASDIR}/header_AllDesc.txt | ${PATHGNU}/gsed ${LINENR06D}' s/#SET = /SET = /' > ${MSBASDIR}/header_tmp.txt
		#cat ${MSBASDIR}/header_tmp.txt | ${PATHGNU}/gsed ${LINENR07D}' s/#SET = /SET = /' > ${MSBASDIR}/header_AllDesc.txt
		#cat ${MSBASDIR}/header_AllDesc.txt | ${PATHGNU}/gsed ${LINENR08D}' s/#SET = /SET = /' > ${MSBASDIR}/header_tmp.txt
		#cat ${MSBASDIR}/header_tmp.txt | ${PATHGNU}/gsed ${LINENR09D}' s/#SET = /SET = /' > ${MSBASDIR}/header_AllDesc.txt
		#cat ${MSBASDIR}/header_AllDesc.txt | ${PATHGNU}/gsed ${LINENR10D}' s/#SET = /SET = /' > ${MSBASDIR}/header_tmp.txt
		#cat ${MSBASDIR}/header_tmp.txt | ${PATHGNU}/gsed ${LINENR11D}' s/#SET = /SET = /' > ${MSBASDIR}/header_AllDesc.txt
		#cat ${MSBASDIR}/header_AllDesc.txt | ${PATHGNU}/gsed ${LINENR12D}' s/#SET = /SET = /' > ${MSBASDIR}/header_tmp.txt
		#cat ${MSBASDIR}/header_tmp.txt | ${PATHGNU}/gsed ${LINENR13D}' s/#SET = /SET = /' > ${MSBASDIR}/header_AllDesc.txt
		#cat ${MSBASDIR}/header_AllDesc.txt | ${PATHGNU}/gsed ${LINENR14D}' s/#SET = /SET = /' > ${MSBASDIR}/header_tmp.txt
		#mv -f ${MSBASDIR}/header_tmp.txt ${MSBASDIR}/header_AllDesc.txt 
		#cp ${MSBASDIR}/header_AllDesc.txt ${MSBASDIR}/header_AllDesc_full.txt
		## Reject if needed some modes
		#if [ ${#ALLMODELIST[@]} -ne ${#MODELIST[@]} ]  # i.e. if the two list have not the same length
		#	then
		#		echo "// Reject some Desc modes "
		#		#   Change "SET = " with "#SET = " for only the mode one wants to reject 
		#		for pos in "${SETTOREJECT[@]}"; do
    	#			cat ${MSBASDIR}/header_AllDesc.txt | ${PATHGNU}/gsed ${pos}' s/SET = /#SET = /' > header_tst.txt
    	#			cp -f header_tst.txt ${MSBASDIR}/header_AllDesc.txt  
		#		done
		#fi
#
		#rm -f ${MSBASDIR}/header_none.txt ${MSBASDIR}/header_tmp.txt

		# LOS of each mode to process (Asc and Desc)
 				for MODE in "${MODELIST[@]}" ; do
 					case "${MODE}" in
 						*A) 	FILEPAIRS="${DOUBLEDIFFPAIRSASC}" 	;;
 						*D) 	FILEPAIRS="${DOUBLEDIFFPAIRSDESC}" 	;;
 					esac
 					eval MODENAME=\"\$MODE${MODE}\"
 					eval FORMERTIME=\"\$FORMERLAST${MODE}TIME\"
 					eval LASTTIME=\"\$LAST${MODE}TIME\"
 					MSBASmode "${MODENAME}" "${FORMERTIME}" "${LASTTIME}"
 				done
 
 		###		MSBASmode AllAsc				
 		###		MSBASmode AllDesc 				

 
 		# Back to normal for next run and get out
 				cp -f ${MSBASDIR}/header_${ALLCOMP}.txt ${MSBASDIR}/header.txt 		 				

				TODAY=`date`
				echo "MSBAS finished on ${TODAY}"  >>  ${MSBASDIR}/_last_MSBAS_process.txt

				# one line per mode, in the order of ALLMODELIST, i.e. always 27 lines 
				rm -f "${MSBASDIR}"/_Last_MassProcessed_Pairs_Time.txt
				for MODE in "${ALLMODELIST[@]}" ; do
					eval LASTTIME=\"\$LAST${MODE}TIME\"
					echo "${LASTTIME}" >> "${MSBASDIR}"/_Last_MassProcessed_Pairs_Time.txt
				done


	# EW_UD i.e. 2D 
 	#--------------
 	
 	cd "${MSBASDIR}"
 	
 	eval LABELORIG="${LABEL}"
 	LABEL="${LABELORIG}_2D" 

	eval ALLCOMP="${ALLCOMP2D} "

	TIMESERIESPTS="${PATH_SCRIPTS}/SCRIPTS_MT/_cron_scripts/List_DoubleDiff_EW_UD_${LABEL}.txt"
 	
 	NUM_THREADS=${NTHR} ${PATH_SCRIPTS}/SCRIPTS_MT/MSBAS.sh "_Auto_${ORDER}_${LAMBDA}_${LABEL}" "${TIMESERIESPTS}" --msbasv4
 	
 	# Now msbas single points (with error bars) times series and plots are in dir. Let's add the description to the naming
	cp "${TIMESERIESPTSDESCR}" "${MSBASDIR}"/"zz_${ALLCOMP}_TS_Auto_${ORDER}_${LAMBDA}_${LABEL}"/

	while read -r DESCR X Y RX RY
		do	
			echo "Rename time series of ${X}_${Y} as ${X}_${Y}_${RX}_${RY}_${DESCR}"
			
			OLL=${ORDER}_${LAMBDA}_${LABEL}
			mv "${MSBASDIR}/MSBAS_${X}_${Y}_${RX}_${RY}.txt" "${MSBASDIR}/zz_${ALLCOMP}_TS_Auto_${OLL}/MSBAS_${X}_${Y}_${RX}_${RY}_${DESCR}.txt"
			mv "${MSBASDIR}/MSBAS_${X}_${Y}_${RX}_${RY}.pdf" "${MSBASDIR}/zz_${ALLCOMP}_TS_Auto_${OLL}/MSBAS_${X}_${Y}_${RX}_${RY}_${DESCR}.pdf"
	done < "${TIMESERIESPTSDESCR}" | tail -n +2  # ignore header

	# Why not some double difference plotting
	#WhichPlots
	while read -r X1 Y1 X2 Y2 DESCR
		do	
			PlotAll ${X1} ${Y1} ${X2} ${Y2} "${DESCR}"
	done < "${DOUBLEDIFFPAIRSEWUD}"	
					
 	# move all plots in same dir 
 	rm -f "${MSBASDIR}/zz_${ALLCOMP}_TS_Auto_${OLL}/__Combi/"*.jpg
 	mv "${MSBASDIR}/zz_${ALLCOMP}_TS_Auto_${OLL}/"*_Combi.jpg "${MSBASDIR}/zz_${ALLCOMP}_TS_Auto_${OLL}/__Combi/"

	# move all time series in dir 
	mv "${MSBASDIR}/zz_${ALLCOMP}_TS_Auto_${OLL}/"*.txt "${MSBASDIR}/zz_${ALLCOMP}_TS_Auto_${OLL}/_Time_series/"

	eval LABEL="${LABELORIG}"

# All done...