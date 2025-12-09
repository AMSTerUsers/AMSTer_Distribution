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
#									6778, 4020, 4034 and 3987 (low incidence angle)
# New in Distro V 1.2 20240411:	- reject mode 3997 (no recent data)  
#								- add S1 Asc SM and Desc IW
# New in Distro V 1.3 20250410:	- change SM for mode 4041 (13D)
# New in Distro V 1.3.1 20250424 :	- check if correct termination in MSBAS_LOG.txt at right place

#
# AMSTer: SAR & InSAR Automated Mass processing Software for Multidimensional Time series
# NdO (c) 2016/03/07 - could make better with more functions... when time.
# -----------------------------------------------------------------------------------------
PRG=`basename "$0"`
VER="Distro V1.3.1 AMSTer script utilities"
AUT="Nicolas d'Oreye, (c)2016-2019, Last modified on Apr 24, 2025"


echo " "
echo "${PRG} ${VER}, ${AUT}"
echo " "

source $HOME/.bashrc

cd

TODAY=`date`
MMDDYYYY=$(date +'%m_%d_%Y') # Needed to restrict pairs after give date

# vvvvvvvvv Hard coded lines vvvvvvvvvvvvvv
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

		SET28="${PATH_1650}/SAR_SM/MSBAS/PF/set1"	# S1 Asc 144 SM
		SET29="${PATH_1650}/SAR_SM/MSBAS/PF/set4"	# S1 Desc 151 IW


		## Modes:
		# Ascending modes 
		MODE01A="6811_L_A"
		MODE02A="6806_L_A"	# make 6807_L_A as well
		MODE03A="6801_L_A"	# make 6802_L_A as well
		MODE04A="6796_L_A"
		MODE05A="6790_L_A"
		MODE06A="6784_L_A"
		MODE07A="6778_L_A"
		MODE08A="6764_R_A"
		MODE09A="6757_R_A"
		MODE10A="6749_R_A"	# make 6750_R_A as well
		MODE11A="6742_R_A"	# make 6741_R_A as well
		MODE12A="6733_R_A"
		MODE13A="6724_R_A"
		
		MODE14A="SM_A_144"	# S1 Asc 144 SM
		
		# Descending modes 
		MODE01D="4020_L_D"
		MODE02D="4014_L_D"	
		MODE03D="4008_L_D"	
		MODE04D="4002_L_D"
		MODE05D="3997_L_D"	# No Recent data 
		MODE06D="3992_L_D"
		MODE07D="3987_L_D"
		MODE08D="4082_R_D"
		MODE09D="4073_R_D"
		MODE10D="4064_R_D"	
		MODE11D="4056_R_D"	
		MODE12D="4048_R_D"
		MODE13D="4041_R_D"
		MODE14D="4034_R_D"	# make 4033_R_D as well
		
		MODE15D="IW_D_151"	# S1 Desc 151 IW
		
		# List of all numbers of modes 
		ALLMODELIST=(01A 02A 03A 04A 05A 06A 07A 08A 09A 10A 11A 12A 13A 01D 02D 03D 04D 05D 06D 07D 08D 09D 10D 11D 12D 13D 14D 14A 15D) # add S1 after all ALOS

		# List of nr of modes to invert using MSBAS
		# All 
		#MODELIST=(01A 02A 03A 04A 05A 06A 07A 08A 09A 10A 11A 12A 13A 01D 02D 03D 04D 05D 06D 07D 08D 09D 10D 11D 12D 13D 14D)
		# All but 07A=6778_L_A,   01D=4020_L_D,   05D=3997_L_D   and   07D=3987_L_D     14D=4034_R_D
		MODELIST=(01A 02A 03A 04A 05A 06A 08A 09A 10A 11A 12A 13A 02D 03D 04D 06D 08D 09D 10D 11D 12D 13D 14A 15D) # add S1 after all ALOS
		
		# search for position of missing modes: 
		if [ ${#ALLMODELIST[@]} -ne ${#MODELIST[@]} ]  # i.e. if the two list have not the same length
			then
				missing_positions=()
				
				# Iterate over ALLMODELIST
				for ((i=0; i<${#ALLMODELIST[@]}; i++)); do
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
		
		SM14A=20190808	# S1 144 Asc SM
		
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

		SM15D=20200622	# S1 151 Desc IW
		
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
		
		
		BP14A1=50	# S1 Asc 144 SM
		BT14A1=50
		BP14A2=90	# S1 Asc 144 SM
		BT14A2=50
		DATECHGS1A=20220501
		
		
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
		
	
		BP15D1=70	# S1 Desc 151 IW
		BT15D1=70
		BP15D2=90	# Desc 151 IW
		BT15D2=70
		DATECHGS1D=20220501

		

		# some files
		############
		
		# Pair files
		TABLE01A="$PATH_1650/SAR_SM/MSBAS/PF/set5/table_0_${BP01A}_0_${BT01A}.txt"
		TABLE02A="$PATH_1650/SAR_SM/MSBAS/PF/set6/table_0_${BP02A}_0_${BT02A}.txt"
		TABLE03A="$PATH_1650/SAR_SM/MSBAS/PF/set7/table_0_${BP03A}_0_${BT03A}.txt"
		TABLE04A="$PATH_1650/SAR_SM/MSBAS/PF/set8/table_0_${BP04A}_0_${BT04A}.txt"
		TABLE05A="$PATH_1650/SAR_SM/MSBAS/PF/set9/table_0_${BP05A}_0_${BT05A}.txt"
		TABLE06A="$PATH_1650/SAR_SM/MSBAS/PF/set10/table_0_${BP06A}_0_${BT06A}.txt"
		TABLE07A="$PATH_1650/SAR_SM/MSBAS/PF/set11/table_0_${BP07A}_0_${BT07A}.txt"
		TABLE08A="$PATH_1650/SAR_SM/MSBAS/PF/set12/table_0_${BP08A}_0_${BT08A}.txt"
		TABLE09A="$PATH_1650/SAR_SM/MSBAS/PF/set13/table_0_${BP09A}_0_${BT09A}.txt"
		TABLE10A="$PATH_1650/SAR_SM/MSBAS/PF/set14/table_0_${BP10A}_0_${BT10A}.txt"
		TABLE11A="$PATH_1650/SAR_SM/MSBAS/PF/set15/table_0_${BP11A}_0_${BT11A}.txt"
		TABLE12A="$PATH_1650/SAR_SM/MSBAS/PF/set16/table_0_${BP12A}_0_${BT12A}.txt"
		TABLE13A="$PATH_1650/SAR_SM/MSBAS/PF/set17/table_0_${BP13A}_0_${BT13A}.txt"
		
		TABLE14A="$PATH_1650/SAR_SM/MSBAS/PF/set1/table_0_${BP14A1}_0_${BT14A1}_Till_${DATECHGS1A}_0_${BP14A2}_0_${BT14A2}_After.txt"
		
		
		TABLE01D="$PATH_1650/SAR_SM/MSBAS/PF/set18/table_0_${BP01D}_0_${BT01D}.txt"
		TABLE02D="$PATH_1650/SAR_SM/MSBAS/PF/set19/table_0_${BP02D}_0_${BT02D}.txt"
		TABLE03D="$PATH_1650/SAR_SM/MSBAS/PF/set20/table_0_${BP03D}_0_${BT03D}.txt"
		TABLE04D="$PATH_1650/SAR_SM/MSBAS/PF/set21/table_0_${BP04D}_0_${BT04D}.txt"
		TABLE05D="$PATH_1650/SAR_SM/MSBAS/PF/set22/table_0_${BP05D}_0_${BT05D}.txt"
		TABLE06D="$PATH_1650/SAR_SM/MSBAS/PF/set23/table_0_${BP06D}_0_${BT06D}.txt"
		TABLE07D="$PATH_1650/SAR_SM/MSBAS/PF/set24/table_0_${BP07D}_0_${BT07D}.txt"
		TABLE08D="$PATH_1650/SAR_SM/MSBAS/PF/set25/table_0_${BP08D}_0_${BT08D}.txt"
		TABLE09D="$PATH_1650/SAR_SM/MSBAS/PF/set26/table_0_${BP09D}_0_${BT09D}.txt"
		TABLE10D="$PATH_1650/SAR_SM/MSBAS/PF/set27/table_0_${BP10D}_0_${BT10D}.txt"
		TABLE11D="$PATH_1650/SAR_SM/MSBAS/PF/set28/table_0_${BP11D}_0_${BT11D}.txt"
		TABLE12D="$PATH_1650/SAR_SM/MSBAS/PF/set29/table_0_${BP12D}_0_${BT12D}.txt"
		TABLE13D="$PATH_1650/SAR_SM/MSBAS/PF/set30/table_0_${BP13D}_0_${BT13D}.txt"
		TABLE14D="$PATH_1650/SAR_SM/MSBAS/PF/set31/table_0_${BP14D}_0_${BT14D}.txt"

		TABLE15D="$PATH_1650/SAR_SM/MSBAS/PF/set4/table_0_${BP15D1}_0_${BT15D1}_Till_${DATECHGS1D}_0_${BP15D2}_0_${BT15D2}_After.txt"


				
		# Date from which to start the time series 
		STARTDATE=20210331
		STARTFROM="YES"		# If set to YES, build_header_msbas_Tables.sh will operate with tables starting after  STARTDATE
		
		if [ ${STARTFROM} == "YES" ] && [ ${STARTDATE} != "" ] ; then 
			#Recreate the table from that start date  
			function StartTableFrom()
				{
					TABLE=$1		# table file e.g. ${TABLE01A}
					# Restric pair table to data after March 2021 (i.e. from April)
					RemovePairsFromFlist_WithImagesBefore.sh ${TABLE} ${STARTDATE}
					## To avoid new table at each run
					mv ${TABLE}_After${STARTDATE}_WithBaselines_${MMDDYYYY}.txt ${TABLE}_After${STARTDATE}_WithBaselines.txt
				}
			StartTableFrom "${TABLE01A}"
			StartTableFrom "${TABLE02A}"
			StartTableFrom "${TABLE03A}"
			StartTableFrom "${TABLE04A}"
			StartTableFrom "${TABLE05A}"
			StartTableFrom "${TABLE06A}"
			StartTableFrom "${TABLE07A}"
			StartTableFrom "${TABLE08A}"
			StartTableFrom "${TABLE09A}"
			StartTableFrom "${TABLE10A}"
			StartTableFrom "${TABLE11A}"
			StartTableFrom "${TABLE12A}"
			StartTableFrom "${TABLE13A}"
			
			StartTableFrom "${TABLE14A}"
	
			StartTableFrom "${TABLE01D}"
			StartTableFrom "${TABLE02D}"
			StartTableFrom "${TABLE03D}"
			StartTableFrom "${TABLE04D}"
			StartTableFrom "${TABLE05D}"
			StartTableFrom "${TABLE06D}"
			StartTableFrom "${TABLE07D}"
			StartTableFrom "${TABLE08D}"
			StartTableFrom "${TABLE09D}"
			StartTableFrom "${TABLE10D}"
			StartTableFrom "${TABLE11D}"
			StartTableFrom "${TABLE12D}"
			StartTableFrom "${TABLE13D}"
			StartTableFrom "${TABLE14D}"
			
			StartTableFrom "${TABLE15D}"
		fi
				
		LABEL="PF" 	# Label for file naming (used for naming zz_ dirs with results and figs etc)

		#R_FLAG
		# Order
		ORDER=2
		# Lambda
		LAMBDA=0.04
		
	# some files and PATH for each mode
	###################################
		# Path to Pair Dirs and Geocoded files to use (need one for each mode)
	
		MASSPROCDIR01A="$PATH_1660/SAR_MASSPROCESS/ALOS2/PF_${MODE01A}/SMNoCrop_SM_${SM01A}_Zoom1_ML8"
		MASSPROCDIR02A="$PATH_1660/SAR_MASSPROCESS/ALOS2/PF_${MODE02A}/SMNoCrop_SM_${SM02A}_Zoom1_ML8"
		MASSPROCDIR03A="$PATH_1660/SAR_MASSPROCESS/ALOS2/PF_${MODE03A}/SMNoCrop_SM_${SM03A}_Zoom1_ML8"
		MASSPROCDIR04A="$PATH_1660/SAR_MASSPROCESS/ALOS2/PF_${MODE04A}/SMNoCrop_SM_${SM04A}_Zoom1_ML8"
		MASSPROCDIR05A="$PATH_1660/SAR_MASSPROCESS/ALOS2/PF_${MODE05A}/SMNoCrop_SM_${SM05A}_Zoom1_ML8"
		MASSPROCDIR06A="$PATH_1660/SAR_MASSPROCESS/ALOS2/PF_${MODE06A}/SMNoCrop_SM_${SM06A}_Zoom1_ML8"
		MASSPROCDIR07A="$PATH_1660/SAR_MASSPROCESS/ALOS2/PF_${MODE07A}/SMNoCrop_SM_${SM07A}_Zoom1_ML8"
		MASSPROCDIR08A="$PATH_1660/SAR_MASSPROCESS/ALOS2/PF_${MODE08A}/SMNoCrop_SM_${SM08A}_Zoom1_ML8"
		MASSPROCDIR09A="$PATH_1660/SAR_MASSPROCESS/ALOS2/PF_${MODE09A}/SMNoCrop_SM_${SM09A}_Zoom1_ML8"
		MASSPROCDIR10A="$PATH_1660/SAR_MASSPROCESS/ALOS2/PF_${MODE10A}/SMNoCrop_SM_${SM10A}_Zoom1_ML8"
		MASSPROCDIR11A="$PATH_1660/SAR_MASSPROCESS/ALOS2/PF_${MODE11A}/SMNoCrop_SM_${SM11A}_Zoom1_ML8"
		MASSPROCDIR12A="$PATH_1660/SAR_MASSPROCESS/ALOS2/PF_${MODE12A}/SMNoCrop_SM_${SM12A}_Zoom1_ML8"
		MASSPROCDIR13A="$PATH_1660/SAR_MASSPROCESS/ALOS2/PF_${MODE13A}/SMNoCrop_SM_${SM13A}_Zoom1_ML8"

		MASSPROCDIR14A="$PATH_3601/SAR_MASSPROCESS/S1/PF_${MODE14A}/SMCrop_SM_${SM14A}_Reunion_-21.41--20.85_55.2-55.85_Zoom1_ML8"	# attention not the same disk
		
		
		MASSPROCDIR01D="$PATH_1660/SAR_MASSPROCESS/ALOS2/PF_${MODE01D}/SMNoCrop_SM_${SM01D}_Zoom1_ML8"
		MASSPROCDIR02D="$PATH_1660/SAR_MASSPROCESS/ALOS2/PF_${MODE02D}/SMNoCrop_SM_${SM02D}_Zoom1_ML8"
		MASSPROCDIR03D="$PATH_1660/SAR_MASSPROCESS/ALOS2/PF_${MODE03D}/SMNoCrop_SM_${SM03D}_Zoom1_ML8"
		MASSPROCDIR04D="$PATH_1660/SAR_MASSPROCESS/ALOS2/PF_${MODE04D}/SMNoCrop_SM_${SM04D}_Zoom1_ML8"
		MASSPROCDIR05D="$PATH_1660/SAR_MASSPROCESS/ALOS2/PF_${MODE05D}/SMNoCrop_SM_${SM05D}_Zoom1_ML8"
		MASSPROCDIR06D="$PATH_1660/SAR_MASSPROCESS/ALOS2/PF_${MODE06D}/SMNoCrop_SM_${SM06D}_Zoom1_ML8"
		MASSPROCDIR07D="$PATH_1660/SAR_MASSPROCESS/ALOS2/PF_${MODE07D}/SMNoCrop_SM_${SM07D}_Zoom1_ML8"
		MASSPROCDIR08D="$PATH_1660/SAR_MASSPROCESS/ALOS2/PF_${MODE08D}/SMNoCrop_SM_${SM08D}_Zoom1_ML8"
		MASSPROCDIR09D="$PATH_1660/SAR_MASSPROCESS/ALOS2/PF_${MODE09D}/SMNoCrop_SM_${SM09D}_Zoom1_ML8"
		MASSPROCDIR10D="$PATH_1660/SAR_MASSPROCESS/ALOS2/PF_${MODE10D}/SMNoCrop_SM_${SM10D}_Zoom1_ML8"
		MASSPROCDIR11D="$PATH_1660/SAR_MASSPROCESS/ALOS2/PF_${MODE11D}/SMNoCrop_SM_${SM11D}_Zoom1_ML8"
		MASSPROCDIR12D="$PATH_1660/SAR_MASSPROCESS/ALOS2/PF_${MODE12D}/SMNoCrop_SM_${SM12D}_Zoom1_ML8"
		MASSPROCDIR13D="$PATH_1660/SAR_MASSPROCESS/ALOS2/PF_${MODE13D}/SMNoCrop_SM_${SM13D}_Zoom1_ML8"
		MASSPROCDIR14D="$PATH_1660/SAR_MASSPROCESS/ALOS2/PF_${MODE14D}/SMNoCrop_SM_${SM14D}_Zoom1_ML8"

		MASSPROCDIR15D="$PATH_3601/SAR_MASSPROCESS/S1/PF_${MODE15D}/SMNoCrop_SM_${SM15D}_Zoom1_ML2"		# attention, not the same disk



		# Parameters files 
		PARAMPROCESS01A="$PATH_1650/Param_files/ALOS2/PF/${MODE01A}/LaunchMTparam_ALOS2_${MODE01A}_Full_Zoom1_ML8_MassProc.txt"
		PARAMPROCESS02A="$PATH_1650/Param_files/ALOS2/PF/${MODE02A}/LaunchMTparam_ALOS2_${MODE02A}_Full_Zoom1_ML8_MassProc.txt"
		PARAMPROCESS03A="$PATH_1650/Param_files/ALOS2/PF/${MODE03A}/LaunchMTparam_ALOS2_${MODE03A}_Full_Zoom1_ML8_MassProc.txt"
		PARAMPROCESS04A="$PATH_1650/Param_files/ALOS2/PF/${MODE04A}/LaunchMTparam_ALOS2_${MODE04A}_Full_Zoom1_ML8_MassProc.txt"
		PARAMPROCESS05A="$PATH_1650/Param_files/ALOS2/PF/${MODE05A}/LaunchMTparam_ALOS2_${MODE05A}_Full_Zoom1_ML8_MassProc.txt"
		PARAMPROCESS06A="$PATH_1650/Param_files/ALOS2/PF/${MODE06A}/LaunchMTparam_ALOS2_${MODE06A}_Full_Zoom1_ML8_MassProc.txt"
		PARAMPROCESS07A="$PATH_1650/Param_files/ALOS2/PF/${MODE07A}/LaunchMTparam_ALOS2_${MODE07A}_Full_Zoom1_ML8_MassProc.txt"
		PARAMPROCESS08A="$PATH_1650/Param_files/ALOS2/PF/${MODE08A}/LaunchMTparam_ALOS2_${MODE08A}_Full_Zoom1_ML8_MassProc.txt"
		PARAMPROCESS09A="$PATH_1650/Param_files/ALOS2/PF/${MODE09A}/LaunchMTparam_ALOS2_${MODE09A}_Full_Zoom1_ML8_MassProc.txt"
		PARAMPROCESS10A="$PATH_1650/Param_files/ALOS2/PF/${MODE10A}/LaunchMTparam_ALOS2_${MODE10A}_Full_Zoom1_ML8_MassProc.txt"
		PARAMPROCESS11A="$PATH_1650/Param_files/ALOS2/PF/${MODE11A}/LaunchMTparam_ALOS2_${MODE11A}_Full_Zoom1_ML8_MassProc.txt"
		PARAMPROCESS12A="$PATH_1650/Param_files/ALOS2/PF/${MODE12A}/LaunchMTparam_ALOS2_${MODE12A}_Full_Zoom1_ML8_MassProc.txt"
		PARAMPROCESS13A="$PATH_1650/Param_files/ALOS2/PF/${MODE13A}/LaunchMTparam_ALOS2_${MODE13A}_Full_Zoom1_ML8_MassProc.txt"
	
		PARAMPROCESS14A="$PATH_1650/Param_files/S1/PF_${MODE14A}/LaunchMTparam_S1_SM_Reunion_Asc_Zoom1_ML8.txt"

		
		PARAMPROCESS01D="$PATH_1650/Param_files/ALOS2/PF/${MODE01D}/LaunchMTparam_ALOS2_${MODE01D}_Full_Zoom1_ML8_MassProc.txt"
		PARAMPROCESS02D="$PATH_1650/Param_files/ALOS2/PF/${MODE02D}/LaunchMTparam_ALOS2_${MODE02D}_Full_Zoom1_ML8_MassProc.txt"
		PARAMPROCESS03D="$PATH_1650/Param_files/ALOS2/PF/${MODE03D}/LaunchMTparam_ALOS2_${MODE03D}_Full_Zoom1_ML8_MassProc.txt"
		PARAMPROCESS04D="$PATH_1650/Param_files/ALOS2/PF/${MODE04D}/LaunchMTparam_ALOS2_${MODE04D}_Full_Zoom1_ML8_MassProc.txt"
		PARAMPROCESS05D="$PATH_1650/Param_files/ALOS2/PF/${MODE05D}/LaunchMTparam_ALOS2_${MODE05D}_Full_Zoom1_ML8_MassProc.txt"
		PARAMPROCESS06D="$PATH_1650/Param_files/ALOS2/PF/${MODE06D}/LaunchMTparam_ALOS2_${MODE06D}_Full_Zoom1_ML8_MassProc.txt"
		PARAMPROCESS07D="$PATH_1650/Param_files/ALOS2/PF/${MODE07D}/LaunchMTparam_ALOS2_${MODE07D}_Full_Zoom1_ML8_MassProc.txt"
		PARAMPROCESS08D="$PATH_1650/Param_files/ALOS2/PF/${MODE08D}/LaunchMTparam_ALOS2_${MODE08D}_Full_Zoom1_ML8_MassProc.txt"
		PARAMPROCESS09D="$PATH_1650/Param_files/ALOS2/PF/${MODE09D}/LaunchMTparam_ALOS2_${MODE09D}_Full_Zoom1_ML8_MassProc.txt"
		PARAMPROCESS10D="$PATH_1650/Param_files/ALOS2/PF/${MODE10D}/LaunchMTparam_ALOS2_${MODE10D}_Full_Zoom1_ML8_MassProc.txt"
		PARAMPROCESS11D="$PATH_1650/Param_files/ALOS2/PF/${MODE11D}/LaunchMTparam_ALOS2_${MODE11D}_Full_Zoom1_ML8_MassProc.txt"
		PARAMPROCESS12D="$PATH_1650/Param_files/ALOS2/PF/${MODE12D}/LaunchMTparam_ALOS2_${MODE12D}_Full_Zoom1_ML8_MassProc.txt"
		PARAMPROCESS13D="$PATH_1650/Param_files/ALOS2/PF/${MODE13D}/LaunchMTparam_ALOS2_${MODE13D}_Full_Zoom1_ML8_MassProc.txt"
		PARAMPROCESS14D="$PATH_1650/Param_files/ALOS2/PF/${MODE14D}/LaunchMTparam_ALOS2_${MODE14D}_Full_Zoom1_ML8_MassProc.txt"		

		PARAMPROCESS15D="$PATH_1650/Param_files/S1/PF_${MODE15D}/LaunchMTparam_S1_IW_Reunion_Desc_Zoom1_ML2_MassProc.txt"		

		
	# Events tables
	###############
		EVENTS="${PATH_1650}/EVENTS_TABLES/${LABEL}"

	# Path to dir where MSBAS will be computed
	###########################################
		#MSBASDIR="${PATH_3602}/MSBAS/_${LABEL}_ALOS2_Auto"
		MSBASDIR="${PATH_3602}/MSBAS/_${LABEL}_ALOS2_S1_Auto"
		
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
				# ${MSBASDIR}/DefoInterpolx2Detrendi/_EXCLUDE_PAIRS_ALTHOUGH_CRITERIA_OK.txt
				# and parameter below set to YES 
				EXCLUDE01A="NO"	# YES or NO
				EXCLUDE02A="NO"	# YES or NO
				EXCLUDE03A="NO"	# YES or NO
				EXCLUDE04A="NO"	# YES or NO
				EXCLUDE05A="NO"	# YES or NO
				EXCLUDE06A="NO"	# YES or NO
				EXCLUDE07A="NO"	# YES or NO
				EXCLUDE08A="NO"	# YES or NO
				EXCLUDE09A="NO"	# YES or NO
				EXCLUDE10A="NO"	# YES or NO
				EXCLUDE11A="NO"	# YES or NO
				EXCLUDE12A="NO"	# YES or NO
				EXCLUDE13A="NO"	# YES or NO
				
				EXCLUDE14A="NO"	# YES or NO
				
				EXCLUDE01D="NO"	# YES or NO
				EXCLUDE02D="NO"	# YES or NO
				EXCLUDE03D="NO"	# YES or NO
				EXCLUDE04D="NO"	# YES or NO
				EXCLUDE05D="NO"	# YES or NO
				EXCLUDE06D="NO"	# YES or NO
				EXCLUDE07D="NO"	# YES or NO
				EXCLUDE08D="NO"	# YES or NO
				EXCLUDE09D="NO"	# YES or NO
				EXCLUDE10D="NO"	# YES or NO
				EXCLUDE11D="NO"	# YES or NO
				EXCLUDE12D="NO"	# YES or NO
				EXCLUDE13D="NO"	# YES or NO
				EXCLUDE14D="NO"	# YES or NO
				
				EXCLUDE15D="NO"	# YES or NO

				if [ ! -s ${KMLCOH} ] ; then echo "Missing kml for coherence estimation. Please Check" ; exit ; fi
			
			else 
				EXCLUDE01A="NO"	# YES or NO
				EXCLUDE02A="NO"	# YES or NO
				EXCLUDE03A="NO"	# YES or NO
				EXCLUDE04A="NO"	# YES or NO
				EXCLUDE05A="NO"	# YES or NO
				EXCLUDE06A="NO"	# YES or NO
				EXCLUDE07A="NO"	# YES or NO
				EXCLUDE08A="NO"	# YES or NO
				EXCLUDE09A="NO"	# YES or NO
				EXCLUDE10A="NO"	# YES or NO
				EXCLUDE11A="NO"	# YES or NO
				EXCLUDE12A="NO"	# YES or NO
				EXCLUDE13A="NO"	# YES or NO
				
				EXCLUDE14A="NO"	# YES or NO
				
				EXCLUDE01D="NO"	# YES or NO
				EXCLUDE02D="NO"	# YES or NO
				EXCLUDE03D="NO"	# YES or NO
				EXCLUDE04D="NO"	# YES or NO
				EXCLUDE05D="NO"	# YES or NO
				EXCLUDE06D="NO"	# YES or NO
				EXCLUDE07D="NO"	# YES or NO
				EXCLUDE08D="NO"	# YES or NO
				EXCLUDE09D="NO"	# YES or NO
				EXCLUDE10D="NO"	# YES or NO
				EXCLUDE11D="NO"	# YES or NO
				EXCLUDE12D="NO"	# YES or NO
				EXCLUDE13D="NO"	# YES or NO
				EXCLUDE14D="NO"	# YES or NO
				
				EXCLUDE15D="NO"	# YES or NO
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
		
		# Path to dir where jpg figs of location of each pair of points are stored
#		PATHLOCA=${PATH_3602}/MSBAS/zz_insets/${LABEL}
		
	# Name of previous cron jobs for the automatic processing of that target (used to check that no other process is runing)
	#########################################################################
	CRONJOB2="PF_ALOS2_Step2_MassProc.sh"
	
# ^^^^^^^^^^ Hard coded lines ^^^^^^^^^^^^

# Prepare directories
#####################
	mkdir -p ${MSBASDIR}

	mkdir -p ${MSBASDIR}/zz_UD_EW_TS_Auto_${ORDER}_${LAMBDA}_${LABEL}
	mkdir -p ${MSBASDIR}/zz_UD_EW_TS_Auto_${ORDER}_${LAMBDA}_${LABEL}/_Time_series
	mkdir -p ${MSBASDIR}/zz_UD_EW_TS_Auto_${ORDER}_${LAMBDA}_${LABEL}/__Combi/

	mkdir -p ${MSBASDIR}/zz_LOS_TS_${MODE01A}_Auto_${ORDER}_${LAMBDA}_${LABEL}
	mkdir -p ${MSBASDIR}/zz_LOS_TS_${MODE01A}_Auto_${ORDER}_${LAMBDA}_${LABEL}/__Combi/
	mkdir -p ${MSBASDIR}/zz_LOS_TS_${MODE01A}_Auto_${ORDER}_${LAMBDA}_${LABEL}/_Time_series
	mkdir -p ${MSBASDIR}/zz_LOS_TS_${MODE02A}_Auto_${ORDER}_${LAMBDA}_${LABEL}	
	mkdir -p ${MSBASDIR}/zz_LOS_TS_${MODE02A}_Auto_${ORDER}_${LAMBDA}_${LABEL}/__Combi/
	mkdir -p ${MSBASDIR}/zz_LOS_TS_${MODE02A}_Auto_${ORDER}_${LAMBDA}_${LABEL}/_Time_series
	mkdir -p ${MSBASDIR}/zz_LOS_TS_${MODE03A}_Auto_${ORDER}_${LAMBDA}_${LABEL}
	mkdir -p ${MSBASDIR}/zz_LOS_TS_${MODE03A}_Auto_${ORDER}_${LAMBDA}_${LABEL}/__Combi/
	mkdir -p ${MSBASDIR}/zz_LOS_TS_${MODE03A}_Auto_${ORDER}_${LAMBDA}_${LABEL}/_Time_series
	mkdir -p ${MSBASDIR}/zz_LOS_TS_${MODE04A}_Auto_${ORDER}_${LAMBDA}_${LABEL}		
	mkdir -p ${MSBASDIR}/zz_LOS_TS_${MODE04A}_Auto_${ORDER}_${LAMBDA}_${LABEL}/__Combi/
	mkdir -p ${MSBASDIR}/zz_LOS_TS_${MODE04A}_Auto_${ORDER}_${LAMBDA}_${LABEL}/_Time_series
	mkdir -p ${MSBASDIR}/zz_LOS_TS_${MODE05A}_Auto_${ORDER}_${LAMBDA}_${LABEL}
	mkdir -p ${MSBASDIR}/zz_LOS_TS_${MODE05A}_Auto_${ORDER}_${LAMBDA}_${LABEL}/__Combi/
	mkdir -p ${MSBASDIR}/zz_LOS_TS_${MODE05A}_Auto_${ORDER}_${LAMBDA}_${LABEL}/_Time_series
	mkdir -p ${MSBASDIR}/zz_LOS_TS_${MODE06A}_Auto_${ORDER}_${LAMBDA}_${LABEL}
	mkdir -p ${MSBASDIR}/zz_LOS_TS_${MODE06A}_Auto_${ORDER}_${LAMBDA}_${LABEL}/__Combi/
	mkdir -p ${MSBASDIR}/zz_LOS_TS_${MODE06A}_Auto_${ORDER}_${LAMBDA}_${LABEL}/_Time_series
	mkdir -p ${MSBASDIR}/zz_LOS_TS_${MODE07A}_Auto_${ORDER}_${LAMBDA}_${LABEL}
	mkdir -p ${MSBASDIR}/zz_LOS_TS_${MODE07A}_Auto_${ORDER}_${LAMBDA}_${LABEL}/__Combi/
	mkdir -p ${MSBASDIR}/zz_LOS_TS_${MODE07A}_Auto_${ORDER}_${LAMBDA}_${LABEL}/_Time_series
	mkdir -p ${MSBASDIR}/zz_LOS_TS_${MODE08A}_Auto_${ORDER}_${LAMBDA}_${LABEL}
	mkdir -p ${MSBASDIR}/zz_LOS_TS_${MODE08A}_Auto_${ORDER}_${LAMBDA}_${LABEL}/__Combi/
	mkdir -p ${MSBASDIR}/zz_LOS_TS_${MODE08A}_Auto_${ORDER}_${LAMBDA}_${LABEL}/_Time_series
	mkdir -p ${MSBASDIR}/zz_LOS_TS_${MODE09A}_Auto_${ORDER}_${LAMBDA}_${LABEL}
	mkdir -p ${MSBASDIR}/zz_LOS_TS_${MODE09A}_Auto_${ORDER}_${LAMBDA}_${LABEL}/__Combi/
	mkdir -p ${MSBASDIR}/zz_LOS_TS_${MODE09A}_Auto_${ORDER}_${LAMBDA}_${LABEL}/_Time_series
	mkdir -p ${MSBASDIR}/zz_LOS_TS_${MODE10A}_Auto_${ORDER}_${LAMBDA}_${LABEL}
	mkdir -p ${MSBASDIR}/zz_LOS_TS_${MODE10A}_Auto_${ORDER}_${LAMBDA}_${LABEL}/__Combi/
	mkdir -p ${MSBASDIR}/zz_LOS_TS_${MODE10A}_Auto_${ORDER}_${LAMBDA}_${LABEL}/_Time_series
	mkdir -p ${MSBASDIR}/zz_LOS_TS_${MODE11A}_Auto_${ORDER}_${LAMBDA}_${LABEL}
	mkdir -p ${MSBASDIR}/zz_LOS_TS_${MODE11A}_Auto_${ORDER}_${LAMBDA}_${LABEL}/__Combi/
	mkdir -p ${MSBASDIR}/zz_LOS_TS_${MODE11A}_Auto_${ORDER}_${LAMBDA}_${LABEL}/_Time_series
	mkdir -p ${MSBASDIR}/zz_LOS_TS_${MODE12A}_Auto_${ORDER}_${LAMBDA}_${LABEL}
	mkdir -p ${MSBASDIR}/zz_LOS_TS_${MODE12A}_Auto_${ORDER}_${LAMBDA}_${LABEL}/__Combi/
	mkdir -p ${MSBASDIR}/zz_LOS_TS_${MODE12A}_Auto_${ORDER}_${LAMBDA}_${LABEL}/_Time_series
	mkdir -p ${MSBASDIR}/zz_LOS_TS_${MODE13A}_Auto_${ORDER}_${LAMBDA}_${LABEL}
	mkdir -p ${MSBASDIR}/zz_LOS_TS_${MODE13A}_Auto_${ORDER}_${LAMBDA}_${LABEL}/__Combi/
	mkdir -p ${MSBASDIR}/zz_LOS_TS_${MODE13A}_Auto_${ORDER}_${LAMBDA}_${LABEL}/_Time_series

	mkdir -p ${MSBASDIR}/zz_LOS_TS_${MODE14A}_Auto_${ORDER}_${LAMBDA}_${LABEL}
	mkdir -p ${MSBASDIR}/zz_LOS_TS_${MODE14A}_Auto_${ORDER}_${LAMBDA}_${LABEL}/__Combi/
	mkdir -p ${MSBASDIR}/zz_LOS_TS_${MODE14A}_Auto_${ORDER}_${LAMBDA}_${LABEL}/_Time_series

#	mkdir -p ${MSBASDIR}/zz_LOS_TS_AllAsc_Auto_${ORDER}_${LAMBDA}_${LABEL}
#	mkdir -p ${MSBASDIR}/zz_LOS_TS_AllAsc_Auto_${ORDER}_${LAMBDA}_${LABEL}/__Combi/
#	mkdir -p ${MSBASDIR}/zz_LOS_TS_AllAsc_Auto_${ORDER}_${LAMBDA}_${LABEL}/_Time_series

	mkdir -p ${MSBASDIR}/zz_LOS_TS_${MODE01D}_Auto_${ORDER}_${LAMBDA}_${LABEL}
	mkdir -p ${MSBASDIR}/zz_LOS_TS_${MODE01D}_Auto_${ORDER}_${LAMBDA}_${LABEL}/__Combi/
	mkdir -p ${MSBASDIR}/zz_LOS_TS_${MODE01D}_Auto_${ORDER}_${LAMBDA}_${LABEL}/_Time_series
	mkdir -p ${MSBASDIR}/zz_LOS_TS_${MODE02D}_Auto_${ORDER}_${LAMBDA}_${LABEL}	
	mkdir -p ${MSBASDIR}/zz_LOS_TS_${MODE02D}_Auto_${ORDER}_${LAMBDA}_${LABEL}/__Combi/
	mkdir -p ${MSBASDIR}/zz_LOS_TS_${MODE02D}_Auto_${ORDER}_${LAMBDA}_${LABEL}/_Time_series
	mkdir -p ${MSBASDIR}/zz_LOS_TS_${MODE03D}_Auto_${ORDER}_${LAMBDA}_${LABEL}
	mkdir -p ${MSBASDIR}/zz_LOS_TS_${MODE03D}_Auto_${ORDER}_${LAMBDA}_${LABEL}/__Combi/
	mkdir -p ${MSBASDIR}/zz_LOS_TS_${MODE03D}_Auto_${ORDER}_${LAMBDA}_${LABEL}/_Time_series
	mkdir -p ${MSBASDIR}/zz_LOS_TS_${MODE04D}_Auto_${ORDER}_${LAMBDA}_${LABEL}		
	mkdir -p ${MSBASDIR}/zz_LOS_TS_${MODE04D}_Auto_${ORDER}_${LAMBDA}_${LABEL}/__Combi/
	mkdir -p ${MSBASDIR}/zz_LOS_TS_${MODE04D}_Auto_${ORDER}_${LAMBDA}_${LABEL}/_Time_series
	mkdir -p ${MSBASDIR}/zz_LOS_TS_${MODE05D}_Auto_${ORDER}_${LAMBDA}_${LABEL}
	mkdir -p ${MSBASDIR}/zz_LOS_TS_${MODE05D}_Auto_${ORDER}_${LAMBDA}_${LABEL}/__Combi/
	mkdir -p ${MSBASDIR}/zz_LOS_TS_${MODE05D}_Auto_${ORDER}_${LAMBDA}_${LABEL}/_Time_series
	mkdir -p ${MSBASDIR}/zz_LOS_TS_${MODE06D}_Auto_${ORDER}_${LAMBDA}_${LABEL}
	mkdir -p ${MSBASDIR}/zz_LOS_TS_${MODE06D}_Auto_${ORDER}_${LAMBDA}_${LABEL}/__Combi/
	mkdir -p ${MSBASDIR}/zz_LOS_TS_${MODE06D}_Auto_${ORDER}_${LAMBDA}_${LABEL}/_Time_series
	mkdir -p ${MSBASDIR}/zz_LOS_TS_${MODE07D}_Auto_${ORDER}_${LAMBDA}_${LABEL}
	mkdir -p ${MSBASDIR}/zz_LOS_TS_${MODE07D}_Auto_${ORDER}_${LAMBDA}_${LABEL}/__Combi/
	mkdir -p ${MSBASDIR}/zz_LOS_TS_${MODE07D}_Auto_${ORDER}_${LAMBDA}_${LABEL}/_Time_series
	mkdir -p ${MSBASDIR}/zz_LOS_TS_${MODE08D}_Auto_${ORDER}_${LAMBDA}_${LABEL}
	mkdir -p ${MSBASDIR}/zz_LOS_TS_${MODE08D}_Auto_${ORDER}_${LAMBDA}_${LABEL}/__Combi/
	mkdir -p ${MSBASDIR}/zz_LOS_TS_${MODE08D}_Auto_${ORDER}_${LAMBDA}_${LABEL}/_Time_series
	mkdir -p ${MSBASDIR}/zz_LOS_TS_${MODE09D}_Auto_${ORDER}_${LAMBDA}_${LABEL}
	mkdir -p ${MSBASDIR}/zz_LOS_TS_${MODE09D}_Auto_${ORDER}_${LAMBDA}_${LABEL}/__Combi/
	mkdir -p ${MSBASDIR}/zz_LOS_TS_${MODE09D}_Auto_${ORDER}_${LAMBDA}_${LABEL}/_Time_series
	mkdir -p ${MSBASDIR}/zz_LOS_TS_${MODE10D}_Auto_${ORDER}_${LAMBDA}_${LABEL}
	mkdir -p ${MSBASDIR}/zz_LOS_TS_${MODE10D}_Auto_${ORDER}_${LAMBDA}_${LABEL}/__Combi/
	mkdir -p ${MSBASDIR}/zz_LOS_TS_${MODE10D}_Auto_${ORDER}_${LAMBDA}_${LABEL}/_Time_series
	mkdir -p ${MSBASDIR}/zz_LOS_TS_${MODE11D}_Auto_${ORDER}_${LAMBDA}_${LABEL}
	mkdir -p ${MSBASDIR}/zz_LOS_TS_${MODE11D}_Auto_${ORDER}_${LAMBDA}_${LABEL}/__Combi/
	mkdir -p ${MSBASDIR}/zz_LOS_TS_${MODE11D}_Auto_${ORDER}_${LAMBDA}_${LABEL}/_Time_series
	mkdir -p ${MSBASDIR}/zz_LOS_TS_${MODE12D}_Auto_${ORDER}_${LAMBDA}_${LABEL}
	mkdir -p ${MSBASDIR}/zz_LOS_TS_${MODE12D}_Auto_${ORDER}_${LAMBDA}_${LABEL}/__Combi/
	mkdir -p ${MSBASDIR}/zz_LOS_TS_${MODE12D}_Auto_${ORDER}_${LAMBDA}_${LABEL}/_Time_series
	mkdir -p ${MSBASDIR}/zz_LOS_TS_${MODE13D}_Auto_${ORDER}_${LAMBDA}_${LABEL}
	mkdir -p ${MSBASDIR}/zz_LOS_TS_${MODE13D}_Auto_${ORDER}_${LAMBDA}_${LABEL}/__Combi/
	mkdir -p ${MSBASDIR}/zz_LOS_TS_${MODE13D}_Auto_${ORDER}_${LAMBDA}_${LABEL}/_Time_series
	mkdir -p ${MSBASDIR}/zz_LOS_TS_${MODE14D}_Auto_${ORDER}_${LAMBDA}_${LABEL}
	mkdir -p ${MSBASDIR}/zz_LOS_TS_${MODE14D}_Auto_${ORDER}_${LAMBDA}_${LABEL}/__Combi/
	mkdir -p ${MSBASDIR}/zz_LOS_TS_${MODE14D}_Auto_${ORDER}_${LAMBDA}_${LABEL}/_Time_series

	mkdir -p ${MSBASDIR}/zz_LOS_TS_${MODE15D}_Auto_${ORDER}_${LAMBDA}_${LABEL}
	mkdir -p ${MSBASDIR}/zz_LOS_TS_${MODE15D}_Auto_${ORDER}_${LAMBDA}_${LABEL}/__Combi/
	mkdir -p ${MSBASDIR}/zz_LOS_TS_${MODE15D}_Auto_${ORDER}_${LAMBDA}_${LABEL}/_Time_series

#	mkdir -p ${MSBASDIR}/zz_LOS_TS_AllDesc_Auto_${ORDER}_${LAMBDA}_${LABEL}
#	mkdir -p ${MSBASDIR}/zz_LOS_TS_AllDesc_Auto_${ORDER}_${LAMBDA}_${LABEL}/__Combi/

	# in Coh threshold restriction
	if [ ${IFCOH} == "YES" ] ; then 
		mkdir -p ${MSBASDIR}/zz_UD_EW_TS_Auto_${ORDER}_${LAMBDA}_${LABEL}_NoCohThresh/
		mkdir -p ${MSBASDIR}/zz_UD_EW_TS_Auto_${ORDER}_${LAMBDA}_${LABEL}_NoCohThresh/__Combi/
		mkdir -p ${MSBASDIR}/zz_UD_EW_TS_Auto_${ORDER}_${LAMBDA}_${LABEL}_NoCohThresh/_Time_series
	fi
	
	cd ${MSBASDIR}

# prepare points lists
######################
	TIMESERIESPTNAME=$(basename "${TIMESERIESPTSDESCR}")
	cp -f ${TIMESERIESPTSDESCR}  ${MSBASDIR}/${TIMESERIESPTNAME}
	TIMESERIESPTSDESCR=${MSBASDIR}/${TIMESERIESPTNAME}
	#cp -f ${TIMESERIESPTSDESCR} ${MSBASDIR}/${TIMESERIESPTNAME}.tmp  #.tmp is now as the original; the original will be cut from first line (title)
	# Remove header and naming in 1st col from Pts list
	${PATHGNU}/gsed '1d' "${TIMESERIESPTSDESCR}" > ${MSBASDIR}/Cln_${TIMESERIESPTNAME}
	${PATHGNU}/gsed  -i -r 's/(\s+)?\S+//1' ${MSBASDIR}/Cln_${TIMESERIESPTNAME}
	# remove 3rd col
	#${PATHGNU}/gsed  -i -r 's/(\s+)?\S+//3' /Users/doris/PROCESS/SCRIPTS_MT/_cron_scripts/Cln_${LABEL}.txt
	TIMESERIESPTS=${MSBASDIR}/Cln_${TIMESERIESPTNAME}
	
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
				${PATH_SCRIPTS}/SCRIPTS_MT/PlotTS_all_comp.sh _Auto_${ORDER}_${LAMBDA}_${LABEL} ${X1} ${Y1} ${X2} ${Y2} -f -r -t -g  # remove -f if does not want the linear fit
			else
				${PATH_SCRIPTS}/SCRIPTS_MT/PlotTS_all_comp.sh _Auto_${ORDER}_${LAMBDA}_${LABEL} ${X1} ${Y1} ${X2} ${Y2} -f -r -t -g -events=${EVENTS}  # remove -f if does not want the linear fit			
		fi
		OLL=${ORDER}_${LAMBDA}_${LABEL}
		COORDLABELNAME1=${X1}_${Y1}_Auto_${ORDER}_${LAMBDA}_${LABEL}
		COORDLABELNAME2=${X2}_${Y2}_Auto_${ORDER}_${LAMBDA}_${LABEL}
        COORDLABELNAME12=${X1}_${Y1}_${X2}_${Y2}_Auto_${ORDER}_${LAMBDA}_${LABEL}		
		
		mv ${MSBASDIR}/timeLines_${COORDLABELNAME1}.eps ${MSBASDIR}/zz_UD_EW_TS_Auto_${OLL}/${DESCRIPTION}_timeLines_${COORDLABELNAME1}.eps 2>/dev/null
		mv ${MSBASDIR}/timeLines_${COORDLABELNAME2}.eps ${MSBASDIR}/zz_UD_EW_TS_Auto_${OLL}/${DESCRIPTION}_timeLines_${COORDLABELNAME2}.eps 2>/dev/null

		mv ${MSBASDIR}/timeLines_${COORDLABELNAME12}.eps ${MSBASDIR}/zz_UD_EW_TS_Auto_${OLL}/${DESCRIPTION}_timeLines_${COORDLABELNAME12}.eps 2>/dev/null
	
#		# add map tag in fig
#		convert -density 300 -rotate 90 -trim ${MSBASDIR}/zz_UD_EW_TS_Auto_${ORDER}_${LAMBDA}_${LABEL}/${DESCRIPTION}_timeLines_${X1}_${Y1}_${X2}_${Y2}_Auto_${ORDER}_${LAMBDA}_${LABEL}.eps ${MSBASDIR}/zz_UD_EW_TS_Auto_${ORDER}_${LAMBDA}_${LABEL}/${DESCRIPTION}_timeLines_${X1}_${Y1}_${X2}_${Y2}_Auto_${ORDER}_${LAMBDA}_${LABEL}.jpg
#		convert ${MSBASDIR}/zz_UD_EW_TS_Auto_${ORDER}_${LAMBDA}_${LABEL}/${DESCRIPTION}_timeLines_${X1}_${Y1}_${X2}_${Y2}_Auto_${ORDER}_${LAMBDA}_${LABEL}.jpg ${PATHLOCA}/Loca_${X1}_${Y1}_${X2}_${Y2}.jpg -gravity northwest -geometry +250+150 -composite ${MSBASDIR}/zz_UD_EW_TS_Auto_${ORDER}_${LAMBDA}_${LABEL}/${DESCRIPTION}_timeLines_${X1}_${Y1}_${X2}_${Y2}_Auto_${ORDER}_${LAMBDA}_${LABEL}_Combi.jpg

        rm -f ${MSBASDIR}/zz_UD_EW_TS_Auto_${OLL}/${DESCRIPTION}_timeLines_${COORDLABELNAME12}_Combi.jpg
		mv ${MSBASDIR}/timeLines_${COORDLABELNAME12}_Combi.jpg ${MSBASDIR}/zz_UD_EW_TS_Auto_${OLL}/${DESCRIPTION}_timeLines_${COORDLABELNAME12}_Combi.jpg 2>/dev/null
		
		mv ${MSBASDIR}/timeLine_UD_${COORDLABELNAME12}.txt ${MSBASDIR}/zz_UD_EW_TS_Auto_${OLL}/${DESCRIPTION}_timeLines_UD_${COORDLABELNAME12}.txt 2>/dev/null
		mv ${MSBASDIR}/timeLine_EW_${COORDLABELNAME12}.txt ${MSBASDIR}/zz_UD_EW_TS_Auto_${OLL}/${DESCRIPTION}_timeLines_EW_${COORDLABELNAME12}.txt 2>/dev/null
	
#		rm -f ${MSBASDIR}/zz_UD_EW_TS_Auto_${ORDER}_${LAMBDA}_${LABEL}/${DESCRIPTION}_timeLines_${X1}_${Y1}_${X2}_${Y2}_Auto_${ORDER}_${LAMBDA}_${LABEL}.jpg
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
				${PATH_SCRIPTS}/SCRIPTS_MT/PlotTS_all_comp.sh _Auto_${ORDER}_${LAMBDA}_${LABEL}_NoCohThresh ${X1} ${Y1} ${X2} ${Y2} -f -r -t -g   # remove -f if does not want the linear fit etc..
			else
				${PATH_SCRIPTS}/SCRIPTS_MT/PlotTS_all_comp.sh _Auto_${ORDER}_${LAMBDA}_${LABEL}_NoCohThresh ${X1} ${Y1} ${X2} ${Y2} -f -r -t -g -events=${EVENTS}  # remove -f if does not want the linear fit etc..		
		fi
	
#		rm plotTS*.gnu timeLines_*.png 
		OLL=${ORDER}_${LAMBDA}_${LABEL}
		COORDLABELNAME1=${X1}_${Y1}_Auto_${ORDER}_${LAMBDA}_${LABEL}
		COORDLABELNAME2=${X2}_${Y2}_Auto_${ORDER}_${LAMBDA}_${LABEL}
        COORDLABELNAME12=${X1}_${Y1}_${X2}_${Y2}_Auto_${ORDER}_${LAMBDA}_${LABEL}		
	
		if [ -f "${MSBASDIR}/timeLines_${COORDLABELNAME1}_NoCohThresh.eps" ] && [ -s "${MSBASDIR}/timeLines_${COORDLABELNAME1}_NoCohThresh.eps" ] ; then 
			mv ${MSBASDIR}/timeLines_${COORDLABELNAME1}_NoCohThresh.eps ${MSBASDIR}/zz_UD_EW_TS_Auto_${OLL}_NoCohThresh/${DESCRIPTION}_timeLines_${COORDLABELNAME1}_NoCohThresh.eps
		fi
		if [ -f "${MSBASDIR}/timeLines_$COORDLABELNAME2}_NoCohThresh.eps" ] && [ -s "${MSBASDIR}/timeLines_$COORDLABELNAME2}_NoCohThresh.eps" ] ; then
			mv ${MSBASDIR}/timeLines_${COORDLABELNAME2}_NoCohThresh.eps ${MSBASDIR}/zz_UD_EW_TS_Auto_${OLL}_NoCohThresh/${DESCRIPTION}_timeLines_${COORDLABELNAME2}_NoCohThresh.eps
		fi 
 
		if [ -f "${MSBASDIR}/timeLines_${COORDLABELNAME12}_NoCohThresh.eps" ] && [ -s "${MSBASDIR}/timeLines_${COORDLABELNAME12}_NoCohThresh.eps" ] ; then
			mv ${MSBASDIR}/timeLines_${COORDLABELNAME12}_NoCohThresh.eps ${MSBASDIR}/zz_UD_EW_TS_Auto_${OLL}_NoCohThresh/${DESCRIPTION}_timeLines_${COORDLABELNAME12}_NoCohThresh.eps 

#			# add map tag in fig
#			convert -density 300 -rotate 90 -trim ${MSBASDIR}/zz_UD_EW_TS_Auto_${ORDER}_${LAMBDA}_${LABEL}_NoCohThresh/${DESCRIPTION}_timeLines_${X1}_${Y1}_${X2}_${Y2}_Auto_${ORDER}_${LAMBDA}_${LABEL}_NoCohThresh.eps ${MSBASDIR}/zz_UD_EW_TS_Auto_${ORDER}_${LAMBDA}_${LABEL}_NoCohThresh/${DESCRIPTION}_timeLines_${X1}_${Y1}_${X2}_${Y2}_Auto_${ORDER}_${LAMBDA}_${LABEL}_NoCohThresh.jpg
#			# get location from dir with coh threshold (where it was added manually)
#			convert ${MSBASDIR}/zz_UD_EW_TS_Auto_${ORDER}_${LAMBDA}_${LABEL}_NoCohThresh/${DESCRIPTION}_timeLines_${X1}_${Y1}_${X2}_${Y2}_Auto_${ORDER}_${LAMBDA}_${LABEL}_NoCohThresh.jpg ${PATHLOCA}/Loca_${X1}_${Y1}_${X2}_${Y2}.jpg -gravity northwest -geometry +250+150 -composite ${MSBASDIR}/zz_UD_EW_TS_Auto_${ORDER}_${LAMBDA}_${LABEL}_NoCohThresh/${DESCRIPTION}_timeLines_${X1}_${Y1}_${X2}_${Y2}_Auto_${ORDER}_${LAMBDA}_${LABEL}_Combi_NoCohThresh.jpg

            rm -f ${MSBASDIR}/zz_UD_EW_TS_Auto_${OLL}_NoCohThresh/${DESCRIPTION}_timeLines_${COORDLABELNAME12}_NoCohThresh_Combi.jpg
			mv ${MSBASDIR}/timeLines_${COORDLABELNAME12}_NoCohThresh_Combi.jpg ${MSBASDIR}/zz_UD_EW_TS_Auto_${OLL}_NoCohThresh/${DESCRIPTION}_timeLines_${COORDLABELNAME12}_NoCohThresh_Combi.jpg

			mv ${MSBASDIR}/timeLine_UD_${COORDLABELNAME12}_NoCohThresh.txt ${MSBASDIR}/zz_UD_EW_TS_Auto_${OLL}_NoCohThresh/${DESCRIPTION}_timeLines_UD_${COORDLABELNAME12}_NoCohThresh.txt
			mv ${MSBASDIR}/timeLine_EW_${COORDLABELNAME12}_NoCohThresh.txt ${MSBASDIR}/zz_UD_EW_TS_Auto_${OLL}_NoCohThresh/${DESCRIPTION}_timeLines_EW_${COORDLABELNAME12}_NoCohThresh.txt
		fi
	
#		rm -f ${MSBASDIR}/zz_UD_EW_TS_Auto_${ORDER}_${LAMBDA}_${LABEL}_NoCohThresh/${DESCRIPTION}_timeLines_${X1}_${Y1}_${X2}_${Y2}_Auto_${ORDER}_${LAMBDA}_${LABEL}_NoCohThresh.jpg
		}

	function PlotAllLOS()
		{
		unset X1 Y1 X2 Y2 DESCRIPTION 
		local X1=$1
		local Y1=$2
		local X2=$3
		local Y2=$4
		local DESCRIPTION=$5
	
		cd ${MSBASDIR}/zz_LOS_${MODE}_Auto_${ORDER}_${LAMBDA}_${LABEL}/
		mkdir -p ${MSBASDIR}/zz_LOS_TS_${MODE}_Auto_${ORDER}_${LAMBDA}_${LABEL}/_Time_series

		if [ "${EVENTS}" == "" ]
			then
				${PATH_SCRIPTS}/SCRIPTS_MT/PlotTS.sh ${X1} ${Y1} ${X2} ${Y2} -f -r -t -g # remove -f if does not want the linear fit
			else
				${PATH_SCRIPTS}/SCRIPTS_MT/PlotTS.sh ${X1} ${Y1} ${X2} ${Y2} -f -r -t -g -events=${EVENTS}  # remove -f if does not want the linear fit etc..		
		fi
	
#		rm plotTS*.gnu timeLine*.png 
		OLL=${ORDER}_${LAMBDA}_${LABEL}
		COORDLABELNAME1=${X1}_${Y1}_Auto_${ORDER}_${LAMBDA}_${LABEL}
		COORDLABELNAME2=${X2}_${Y2}_Auto_${ORDER}_${LAMBDA}_${LABEL}
        COORDLABELNAME12=${X1}_${Y1}_${X2}_${Y2}_Auto_${ORDER}_${LAMBDA}_${LABEL}		

		mv ${MSBASDIR}/zz_LOS_${MODE}_Auto_${OLL}/timeLine${X1}_${Y1}.eps ${MSBASDIR}/zz_LOS_TS_${MODE}_Auto_${OLL}/${DESCRIPTION}_timeLine_${COORDLABELNAME1}.eps 2>/dev/null
		mv ${MSBASDIR}/zz_LOS_${MODE}_Auto_${OLL}/timeLine${X2}_${Y2}.eps ${MSBASDIR}/zz_LOS_TS_${MODE}_Auto_${OLL}/${DESCRIPTION}_timeLine_${COORDLABELNAME2}.eps 2>/dev/null
		mv ${MSBASDIR}/zz_LOS_${MODE}_Auto_${OLL}/timeLine${X1}_${Y1}_${X2}_${Y2}.eps ${MSBASDIR}/zz_LOS_TS_${MODE}_Auto_${OLL}/${DESCRIPTION}_timeLine_${COORDLABELNAME12}.eps 2>/dev/null

		mv ${MSBASDIR}/zz_LOS_${MODE}_Auto_${OLL}/timeLine${X1}_${Y1}.txt ${MSBASDIR}/zz_LOS_TS_${MODE}_Auto_${OLL}/_Time_series/ 2>/dev/null
		mv ${MSBASDIR}/zz_LOS_${MODE}_Auto_${OLL}/timeLine${X2}_${Y2}.txt ${MSBASDIR}/zz_LOS_TS_${MODE}_Auto_${OLL}/_Time_series/ 2>/dev/null
		mv ${MSBASDIR}/zz_LOS_${MODE}_Auto_${OLL}/timeLine${X1}_${Y1}_${X2}_${Y2}.txt ${MSBASDIR}/zz_LOS_TS_${MODE}_Auto_${OLL}/_Time_series/ 2>/dev/null
	
#		# add map tag in fig
#		convert -density 300 -rotate 90 -trim ${MSBASDIR}/zz_LOS_TS_${MODE}_Auto_${ORDER}_${LAMBDA}_${LABEL}/${DESCRIPTION}_timeLine_${X1}_${Y1}_${X2}_${Y2}_Auto_${ORDER}_${LAMBDA}_${LABEL}.eps ${MSBASDIR}/zz_LOS_TS_${MODE}_Auto_${ORDER}_${LAMBDA}_${LABEL}/${DESCRIPTION}_timeLine_${X1}_${Y1}_${X2}_${Y2}_Auto_${ORDER}_${LAMBDA}_${LABEL}.jpg
#		convert ${MSBASDIR}/zz_LOS_TS_${MODE}_Auto_${ORDER}_${LAMBDA}_${LABEL}/${DESCRIPTION}_timeLine_${X1}_${Y1}_${X2}_${Y2}_Auto_${ORDER}_${LAMBDA}_${LABEL}.jpg ${PATHLOCA}/Loca_${X1}_${Y1}_${X2}_${Y2}.jpg -gravity northwest -geometry +250+150 -composite ${MSBASDIR}/zz_LOS_TS_${MODE}_Auto_${ORDER}_${LAMBDA}_${LABEL}/${DESCRIPTION}_timeLine_${X1}_${Y1}_${X2}_${Y2}_Auto_${ORDER}_${LAMBDA}_${LABEL}_Combi_${MODE}.jpg

        rm -f ${MSBASDIR}/zz_LOS_TS_${MODE}_Auto_${OLL}/${DESCRIPTION}_timeLine_${COORDLABELNAME12}_Combi_${MODE}.jpg
		mv ${MSBASDIR}/zz_LOS_${MODE}_Auto_${OLL}/timeLine${X1}_${Y1}_${X2}_${Y2}_Combi.jpg ${MSBASDIR}/zz_LOS_TS_${MODE}_Auto_${OLL}/${DESCRIPTION}_timeLine_${COORDLABELNAME12}_Combi_${MODE}.jpg 2>/dev/null

		#mv ${MSBASDIR}/timeLine_UD_${X1}_${Y1}_${X2}_${Y2}_Auto_${ORDER}_${LAMBDA}_${LABEL}.txt ${MSBASDIR}/zz_UD_EW_TS_Auto_${ORDER}_${LAMBDA}_${LABEL}/${DESCRIPTION}_timeLines_UD_${X1}_${Y1}_${X2}_${Y2}_Auto_${ORDER}_${LAMBDA}_${LABEL}.txt
		#mv ${MSBASDIR}/timeLine_EW_${X1}_${Y1}_${X2}_${Y2}_Auto_${ORDER}_${LAMBDA}_${LABEL}.txt ${MSBASDIR}/zz_UD_EW_TS_Auto_${ORDER}_${LAMBDA}_${LABEL}/${DESCRIPTION}_timeLines_EW_${X1}_${Y1}_${X2}_${Y2}_Auto_${ORDER}_${LAMBDA}_${LABEL}.txt
	
#		rm -f ${MSBASDIR}/zz_LOS_TS_${MODE}_Auto_${ORDER}_${LAMBDA}_${LABEL}/${DESCRIPTION}_timeLine_${X1}_${Y1}_${X2}_${Y2}_Auto_${ORDER}_${LAMBDA}_${LABEL}.jpg

		}

	function MSBASmode()
		{
		unset MODE # e.g. 6811_L_A ...
		local MODE=$1
		
		echo ""
		echo "// Processing ${MODE}"
		echo "/////////////////////"
		cd ${MSBASDIR}
		cp -f ${MSBASDIR}/header_${MODE}.txt  header.txt 
		${PATH_SCRIPTS}/SCRIPTS_MT/MSBAS.sh _${MODE}_Auto_${ORDER}_${LAMBDA}_${LABEL} ${TIMESERIESPTS}

		cp ${TIMESERIESPTSDESCR} ${MSBASDIR}/zz_LOS_TS_${MODE}_Auto_${ORDER}_${LAMBDA}_${LABEL}/
		# remove header line to avoid error message 
		#TIMESERIESPTSDESCRNOHEADER=`tail -n +2 ${TIMESERIESPTSDESCR}`
		while read -r DESCR X Y RX RY
			do	
				echo "Rename time series of ${X}_${Y} as ${X}_${Y}_${RX}_${RY}_${DESCR}"
				mv ${MSBASDIR}/zz_LOS_TS_${MODE}_Auto_${ORDER}_${LAMBDA}_${LABEL}/MSBAS_${X}_${Y}_${RX}_${RY}.txt ${MSBASDIR}/zz_LOS_TS_${MODE}_Auto_${ORDER}_${LAMBDA}_${LABEL}/MSBAS_${X}_${Y}_${RX}_${RY}_${DESCR}.txt
				# there is no automatic plotting by msbas when only in LOS 
		done < ${TIMESERIESPTSDESCR} | tail -n +2  # ignore header
 
		# Why not some double difference plotting
		while read -r X1 Y1 X2 Y2 DESCR
			do	
				PlotAllLOS ${X1} ${Y1} ${X2} ${Y2} ${DESCR} ${MODE}
		done < ${FILEPAIRS}						
	
		# move all plots in same dir 

		OLL=${ORDER}_${LAMBDA}_${LABEL}
		
		rm -f ${MSBASDIR}/zz_LOS_TS_${MODE}_Auto_${OLL}/__Combi/*.jpg
		mv ${MSBASDIR}/zz_LOS_TS_${MODE}_Auto_${OLL}/*_Combi*.jpg ${MSBASDIR}/zz_LOS_TS_${MODE}_Auto_${OLL}/__Combi/

		# move all time series in dir 
		#mv ${MSBASDIR}/zz_LOS_TS_${MODE}_Auto_${ORDER}_${LAMBDA}_${LABEL}/*.txt ${MSBASDIR}/zz_LOS_TS_${MODE}_Auto_${ORDER}_${LAMBDA}_${LABEL}/_Time_series/
		}


# Check that there is no other cron (Step 2 or 3) or manuam SuperMaster_MassProc.sh running
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
			echo "MSBAS attempt aborted on ${TODAY} because ${REASON}" >>  ${MSBASDIR}/_last_MSBAS_process.txt
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
		cd ${MASSDIR}
		Remove_Duplicate_Pairs_File_All_Modes_But_Ampl.sh
		}
		
	RemoveDuplic ${MASSPROCDIR01A} &
	RemoveDuplic ${MASSPROCDIR02A} &
	RemoveDuplic ${MASSPROCDIR03A} &
	RemoveDuplic ${MASSPROCDIR04A} &
	RemoveDuplic ${MASSPROCDIR05A} &
	RemoveDuplic ${MASSPROCDIR06A} &
	RemoveDuplic ${MASSPROCDIR07A} &
	wait
	RemoveDuplic ${MASSPROCDIR08A} &
	RemoveDuplic ${MASSPROCDIR09A} &
	RemoveDuplic ${MASSPROCDIR10A} &
	RemoveDuplic ${MASSPROCDIR11A} &
	RemoveDuplic ${MASSPROCDIR12A} &
	RemoveDuplic ${MASSPROCDIR13A} &
	RemoveDuplic ${MASSPROCDIR14A} &
	wait
	RemoveDuplic ${MASSPROCDIR01D} &
	RemoveDuplic ${MASSPROCDIR02D} &
	RemoveDuplic ${MASSPROCDIR03D} &
	RemoveDuplic ${MASSPROCDIR04D} &
	RemoveDuplic ${MASSPROCDIR05D} &
	RemoveDuplic ${MASSPROCDIR06D} &
	RemoveDuplic ${MASSPROCDIR07D} &
	wait
	RemoveDuplic ${MASSPROCDIR08D} &
	RemoveDuplic ${MASSPROCDIR09D} &
	RemoveDuplic ${MASSPROCDIR10D} &
	RemoveDuplic ${MASSPROCDIR11D} &
	RemoveDuplic ${MASSPROCDIR12D} &
	RemoveDuplic ${MASSPROCDIR13D} &
	RemoveDuplic ${MASSPROCDIR14D} &
	RemoveDuplic ${MASSPROCDIR15D} &
	wait
	
# Get date (in sec) of last available processed pairs in each MODE
##################################################################
	# get the name of last available processed pair in each MODE
	LAST01A=`find ${MASSPROCDIR01A}/Geocoded/DefoInterpolx2Detrend/ -maxdepth 1 -type f -name "*deg" -printf "%T+ %p\n" | sort -r | head -1 | ${PATHGNU}/gawk '{print $2}'`
	LAST02A=`find ${MASSPROCDIR02A}/Geocoded/DefoInterpolx2Detrend/ -maxdepth 1 -type f -name "*deg" -printf "%T+ %p\n" | sort -r | head -1 | ${PATHGNU}/gawk '{print $2}'`
	LAST03A=`find ${MASSPROCDIR03A}/Geocoded/DefoInterpolx2Detrend/ -maxdepth 1 -type f -name "*deg" -printf "%T+ %p\n" | sort -r | head -1 | ${PATHGNU}/gawk '{print $2}'`
	LAST04A=`find ${MASSPROCDIR04A}/Geocoded/DefoInterpolx2Detrend/ -maxdepth 1 -type f -name "*deg" -printf "%T+ %p\n" | sort -r | head -1 | ${PATHGNU}/gawk '{print $2}'`
	LAST05A=`find ${MASSPROCDIR05A}/Geocoded/DefoInterpolx2Detrend/ -maxdepth 1 -type f -name "*deg" -printf "%T+ %p\n" | sort -r | head -1 | ${PATHGNU}/gawk '{print $2}'`
	LAST06A=`find ${MASSPROCDIR06A}/Geocoded/DefoInterpolx2Detrend/ -maxdepth 1 -type f -name "*deg" -printf "%T+ %p\n" | sort -r | head -1 | ${PATHGNU}/gawk '{print $2}'`
	LAST07A=`find ${MASSPROCDIR07A}/Geocoded/DefoInterpolx2Detrend/ -maxdepth 1 -type f -name "*deg" -printf "%T+ %p\n" | sort -r | head -1 | ${PATHGNU}/gawk '{print $2}'`
	LAST08A=`find ${MASSPROCDIR08A}/Geocoded/DefoInterpolx2Detrend/ -maxdepth 1 -type f -name "*deg" -printf "%T+ %p\n" | sort -r | head -1 | ${PATHGNU}/gawk '{print $2}'`
	LAST09A=`find ${MASSPROCDIR09A}/Geocoded/DefoInterpolx2Detrend/ -maxdepth 1 -type f -name "*deg" -printf "%T+ %p\n" | sort -r | head -1 | ${PATHGNU}/gawk '{print $2}'`
	LAST10A=`find ${MASSPROCDIR10A}/Geocoded/DefoInterpolx2Detrend/ -maxdepth 1 -type f -name "*deg" -printf "%T+ %p\n" | sort -r | head -1 | ${PATHGNU}/gawk '{print $2}'`
	LAST11A=`find ${MASSPROCDIR11A}/Geocoded/DefoInterpolx2Detrend/ -maxdepth 1 -type f -name "*deg" -printf "%T+ %p\n" | sort -r | head -1 | ${PATHGNU}/gawk '{print $2}'`
	LAST12A=`find ${MASSPROCDIR12A}/Geocoded/DefoInterpolx2Detrend/ -maxdepth 1 -type f -name "*deg" -printf "%T+ %p\n" | sort -r | head -1 | ${PATHGNU}/gawk '{print $2}'`
	LAST13A=`find ${MASSPROCDIR13A}/Geocoded/DefoInterpolx2Detrend/ -maxdepth 1 -type f -name "*deg" -printf "%T+ %p\n" | sort -r | head -1 | ${PATHGNU}/gawk '{print $2}'`

	LAST14A=`find ${MASSPROCDIR14A}/Geocoded/DefoInterpolx2Detrend/ -maxdepth 1 -type f -name "*deg" -printf "%T+ %p\n" | sort -r | head -1 | ${PATHGNU}/gawk '{print $2}'`


	LAST01D=`find ${MASSPROCDIR01D}/Geocoded/DefoInterpolx2Detrend/ -maxdepth 1 -type f -name "*deg" -printf "%T+ %p\n" | sort -r | head -1 | ${PATHGNU}/gawk '{print $2}'`
	LAST02D=`find ${MASSPROCDIR02D}/Geocoded/DefoInterpolx2Detrend/ -maxdepth 1 -type f -name "*deg" -printf "%T+ %p\n" | sort -r | head -1 | ${PATHGNU}/gawk '{print $2}'`
	LAST03D=`find ${MASSPROCDIR03D}/Geocoded/DefoInterpolx2Detrend/ -maxdepth 1 -type f -name "*deg" -printf "%T+ %p\n" | sort -r | head -1 | ${PATHGNU}/gawk '{print $2}'`
	LAST04D=`find ${MASSPROCDIR04D}/Geocoded/DefoInterpolx2Detrend/ -maxdepth 1 -type f -name "*deg" -printf "%T+ %p\n" | sort -r | head -1 | ${PATHGNU}/gawk '{print $2}'`
	LAST05D=`find ${MASSPROCDIR05D}/Geocoded/DefoInterpolx2Detrend/ -maxdepth 1 -type f -name "*deg" -printf "%T+ %p\n" | sort -r | head -1 | ${PATHGNU}/gawk '{print $2}'`
	LAST06D=`find ${MASSPROCDIR06D}/Geocoded/DefoInterpolx2Detrend/ -maxdepth 1 -type f -name "*deg" -printf "%T+ %p\n" | sort -r | head -1 | ${PATHGNU}/gawk '{print $2}'`
	LAST07D=`find ${MASSPROCDIR07D}/Geocoded/DefoInterpolx2Detrend/ -maxdepth 1 -type f -name "*deg" -printf "%T+ %p\n" | sort -r | head -1 | ${PATHGNU}/gawk '{print $2}'`
	LAST08D=`find ${MASSPROCDIR08D}/Geocoded/DefoInterpolx2Detrend/ -maxdepth 1 -type f -name "*deg" -printf "%T+ %p\n" | sort -r | head -1 | ${PATHGNU}/gawk '{print $2}'`
	LAST09D=`find ${MASSPROCDIR09D}/Geocoded/DefoInterpolx2Detrend/ -maxdepth 1 -type f -name "*deg" -printf "%T+ %p\n" | sort -r | head -1 | ${PATHGNU}/gawk '{print $2}'`
	LAST10D=`find ${MASSPROCDIR10D}/Geocoded/DefoInterpolx2Detrend/ -maxdepth 1 -type f -name "*deg" -printf "%T+ %p\n" | sort -r | head -1 | ${PATHGNU}/gawk '{print $2}'`
	LAST11D=`find ${MASSPROCDIR11D}/Geocoded/DefoInterpolx2Detrend/ -maxdepth 1 -type f -name "*deg" -printf "%T+ %p\n" | sort -r | head -1 | ${PATHGNU}/gawk '{print $2}'`
	LAST12D=`find ${MASSPROCDIR12D}/Geocoded/DefoInterpolx2Detrend/ -maxdepth 1 -type f -name "*deg" -printf "%T+ %p\n" | sort -r | head -1 | ${PATHGNU}/gawk '{print $2}'`
	LAST13D=`find ${MASSPROCDIR13D}/Geocoded/DefoInterpolx2Detrend/ -maxdepth 1 -type f -name "*deg" -printf "%T+ %p\n" | sort -r | head -1 | ${PATHGNU}/gawk '{print $2}'`
	LAST14D=`find ${MASSPROCDIR14D}/Geocoded/DefoInterpolx2Detrend/ -maxdepth 1 -type f -name "*deg" -printf "%T+ %p\n" | sort -r | head -1 | ${PATHGNU}/gawk '{print $2}'`

	LAST15D=`find ${MASSPROCDIR15D}/Geocoded/DefoInterpolx2Detrend/ -maxdepth 1 -type f -name "*deg" -printf "%T+ %p\n" | sort -r | head -1 | ${PATHGNU}/gawk '{print $2}'`

	# get date in sec of last available processed pairs in each MODE
	LAST01ATIME=`stat -c %Y ${LAST01A}`
	LAST02ATIME=`stat -c %Y ${LAST02A}`
	LAST03ATIME=`stat -c %Y ${LAST03A}`
	LAST04ATIME=`stat -c %Y ${LAST04A}`
	LAST05ATIME=`stat -c %Y ${LAST05A}`
	LAST06ATIME=`stat -c %Y ${LAST06A}`
	LAST07ATIME=`stat -c %Y ${LAST07A}`
	LAST08ATIME=`stat -c %Y ${LAST08A}`
	LAST09ATIME=`stat -c %Y ${LAST09A}`
	LAST10ATIME=`stat -c %Y ${LAST10A}`
	LAST11ATIME=`stat -c %Y ${LAST11A}`
	LAST12ATIME=`stat -c %Y ${LAST12A}`
	LAST13ATIME=`stat -c %Y ${LAST13A}`	

	LAST14ATIME=`stat -c %Y ${LAST14A}`	

	LAST01DTIME=`stat -c %Y ${LAST01D}`
	LAST02DTIME=`stat -c %Y ${LAST02D}`
	LAST03DTIME=`stat -c %Y ${LAST03D}`
	LAST04DTIME=`stat -c %Y ${LAST04D}`
	LAST05DTIME=`stat -c %Y ${LAST05D}`
	LAST06DTIME=`stat -c %Y ${LAST06D}`
	LAST07DTIME=`stat -c %Y ${LAST07D}`
	LAST08DTIME=`stat -c %Y ${LAST08D}`
	LAST09DTIME=`stat -c %Y ${LAST09D}`
	LAST10DTIME=`stat -c %Y ${LAST10D}`
	LAST11DTIME=`stat -c %Y ${LAST11D}`
	LAST12DTIME=`stat -c %Y ${LAST12D}`
	LAST13DTIME=`stat -c %Y ${LAST13D}`
	LAST14DTIME=`stat -c %Y ${LAST14D}`

	LAST15DTIME=`stat -c %Y ${LAST15D}`


# Check if first run and if  appropriate, get time of last images in time series
################################################################################
	if [ -f "${MSBASDIR}/_Last_MassProcessed_Pairs_Time.txt" ] && [ -s "${MSBASDIR}/_Last_MassProcessed_Pairs_Time.txt" ] 
		then   
			echo "Existing ${MSBASDIR}/_Last_MassProcessed_Pairs_Time.txt, hence not the first run"
			FIRSTRUN=NO
			FORMERLAST01ATIME=`head -1 ${MSBASDIR}/_Last_MassProcessed_Pairs_Time.txt`
			FORMERLAST02ATIME=`head -2 ${MSBASDIR}/_Last_MassProcessed_Pairs_Time.txt | tail -1`
			FORMERLAST03ATIME=`head -3 ${MSBASDIR}/_Last_MassProcessed_Pairs_Time.txt | tail -1`
			FORMERLAST04ATIME=`head -4 ${MSBASDIR}/_Last_MassProcessed_Pairs_Time.txt | tail -1`
			FORMERLAST05ATIME=`head -5 ${MSBASDIR}/_Last_MassProcessed_Pairs_Time.txt | tail -1`
			FORMERLAST06ATIME=`head -6 ${MSBASDIR}/_Last_MassProcessed_Pairs_Time.txt | tail -1`
			FORMERLAST07ATIME=`head -7 ${MSBASDIR}/_Last_MassProcessed_Pairs_Time.txt | tail -1`
			FORMERLAST08ATIME=`head -8 ${MSBASDIR}/_Last_MassProcessed_Pairs_Time.txt | tail -1`
			FORMERLAST09ATIME=`head -9 ${MSBASDIR}/_Last_MassProcessed_Pairs_Time.txt | tail -1`
			FORMERLAST10ATIME=`head -10 ${MSBASDIR}/_Last_MassProcessed_Pairs_Time.txt | tail -1`
			FORMERLAST11ATIME=`head -11 ${MSBASDIR}/_Last_MassProcessed_Pairs_Time.txt | tail -1`
			FORMERLAST12ATIME=`head -12 ${MSBASDIR}/_Last_MassProcessed_Pairs_Time.txt | tail -1`
			FORMERLAST13ATIME=`head -13 ${MSBASDIR}/_Last_MassProcessed_Pairs_Time.txt | tail -1`

			FORMERLAST01DTIME=`head -14 ${MSBASDIR}/_Last_MassProcessed_Pairs_Time.txt | tail -1`
			FORMERLAST02DTIME=`head -15 ${MSBASDIR}/_Last_MassProcessed_Pairs_Time.txt | tail -1`
			FORMERLAST03DTIME=`head -16 ${MSBASDIR}/_Last_MassProcessed_Pairs_Time.txt | tail -1`
			FORMERLAST04DTIME=`head -17 ${MSBASDIR}/_Last_MassProcessed_Pairs_Time.txt | tail -1`
			FORMERLAST05DTIME=`head -18 ${MSBASDIR}/_Last_MassProcessed_Pairs_Time.txt | tail -1`
			FORMERLAST06DTIME=`head -19 ${MSBASDIR}/_Last_MassProcessed_Pairs_Time.txt | tail -1`
			FORMERLAST07DTIME=`head -20 ${MSBASDIR}/_Last_MassProcessed_Pairs_Time.txt | tail -1`
			FORMERLAST08DTIME=`head -21 ${MSBASDIR}/_Last_MassProcessed_Pairs_Time.txt | tail -1`
			FORMERLAST09DTIME=`head -22 ${MSBASDIR}/_Last_MassProcessed_Pairs_Time.txt | tail -1`
			FORMERLAST10DTIME=`head -23 ${MSBASDIR}/_Last_MassProcessed_Pairs_Time.txt | tail -1`
			FORMERLAST11DTIME=`head -24 ${MSBASDIR}/_Last_MassProcessed_Pairs_Time.txt | tail -1`
			FORMERLAST12DTIME=`head -25 ${MSBASDIR}/_Last_MassProcessed_Pairs_Time.txt | tail -1`
			FORMERLAST13DTIME=`head -26 ${MSBASDIR}/_Last_MassProcessed_Pairs_Time.txt | tail -1`
			#FORMERLAST14DTIME=`tail -1 ${MSBASDIR}/_Last_MassProcessed_Pairs_Time.txt`
			FORMERLAST14DTIME=`head -27 ${MSBASDIR}/_Last_MassProcessed_Pairs_Time.txt | tail -1`
			
			FORMERLAST14ATIME=`head -28 ${MSBASDIR}/_Last_MassProcessed_Pairs_Time.txt | tail -1`		# add S1 at the end 
			FORMERLAST15DTIME=`tail -1 ${MSBASDIR}/_Last_MassProcessed_Pairs_Time.txt`

			
			if 	[ ${FORMERLAST01ATIME} -eq ${LAST01ATIME} ] && \
				[ ${FORMERLAST02ATIME} -eq ${LAST02ATIME} ] && \
				[ ${FORMERLAST03ATIME} -eq ${LAST03ATIME} ] && \
				[ ${FORMERLAST04ATIME} -eq ${LAST04ATIME} ] && \
				[ ${FORMERLAST05ATIME} -eq ${LAST05ATIME} ] && \
				[ ${FORMERLAST06ATIME} -eq ${LAST06ATIME} ] && \
				[ ${FORMERLAST07ATIME} -eq ${LAST07ATIME} ] && \
				[ ${FORMERLAST08ATIME} -eq ${LAST08ATIME} ] && \
				[ ${FORMERLAST09ATIME} -eq ${LAST09ATIME} ] && \
				[ ${FORMERLAST10ATIME} -eq ${LAST10ATIME} ] && \
				[ ${FORMERLAST11ATIME} -eq ${LAST11ATIME} ] && \
				[ ${FORMERLAST12ATIME} -eq ${LAST12ATIME} ] && \
				[ ${FORMERLAST13ATIME} -eq ${LAST13ATIME} ] && \
				[ ${FORMERLAST14ATIME} -eq ${LAST14ATIME} ] && \
				[ ${FORMERLAST01DTIME} -eq ${LAST01DTIME} ] && \
				[ ${FORMERLAST02DTIME} -eq ${LAST02DTIME} ] && \
				[ ${FORMERLAST03DTIME} -eq ${LAST03DTIME} ] && \
				[ ${FORMERLAST04DTIME} -eq ${LAST04DTIME} ] && \
				[ ${FORMERLAST05DTIME} -eq ${LAST05DTIME} ] && \
				[ ${FORMERLAST06DTIME} -eq ${LAST06DTIME} ] && \
				[ ${FORMERLAST07DTIME} -eq ${LAST07DTIME} ] && \
				[ ${FORMERLAST08DTIME} -eq ${LAST08DTIME} ] && \
				[ ${FORMERLAST09DTIME} -eq ${LAST09DTIME} ] && \
				[ ${FORMERLAST10DTIME} -eq ${LAST10DTIME} ] && \
				[ ${FORMERLAST11DTIME} -eq ${LAST11DTIME} ] && \
				[ ${FORMERLAST12DTIME} -eq ${LAST12DTIME} ] && \
				[ ${FORMERLAST13DTIME} -eq ${LAST13DTIME} ] && \
				[ ${FORMERLAST14DTIME} -eq ${LAST14DTIME} ] && \
				[ ${FORMERLAST15DTIME} -eq ${LAST15DTIME} ] # if no more recent file is available since the last cron processing
				
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
		echo "Remove Broken Links and Clean txt file in existing ${MSBASDIR}/DefoInterpolx2Detrend"
		Remove_BrokenLinks_and_Clean_txt_file.sh ${MSBASDIR}/DefoInterpolx2Detrend1 &
		Remove_BrokenLinks_and_Clean_txt_file.sh ${MSBASDIR}/DefoInterpolx2Detrend2 &
		Remove_BrokenLinks_and_Clean_txt_file.sh ${MSBASDIR}/DefoInterpolx2Detrend3 &
		Remove_BrokenLinks_and_Clean_txt_file.sh ${MSBASDIR}/DefoInterpolx2Detrend4 &
		wait
		Remove_BrokenLinks_and_Clean_txt_file.sh ${MSBASDIR}/DefoInterpolx2Detrend5 &
		Remove_BrokenLinks_and_Clean_txt_file.sh ${MSBASDIR}/DefoInterpolx2Detrend6 &
		Remove_BrokenLinks_and_Clean_txt_file.sh ${MSBASDIR}/DefoInterpolx2Detrend7 &
		Remove_BrokenLinks_and_Clean_txt_file.sh ${MSBASDIR}/DefoInterpolx2Detrend8 &
		wait
		Remove_BrokenLinks_and_Clean_txt_file.sh ${MSBASDIR}/DefoInterpolx2Detrend9 &
		Remove_BrokenLinks_and_Clean_txt_file.sh ${MSBASDIR}/DefoInterpolx2Detrend10 &
		Remove_BrokenLinks_and_Clean_txt_file.sh ${MSBASDIR}/DefoInterpolx2Detrend11 &
		Remove_BrokenLinks_and_Clean_txt_file.sh ${MSBASDIR}/DefoInterpolx2Detrend12 &
		wait
		Remove_BrokenLinks_and_Clean_txt_file.sh ${MSBASDIR}/DefoInterpolx2Detrend13 &
		Remove_BrokenLinks_and_Clean_txt_file.sh ${MSBASDIR}/DefoInterpolx2Detrend14 &
		Remove_BrokenLinks_and_Clean_txt_file.sh ${MSBASDIR}/DefoInterpolx2Detrend15 &
		Remove_BrokenLinks_and_Clean_txt_file.sh ${MSBASDIR}/DefoInterpolx2Detrend16 &
		wait
		Remove_BrokenLinks_and_Clean_txt_file.sh ${MSBASDIR}/DefoInterpolx2Detrend17 &
		Remove_BrokenLinks_and_Clean_txt_file.sh ${MSBASDIR}/DefoInterpolx2Detrend18 &
		Remove_BrokenLinks_and_Clean_txt_file.sh ${MSBASDIR}/DefoInterpolx2Detrend19 &
		Remove_BrokenLinks_and_Clean_txt_file.sh ${MSBASDIR}/DefoInterpolx2Detrend20 &
		wait
		Remove_BrokenLinks_and_Clean_txt_file.sh ${MSBASDIR}/DefoInterpolx2Detrend21 &
		Remove_BrokenLinks_and_Clean_txt_file.sh ${MSBASDIR}/DefoInterpolx2Detrend22 &
		Remove_BrokenLinks_and_Clean_txt_file.sh ${MSBASDIR}/DefoInterpolx2Detrend23 &
		Remove_BrokenLinks_and_Clean_txt_file.sh ${MSBASDIR}/DefoInterpolx2Detrend24 &
		wait
		Remove_BrokenLinks_and_Clean_txt_file.sh ${MSBASDIR}/DefoInterpolx2Detrend25 &
		Remove_BrokenLinks_and_Clean_txt_file.sh ${MSBASDIR}/DefoInterpolx2Detrend26 &
		Remove_BrokenLinks_and_Clean_txt_file.sh ${MSBASDIR}/DefoInterpolx2Detrend27 &
		
		Remove_BrokenLinks_and_Clean_txt_file.sh ${MSBASDIR}/DefoInterpolx2Detrend28 &
		Remove_BrokenLinks_and_Clean_txt_file.sh ${MSBASDIR}/DefoInterpolx2Detrend29 &
		wait

		echo "Possible broken links in former existing MODEi dir are cleaned"
		echo ""

		#Need also for the _Full ones (that is without coh threshold)	
		if [ ${IFCOH} == "YES" ] ; then 
			Remove_BrokenLinks_and_Clean_txt_file.sh ${MSBASDIR}/DefoInterpolx2Detrend1_Full &
			Remove_BrokenLinks_and_Clean_txt_file.sh ${MSBASDIR}/DefoInterpolx2Detrend2_Full &
			Remove_BrokenLinks_and_Clean_txt_file.sh ${MSBASDIR}/DefoInterpolx2Detrend3_Full &
			Remove_BrokenLinks_and_Clean_txt_file.sh ${MSBASDIR}/DefoInterpolx2Detrend4_Full &
			wait
			Remove_BrokenLinks_and_Clean_txt_file.sh ${MSBASDIR}/DefoInterpolx2Detrend5_Full &
			Remove_BrokenLinks_and_Clean_txt_file.sh ${MSBASDIR}/DefoInterpolx2Detrend6_Full &
			Remove_BrokenLinks_and_Clean_txt_file.sh ${MSBASDIR}/DefoInterpolx2Detrend7_Full &
			Remove_BrokenLinks_and_Clean_txt_file.sh ${MSBASDIR}/DefoInterpolx2Detrend8_Full &
			wait
			Remove_BrokenLinks_and_Clean_txt_file.sh ${MSBASDIR}/DefoInterpolx2Detrend9_Full &
			Remove_BrokenLinks_and_Clean_txt_file.sh ${MSBASDIR}/DefoInterpolx2Detrend10_Full &
			Remove_BrokenLinks_and_Clean_txt_file.sh ${MSBASDIR}/DefoInterpolx2Detrend11_Full &
			Remove_BrokenLinks_and_Clean_txt_file.sh ${MSBASDIR}/DefoInterpolx2Detrend12_Full &
			wait
			Remove_BrokenLinks_and_Clean_txt_file.sh ${MSBASDIR}/DefoInterpolx2Detrend13_Full &
			Remove_BrokenLinks_and_Clean_txt_file.sh ${MSBASDIR}/DefoInterpolx2Detrend14_Full &
			Remove_BrokenLinks_and_Clean_txt_file.sh ${MSBASDIR}/DefoInterpolx2Detrend15_Full &
			Remove_BrokenLinks_and_Clean_txt_file.sh ${MSBASDIR}/DefoInterpolx2Detrend16_Full &
			wait
			Remove_BrokenLinks_and_Clean_txt_file.sh ${MSBASDIR}/DefoInterpolx2Detrend17_Full &
			Remove_BrokenLinks_and_Clean_txt_file.sh ${MSBASDIR}/DefoInterpolx2Detrend18_Full &
			Remove_BrokenLinks_and_Clean_txt_file.sh ${MSBASDIR}/DefoInterpolx2Detrend19_Full &
			Remove_BrokenLinks_and_Clean_txt_file.sh ${MSBASDIR}/DefoInterpolx2Detrend20_Full &
			wait
			Remove_BrokenLinks_and_Clean_txt_file.sh ${MSBASDIR}/DefoInterpolx2Detrend21_Full &
			Remove_BrokenLinks_and_Clean_txt_file.sh ${MSBASDIR}/DefoInterpolx2Detrend22_Full &
			Remove_BrokenLinks_and_Clean_txt_file.sh ${MSBASDIR}/DefoInterpolx2Detrend23_Full &
			Remove_BrokenLinks_and_Clean_txt_file.sh ${MSBASDIR}/DefoInterpolx2Detrend24_Full &
			wait
			Remove_BrokenLinks_and_Clean_txt_file.sh ${MSBASDIR}/DefoInterpolx2Detrend25_Full &
			Remove_BrokenLinks_and_Clean_txt_file.sh ${MSBASDIR}/DefoInterpolx2Detrend26_Full &
			Remove_BrokenLinks_and_Clean_txt_file.sh ${MSBASDIR}/DefoInterpolx2Detrend27_Full &
			
			Remove_BrokenLinks_and_Clean_txt_file.sh ${MSBASDIR}/DefoInterpolx2Detrend28_Full &
			Remove_BrokenLinks_and_Clean_txt_file.sh ${MSBASDIR}/DefoInterpolx2Detrend29_Full &
			
			wait
			echo "Possible broken links in former existing MODEi_Full dir are cleaned"
			echo ""
		fi
	fi

# Check MSBAS/.../MODEi.txt file
################################
cd ${MSBASDIR}

# Remove possible lines with less that 4 columns
	if [ "${FIRSTRUN}" == "NO" ] ; then 
		mv DefoInterpolx2Detrend1.txt DefoInterpolx2Detrend1_all4col.txt
		mv DefoInterpolx2Detrend2.txt DefoInterpolx2Detrend2_all4col.txt
		mv DefoInterpolx2Detrend3.txt DefoInterpolx2Detrend3_all4col.txt
		mv DefoInterpolx2Detrend4.txt DefoInterpolx2Detrend4_all4col.txt	
		mv DefoInterpolx2Detrend5.txt DefoInterpolx2Detrend5_all4col.txt
		mv DefoInterpolx2Detrend6.txt DefoInterpolx2Detrend6_all4col.txt
		mv DefoInterpolx2Detrend7.txt DefoInterpolx2Detrend7_all4col.txt
		mv DefoInterpolx2Detrend8.txt DefoInterpolx2Detrend8_all4col.txt	
		mv DefoInterpolx2Detrend9.txt DefoInterpolx2Detrend9_all4col.txt
		mv DefoInterpolx2Detrend10.txt DefoInterpolx2Detrend10_all4col.txt
		mv DefoInterpolx2Detrend11.txt DefoInterpolx2Detrend11_all4col.txt
		mv DefoInterpolx2Detrend12.txt DefoInterpolx2Detrend12_all4col.txt	
		mv DefoInterpolx2Detrend13.txt DefoInterpolx2Detrend13_all4col.txt
		mv DefoInterpolx2Detrend14.txt DefoInterpolx2Detrend14_all4col.txt
		mv DefoInterpolx2Detrend15.txt DefoInterpolx2Detrend15_all4col.txt
		mv DefoInterpolx2Detrend16.txt DefoInterpolx2Detrend16_all4col.txt	
		mv DefoInterpolx2Detrend17.txt DefoInterpolx2Detrend17_all4col.txt
		mv DefoInterpolx2Detrend18.txt DefoInterpolx2Detrend18_all4col.txt
		mv DefoInterpolx2Detrend19.txt DefoInterpolx2Detrend19_all4col.txt
		mv DefoInterpolx2Detrend20.txt DefoInterpolx2Detrend20_all4col.txt	
		mv DefoInterpolx2Detrend21.txt DefoInterpolx2Detrend21_all4col.txt
		mv DefoInterpolx2Detrend22.txt DefoInterpolx2Detrend22_all4col.txt
		mv DefoInterpolx2Detrend23.txt DefoInterpolx2Detrend23_all4col.txt
		mv DefoInterpolx2Detrend24.txt DefoInterpolx2Detrend24_all4col.txt	
		mv DefoInterpolx2Detrend25.txt DefoInterpolx2Detrend25_all4col.txt
		mv DefoInterpolx2Detrend26.txt DefoInterpolx2Detrend26_all4col.txt
		mv DefoInterpolx2Detrend27.txt DefoInterpolx2Detrend27_all4col.txt

		mv DefoInterpolx2Detrend28.txt DefoInterpolx2Detrend28_all4col.txt
		mv DefoInterpolx2Detrend29.txt DefoInterpolx2Detrend29_all4col.txt

		
		${PATHGNU}/gawk 'NF>=4' DefoInterpolx2Detrend1_all4col.txt > DefoInterpolx2Detrend1.txt 
		${PATHGNU}/gawk 'NF>=4' DefoInterpolx2Detrend2_all4col.txt > DefoInterpolx2Detrend2.txt 
		${PATHGNU}/gawk 'NF>=4' DefoInterpolx2Detrend3_all4col.txt > DefoInterpolx2Detrend3.txt 
		${PATHGNU}/gawk 'NF>=4' DefoInterpolx2Detrend4_all4col.txt > DefoInterpolx2Detrend4.txt 
		${PATHGNU}/gawk 'NF>=4' DefoInterpolx2Detrend5_all4col.txt > DefoInterpolx2Detrend5.txt 
		${PATHGNU}/gawk 'NF>=4' DefoInterpolx2Detrend6_all4col.txt > DefoInterpolx2Detrend6.txt 
		${PATHGNU}/gawk 'NF>=4' DefoInterpolx2Detrend7_all4col.txt > DefoInterpolx2Detrend7.txt 
		${PATHGNU}/gawk 'NF>=4' DefoInterpolx2Detrend8_all4col.txt > DefoInterpolx2Detrend8.txt 
		${PATHGNU}/gawk 'NF>=4' DefoInterpolx2Detrend9_all4col.txt > DefoInterpolx2Detrend9.txt 
		${PATHGNU}/gawk 'NF>=4' DefoInterpolx2Detrend10_all4col.txt > DefoInterpolx2Detrend10.txt 
		${PATHGNU}/gawk 'NF>=4' DefoInterpolx2Detrend11_all4col.txt > DefoInterpolx2Detrend11.txt 
		${PATHGNU}/gawk 'NF>=4' DefoInterpolx2Detrend12_all4col.txt > DefoInterpolx2Detrend12.txt 
		${PATHGNU}/gawk 'NF>=4' DefoInterpolx2Detrend13_all4col.txt > DefoInterpolx2Detrend13.txt 
		${PATHGNU}/gawk 'NF>=4' DefoInterpolx2Detrend14_all4col.txt > DefoInterpolx2Detrend14.txt 
		${PATHGNU}/gawk 'NF>=4' DefoInterpolx2Detrend15_all4col.txt > DefoInterpolx2Detrend15.txt 
		${PATHGNU}/gawk 'NF>=4' DefoInterpolx2Detrend16_all4col.txt > DefoInterpolx2Detrend16.txt 
		${PATHGNU}/gawk 'NF>=4' DefoInterpolx2Detrend17_all4col.txt > DefoInterpolx2Detrend17.txt 
		${PATHGNU}/gawk 'NF>=4' DefoInterpolx2Detrend18_all4col.txt > DefoInterpolx2Detrend18.txt 
		${PATHGNU}/gawk 'NF>=4' DefoInterpolx2Detrend19_all4col.txt > DefoInterpolx2Detrend19.txt 
		${PATHGNU}/gawk 'NF>=4' DefoInterpolx2Detrend20_all4col.txt > DefoInterpolx2Detrend20.txt 
		${PATHGNU}/gawk 'NF>=4' DefoInterpolx2Detrend21_all4col.txt > DefoInterpolx2Detrend21.txt 
		${PATHGNU}/gawk 'NF>=4' DefoInterpolx2Detrend22_all4col.txt > DefoInterpolx2Detrend22.txt 
		${PATHGNU}/gawk 'NF>=4' DefoInterpolx2Detrend23_all4col.txt > DefoInterpolx2Detrend23.txt 
		${PATHGNU}/gawk 'NF>=4' DefoInterpolx2Detrend24_all4col.txt > DefoInterpolx2Detrend24.txt 
		${PATHGNU}/gawk 'NF>=4' DefoInterpolx2Detrend25_all4col.txt > DefoInterpolx2Detrend25.txt 
		${PATHGNU}/gawk 'NF>=4' DefoInterpolx2Detrend26_all4col.txt > DefoInterpolx2Detrend26.txt 
		${PATHGNU}/gawk 'NF>=4' DefoInterpolx2Detrend27_all4col.txt > DefoInterpolx2Detrend27.txt 

		${PATHGNU}/gawk 'NF>=4' DefoInterpolx2Detrend28_all4col.txt > DefoInterpolx2Detrend28.txt 
		${PATHGNU}/gawk 'NF>=4' DefoInterpolx2Detrend29_all4col.txt > DefoInterpolx2Detrend29.txt 

	
		rm -f DefoInterpolx2Detrend1_all4col.txt
		rm -f DefoInterpolx2Detrend2_all4col.txt
		rm -f DefoInterpolx2Detrend3_all4col.txt
		rm -f DefoInterpolx2Detrend4_all4col.txt	
		rm -f DefoInterpolx2Detrend5_all4col.txt
		rm -f DefoInterpolx2Detrend6_all4col.txt
		rm -f DefoInterpolx2Detrend7_all4col.txt
		rm -f DefoInterpolx2Detrend8_all4col.txt	
		rm -f DefoInterpolx2Detrend9_all4col.txt
		rm -f DefoInterpolx2Detrend10_all4col.txt
		rm -f DefoInterpolx2Detrend11_all4col.txt
		rm -f DefoInterpolx2Detrend12_all4col.txt
		rm -f DefoInterpolx2Detrend13_all4col.txt
		rm -f DefoInterpolx2Detrend14_all4col.txt
		rm -f DefoInterpolx2Detrend15_all4col.txt
		rm -f DefoInterpolx2Detrend16_all4col.txt
		rm -f DefoInterpolx2Detrend17_all4col.txt
		rm -f DefoInterpolx2Detrend18_all4col.txt
		rm -f DefoInterpolx2Detrend19_all4col.txt
		rm -f DefoInterpolx2Detrend20_all4col.txt
		rm -f DefoInterpolx2Detrend21_all4col.txt
		rm -f DefoInterpolx2Detrend22_all4col.txt
		rm -f DefoInterpolx2Detrend23_all4col.txt
		rm -f DefoInterpolx2Detrend24_all4col.txt
		rm -f DefoInterpolx2Detrend25_all4col.txt
		rm -f DefoInterpolx2Detrend26_all4col.txt
		rm -f DefoInterpolx2Detrend27_all4col.txt

		rm -f DefoInterpolx2Detrend28_all4col.txt
		rm -f DefoInterpolx2Detrend29_all4col.txt

	
		echo "All lines in former existing MODEi.txt have 4 columns"
		echo ""

		#Need also for the _Full ones (that is without coh threshold)
		if [ ${IFCOH} == "YES" ] ; then 
			mv ${MSBASDIR}/DefoInterpolx2Detrend1_Full/DefoInterpolx2Detrend1_Full.txt ${MSBASDIR}/DefoInterpolx2Detrend1_Full/DefoInterpolx2Detrend1_Full_all4col.txt
			mv ${MSBASDIR}/DefoInterpolx2Detrend2_Full/DefoInterpolx2Detrend2_Full.txt ${MSBASDIR}/DefoInterpolx2Detrend2_Full/DefoInterpolx2Detrend2_Full_all4col.txt
			mv ${MSBASDIR}/DefoInterpolx2Detrend3_Full/DefoInterpolx2Detrend3_Full.txt ${MSBASDIR}/DefoInterpolx2Detrend3_Full/DefoInterpolx2Detrend3_Full_all4col.txt
			mv ${MSBASDIR}/DefoInterpolx2Detrend4_Full/DefoInterpolx2Detrend4_Full.txt ${MSBASDIR}/DefoInterpolx2Detrend4_Full/DefoInterpolx2Detrend4_Full_all4col.txt
			mv ${MSBASDIR}/DefoInterpolx2Detrend5_Full/DefoInterpolx2Detrend5_Full.txt ${MSBASDIR}/DefoInterpolx2Detrend5_Full/DefoInterpolx2Detrend5_Full_all4col.txt
			mv ${MSBASDIR}/DefoInterpolx2Detrend6_Full/DefoInterpolx2Detrend6_Full.txt ${MSBASDIR}/DefoInterpolx2Detrend6_Full/DefoInterpolx2Detrend6_Full_all4col.txt
			mv ${MSBASDIR}/DefoInterpolx2Detrend7_Full/DefoInterpolx2Detrend7_Full.txt ${MSBASDIR}/DefoInterpolx2Detrend7_Full/DefoInterpolx2Detrend7_Full_all4col.txt
			mv ${MSBASDIR}/DefoInterpolx2Detrend8_Full/DefoInterpolx2Detrend8_Full.txt ${MSBASDIR}/DefoInterpolx2Detrend8_Full/DefoInterpolx2Detrend8_Full_all4col.txt
			mv ${MSBASDIR}/DefoInterpolx2Detrend9_Full/DefoInterpolx2Detrend9_Full.txt ${MSBASDIR}/DefoInterpolx2Detrend9_Full/DefoInterpolx2Detrend9_Full_all4col.txt			
			mv ${MSBASDIR}/DefoInterpolx2Detrend10_Full/DefoInterpolx2Detrend10_Full.txt ${MSBASDIR}/DefoInterpolx2Detrend10_Full/DefoInterpolx2Detrend10_Full_all4col.txt
			mv ${MSBASDIR}/DefoInterpolx2Detrend11_Full/DefoInterpolx2Detrend11_Full.txt ${MSBASDIR}/DefoInterpolx2Detrend11_Full/DefoInterpolx2Detrend11_Full_all4col.txt
			mv ${MSBASDIR}/DefoInterpolx2Detrend12_Full/DefoInterpolx2Detrend12_Full.txt ${MSBASDIR}/DefoInterpolx2Detrend12_Full/DefoInterpolx2Detrend12_Full_all4col.txt
			mv ${MSBASDIR}/DefoInterpolx2Detrend13_Full/DefoInterpolx2Detrend13_Full.txt ${MSBASDIR}/DefoInterpolx2Detrend13_Full/DefoInterpolx2Detrend13_Full_all4col.txt
			mv ${MSBASDIR}/DefoInterpolx2Detrend14_Full/DefoInterpolx2Detrend14_Full.txt ${MSBASDIR}/DefoInterpolx2Detrend14_Full/DefoInterpolx2Detrend14_Full_all4col.txt
			mv ${MSBASDIR}/DefoInterpolx2Detrend15_Full/DefoInterpolx2Detrend15_Full.txt ${MSBASDIR}/DefoInterpolx2Detrend15_Full/DefoInterpolx2Detrend15_Full_all4col.txt
			mv ${MSBASDIR}/DefoInterpolx2Detrend16_Full/DefoInterpolx2Detrend16_Full.txt ${MSBASDIR}/DefoInterpolx2Detrend16_Full/DefoInterpolx2Detrend16_Full_all4col.txt
			mv ${MSBASDIR}/DefoInterpolx2Detrend17_Full/DefoInterpolx2Detrend17_Full.txt ${MSBASDIR}/DefoInterpolx2Detrend17_Full/DefoInterpolx2Detrend17_Full_all4col.txt
			mv ${MSBASDIR}/DefoInterpolx2Detrend18_Full/DefoInterpolx2Detrend18_Full.txt ${MSBASDIR}/DefoInterpolx2Detrend18_Full/DefoInterpolx2Detrend18_Full_all4col.txt
			mv ${MSBASDIR}/DefoInterpolx2Detrend19_Full/DefoInterpolx2Detrend19_Full.txt ${MSBASDIR}/DefoInterpolx2Detrend19_Full/DefoInterpolx2Detrend19_Full_all4col.txt
			mv ${MSBASDIR}/DefoInterpolx2Detrend20_Full/DefoInterpolx2Detrend20_Full.txt ${MSBASDIR}/DefoInterpolx2Detrend20_Full/DefoInterpolx2Detrend20_Full_all4col.txt
			mv ${MSBASDIR}/DefoInterpolx2Detrend21_Full/DefoInterpolx2Detrend21_Full.txt ${MSBASDIR}/DefoInterpolx2Detrend21_Full/DefoInterpolx2Detrend21_Full_all4col.txt
			mv ${MSBASDIR}/DefoInterpolx2Detrend22_Full/DefoInterpolx2Detrend22_Full.txt ${MSBASDIR}/DefoInterpolx2Detrend22_Full/DefoInterpolx2Detrend22_Full_all4col.txt
			mv ${MSBASDIR}/DefoInterpolx2Detrend23_Full/DefoInterpolx2Detrend23_Full.txt ${MSBASDIR}/DefoInterpolx2Detrend23_Full/DefoInterpolx2Detrend23_Full_all4col.txt
			mv ${MSBASDIR}/DefoInterpolx2Detrend24_Full/DefoInterpolx2Detrend24_Full.txt ${MSBASDIR}/DefoInterpolx2Detrend24_Full/DefoInterpolx2Detrend24_Full_all4col.txt
			mv ${MSBASDIR}/DefoInterpolx2Detrend25_Full/DefoInterpolx2Detrend25_Full.txt ${MSBASDIR}/DefoInterpolx2Detrend25_Full/DefoInterpolx2Detrend25_Full_all4col.txt
			mv ${MSBASDIR}/DefoInterpolx2Detrend26_Full/DefoInterpolx2Detrend26_Full.txt ${MSBASDIR}/DefoInterpolx2Detrend26_Full/DefoInterpolx2Detrend26_Full_all4col.txt
			mv ${MSBASDIR}/DefoInterpolx2Detrend27_Full/DefoInterpolx2Detrend27_Full.txt ${MSBASDIR}/DefoInterpolx2Detrend27_Full/DefoInterpolx2Detrend27_Full_all4col.txt

			mv ${MSBASDIR}/DefoInterpolx2Detrend28_Full/DefoInterpolx2Detrend28_Full.txt ${MSBASDIR}/DefoInterpolx2Detrend28_Full/DefoInterpolx2Detrend28_Full_all4col.txt
			mv ${MSBASDIR}/DefoInterpolx2Detrend29_Full/DefoInterpolx2Detrend29_Full.txt ${MSBASDIR}/DefoInterpolx2Detrend29_Full/DefoInterpolx2Detrend29_Full_all4col.txt

	
			${PATHGNU}/gawk 'NF>=4' ${MSBASDIR}/DefoInterpolx2Detrend1_Full/DefoInterpolx2Detrend1_Full_all4col.txt > ${MSBASDIR}/DefoInterpolx2Detrend1_Full/DefoInterpolx2Detrend1_Full.txt 
			${PATHGNU}/gawk 'NF>=4' ${MSBASDIR}/DefoInterpolx2Detrend2_Full/DefoInterpolx2Detrend2_Full_all4col.txt > ${MSBASDIR}/DefoInterpolx2Detrend2_Full/DefoInterpolx2Detrend2_Full.txt 
			${PATHGNU}/gawk 'NF>=4' ${MSBASDIR}/DefoInterpolx2Detrend3_Full/DefoInterpolx2Detrend3_Full_all4col.txt > ${MSBASDIR}/DefoInterpolx2Detrend3_Full/DefoInterpolx2Detrend3_Full.txt 
			${PATHGNU}/gawk 'NF>=4' ${MSBASDIR}/DefoInterpolx2Detrend4_Full/DefoInterpolx2Detrend4_Full_all4col.txt > ${MSBASDIR}/DefoInterpolx2Detrend4_Full/DefoInterpolx2Detrend4_Full.txt 
			${PATHGNU}/gawk 'NF>=4' ${MSBASDIR}/DefoInterpolx2Detrend5_Full/DefoInterpolx2Detrend5_Full_all4col.txt > ${MSBASDIR}/DefoInterpolx2Detrend5_Full/DefoInterpolx2Detrend5_Full.txt 
			${PATHGNU}/gawk 'NF>=4' ${MSBASDIR}/DefoInterpolx2Detrend6_Full/DefoInterpolx2Detrend6_Full_all4col.txt > ${MSBASDIR}/DefoInterpolx2Detrend6_Full/DefoInterpolx2Detrend6_Full.txt 
			${PATHGNU}/gawk 'NF>=4' ${MSBASDIR}/DefoInterpolx2Detrend7_Full/DefoInterpolx2Detrend7_Full_all4col.txt > ${MSBASDIR}/DefoInterpolx2Detrend7_Full/DefoInterpolx2Detrend7_Full.txt 
			${PATHGNU}/gawk 'NF>=4' ${MSBASDIR}/DefoInterpolx2Detrend8_Full/DefoInterpolx2Detrend8_Full_all4col.txt > ${MSBASDIR}/DefoInterpolx2Detrend8_Full/DefoInterpolx2Detrend8_Full.txt 
			${PATHGNU}/gawk 'NF>=4' ${MSBASDIR}/DefoInterpolx2Detrend9_Full/DefoInterpolx2Detrend9_Full_all4col.txt > ${MSBASDIR}/DefoInterpolx2Detrend9_Full/DefoInterpolx2Detrend9_Full.txt 
			${PATHGNU}/gawk 'NF>=4' ${MSBASDIR}/DefoInterpolx2Detrend10_Full/DefoInterpolx2Detrend10_Full_all4col.txt > ${MSBASDIR}/DefoInterpolx2Detrend10_Full/DefoInterpolx2Detrend10_Full.txt 
			${PATHGNU}/gawk 'NF>=4' ${MSBASDIR}/DefoInterpolx2Detrend11_Full/DefoInterpolx2Detrend11_Full_all4col.txt > ${MSBASDIR}/DefoInterpolx2Detrend11_Full/DefoInterpolx2Detrend11_Full.txt 
			${PATHGNU}/gawk 'NF>=4' ${MSBASDIR}/DefoInterpolx2Detrend12_Full/DefoInterpolx2Detrend12_Full_all4col.txt > ${MSBASDIR}/DefoInterpolx2Detrend12_Full/DefoInterpolx2Detrend12_Full.txt 
			${PATHGNU}/gawk 'NF>=4' ${MSBASDIR}/DefoInterpolx2Detrend13_Full/DefoInterpolx2Detrend13_Full_all4col.txt > ${MSBASDIR}/DefoInterpolx2Detrend13_Full/DefoInterpolx2Detrend13_Full.txt 
			${PATHGNU}/gawk 'NF>=4' ${MSBASDIR}/DefoInterpolx2Detrend14_Full/DefoInterpolx2Detrend14_Full_all4col.txt > ${MSBASDIR}/DefoInterpolx2Detrend14_Full/DefoInterpolx2Detrend14_Full.txt 
			${PATHGNU}/gawk 'NF>=4' ${MSBASDIR}/DefoInterpolx2Detrend15_Full/DefoInterpolx2Detrend15_Full_all4col.txt > ${MSBASDIR}/DefoInterpolx2Detrend15_Full/DefoInterpolx2Detrend15_Full.txt 
			${PATHGNU}/gawk 'NF>=4' ${MSBASDIR}/DefoInterpolx2Detrend16_Full/DefoInterpolx2Detrend16_Full_all4col.txt > ${MSBASDIR}/DefoInterpolx2Detrend16_Full/DefoInterpolx2Detrend16_Full.txt 
			${PATHGNU}/gawk 'NF>=4' ${MSBASDIR}/DefoInterpolx2Detrend17_Full/DefoInterpolx2Detrend17_Full_all4col.txt > ${MSBASDIR}/DefoInterpolx2Detrend17_Full/DefoInterpolx2Detrend17_Full.txt 
			${PATHGNU}/gawk 'NF>=4' ${MSBASDIR}/DefoInterpolx2Detrend18_Full/DefoInterpolx2Detrend18_Full_all4col.txt > ${MSBASDIR}/DefoInterpolx2Detrend18_Full/DefoInterpolx2Detrend18_Full.txt 
			${PATHGNU}/gawk 'NF>=4' ${MSBASDIR}/DefoInterpolx2Detrend19_Full/DefoInterpolx2Detrend19_Full_all4col.txt > ${MSBASDIR}/DefoInterpolx2Detrend19_Full/DefoInterpolx2Detrend19_Full.txt 
			${PATHGNU}/gawk 'NF>=4' ${MSBASDIR}/DefoInterpolx2Detrend20_Full/DefoInterpolx2Detrend20_Full_all4col.txt > ${MSBASDIR}/DefoInterpolx2Detrend20_Full/DefoInterpolx2Detrend20_Full.txt 
			${PATHGNU}/gawk 'NF>=4' ${MSBASDIR}/DefoInterpolx2Detrend21_Full/DefoInterpolx2Detrend21_Full_all4col.txt > ${MSBASDIR}/DefoInterpolx2Detrend21_Full/DefoInterpolx2Detrend21_Full.txt 
			${PATHGNU}/gawk 'NF>=4' ${MSBASDIR}/DefoInterpolx2Detrend22_Full/DefoInterpolx2Detrend22_Full_all4col.txt > ${MSBASDIR}/DefoInterpolx2Detrend22_Full/DefoInterpolx2Detrend22_Full.txt 
			${PATHGNU}/gawk 'NF>=4' ${MSBASDIR}/DefoInterpolx2Detrend23_Full/DefoInterpolx2Detrend23_Full_all4col.txt > ${MSBASDIR}/DefoInterpolx2Detrend23_Full/DefoInterpolx2Detrend23_Full.txt 
			${PATHGNU}/gawk 'NF>=4' ${MSBASDIR}/DefoInterpolx2Detrend24_Full/DefoInterpolx2Detrend24_Full_all4col.txt > ${MSBASDIR}/DefoInterpolx2Detrend24_Full/DefoInterpolx2Detrend24_Full.txt 
			${PATHGNU}/gawk 'NF>=4' ${MSBASDIR}/DefoInterpolx2Detrend25_Full/DefoInterpolx2Detrend25_Full_all4col.txt > ${MSBASDIR}/DefoInterpolx2Detrend25_Full/DefoInterpolx2Detrend25_Full.txt 
			${PATHGNU}/gawk 'NF>=4' ${MSBASDIR}/DefoInterpolx2Detrend26_Full/DefoInterpolx2Detrend26_Full_all4col.txt > ${MSBASDIR}/DefoInterpolx2Detrend26_Full/DefoInterpolx2Detrend26_Full.txt 
			${PATHGNU}/gawk 'NF>=4' ${MSBASDIR}/DefoInterpolx2Detrend27_Full/DefoInterpolx2Detrend27_Full_all4col.txt > ${MSBASDIR}/DefoInterpolx2Detrend27_Full/DefoInterpolx2Detrend27_Full.txt 

			${PATHGNU}/gawk 'NF>=4' ${MSBASDIR}/DefoInterpolx2Detrend28_Full/DefoInterpolx2Detrend28_Full_all4col.txt > ${MSBASDIR}/DefoInterpolx2Detrend28_Full/DefoInterpolx2Detrend28_Full.txt 
			${PATHGNU}/gawk 'NF>=4' ${MSBASDIR}/DefoInterpolx2Detrend29_Full/DefoInterpolx2Detrend29_Full_all4col.txt > ${MSBASDIR}/DefoInterpolx2Detrend29_Full/DefoInterpolx2Detrend29_Full.txt 

			
			rm -f ${MSBASDIR}/DefoInterpolx2Detrend1_Full/DefoInterpolx2Detrend1_Full_all4col.txt 
			rm -f ${MSBASDIR}/DefoInterpolx2Detrend2_Full/DefoInterpolx2Detrend2_Full_all4col.txt 
			rm -f ${MSBASDIR}/DefoInterpolx2Detrend3_Full/DefoInterpolx2Detrend3_Full_all4col.txt 
			rm -f ${MSBASDIR}/DefoInterpolx2Detrend4_Full/DefoInterpolx2Detrend4_Full_all4col.txt 
			rm -f ${MSBASDIR}/DefoInterpolx2Detrend5_Full/DefoInterpolx2Detrend5_Full_all4col.txt 
			rm -f ${MSBASDIR}/DefoInterpolx2Detrend6_Full/DefoInterpolx2Detrend6_Full_all4col.txt 
			rm -f ${MSBASDIR}/DefoInterpolx2Detrend7_Full/DefoInterpolx2Detrend7_Full_all4col.txt 
			rm -f ${MSBASDIR}/DefoInterpolx2Detrend8_Full/DefoInterpolx2Detrend8_Full_all4col.txt 
			rm -f ${MSBASDIR}/DefoInterpolx2Detrend9_Full/DefoInterpolx2Detrend9_Full_all4col.txt 
			rm -f ${MSBASDIR}/DefoInterpolx2Detrend10_Full/DefoInterpolx2Detrend10_Full_all4col.txt 
			rm -f ${MSBASDIR}/DefoInterpolx2Detrend11_Full/DefoInterpolx2Detrend11_Full_all4col.txt 
			rm -f ${MSBASDIR}/DefoInterpolx2Detrend12_Full/DefoInterpolx2Detrend12_Full_all4col.txt 
			rm -f ${MSBASDIR}/DefoInterpolx2Detrend13_Full/DefoInterpolx2Detrend13_Full_all4col.txt 
			rm -f ${MSBASDIR}/DefoInterpolx2Detrend14_Full/DefoInterpolx2Detrend14_Full_all4col.txt 
			rm -f ${MSBASDIR}/DefoInterpolx2Detrend15_Full/DefoInterpolx2Detrend15_Full_all4col.txt 
			rm -f ${MSBASDIR}/DefoInterpolx2Detrend16_Full/DefoInterpolx2Detrend16_Full_all4col.txt 
			rm -f ${MSBASDIR}/DefoInterpolx2Detrend17_Full/DefoInterpolx2Detrend17_Full_all4col.txt 
			rm -f ${MSBASDIR}/DefoInterpolx2Detrend18_Full/DefoInterpolx2Detrend18_Full_all4col.txt 
			rm -f ${MSBASDIR}/DefoInterpolx2Detrend19_Full/DefoInterpolx2Detrend19_Full_all4col.txt 
			rm -f ${MSBASDIR}/DefoInterpolx2Detrend20_Full/DefoInterpolx2Detrend20_Full_all4col.txt 
			rm -f ${MSBASDIR}/DefoInterpolx2Detrend21_Full/DefoInterpolx2Detrend21_Full_all4col.txt 
			rm -f ${MSBASDIR}/DefoInterpolx2Detrend22_Full/DefoInterpolx2Detrend22_Full_all4col.txt 
			rm -f ${MSBASDIR}/DefoInterpolx2Detrend23_Full/DefoInterpolx2Detrend23_Full_all4col.txt 
			rm -f ${MSBASDIR}/DefoInterpolx2Detrend24_Full/DefoInterpolx2Detrend24_Full_all4col.txt 
			rm -f ${MSBASDIR}/DefoInterpolx2Detrend25_Full/DefoInterpolx2Detrend25_Full_all4col.txt 
			rm -f ${MSBASDIR}/DefoInterpolx2Detrend26_Full/DefoInterpolx2Detrend26_Full_all4col.txt 
			rm -f ${MSBASDIR}/DefoInterpolx2Detrend27_Full/DefoInterpolx2Detrend27_Full_all4col.txt 

			rm -f ${MSBASDIR}/DefoInterpolx2Detrend28_Full/DefoInterpolx2Detrend28_Full_all4col.txt 
			rm -f ${MSBASDIR}/DefoInterpolx2Detrend29_Full/DefoInterpolx2Detrend29_Full_all4col.txt 


			echo "All lines in former existing MODEi_Full.txt have 4 columns"
			echo ""
		fi
	
# Remove lines in MSBAS/MODEi.txt file associated to possible broken links or duplicated lines with same name though wrong BP (e.g. after S1 orb update) 
		cd ${MSBASDIR}
		echo "Remove lines in existing MSBAS/MODEi.txt file associated to possible broken links or duplicated lines"
		_Check_bad_DefoInterpolx2Detrend.sh DefoInterpolx2Detrend1 ${PATH_1660}/SAR_MASSPROCESS &
		_Check_bad_DefoInterpolx2Detrend.sh DefoInterpolx2Detrend2 ${PATH_1660}/SAR_MASSPROCESS &
		_Check_bad_DefoInterpolx2Detrend.sh DefoInterpolx2Detrend3 ${PATH_1660}/SAR_MASSPROCESS &
		_Check_bad_DefoInterpolx2Detrend.sh DefoInterpolx2Detrend4 ${PATH_1660}/SAR_MASSPROCESS &
		wait
		_Check_bad_DefoInterpolx2Detrend.sh DefoInterpolx2Detrend5 ${PATH_1660}/SAR_MASSPROCESS &
		_Check_bad_DefoInterpolx2Detrend.sh DefoInterpolx2Detrend6 ${PATH_1660}/SAR_MASSPROCESS &
		_Check_bad_DefoInterpolx2Detrend.sh DefoInterpolx2Detrend7 ${PATH_1660}/SAR_MASSPROCESS &
		_Check_bad_DefoInterpolx2Detrend.sh DefoInterpolx2Detrend8 ${PATH_1660}/SAR_MASSPROCESS &
		wait
		_Check_bad_DefoInterpolx2Detrend.sh DefoInterpolx2Detrend9 ${PATH_1660}/SAR_MASSPROCESS &
		_Check_bad_DefoInterpolx2Detrend.sh DefoInterpolx2Detrend10 ${PATH_1660}/SAR_MASSPROCESS &
		_Check_bad_DefoInterpolx2Detrend.sh DefoInterpolx2Detrend11 ${PATH_1660}/SAR_MASSPROCESS &
		_Check_bad_DefoInterpolx2Detrend.sh DefoInterpolx2Detrend12 ${PATH_1660}/SAR_MASSPROCESS &
		wait
		_Check_bad_DefoInterpolx2Detrend.sh DefoInterpolx2Detrend13 ${PATH_1660}/SAR_MASSPROCESS &
		_Check_bad_DefoInterpolx2Detrend.sh DefoInterpolx2Detrend14 ${PATH_1660}/SAR_MASSPROCESS &
		_Check_bad_DefoInterpolx2Detrend.sh DefoInterpolx2Detrend15 ${PATH_1660}/SAR_MASSPROCESS &
		_Check_bad_DefoInterpolx2Detrend.sh DefoInterpolx2Detrend16 ${PATH_1660}/SAR_MASSPROCESS &
		wait
		_Check_bad_DefoInterpolx2Detrend.sh DefoInterpolx2Detrend17 ${PATH_1660}/SAR_MASSPROCESS &
		_Check_bad_DefoInterpolx2Detrend.sh DefoInterpolx2Detrend18 ${PATH_1660}/SAR_MASSPROCESS &
		_Check_bad_DefoInterpolx2Detrend.sh DefoInterpolx2Detrend19 ${PATH_1660}/SAR_MASSPROCESS &
		_Check_bad_DefoInterpolx2Detrend.sh DefoInterpolx2Detrend20 ${PATH_1660}/SAR_MASSPROCESS &
		wait
		_Check_bad_DefoInterpolx2Detrend.sh DefoInterpolx2Detrend21 ${PATH_1660}/SAR_MASSPROCESS &
		_Check_bad_DefoInterpolx2Detrend.sh DefoInterpolx2Detrend22 ${PATH_1660}/SAR_MASSPROCESS &
		_Check_bad_DefoInterpolx2Detrend.sh DefoInterpolx2Detrend23 ${PATH_1660}/SAR_MASSPROCESS &
		_Check_bad_DefoInterpolx2Detrend.sh DefoInterpolx2Detrend24 ${PATH_1660}/SAR_MASSPROCESS &
		wait
		_Check_bad_DefoInterpolx2Detrend.sh DefoInterpolx2Detrend25 ${PATH_1660}/SAR_MASSPROCESS &
		_Check_bad_DefoInterpolx2Detrend.sh DefoInterpolx2Detrend26 ${PATH_1660}/SAR_MASSPROCESS &
		_Check_bad_DefoInterpolx2Detrend.sh DefoInterpolx2Detrend27 ${PATH_1660}/SAR_MASSPROCESS &

		_Check_bad_DefoInterpolx2Detrend.sh DefoInterpolx2Detrend28 ${PATH_3601}/SAR_MASSPROCESS &	# Attention, not the same disk
		_Check_bad_DefoInterpolx2Detrend.sh DefoInterpolx2Detrend29 ${PATH_3601}/SAR_MASSPROCESS &
		wait

		echo "All lines in former existing MODEi.txt are ok"
		echo ""
	
		#Need also for the _Full ones (that is without coh threshold)
		if [ ${IFCOH} == "YES" ] ; then 
			_Check_bad_DefoInterpolx2Detrend.sh DefoInterpolx2Detrend1_Full ${PATH_1660}/SAR_MASSPROCESS &
			_Check_bad_DefoInterpolx2Detrend.sh DefoInterpolx2Detrend2_Full ${PATH_1660}/SAR_MASSPROCESS &
			_Check_bad_DefoInterpolx2Detrend.sh DefoInterpolx2Detrend3_Full ${PATH_1660}/SAR_MASSPROCESS &
			_Check_bad_DefoInterpolx2Detrend.sh DefoInterpolx2Detrend4_Full ${PATH_1660}/SAR_MASSPROCESS &
			wait
			_Check_bad_DefoInterpolx2Detrend.sh DefoInterpolx2Detrend5_Full ${PATH_1660}/SAR_MASSPROCESS &
			_Check_bad_DefoInterpolx2Detrend.sh DefoInterpolx2Detrend6_Full ${PATH_1660}/SAR_MASSPROCESS &
			_Check_bad_DefoInterpolx2Detrend.sh DefoInterpolx2Detrend7_Full ${PATH_1660}/SAR_MASSPROCESS &
			_Check_bad_DefoInterpolx2Detrend.sh DefoInterpolx2Detrend8_Full ${PATH_1660}/SAR_MASSPROCESS &
			wait
			_Check_bad_DefoInterpolx2Detrend.sh DefoInterpolx2Detrend9_Full ${PATH_1660}/SAR_MASSPROCESS &
			_Check_bad_DefoInterpolx2Detrend.sh DefoInterpolx2Detrend10_Full ${PATH_1660}/SAR_MASSPROCESS &
			_Check_bad_DefoInterpolx2Detrend.sh DefoInterpolx2Detrend11_Full ${PATH_1660}/SAR_MASSPROCESS &
			_Check_bad_DefoInterpolx2Detrend.sh DefoInterpolx2Detrend12_Full ${PATH_1660}/SAR_MASSPROCESS &
			wait
			_Check_bad_DefoInterpolx2Detrend.sh DefoInterpolx2Detrend13_Full ${PATH_1660}/SAR_MASSPROCESS &
			_Check_bad_DefoInterpolx2Detrend.sh DefoInterpolx2Detrend14_Full ${PATH_1660}/SAR_MASSPROCESS &
			_Check_bad_DefoInterpolx2Detrend.sh DefoInterpolx2Detrend15_Full ${PATH_1660}/SAR_MASSPROCESS &
			_Check_bad_DefoInterpolx2Detrend.sh DefoInterpolx2Detrend16_Full ${PATH_1660}/SAR_MASSPROCESS &
			wait
			_Check_bad_DefoInterpolx2Detrend.sh DefoInterpolx2Detrend17_Full ${PATH_1660}/SAR_MASSPROCESS &
			_Check_bad_DefoInterpolx2Detrend.sh DefoInterpolx2Detrend18_Full ${PATH_1660}/SAR_MASSPROCESS &
			_Check_bad_DefoInterpolx2Detrend.sh DefoInterpolx2Detrend19_Full ${PATH_1660}/SAR_MASSPROCESS &
			_Check_bad_DefoInterpolx2Detrend.sh DefoInterpolx2Detrend20_Full ${PATH_1660}/SAR_MASSPROCESS &
			wait
			_Check_bad_DefoInterpolx2Detrend.sh DefoInterpolx2Detrend21_Full ${PATH_1660}/SAR_MASSPROCESS &
			_Check_bad_DefoInterpolx2Detrend.sh DefoInterpolx2Detrend22_Full ${PATH_1660}/SAR_MASSPROCESS &
			_Check_bad_DefoInterpolx2Detrend.sh DefoInterpolx2Detrend23_Full ${PATH_1660}/SAR_MASSPROCESS &
			_Check_bad_DefoInterpolx2Detrend.sh DefoInterpolx2Detrend24_Full ${PATH_1660}/SAR_MASSPROCESS &
			wait
			_Check_bad_DefoInterpolx2Detrend.sh DefoInterpolx2Detrend25_Full ${PATH_1660}/SAR_MASSPROCESS &
			_Check_bad_DefoInterpolx2Detrend.sh DefoInterpolx2Detrend26_Full ${PATH_1660}/SAR_MASSPROCESS &
			_Check_bad_DefoInterpolx2Detrend.sh DefoInterpolx2Detrend27_Full ${PATH_1660}/SAR_MASSPROCESS &

			_Check_bad_DefoInterpolx2Detrend.sh DefoInterpolx2Detrend28_Full ${PATH_3601}/SAR_MASSPROCESS &	# Attention, not the same disk
			_Check_bad_DefoInterpolx2Detrend.sh DefoInterpolx2Detrend29_Full ${PATH_3601}/SAR_MASSPROCESS &

			wait
			echo "All lines in former existing MODEi_Full.txt are ok"
			echo ""	
		fi
	
	fi

# Prepare MSBAS
###############

	# All 27 modes must be prepared to keep the same numbering
	if [ ${STARTFROM} == "YES" ] && [ ${STARTDATE} != "" ] 
		then 
			# From STARTDATE only  - set S1 after all ALOS
			${PATH_SCRIPTS}/SCRIPTS_MT/build_header_msbas_Tables.sh DefoInterpolx2Detrend 29 \
				${TABLE01A}_After${STARTDATE}_WithBaselines.txt ${TABLE02A}_After${STARTDATE}_WithBaselines.txt ${TABLE03A}_After${STARTDATE}_WithBaselines.txt ${TABLE04A}_After${STARTDATE}_WithBaselines.txt ${TABLE05A}_After${STARTDATE}_WithBaselines.txt ${TABLE06A}_After${STARTDATE}_WithBaselines.txt ${TABLE07A}_After${STARTDATE}_WithBaselines.txt  \
				${TABLE08A}_After${STARTDATE}_WithBaselines.txt ${TABLE09A}_After${STARTDATE}_WithBaselines.txt ${TABLE10A}_After${STARTDATE}_WithBaselines.txt ${TABLE11A}_After${STARTDATE}_WithBaselines.txt ${TABLE12A}_After${STARTDATE}_WithBaselines.txt ${TABLE13A}_After${STARTDATE}_WithBaselines.txt  \
				${TABLE01D}_After${STARTDATE}_WithBaselines.txt ${TABLE02D}_After${STARTDATE}_WithBaselines.txt ${TABLE03D}_After${STARTDATE}_WithBaselines.txt ${TABLE04D}_After${STARTDATE}_WithBaselines.txt ${TABLE05D}_After${STARTDATE}_WithBaselines.txt ${TABLE06D}_After${STARTDATE}_WithBaselines.txt ${TABLE07D}_After${STARTDATE}_WithBaselines.txt  \
				${TABLE08D}_After${STARTDATE}_WithBaselines.txt ${TABLE09D}_After${STARTDATE}_WithBaselines.txt ${TABLE10D}_After${STARTDATE}_WithBaselines.txt ${TABLE11D}_After${STARTDATE}_WithBaselines.txt ${TABLE12D}_After${STARTDATE}_WithBaselines.txt ${TABLE13D}_After${STARTDATE}_WithBaselines.txt ${TABLE14D}_After${STARTDATE}_WithBaselines.txt ${TABLE14A}_After${STARTDATE}_WithBaselines.txt ${TABLE15D}_After${STARTDATE}_WithBaselines.txt  \
				${MASSPROCDIR01A} ${MASSPROCDIR02A} ${MASSPROCDIR03A} ${MASSPROCDIR04A} ${MASSPROCDIR05A} ${MASSPROCDIR06A} ${MASSPROCDIR07A} ${MASSPROCDIR08A} ${MASSPROCDIR09A} ${MASSPROCDIR10A} ${MASSPROCDIR11A} ${MASSPROCDIR12A} ${MASSPROCDIR13A} \
				${MASSPROCDIR01D} ${MASSPROCDIR02D} ${MASSPROCDIR03D} ${MASSPROCDIR04D} ${MASSPROCDIR05D} ${MASSPROCDIR06D} ${MASSPROCDIR07D} ${MASSPROCDIR08D} ${MASSPROCDIR09D} ${MASSPROCDIR10D} ${MASSPROCDIR11D} ${MASSPROCDIR12D} ${MASSPROCDIR13D} ${MASSPROCDIR14D} ${MASSPROCDIR14A} ${MASSPROCDIR15D}
		else 
			# Full tables  - set S1 after all ALOS
			${PATH_SCRIPTS}/SCRIPTS_MT/build_header_msbas_Tables.sh DefoInterpolx2Detrend 29 \
				${TABLE01A} ${TABLE02A} ${TABLE03A} ${TABLE04A} ${TABLE05A} ${TABLE06A} ${TABLE07A} ${TABLE08A} ${TABLE09A} ${TABLE10A} ${TABLE11A} ${TABLE12A} ${TABLE13A} \
				${TABLE01D} ${TABLE02D} ${TABLE03D} ${TABLE04D} ${TABLE05D} ${TABLE06D} ${TABLE07D} ${TABLE08D} ${TABLE09D} ${TABLE10D} ${TABLE11D} ${TABLE12D} ${TABLE13D} ${TABLE14D} ${TABLE14A} ${TABLE15D} \
				${MASSPROCDIR01A} ${MASSPROCDIR02A} ${MASSPROCDIR03A} ${MASSPROCDIR04A} ${MASSPROCDIR05A} ${MASSPROCDIR06A} ${MASSPROCDIR07A} ${MASSPROCDIR08A} ${MASSPROCDIR09A} ${MASSPROCDIR10A} ${MASSPROCDIR11A} ${MASSPROCDIR12A} ${MASSPROCDIR13A} \
				${MASSPROCDIR01D} ${MASSPROCDIR02D} ${MASSPROCDIR03D} ${MASSPROCDIR04D} ${MASSPROCDIR05D} ${MASSPROCDIR06D} ${MASSPROCDIR07D} ${MASSPROCDIR08D} ${MASSPROCDIR09D} ${MASSPROCDIR10D} ${MASSPROCDIR11D} ${MASSPROCDIR12D} ${MASSPROCDIR13D} ${MASSPROCDIR14D} ${MASSPROCDIR14A} ${MASSPROCDIR15D}
	fi

	# update here the R_FLAG if needed
	${PATHGNU}/gsed -i "s/R_FLAG = 2, 0.02/R_FLAG = ${ORDER}, ${LAMBDA}/"  ${MSBASDIR}/header.txt
	# because interferos are detreneded, i.e. averaged to zero, there is no need to calibrate again 
	${PATHGNU}/gsed -i 's/C_FLAG = 10/C_FLAG = 0/' ${MSBASDIR}/header.txt

	# Check again that files are OK
		# ensure that format is ok, that is with 4 columns 
		mv DefoInterpolx2Detrend1.txt DefoInterpolx2Detrend1_all4col.txt
		mv DefoInterpolx2Detrend2.txt DefoInterpolx2Detrend2_all4col.txt
		mv DefoInterpolx2Detrend3.txt DefoInterpolx2Detrend3_all4col.txt
		mv DefoInterpolx2Detrend4.txt DefoInterpolx2Detrend4_all4col.txt	
		mv DefoInterpolx2Detrend5.txt DefoInterpolx2Detrend5_all4col.txt
		mv DefoInterpolx2Detrend6.txt DefoInterpolx2Detrend6_all4col.txt
		mv DefoInterpolx2Detrend7.txt DefoInterpolx2Detrend7_all4col.txt
		mv DefoInterpolx2Detrend8.txt DefoInterpolx2Detrend8_all4col.txt	
		mv DefoInterpolx2Detrend9.txt DefoInterpolx2Detrend9_all4col.txt
		mv DefoInterpolx2Detrend10.txt DefoInterpolx2Detrend10_all4col.txt
		mv DefoInterpolx2Detrend11.txt DefoInterpolx2Detrend11_all4col.txt
		mv DefoInterpolx2Detrend12.txt DefoInterpolx2Detrend12_all4col.txt	
		mv DefoInterpolx2Detrend13.txt DefoInterpolx2Detrend13_all4col.txt
		mv DefoInterpolx2Detrend14.txt DefoInterpolx2Detrend14_all4col.txt
		mv DefoInterpolx2Detrend15.txt DefoInterpolx2Detrend15_all4col.txt
		mv DefoInterpolx2Detrend16.txt DefoInterpolx2Detrend16_all4col.txt	
		mv DefoInterpolx2Detrend17.txt DefoInterpolx2Detrend17_all4col.txt
		mv DefoInterpolx2Detrend18.txt DefoInterpolx2Detrend18_all4col.txt
		mv DefoInterpolx2Detrend19.txt DefoInterpolx2Detrend19_all4col.txt
		mv DefoInterpolx2Detrend20.txt DefoInterpolx2Detrend20_all4col.txt	
		mv DefoInterpolx2Detrend21.txt DefoInterpolx2Detrend21_all4col.txt
		mv DefoInterpolx2Detrend22.txt DefoInterpolx2Detrend22_all4col.txt
		mv DefoInterpolx2Detrend23.txt DefoInterpolx2Detrend23_all4col.txt
		mv DefoInterpolx2Detrend24.txt DefoInterpolx2Detrend24_all4col.txt	
		mv DefoInterpolx2Detrend25.txt DefoInterpolx2Detrend25_all4col.txt
		mv DefoInterpolx2Detrend26.txt DefoInterpolx2Detrend26_all4col.txt
		mv DefoInterpolx2Detrend27.txt DefoInterpolx2Detrend27_all4col.txt

		mv DefoInterpolx2Detrend28.txt DefoInterpolx2Detrend28_all4col.txt
		mv DefoInterpolx2Detrend29.txt DefoInterpolx2Detrend29_all4col.txt

		
		${PATHGNU}/gawk 'NF>=4' DefoInterpolx2Detrend1_all4col.txt > DefoInterpolx2Detrend1.txt 
		${PATHGNU}/gawk 'NF>=4' DefoInterpolx2Detrend2_all4col.txt > DefoInterpolx2Detrend2.txt 
		${PATHGNU}/gawk 'NF>=4' DefoInterpolx2Detrend3_all4col.txt > DefoInterpolx2Detrend3.txt 
		${PATHGNU}/gawk 'NF>=4' DefoInterpolx2Detrend4_all4col.txt > DefoInterpolx2Detrend4.txt 
		${PATHGNU}/gawk 'NF>=4' DefoInterpolx2Detrend5_all4col.txt > DefoInterpolx2Detrend5.txt 
		${PATHGNU}/gawk 'NF>=4' DefoInterpolx2Detrend6_all4col.txt > DefoInterpolx2Detrend6.txt 
		${PATHGNU}/gawk 'NF>=4' DefoInterpolx2Detrend7_all4col.txt > DefoInterpolx2Detrend7.txt 
		${PATHGNU}/gawk 'NF>=4' DefoInterpolx2Detrend8_all4col.txt > DefoInterpolx2Detrend8.txt 
		${PATHGNU}/gawk 'NF>=4' DefoInterpolx2Detrend9_all4col.txt > DefoInterpolx2Detrend9.txt 
		${PATHGNU}/gawk 'NF>=4' DefoInterpolx2Detrend10_all4col.txt > DefoInterpolx2Detrend10.txt 
		${PATHGNU}/gawk 'NF>=4' DefoInterpolx2Detrend11_all4col.txt > DefoInterpolx2Detrend11.txt 
		${PATHGNU}/gawk 'NF>=4' DefoInterpolx2Detrend12_all4col.txt > DefoInterpolx2Detrend12.txt 
		${PATHGNU}/gawk 'NF>=4' DefoInterpolx2Detrend13_all4col.txt > DefoInterpolx2Detrend13.txt 
		${PATHGNU}/gawk 'NF>=4' DefoInterpolx2Detrend14_all4col.txt > DefoInterpolx2Detrend14.txt 
		${PATHGNU}/gawk 'NF>=4' DefoInterpolx2Detrend15_all4col.txt > DefoInterpolx2Detrend15.txt 
		${PATHGNU}/gawk 'NF>=4' DefoInterpolx2Detrend16_all4col.txt > DefoInterpolx2Detrend16.txt 
		${PATHGNU}/gawk 'NF>=4' DefoInterpolx2Detrend17_all4col.txt > DefoInterpolx2Detrend17.txt 
		${PATHGNU}/gawk 'NF>=4' DefoInterpolx2Detrend18_all4col.txt > DefoInterpolx2Detrend18.txt 
		${PATHGNU}/gawk 'NF>=4' DefoInterpolx2Detrend19_all4col.txt > DefoInterpolx2Detrend19.txt 
		${PATHGNU}/gawk 'NF>=4' DefoInterpolx2Detrend20_all4col.txt > DefoInterpolx2Detrend20.txt 
		${PATHGNU}/gawk 'NF>=4' DefoInterpolx2Detrend21_all4col.txt > DefoInterpolx2Detrend21.txt 
		${PATHGNU}/gawk 'NF>=4' DefoInterpolx2Detrend22_all4col.txt > DefoInterpolx2Detrend22.txt 
		${PATHGNU}/gawk 'NF>=4' DefoInterpolx2Detrend23_all4col.txt > DefoInterpolx2Detrend23.txt 
		${PATHGNU}/gawk 'NF>=4' DefoInterpolx2Detrend24_all4col.txt > DefoInterpolx2Detrend24.txt 
		${PATHGNU}/gawk 'NF>=4' DefoInterpolx2Detrend25_all4col.txt > DefoInterpolx2Detrend25.txt 
		${PATHGNU}/gawk 'NF>=4' DefoInterpolx2Detrend26_all4col.txt > DefoInterpolx2Detrend26.txt 
		${PATHGNU}/gawk 'NF>=4' DefoInterpolx2Detrend27_all4col.txt > DefoInterpolx2Detrend27.txt 		

		${PATHGNU}/gawk 'NF>=4' DefoInterpolx2Detrend28_all4col.txt > DefoInterpolx2Detrend28.txt 
		${PATHGNU}/gawk 'NF>=4' DefoInterpolx2Detrend29_all4col.txt > DefoInterpolx2Detrend29.txt 		

		
		# keep track of prblms
		${PATHGNU}/gawk 'NF<4' DefoInterpolx2Detrend1_all4col.txt > DefoInterpolx2Detrend1_MissingCol.txt 
		${PATHGNU}/gawk 'NF<4' DefoInterpolx2Detrend2_all4col.txt > DefoInterpolx2Detrend2_MissingCol.txt 
		${PATHGNU}/gawk 'NF<4' DefoInterpolx2Detrend3_all4col.txt > DefoInterpolx2Detrend3_MissingCol.txt 
		${PATHGNU}/gawk 'NF<4' DefoInterpolx2Detrend4_all4col.txt > DefoInterpolx2Detrend4_MissingCol.txt 
		${PATHGNU}/gawk 'NF<4' DefoInterpolx2Detrend5_all4col.txt > DefoInterpolx2Detrend5_MissingCol.txt 
		${PATHGNU}/gawk 'NF<4' DefoInterpolx2Detrend6_all4col.txt > DefoInterpolx2Detrend6_MissingCol.txt 
		${PATHGNU}/gawk 'NF<4' DefoInterpolx2Detrend7_all4col.txt > DefoInterpolx2Detrend7_MissingCol.txt 
		${PATHGNU}/gawk 'NF<4' DefoInterpolx2Detrend8_all4col.txt > DefoInterpolx2Detrend8_MissingCol.txt 
		${PATHGNU}/gawk 'NF<4' DefoInterpolx2Detrend9_all4col.txt > DefoInterpolx2Detrend9_MissingCol.txt 
		${PATHGNU}/gawk 'NF<4' DefoInterpolx2Detrend10_all4col.txt > DefoInterpolx2Detrend10_MissingCol.txt 
		${PATHGNU}/gawk 'NF<4' DefoInterpolx2Detrend11_all4col.txt > DefoInterpolx2Detrend11_MissingCol.txt 
		${PATHGNU}/gawk 'NF<4' DefoInterpolx2Detrend12_all4col.txt > DefoInterpolx2Detrend12_MissingCol.txt 
		${PATHGNU}/gawk 'NF<4' DefoInterpolx2Detrend13_all4col.txt > DefoInterpolx2Detrend13_MissingCol.txt 
		${PATHGNU}/gawk 'NF<4' DefoInterpolx2Detrend14_all4col.txt > DefoInterpolx2Detrend14_MissingCol.txt 
		${PATHGNU}/gawk 'NF<4' DefoInterpolx2Detrend15_all4col.txt > DefoInterpolx2Detrend15_MissingCol.txt 
		${PATHGNU}/gawk 'NF<4' DefoInterpolx2Detrend16_all4col.txt > DefoInterpolx2Detrend16_MissingCol.txt 
		${PATHGNU}/gawk 'NF<4' DefoInterpolx2Detrend17_all4col.txt > DefoInterpolx2Detrend17_MissingCol.txt 
		${PATHGNU}/gawk 'NF<4' DefoInterpolx2Detrend18_all4col.txt > DefoInterpolx2Detrend18_MissingCol.txt 
		${PATHGNU}/gawk 'NF<4' DefoInterpolx2Detrend19_all4col.txt > DefoInterpolx2Detrend19_MissingCol.txt 
		${PATHGNU}/gawk 'NF<4' DefoInterpolx2Detrend20_all4col.txt > DefoInterpolx2Detrend20_MissingCol.txt 
		${PATHGNU}/gawk 'NF<4' DefoInterpolx2Detrend21_all4col.txt > DefoInterpolx2Detrend21_MissingCol.txt 
		${PATHGNU}/gawk 'NF<4' DefoInterpolx2Detrend22_all4col.txt > DefoInterpolx2Detrend22_MissingCol.txt 
		${PATHGNU}/gawk 'NF<4' DefoInterpolx2Detrend23_all4col.txt > DefoInterpolx2Detrend23_MissingCol.txt 
		${PATHGNU}/gawk 'NF<4' DefoInterpolx2Detrend24_all4col.txt > DefoInterpolx2Detrend24_MissingCol.txt 
		${PATHGNU}/gawk 'NF<4' DefoInterpolx2Detrend25_all4col.txt > DefoInterpolx2Detrend25_MissingCol.txt 
		${PATHGNU}/gawk 'NF<4' DefoInterpolx2Detrend26_all4col.txt > DefoInterpolx2Detrend26_MissingCol.txt 
		${PATHGNU}/gawk 'NF<4' DefoInterpolx2Detrend27_all4col.txt > DefoInterpolx2Detrend27_MissingCol.txt 		

		${PATHGNU}/gawk 'NF<4' DefoInterpolx2Detrend28_all4col.txt > DefoInterpolx2Detrend28_MissingCol.txt 
		${PATHGNU}/gawk 'NF<4' DefoInterpolx2Detrend29_all4col.txt > DefoInterpolx2Detrend29_MissingCol.txt 		


		rm -f DefoInterpolx2Detrend1_all4col.txt
		rm -f DefoInterpolx2Detrend2_all4col.txt
		rm -f DefoInterpolx2Detrend3_all4col.txt
		rm -f DefoInterpolx2Detrend4_all4col.txt	
		rm -f DefoInterpolx2Detrend5_all4col.txt
		rm -f DefoInterpolx2Detrend6_all4col.txt
		rm -f DefoInterpolx2Detrend7_all4col.txt
		rm -f DefoInterpolx2Detrend8_all4col.txt	
		rm -f DefoInterpolx2Detrend9_all4col.txt
		rm -f DefoInterpolx2Detrend10_all4col.txt
		rm -f DefoInterpolx2Detrend11_all4col.txt
		rm -f DefoInterpolx2Detrend12_all4col.txt
		rm -f DefoInterpolx2Detrend13_all4col.txt
		rm -f DefoInterpolx2Detrend14_all4col.txt
		rm -f DefoInterpolx2Detrend15_all4col.txt
		rm -f DefoInterpolx2Detrend16_all4col.txt
		rm -f DefoInterpolx2Detrend17_all4col.txt
		rm -f DefoInterpolx2Detrend18_all4col.txt
		rm -f DefoInterpolx2Detrend19_all4col.txt
		rm -f DefoInterpolx2Detrend20_all4col.txt
		rm -f DefoInterpolx2Detrend21_all4col.txt
		rm -f DefoInterpolx2Detrend22_all4col.txt
		rm -f DefoInterpolx2Detrend23_all4col.txt
		rm -f DefoInterpolx2Detrend24_all4col.txt
		rm -f DefoInterpolx2Detrend25_all4col.txt
		rm -f DefoInterpolx2Detrend26_all4col.txt
		rm -f DefoInterpolx2Detrend27_all4col.txt

		rm -f DefoInterpolx2Detrend28_all4col.txt
		rm -f DefoInterpolx2Detrend29_all4col.txt

		
		# Need again to check for duplicated lines with different Bp in Col 2 resulting from orbit update 
		if [ ${IFCOH} == "YES" ] ; then 
			echo "Remove lines in newly created MSBAS/MODEi.txt file associated to possible broken links or duplicated lines"
			_Check_bad_DefoInterpolx2Detrend.sh DefoInterpolx2Detrend1 ${PATH_1660}/SAR_MASSPROCESS &
			_Check_bad_DefoInterpolx2Detrend.sh DefoInterpolx2Detrend2 ${PATH_1660}/SAR_MASSPROCESS &
			_Check_bad_DefoInterpolx2Detrend.sh DefoInterpolx2Detrend3 ${PATH_1660}/SAR_MASSPROCESS &
			_Check_bad_DefoInterpolx2Detrend.sh DefoInterpolx2Detrend4 ${PATH_1660}/SAR_MASSPROCESS &
			wait
			_Check_bad_DefoInterpolx2Detrend.sh DefoInterpolx2Detrend5 ${PATH_1660}/SAR_MASSPROCESS &
			_Check_bad_DefoInterpolx2Detrend.sh DefoInterpolx2Detrend6 ${PATH_1660}/SAR_MASSPROCESS &
			_Check_bad_DefoInterpolx2Detrend.sh DefoInterpolx2Detrend7 ${PATH_1660}/SAR_MASSPROCESS &
			_Check_bad_DefoInterpolx2Detrend.sh DefoInterpolx2Detrend8 ${PATH_1660}/SAR_MASSPROCESS &
			wait
			_Check_bad_DefoInterpolx2Detrend.sh DefoInterpolx2Detrend9 ${PATH_1660}/SAR_MASSPROCESS &
			_Check_bad_DefoInterpolx2Detrend.sh DefoInterpolx2Detrend10 ${PATH_1660}/SAR_MASSPROCESS &
			_Check_bad_DefoInterpolx2Detrend.sh DefoInterpolx2Detrend11 ${PATH_1660}/SAR_MASSPROCESS &
			_Check_bad_DefoInterpolx2Detrend.sh DefoInterpolx2Detrend12 ${PATH_1660}/SAR_MASSPROCESS &
			wait
			_Check_bad_DefoInterpolx2Detrend.sh DefoInterpolx2Detrend13 ${PATH_1660}/SAR_MASSPROCESS &
			_Check_bad_DefoInterpolx2Detrend.sh DefoInterpolx2Detrend14 ${PATH_1660}/SAR_MASSPROCESS &
			_Check_bad_DefoInterpolx2Detrend.sh DefoInterpolx2Detrend15 ${PATH_1660}/SAR_MASSPROCESS &
			_Check_bad_DefoInterpolx2Detrend.sh DefoInterpolx2Detrend16 ${PATH_1660}/SAR_MASSPROCESS &
			wait
			_Check_bad_DefoInterpolx2Detrend.sh DefoInterpolx2Detrend17 ${PATH_1660}/SAR_MASSPROCESS &
			_Check_bad_DefoInterpolx2Detrend.sh DefoInterpolx2Detrend18 ${PATH_1660}/SAR_MASSPROCESS &
			_Check_bad_DefoInterpolx2Detrend.sh DefoInterpolx2Detrend19 ${PATH_1660}/SAR_MASSPROCESS &
			_Check_bad_DefoInterpolx2Detrend.sh DefoInterpolx2Detrend20 ${PATH_1660}/SAR_MASSPROCESS &
			wait
			_Check_bad_DefoInterpolx2Detrend.sh DefoInterpolx2Detrend21 ${PATH_1660}/SAR_MASSPROCESS &
			_Check_bad_DefoInterpolx2Detrend.sh DefoInterpolx2Detrend22 ${PATH_1660}/SAR_MASSPROCESS &
			_Check_bad_DefoInterpolx2Detrend.sh DefoInterpolx2Detrend23 ${PATH_1660}/SAR_MASSPROCESS &
			_Check_bad_DefoInterpolx2Detrend.sh DefoInterpolx2Detrend24 ${PATH_1660}/SAR_MASSPROCESS &
			wait
			_Check_bad_DefoInterpolx2Detrend.sh DefoInterpolx2Detrend25 ${PATH_1660}/SAR_MASSPROCESS &
			_Check_bad_DefoInterpolx2Detrend.sh DefoInterpolx2Detrend26 ${PATH_1660}/SAR_MASSPROCESS &
			_Check_bad_DefoInterpolx2Detrend.sh DefoInterpolx2Detrend27 ${PATH_1660}/SAR_MASSPROCESS &

			_Check_bad_DefoInterpolx2Detrend.sh DefoInterpolx2Detrend28 ${PATH_3601}/SAR_MASSPROCESS &	# Attention: not the same disk
			_Check_bad_DefoInterpolx2Detrend.sh DefoInterpolx2Detrend29 ${PATH_3601}/SAR_MASSPROCESS &
			wait

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
 	#LINENR14D=$(cat ${MSBASDIR}/header.txt | ${PATHGNU}/grep -n "SET =" | tail -1 | cut -d: -f1)
	LINENR14D=$(cat ${MSBASDIR}/header.txt | ${PATHGNU}/grep -n "SET =" | head -27 | tail -1 | cut -d: -f1)
	
 	LINENR14A=$(cat ${MSBASDIR}/header.txt | ${PATHGNU}/grep -n "SET =" | head -28 | tail -1 | cut -d: -f1)		# set S1 at the end
 	LINENR15D=$(cat ${MSBASDIR}/header.txt | ${PATHGNU}/grep -n "SET =" | tail -1 | cut -d: -f1)


	SETLINENRS=(${LINENR01A} ${LINENR02A} ${LINENR03A} ${LINENR04A} ${LINENR05A} ${LINENR06A} ${LINENR07A} ${LINENR08A} ${LINENR09A} ${LINENR10A} ${LINENR11A} ${LINENR12A} ${LINENR13A} ${LINENR01D} ${LINENR02D} ${LINENR03D} ${LINENR04D} ${LINENR05D} ${LINENR06D} ${LINENR07D} ${LINENR08D} ${LINENR09D} ${LINENR10D} ${LINENR11D} ${LINENR12D} ${LINENR13D} ${LINENR14D} ${LINENR14A} ${LINENR15D}) # set S1 at the end 
	echo "// List of line numbers for all sets in header.txt: ${SETLINENRS[@]}"	

	cp header.txt header_all_modes.txt # to be kept all time		
	# If not all the modes are wanted, one must comment them here
	if [ ${#ALLMODELIST[@]} -ne ${#MODELIST[@]} ]  # i.e. if the two list have not the same length
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
    			cat ${MSBASDIR}/header_tmp.txt | ${PATHGNU}/gsed ${pos}' s/SET = /#SET = /' > ${MSBASDIR}/header.txt
    			cp -f ${MSBASDIR}/header.txt ${MSBASDIR}/header_tmp.txt  
			done
			rm -f ${MSBASDIR}/header_tmp.txt
	
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
# 		${PATH_SCRIPTS}/SCRIPTS_MT/MSBAS.sh _Auto_${ORDER}_${LAMBDA}_${LABEL}_NoCohThresh ${TIMESERIESPTS}
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
         cd ${MSBASDIR}
         #cp -f header_back.txt header.txt

        # run restrict_msbas_to_Coh.sh         
#         restrict_msbas_to_Coh.sh DefoInterpolx2Detrend1 ${COHRESTRICT} ${KMLCOH} ${S1ASC}/Geocoded/Coh
 #        restrict_msbas_to_Coh.sh DefoInterpolx2Detrend2 ${COHRESTRICT} ${KMLCOH} ${S1DESC}/Geocoded/Coh
		
		# Force pair exclusion 
			if [ ${EXCLUDE01A} == "YES" ] ; then ${PATH_SCRIPTS}/SCRIPTS_MT/zz_Utilities_MT/Exclude_Pairs_From_Mode.txt.sh ${MSBASDIR}/DefoInterpolx2Detrend1 ; fi 
			if [ ${EXCLUDE02A} == "YES" ] ; then ${PATH_SCRIPTS}/SCRIPTS_MT/zz_Utilities_MT/Exclude_Pairs_From_Mode.txt.sh ${MSBASDIR}/DefoInterpolx2Detrend2 ; fi 
			if [ ${EXCLUDE03A} == "YES" ] ; then ${PATH_SCRIPTS}/SCRIPTS_MT/zz_Utilities_MT/Exclude_Pairs_From_Mode.txt.sh ${MSBASDIR}/DefoInterpolx2Detrend3 ; fi 
			if [ ${EXCLUDE04A} == "YES" ] ; then ${PATH_SCRIPTS}/SCRIPTS_MT/zz_Utilities_MT/Exclude_Pairs_From_Mode.txt.sh ${MSBASDIR}/DefoInterpolx2Detrend4 ; fi 
			if [ ${EXCLUDE05A} == "YES" ] ; then ${PATH_SCRIPTS}/SCRIPTS_MT/zz_Utilities_MT/Exclude_Pairs_From_Mode.txt.sh ${MSBASDIR}/DefoInterpolx2Detrend5 ; fi 
			if [ ${EXCLUDE06A} == "YES" ] ; then ${PATH_SCRIPTS}/SCRIPTS_MT/zz_Utilities_MT/Exclude_Pairs_From_Mode.txt.sh ${MSBASDIR}/DefoInterpolx2Detrend6 ; fi 
			if [ ${EXCLUDE07A} == "YES" ] ; then ${PATH_SCRIPTS}/SCRIPTS_MT/zz_Utilities_MT/Exclude_Pairs_From_Mode.txt.sh ${MSBASDIR}/DefoInterpolx2Detrend7 ; fi 
			if [ ${EXCLUDE08A} == "YES" ] ; then ${PATH_SCRIPTS}/SCRIPTS_MT/zz_Utilities_MT/Exclude_Pairs_From_Mode.txt.sh ${MSBASDIR}/DefoInterpolx2Detrend8 ; fi 
			if [ ${EXCLUDE09A} == "YES" ] ; then ${PATH_SCRIPTS}/SCRIPTS_MT/zz_Utilities_MT/Exclude_Pairs_From_Mode.txt.sh ${MSBASDIR}/DefoInterpolx2Detrend9 ; fi 
			if [ ${EXCLUDE10A} == "YES" ] ; then ${PATH_SCRIPTS}/SCRIPTS_MT/zz_Utilities_MT/Exclude_Pairs_From_Mode.txt.sh ${MSBASDIR}/DefoInterpolx2Detrend10 ; fi 
			if [ ${EXCLUDE11A} == "YES" ] ; then ${PATH_SCRIPTS}/SCRIPTS_MT/zz_Utilities_MT/Exclude_Pairs_From_Mode.txt.sh ${MSBASDIR}/DefoInterpolx2Detrend11 ; fi 
			if [ ${EXCLUDE12A} == "YES" ] ; then ${PATH_SCRIPTS}/SCRIPTS_MT/zz_Utilities_MT/Exclude_Pairs_From_Mode.txt.sh ${MSBASDIR}/DefoInterpolx2Detrend12 ; fi 
			if [ ${EXCLUDE13A} == "YES" ] ; then ${PATH_SCRIPTS}/SCRIPTS_MT/zz_Utilities_MT/Exclude_Pairs_From_Mode.txt.sh ${MSBASDIR}/DefoInterpolx2Detrend13 ; fi 

			if [ ${EXCLUDE14A} == "YES" ] ; then ${PATH_SCRIPTS}/SCRIPTS_MT/zz_Utilities_MT/Exclude_Pairs_From_Mode.txt.sh ${MSBASDIR}/DefoInterpolx2Detrend28 ; fi 


			if [ ${EXCLUDE01D} == "YES" ] ; then ${PATH_SCRIPTS}/SCRIPTS_MT/zz_Utilities_MT/Exclude_Pairs_From_Mode.txt.sh ${MSBASDIR}/DefoInterpolx2Detrend14 ; fi 
			if [ ${EXCLUDE02D} == "YES" ] ; then ${PATH_SCRIPTS}/SCRIPTS_MT/zz_Utilities_MT/Exclude_Pairs_From_Mode.txt.sh ${MSBASDIR}/DefoInterpolx2Detrend15 ; fi 
			if [ ${EXCLUDE03D} == "YES" ] ; then ${PATH_SCRIPTS}/SCRIPTS_MT/zz_Utilities_MT/Exclude_Pairs_From_Mode.txt.sh ${MSBASDIR}/DefoInterpolx2Detrend16 ; fi 
			if [ ${EXCLUDE04D} == "YES" ] ; then ${PATH_SCRIPTS}/SCRIPTS_MT/zz_Utilities_MT/Exclude_Pairs_From_Mode.txt.sh ${MSBASDIR}/DefoInterpolx2Detrend17 ; fi 
			if [ ${EXCLUDE05D} == "YES" ] ; then ${PATH_SCRIPTS}/SCRIPTS_MT/zz_Utilities_MT/Exclude_Pairs_From_Mode.txt.sh ${MSBASDIR}/DefoInterpolx2Detrend18 ; fi 
			if [ ${EXCLUDE06D} == "YES" ] ; then ${PATH_SCRIPTS}/SCRIPTS_MT/zz_Utilities_MT/Exclude_Pairs_From_Mode.txt.sh ${MSBASDIR}/DefoInterpolx2Detrend19 ; fi 
			if [ ${EXCLUDE07D} == "YES" ] ; then ${PATH_SCRIPTS}/SCRIPTS_MT/zz_Utilities_MT/Exclude_Pairs_From_Mode.txt.sh ${MSBASDIR}/DefoInterpolx2Detrend20 ; fi 
			if [ ${EXCLUDE08D} == "YES" ] ; then ${PATH_SCRIPTS}/SCRIPTS_MT/zz_Utilities_MT/Exclude_Pairs_From_Mode.txt.sh ${MSBASDIR}/DefoInterpolx2Detrend21 ; fi 
			if [ ${EXCLUDE09D} == "YES" ] ; then ${PATH_SCRIPTS}/SCRIPTS_MT/zz_Utilities_MT/Exclude_Pairs_From_Mode.txt.sh ${MSBASDIR}/DefoInterpolx2Detrend22 ; fi 
			if [ ${EXCLUDE10D} == "YES" ] ; then ${PATH_SCRIPTS}/SCRIPTS_MT/zz_Utilities_MT/Exclude_Pairs_From_Mode.txt.sh ${MSBASDIR}/DefoInterpolx2Detrend23 ; fi 
			if [ ${EXCLUDE11D} == "YES" ] ; then ${PATH_SCRIPTS}/SCRIPTS_MT/zz_Utilities_MT/Exclude_Pairs_From_Mode.txt.sh ${MSBASDIR}/DefoInterpolx2Detrend24 ; fi 
			if [ ${EXCLUDE12D} == "YES" ] ; then ${PATH_SCRIPTS}/SCRIPTS_MT/zz_Utilities_MT/Exclude_Pairs_From_Mode.txt.sh ${MSBASDIR}/DefoInterpolx2Detrend25 ; fi 
			if [ ${EXCLUDE13D} == "YES" ] ; then ${PATH_SCRIPTS}/SCRIPTS_MT/zz_Utilities_MT/Exclude_Pairs_From_Mode.txt.sh ${MSBASDIR}/DefoInterpolx2Detrend26 ; fi 
			if [ ${EXCLUDE14D} == "YES" ] ; then ${PATH_SCRIPTS}/SCRIPTS_MT/zz_Utilities_MT/Exclude_Pairs_From_Mode.txt.sh ${MSBASDIR}/DefoInterpolx2Detrend27 ; fi 

			if [ ${EXCLUDE15D} == "YES" ] ; then ${PATH_SCRIPTS}/SCRIPTS_MT/zz_Utilities_MT/Exclude_Pairs_From_Mode.txt.sh ${MSBASDIR}/DefoInterpolx2Detrend29 ; fi 

		cd ${MSBASDIR}

		${PATH_SCRIPTS}/SCRIPTS_MT/MSBAS.sh _Auto_${ORDER}_${LAMBDA}_${LABEL} ${TIMESERIESPTS}

		# test if MSBAS_log.txt contains "completed 100%" ; if not log error 
#		if ${PATHGNU}/grep -q "writing results to a disk" ${MSBASDIR}/zz_EW_Auto_${ORDER}_${LAMBDA}_${LABEL}/MSBAS_LOG.txt 
#	 		then 
# 				echo "MSBAS ok" 
# 			else 
# 				# try again after cleaning DefoInterpolx2Detrendi.txt
# 				_Check_bad_DefoInterpolx2Detrend.sh DefoInterpolx2Detrend1 ${PATH_1660}/SAR_MASSPROCESS &
# 				_Check_bad_DefoInterpolx2Detrend.sh DefoInterpolx2Detrend2 ${PATH_1660}/SAR_MASSPROCESS &
# 				wait 
# 				
# 				${PATH_SCRIPTS}/SCRIPTS_MT/MSBAS.sh _Auto_${ORDER}_${LAMBDA}_${LABEL} ${TIMESERIESPTS}
# 				if ${PATHGNU}/grep -q "writing results to a disk" ${MSBASDIR}/zz_EW_Auto_${ORDER}_${LAMBDA}_${LABEL}/MSBAS_LOG.txt ; then echo "Solved after cleaning DefoInterpolx2Detrend's txt"; else  echo "!! MSBAS crashed on ${TODAY}"  >>  ${MSBASDIR}/_last_MSBAS_process.txt ; fi
# 		fi

		# Make baseline plot  
		PlotBaselineGeocMSBASmodeTXT.sh "${SET01}" "${MSBASDIR}/DefoInterpolx2Detrend1.txt" 
		PlotBaselineGeocMSBASmodeTXT.sh "${SET02}" "${MSBASDIR}/DefoInterpolx2Detrend2.txt" 
		PlotBaselineGeocMSBASmodeTXT.sh "${SET03}" "${MSBASDIR}/DefoInterpolx2Detrend3.txt" 
		PlotBaselineGeocMSBASmodeTXT.sh "${SET04}" "${MSBASDIR}/DefoInterpolx2Detrend4.txt" 
		PlotBaselineGeocMSBASmodeTXT.sh "${SET05}" "${MSBASDIR}/DefoInterpolx2Detrend5.txt" 
		PlotBaselineGeocMSBASmodeTXT.sh "${SET06}" "${MSBASDIR}/DefoInterpolx2Detrend6.txt" 
		PlotBaselineGeocMSBASmodeTXT.sh "${SET07}" "${MSBASDIR}/DefoInterpolx2Detrend7.txt" 
		PlotBaselineGeocMSBASmodeTXT.sh "${SET08}" "${MSBASDIR}/DefoInterpolx2Detrend8.txt" 
		PlotBaselineGeocMSBASmodeTXT.sh "${SET09}" "${MSBASDIR}/DefoInterpolx2Detrend9.txt" 
		PlotBaselineGeocMSBASmodeTXT.sh "${SET10}" "${MSBASDIR}/DefoInterpolx2Detrend10.txt" 
		PlotBaselineGeocMSBASmodeTXT.sh "${SET11}" "${MSBASDIR}/DefoInterpolx2Detrend11.txt" 
		PlotBaselineGeocMSBASmodeTXT.sh "${SET12}" "${MSBASDIR}/DefoInterpolx2Detrend12.txt" 
		PlotBaselineGeocMSBASmodeTXT.sh "${SET13}" "${MSBASDIR}/DefoInterpolx2Detrend13.txt" 
		PlotBaselineGeocMSBASmodeTXT.sh "${SET14}" "${MSBASDIR}/DefoInterpolx2Detrend14.txt" 
		PlotBaselineGeocMSBASmodeTXT.sh "${SET15}" "${MSBASDIR}/DefoInterpolx2Detrend15.txt" 
		PlotBaselineGeocMSBASmodeTXT.sh "${SET16}" "${MSBASDIR}/DefoInterpolx2Detrend16.txt" 
		PlotBaselineGeocMSBASmodeTXT.sh "${SET17}" "${MSBASDIR}/DefoInterpolx2Detrend17.txt" 
		PlotBaselineGeocMSBASmodeTXT.sh "${SET18}" "${MSBASDIR}/DefoInterpolx2Detrend18.txt" 
		PlotBaselineGeocMSBASmodeTXT.sh "${SET19}" "${MSBASDIR}/DefoInterpolx2Detrend19.txt" 
		PlotBaselineGeocMSBASmodeTXT.sh "${SET20}" "${MSBASDIR}/DefoInterpolx2Detrend20.txt" 
		PlotBaselineGeocMSBASmodeTXT.sh "${SET21}" "${MSBASDIR}/DefoInterpolx2Detrend21.txt" 
		PlotBaselineGeocMSBASmodeTXT.sh "${SET22}" "${MSBASDIR}/DefoInterpolx2Detrend22.txt" 
		PlotBaselineGeocMSBASmodeTXT.sh "${SET23}" "${MSBASDIR}/DefoInterpolx2Detrend23.txt" 
		PlotBaselineGeocMSBASmodeTXT.sh "${SET24}" "${MSBASDIR}/DefoInterpolx2Detrend24.txt" 
		PlotBaselineGeocMSBASmodeTXT.sh "${SET25}" "${MSBASDIR}/DefoInterpolx2Detrend25.txt" 
		PlotBaselineGeocMSBASmodeTXT.sh "${SET26}" "${MSBASDIR}/DefoInterpolx2Detrend26.txt" 
		PlotBaselineGeocMSBASmodeTXT.sh "${SET27}" "${MSBASDIR}/DefoInterpolx2Detrend27.txt" 

		PlotBaselineGeocMSBASmodeTXT.sh "${SET28}" "${MSBASDIR}/DefoInterpolx2Detrend28.txt" 
		PlotBaselineGeocMSBASmodeTXT.sh "${SET29}" "${MSBASDIR}/DefoInterpolx2Detrend29.txt" 

		
		# Now msbas single points (with error bars) times series and plots are in dir. Let's add the description to the naming
		cp ${TIMESERIESPTSDESCR} ${MSBASDIR}/zz_UD_EW_TS_Auto_${ORDER}_${LAMBDA}_${LABEL}/

		while read -r DESCR X Y RX RY
			do	
				echo "Rename time series of ${X}_${Y} as ${X}_${Y}_${RX}_${RY}_${DESCR}"
				
				OLL=${ORDER}_${LAMBDA}_${LABEL}
				mv ${MSBASDIR}/zz_UD_EW_TS_Auto_${OLL}/MSBAS_${X}_${Y}_${RX}_${RY}.txt ${MSBASDIR}/zz_UD_EW_TS_Auto_${OLL}/MSBAS_${X}_${Y}_${RX}_${RY}_${DESCR}.txt
				mv ${MSBASDIR}/zz_UD_EW_TS_Auto_${OLL}/MSBAS_${X}_${Y}_${RX}_${RY}.pdf ${MSBASDIR}/zz_UD_EW_TS_Auto_${OLL}/MSBAS_${X}_${Y}_${RX}_${RY}_${DESCR}.pdf
		done < ${TIMESERIESPTSDESCR} | tail -n +2  # ignore header

		# Why not some double difference plotting
		#WhichPlots
		while read -r X1 Y1 X2 Y2 DESCR
			do	
				PlotAll ${X1} ${Y1} ${X2} ${Y2} ${DESCR}
		done < ${DOUBLEDIFFPAIRSEWUD}	
						
 		# move all plots in same dir 
 		rm -f ${MSBASDIR}/zz_UD_EW_TS_Auto_${OLL}/__Combi/*.jpg
 		mv ${MSBASDIR}/zz_UD_EW_TS_Auto_${OLL}/*_Combi.jpg ${MSBASDIR}/zz_UD_EW_TS_Auto_${OLL}/__Combi/

		# move all time series in dir 
		mv ${MSBASDIR}/zz_UD_EW_TS_Auto_${OLL}/*.txt ${MSBASDIR}/zz_UD_EW_TS_Auto_${OLL}/_Time_series/

# Do not needed because performed by ALOS and S1 MSBAS processings  		
#	# Asc and Desc 
# 	#--------------
# 		# Prepare header files
#		#   backup header
#		cp -f ${MSBASDIR}/header.txt ${MSBASDIR}/header_UD_EW.txt 
#
# 		#   Change "SET = " with "#SET = " in each line of header
#		#cat ${MSBASDIR}/header.txt | ${PATHGNU}/gsed "s/SET = /#SET = /g" > ${MSBASDIR}/header_none.txt	 		# This preserves the exclusion of modes here above because excluded ones wil be set as ##SET= here, then back to #SET below
#		cat ${MSBASDIR}/header_all_modes.txt | ${PATHGNU}/gsed "s/SET = /#SET = /g" > ${MSBASDIR}/header_none.txt	# This allows computing LoS of rejected modes as well
#		
#		#   Change "#SET = " with "SET = " for only the mode one wants to keep 
#		cat ${MSBASDIR}/header_none.txt | ${PATHGNU}/gsed ${LINENR01A}' s/#SET = /SET = /' > ${MSBASDIR}/header_${MODE01A}.txt
#		cat ${MSBASDIR}/header_none.txt | ${PATHGNU}/gsed ${LINENR02A}' s/#SET = /SET = /' > ${MSBASDIR}/header_${MODE02A}.txt
#		cat ${MSBASDIR}/header_none.txt | ${PATHGNU}/gsed ${LINENR03A}' s/#SET = /SET = /' > ${MSBASDIR}/header_${MODE03A}.txt
#		cat ${MSBASDIR}/header_none.txt | ${PATHGNU}/gsed ${LINENR04A}' s/#SET = /SET = /' > ${MSBASDIR}/header_${MODE04A}.txt
#		cat ${MSBASDIR}/header_none.txt | ${PATHGNU}/gsed ${LINENR05A}' s/#SET = /SET = /' > ${MSBASDIR}/header_${MODE05A}.txt
#		cat ${MSBASDIR}/header_none.txt | ${PATHGNU}/gsed ${LINENR06A}' s/#SET = /SET = /' > ${MSBASDIR}/header_${MODE06A}.txt
#		cat ${MSBASDIR}/header_none.txt | ${PATHGNU}/gsed ${LINENR07A}' s/#SET = /SET = /' > ${MSBASDIR}/header_${MODE07A}.txt
#		cat ${MSBASDIR}/header_none.txt | ${PATHGNU}/gsed ${LINENR08A}' s/#SET = /SET = /' > ${MSBASDIR}/header_${MODE08A}.txt
#		cat ${MSBASDIR}/header_none.txt | ${PATHGNU}/gsed ${LINENR09A}' s/#SET = /SET = /' > ${MSBASDIR}/header_${MODE09A}.txt
#		cat ${MSBASDIR}/header_none.txt | ${PATHGNU}/gsed ${LINENR10A}' s/#SET = /SET = /' > ${MSBASDIR}/header_${MODE10A}.txt
#		cat ${MSBASDIR}/header_none.txt | ${PATHGNU}/gsed ${LINENR11A}' s/#SET = /SET = /' > ${MSBASDIR}/header_${MODE11A}.txt
#		cat ${MSBASDIR}/header_none.txt | ${PATHGNU}/gsed ${LINENR12A}' s/#SET = /SET = /' > ${MSBASDIR}/header_${MODE12A}.txt
#		cat ${MSBASDIR}/header_none.txt | ${PATHGNU}/gsed ${LINENR13A}' s/#SET = /SET = /' > ${MSBASDIR}/header_${MODE13A}.txt
#
#		cat ${MSBASDIR}/header_none.txt | ${PATHGNU}/gsed ${LINENR01D}' s/#SET = /SET = /' > ${MSBASDIR}/header_${MODE01D}.txt
#		cat ${MSBASDIR}/header_none.txt | ${PATHGNU}/gsed ${LINENR02D}' s/#SET = /SET = /' > ${MSBASDIR}/header_${MODE02D}.txt
#		cat ${MSBASDIR}/header_none.txt | ${PATHGNU}/gsed ${LINENR03D}' s/#SET = /SET = /' > ${MSBASDIR}/header_${MODE03D}.txt
#		cat ${MSBASDIR}/header_none.txt | ${PATHGNU}/gsed ${LINENR04D}' s/#SET = /SET = /' > ${MSBASDIR}/header_${MODE04D}.txt
#		cat ${MSBASDIR}/header_none.txt | ${PATHGNU}/gsed ${LINENR05D}' s/#SET = /SET = /' > ${MSBASDIR}/header_${MODE05D}.txt
#		cat ${MSBASDIR}/header_none.txt | ${PATHGNU}/gsed ${LINENR06D}' s/#SET = /SET = /' > ${MSBASDIR}/header_${MODE06D}.txt
#		cat ${MSBASDIR}/header_none.txt | ${PATHGNU}/gsed ${LINENR07D}' s/#SET = /SET = /' > ${MSBASDIR}/header_${MODE07D}.txt
#		cat ${MSBASDIR}/header_none.txt | ${PATHGNU}/gsed ${LINENR08D}' s/#SET = /SET = /' > ${MSBASDIR}/header_${MODE08D}.txt
#		cat ${MSBASDIR}/header_none.txt | ${PATHGNU}/gsed ${LINENR09D}' s/#SET = /SET = /' > ${MSBASDIR}/header_${MODE09D}.txt
#		cat ${MSBASDIR}/header_none.txt | ${PATHGNU}/gsed ${LINENR10D}' s/#SET = /SET = /' > ${MSBASDIR}/header_${MODE10D}.txt
#		cat ${MSBASDIR}/header_none.txt | ${PATHGNU}/gsed ${LINENR11D}' s/#SET = /SET = /' > ${MSBASDIR}/header_${MODE11D}.txt
#		cat ${MSBASDIR}/header_none.txt | ${PATHGNU}/gsed ${LINENR12D}' s/#SET = /SET = /' > ${MSBASDIR}/header_${MODE12D}.txt
#		cat ${MSBASDIR}/header_none.txt | ${PATHGNU}/gsed ${LINENR13D}' s/#SET = /SET = /' > ${MSBASDIR}/header_${MODE13D}.txt
#		cat ${MSBASDIR}/header_none.txt | ${PATHGNU}/gsed ${LINENR14D}' s/#SET = /SET = /' > ${MSBASDIR}/header_${MODE14D}.txt
#
#		# Several Asc or Desc modes ? 
#		# All Asc 
#		#cp ${MSBASDIR}/header_all_modes.txt > ${MSBASDIR}/header_tmp.txt
#		#cat ${MSBASDIR}/header_tmp.txt | ${PATHGNU}/gsed ${LINENR01A}' s/#SET = /SET = /' > ${MSBASDIR}/header_AllAsc.txt
#		#cat ${MSBASDIR}/header_AllAsc.txt | ${PATHGNU}/gsed ${LINENR02A}' s/#SET = /SET = /' > ${MSBASDIR}/header_tmp.txt
#		#cat ${MSBASDIR}/header_tmp.txt | ${PATHGNU}/gsed ${LINENR03A}' s/#SET = /SET = /' > ${MSBASDIR}/header_AllAsc.txt
#		#cat ${MSBASDIR}/header_AllAsc.txt | ${PATHGNU}/gsed ${LINENR04A}' s/#SET = /SET = /' > ${MSBASDIR}/header_tmp.txt
#		#cat ${MSBASDIR}/header_tmp.txt | ${PATHGNU}/gsed ${LINENR05A}' s/#SET = /SET = /' > ${MSBASDIR}/header_AllAsc.txt
#		#cat ${MSBASDIR}/header_AllAsc.txt | ${PATHGNU}/gsed ${LINENR06A}' s/#SET = /SET = /' > ${MSBASDIR}/header_tmp.txt
#		#cat ${MSBASDIR}/header_tmp.txt | ${PATHGNU}/gsed ${LINENR07A}' s/#SET = /SET = /' > ${MSBASDIR}/header_AllAsc.txt
#		#cat ${MSBASDIR}/header_AllAsc.txt | ${PATHGNU}/gsed ${LINENR08A}' s/#SET = /SET = /' > ${MSBASDIR}/header_tmp.txt
#		#cat ${MSBASDIR}/header_tmp.txt | ${PATHGNU}/gsed ${LINENR09A}' s/#SET = /SET = /' > ${MSBASDIR}/header_AllAsc.txt
#		#cat ${MSBASDIR}/header_AllAsc.txt | ${PATHGNU}/gsed ${LINENR10A}' s/#SET = /SET = /' > ${MSBASDIR}/header_tmp.txt
#		#cat ${MSBASDIR}/header_tmp.txt | ${PATHGNU}/gsed ${LINENR11A}' s/#SET = /SET = /' > ${MSBASDIR}/header_AllAsc.txt
#		#cat ${MSBASDIR}/header_AllAsc.txt | ${PATHGNU}/gsed ${LINENR12A}' s/#SET = /SET = /' > ${MSBASDIR}/header_tmp.txt
#		#cat ${MSBASDIR}/header_tmp.txt | ${PATHGNU}/gsed ${LINENR13A}' s/#SET = /SET = /' > ${MSBASDIR}/header_AllAsc.txt
#		#cp ${MSBASDIR}/header_AllAsc.txt ${MSBASDIR}/header_AllAsc_full.txt
#		# Reject if needed some modes
#		#if [ ${#ALLMODELIST[@]} -ne ${#MODELIST[@]} ]  # i.e. if the two list have not the same length
#		#	then
#		#		echo "// Reject some Asc modes "
#		#		#   Change "SET = " with "#SET = " for only the mode one wants to reject 
#		#		for pos in "${SETTOREJECT[@]}"; do
#    	#			cat ${MSBASDIR}/header_AllAsc.txt | ${PATHGNU}/gsed ${pos}' s/SET = /#SET = /' > header_tst.txt
#    	#			cp -f header_tst.txt ${MSBASDIR}/header_AllAsc.txt  
#		#		done
#		#fi
#
#		# All Desc (beware it would mixe several look angles and az ! => would produce UD/EW decomposition ! DO NOT RUN)
#		#cp ${MSBASDIR}/header_all_modes.txt > ${MSBASDIR}/header_tmp.txt
#		#cat ${MSBASDIR}/header_tmp.txt | ${PATHGNU}/gsed ${LINENR01D}' s/#SET = /SET = /' > ${MSBASDIR}/header_AllDesc.txt
#		#cat ${MSBASDIR}/header_AllDesc.txt | ${PATHGNU}/gsed ${LINENR02D}' s/#SET = /SET = /' > ${MSBASDIR}/header_tmp.txt
#		#cat ${MSBASDIR}/header_tmp.txt | ${PATHGNU}/gsed ${LINENR03D}' s/#SET = /SET = /' > ${MSBASDIR}/header_AllDesc.txt
#		#cat ${MSBASDIR}/header_AllDesc.txt | ${PATHGNU}/gsed ${LINENR04D}' s/#SET = /SET = /' > ${MSBASDIR}/header_tmp.txt
#		#cat ${MSBASDIR}/header_tmp.txt | ${PATHGNU}/gsed ${LINENR05D}' s/#SET = /SET = /' > ${MSBASDIR}/header_AllDesc.txt
#		#cat ${MSBASDIR}/header_AllDesc.txt | ${PATHGNU}/gsed ${LINENR06D}' s/#SET = /SET = /' > ${MSBASDIR}/header_tmp.txt
#		#cat ${MSBASDIR}/header_tmp.txt | ${PATHGNU}/gsed ${LINENR07D}' s/#SET = /SET = /' > ${MSBASDIR}/header_AllDesc.txt
#		#cat ${MSBASDIR}/header_AllDesc.txt | ${PATHGNU}/gsed ${LINENR08D}' s/#SET = /SET = /' > ${MSBASDIR}/header_tmp.txt
#		#cat ${MSBASDIR}/header_tmp.txt | ${PATHGNU}/gsed ${LINENR09D}' s/#SET = /SET = /' > ${MSBASDIR}/header_AllDesc.txt
#		#cat ${MSBASDIR}/header_AllDesc.txt | ${PATHGNU}/gsed ${LINENR10D}' s/#SET = /SET = /' > ${MSBASDIR}/header_tmp.txt
#		#cat ${MSBASDIR}/header_tmp.txt | ${PATHGNU}/gsed ${LINENR11D}' s/#SET = /SET = /' > ${MSBASDIR}/header_AllDesc.txt
#		#cat ${MSBASDIR}/header_AllDesc.txt | ${PATHGNU}/gsed ${LINENR12D}' s/#SET = /SET = /' > ${MSBASDIR}/header_tmp.txt
#		#cat ${MSBASDIR}/header_tmp.txt | ${PATHGNU}/gsed ${LINENR13D}' s/#SET = /SET = /' > ${MSBASDIR}/header_AllDesc.txt
#		#cat ${MSBASDIR}/header_AllDesc.txt | ${PATHGNU}/gsed ${LINENR14D}' s/#SET = /SET = /' > ${MSBASDIR}/header_tmp.txt
#		#mv -f ${MSBASDIR}/header_tmp.txt ${MSBASDIR}/header_AllDesc.txt 
#		#cp ${MSBASDIR}/header_AllDesc.txt ${MSBASDIR}/header_AllDesc_full.txt
#		## Reject if needed some modes
#		#if [ ${#ALLMODELIST[@]} -ne ${#MODELIST[@]} ]  # i.e. if the two list have not the same length
#		#	then
#		#		echo "// Reject some Desc modes "
#		#		#   Change "SET = " with "#SET = " for only the mode one wants to reject 
#		#		for pos in "${SETTOREJECT[@]}"; do
#    	#			cat ${MSBASDIR}/header_AllDesc.txt | ${PATHGNU}/gsed ${pos}' s/SET = /#SET = /' > header_tst.txt
#    	#			cp -f header_tst.txt ${MSBASDIR}/header_AllDesc.txt  
#		#		done
#		#fi
##
#		#rm -f ${MSBASDIR}/header_none.txt ${MSBASDIR}/header_tmp.txt
#
#		# Asc modes
# 				FILEPAIRS=${DOUBLEDIFFPAIRSASC}
# 
# 				MSBASmode ${MODE01A}	# May need to put here the mode instead of its var name ? Or eval in fct 
#   				MSBASmode ${MODE02A}
# 				MSBASmode ${MODE03A}
# 				MSBASmode ${MODE04A}
# 				MSBASmode ${MODE05A}
# 				MSBASmode ${MODE06A}
# 				MSBASmode ${MODE07A}
# 				MSBASmode ${MODE08A}
# 				MSBASmode ${MODE09A}
# 				MSBASmode ${MODE10A}
# 				MSBASmode ${MODE11A}
# 				MSBASmode ${MODE12A}
# 				MSBASmode ${MODE13A}
#
# 		###		MSBASmode AllAsc				
# 				
#		# Desc modes
#  				FILEPAIRS=${DOUBLEDIFFPAIRSDESC}
#
# 				MSBASmode  ${MODE01D}
#   				MSBASmode  ${MODE02D}
# 				MSBASmode  ${MODE03D}
# 				MSBASmode  ${MODE04D}
# 				MSBASmode  ${MODE05D}
# 				MSBASmode  ${MODE06D}
# 				MSBASmode  ${MODE07D}
# 				MSBASmode  ${MODE08D}
# 				MSBASmode  ${MODE09D}
# 				MSBASmode  ${MODE10D}
# 				MSBASmode  ${MODE11D}
# 				MSBASmode  ${MODE12D}
# 				MSBASmode  ${MODE13D}
# 				MSBASmode  ${MODE14D}
#    
#   		###		MSBASmode AllDesc 				
#
# 
# 		# Back to normal for next run and get out
# 				cp -f ${MSBASDIR}/header_UD_EW.txt ${MSBASDIR}/header.txt 		 				
#
				TODAY=`date`
				echo "MSBAS finished on ${TODAY}"  >>  ${MSBASDIR}/_last_MSBAS_process.txt

				echo "${LAST01ATIME}" > ${MSBASDIR}/_Last_MassProcessed_Pairs_Time.txt
				echo "${LAST02ATIME}" >> ${MSBASDIR}/_Last_MassProcessed_Pairs_Time.txt
				echo "${LAST03ATIME}" >> ${MSBASDIR}/_Last_MassProcessed_Pairs_Time.txt
				echo "${LAST04ATIME}" >> ${MSBASDIR}/_Last_MassProcessed_Pairs_Time.txt
				echo "${LAST05ATIME}" >> ${MSBASDIR}/_Last_MassProcessed_Pairs_Time.txt
				echo "${LAST06ATIME}" >> ${MSBASDIR}/_Last_MassProcessed_Pairs_Time.txt
				echo "${LAST07ATIME}" >> ${MSBASDIR}/_Last_MassProcessed_Pairs_Time.txt
				echo "${LAST08ATIME}" >> ${MSBASDIR}/_Last_MassProcessed_Pairs_Time.txt
				echo "${LAST09ATIME}" >> ${MSBASDIR}/_Last_MassProcessed_Pairs_Time.txt
				echo "${LAST10ATIME}" >> ${MSBASDIR}/_Last_MassProcessed_Pairs_Time.txt
				echo "${LAST11ATIME}" >> ${MSBASDIR}/_Last_MassProcessed_Pairs_Time.txt
				echo "${LAST12ATIME}" >> ${MSBASDIR}/_Last_MassProcessed_Pairs_Time.txt
				echo "${LAST13ATIME}" >> ${MSBASDIR}/_Last_MassProcessed_Pairs_Time.txt

				echo "${LAST01DTIME}" >> ${MSBASDIR}/_Last_MassProcessed_Pairs_Time.txt
				echo "${LAST02DTIME}" >> ${MSBASDIR}/_Last_MassProcessed_Pairs_Time.txt
				echo "${LAST03DTIME}" >> ${MSBASDIR}/_Last_MassProcessed_Pairs_Time.txt
				echo "${LAST04DTIME}" >> ${MSBASDIR}/_Last_MassProcessed_Pairs_Time.txt
				echo "${LAST05DTIME}" >> ${MSBASDIR}/_Last_MassProcessed_Pairs_Time.txt
				echo "${LAST06DTIME}" >> ${MSBASDIR}/_Last_MassProcessed_Pairs_Time.txt
				echo "${LAST07DTIME}" >> ${MSBASDIR}/_Last_MassProcessed_Pairs_Time.txt
				echo "${LAST08DTIME}" >> ${MSBASDIR}/_Last_MassProcessed_Pairs_Time.txt
				echo "${LAST09DTIME}" >> ${MSBASDIR}/_Last_MassProcessed_Pairs_Time.txt
				echo "${LAST10DTIME}" >> ${MSBASDIR}/_Last_MassProcessed_Pairs_Time.txt
				echo "${LAST11DTIME}" >> ${MSBASDIR}/_Last_MassProcessed_Pairs_Time.txt
				echo "${LAST12DTIME}" >> ${MSBASDIR}/_Last_MassProcessed_Pairs_Time.txt
				echo "${LAST13DTIME}" >> ${MSBASDIR}/_Last_MassProcessed_Pairs_Time.txt
				echo "${LAST14DTIME}" >> ${MSBASDIR}/_Last_MassProcessed_Pairs_Time.txt
				
				echo "${LAST14ATIME}" >> ${MSBASDIR}/_Last_MassProcessed_Pairs_Time.txt
				echo "${LAST15DTIME}" >> ${MSBASDIR}/_Last_MassProcessed_Pairs_Time.txt

#
## 						
## 		# ASCENDING
## 			cd ${MSBASDIR}
## 			cp -f header_Asc.txt  header.txt 
## 
## 			${PATH_SCRIPTS}/SCRIPTS_MT/MSBAS.sh _Asc_Auto_${ORDER}_${LAMBDA}_${LABEL} ${TIMESERIESPTS}
## 
## 			cp ${TIMESERIESPTSDESCR} ${MSBASDIR}/zz_LOS_TS_Asc_Auto_${ORDER}_${LAMBDA}_${LABEL}/
## 			while read -r DESCR X Y RX RY
## 				do	
## 					echo "Rename time series of ${X}_${Y} as ${X}_${Y}_${RX}_${RY}_${DESCR}"
## 					mv ${MSBASDIR}/zz_LOS_TS_Asc_Auto_${ORDER}_${LAMBDA}_${LABEL}/MSBAS_${X}_${Y}_${RX}_${RY}.txt ${MSBASDIR}/zz_LOS_TS_Asc_Auto_${ORDER}_${LAMBDA}_${LABEL}/MSBAS_${X}_${Y}_${RX}_${RY}_${DESCR}.txt
## 					# there is no automatic plotting by msbas when only in LOS 
## 			done < ${TIMESERIESPTSDESCRNOHEADER}
## 
## 			# Why not some double difference plotting
## 			while read -r X1 Y1 X2 Y2 DESCR
## 				do	
## 					PlotAllLOSasc ${X1} ${Y1} ${X2} ${Y2} ${DESCR}
## 			done < ${DOUBLEDIFFPAIRSASC}		
## 								
## 			# move all plots in same dir 
##  			mv ${MSBASDIR}/zz_LOS_TS_Asc_Auto_${ORDER}_${LAMBDA}_${LABEL}/*_Combi*.jpg ${MSBASDIR}/zz_LOS_TS_Asc_Auto_${ORDER}_${LAMBDA}_${LABEL}/__Combi/
##    			# move all time series in dir 
## 			mv ${MSBASDIR}/zz_LOS_TS_Asc_Auto_${ORDER}_${LAMBDA}_${LABEL}/*.txt ${MSBASDIR}/zz_LOS_TS_Asc_Auto_${ORDER}_${LAMBDA}_${LABEL}/_Time_series/
## 
## 		# DESCENDING
## 			cd ${MSBASDIR}
## 			cp -f header_Desc.txt  header.txt 
## 			
## 			${PATH_SCRIPTS}/SCRIPTS_MT/MSBAS.sh _Desc_Auto_${ORDER}_${LAMBDA}_${LABEL} ${TIMESERIESPTS}
## 
## 			cp ${TIMESERIESPTSDESCR} ${MSBASDIR}/zz_LOS_TS_Desc_Auto_${ORDER}_${LAMBDA}_${LABEL}/
## 			while read -r DESCR X Y RX RY
## 				do	
## 					echo "Rename time series of ${X}_${Y} as ${X}_${Y}_${RX}_${RY}_${DESCR}"
## 					mv ${MSBASDIR}/zz_LOS_TS_Desc_Auto_${ORDER}_${LAMBDA}_${LABEL}/MSBAS_${X}_${Y}_${RX}_${RY}.txt ${MSBASDIR}/zz_LOS_TS_Desc_Auto_${ORDER}_${LAMBDA}_${LABEL}/MSBAS_${X}_${Y}_${RX}_${RY}_${DESCR}.txt
## 					# there is no automatic plotting by msbas when only in LOS 
## 			done < ${TIMESERIESPTSDESCRNOHEADER}
## 
## 			# Why not some double difference plotting			
## 			while read -r X1 Y1 X2 Y2 DESCR
## 				do	
## 					PlotAllLOSdesc ${X1} ${Y1} ${X2} ${Y2} ${DESCR}
## 			done < ${DOUBLEDIFFPAIRSDESC}		
## 	
## 			# move all plots in same dir 
##  			mv ${MSBASDIR}/zz_LOS_TS_Desc_Auto_${ORDER}_${LAMBDA}_${LABEL}/*_Combi*.jpg ${MSBASDIR}/zz_LOS_TS_Desc_Auto_${ORDER}_${LAMBDA}_${LABEL}/__Combi/
##  			# move all time series in dir 
## 			mv ${MSBASDIR}/zz_LOS_TS_Desc_Auto_${ORDER}_${LAMBDA}_${LABEL}/*.txt ${MSBASDIR}/zz_LOS_TS_Desc_Auto_${ORDER}_${LAMBDA}_${LABEL}/_Time_series/
## 
## 	# Back to normal for next run and get out
## 		cp -f ${MSBASDIR}/header_back.txt ${MSBASDIR}/header.txt 		 				
## 
## 		TODAY=`date`
## 		echo "MSBAS finished on ${TODAY}"  >>  ${MSBASDIR}/_last_MSBAS_process.txt
## 
## 		echo "${LASTASCTIME}" > ${MSBASDIR}/_Last_MassProcessed_Pairs_Time.txt
## 		echo "${LASTDESCTIME}" >> ${MSBASDIR}/_Last_MassProcessed_Pairs_Time.txt
#		
#		#mv -f ${MSBASDIR}/${TIMESERIESPTSDESCR}.tmp ${MSBASDIR}/${TIMESERIESPTSDESCR}
#
## All done...
