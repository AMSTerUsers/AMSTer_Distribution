#!/bin/bash
# Script to run in cronjob for processing PF ALOS2 images:
# Runs a mass processing after having checked that no other process is using the same param file (on this computer). 
#
#
# New in Distro V 1.1 20240404:	- run all mass processing in background. 
#								  Beware, this is OK for a routine run, i.e. when not all the 26 
#								  modes are expected to be computed at the same time. In such a case
#								  you may want to add some wait commands in if statement at the end. 
# New in Distro V 1.1 20240521:	- Do not run mass processing of high looking angle (<20°), i.e. 
#								  6778_L_A, 4020_L_D and 4034_R_D because useless and crashes at least before updated reading. 
# New in Distro V 1.2 20240925:	- corr path to log files in $PATH_1660/SAR_MASSPROCESS/ALOS2 instead of S1
# New in Distro V 1.3 202241230 :	- replace ${PATH_1650}/SAR_SM/MSBAS/PF_oldDEM with ${PATH_1650}/SAR_SM/MSBAS/PF
# New in Distro V 1.4 20250410:	- change SM for mode 4041 (13D)
#
# AMSTer: SAR & InSAR Automated Mass processing Software for Multidimensional Time series
# NdO (c) 2016/03/07 - could make better with more functions... when time.
# -----------------------------------------------------------------------------------------
PRG=`basename "$0"`
VER="Distro V1.4 AMSTer script utilities"
AUT="Nicolas d'Oreye, (c)2016-2019, Last modified on Apr 10, 2025"


source $HOME/.bashrc

echo "Starting $0"
cd

TODAY=`date`
MMDDYYYY=$(date +'%m_%d_%Y') # Only needed if restrict pairs after give date, which needs changing hard coded lines in fct

# Ascending modes 
MODE01A=6811_L_A
MODE02A=6806_L_A	# make 6807_L_A as well
MODE03A=6801_L_A	# make 6802_L_A as well
MODE04A=6796_L_A
MODE05A=6790_L_A
MODE06A=6784_L_A
MODE07A=6778_L_A
MODE08A=6764_R_A
MODE09A=6757_R_A
MODE10A=6749_R_A	# make 6750_R_A as well
MODE11A=6742_R_A	# make 6741_R_A as well
MODE12A=6733_R_A
MODE13A=6724_R_A

# Descending modes 
MODE01D=4020_L_D
MODE02D=4014_L_D	
MODE03D=4008_L_D	
MODE04D=4002_L_D
MODE05D=3997_L_D
MODE06D=3992_L_D
MODE07D=3987_L_D
MODE08D=4082_R_D
MODE09D=4073_R_D
MODE10D=4064_R_D	
MODE11D=4056_R_D	
MODE12D=4048_R_D
MODE13D=4041_R_D
MODE14D=4034_R_D	# make 4033_R_D as well


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

# BEWARE: TEMPORARY LOCATION 
SETDIR=$PATH_1650/SAR_SM/MSBAS/PF						# where baseline plots are computed


# Pair files
TABLE01A=${SETDIR}/set5/table_0_${BP01A}_0_${BT01A}.txt		# 6811_L_A
TABLE02A=${SETDIR}/set6/table_0_${BP02A}_0_${BT02A}.txt		# 6806_L_A
TABLE03A=${SETDIR}/set7/table_0_${BP03A}_0_${BT03A}.txt		# 6801_L_A
TABLE04A=${SETDIR}/set8/table_0_${BP04A}_0_${BT04A}.txt		# 6796_L_A
TABLE05A=${SETDIR}/set9/table_0_${BP05A}_0_${BT05A}.txt		# 6790_L_A
TABLE06A=${SETDIR}/set10/table_0_${BP06A}_0_${BT06A}.txt		# 6784_L_A
TABLE07A=${SETDIR}/set11/table_0_${BP07A}_0_${BT07A}.txt		# 6778_L_A
TABLE08A=${SETDIR}/set12/table_0_${BP08A}_0_${BT08A}.txt		# 6764_R_A
TABLE09A=${SETDIR}/set13/table_0_${BP09A}_0_${BT09A}.txt		# 6757_R_A
TABLE10A=${SETDIR}/set14/table_0_${BP10A}_0_${BT10A}.txt		# 6749_R_A
TABLE11A=${SETDIR}/set15/table_0_${BP11A}_0_${BT11A}.txt		# 6742_R_A
TABLE12A=${SETDIR}/set16/table_0_${BP12A}_0_${BT12A}.txt		# 6733_R_A
TABLE13A=${SETDIR}/set17/table_0_${BP13A}_0_${BT13A}.txt		# 6724_R_A

TABLE01D=${SETDIR}/set18/table_0_${BP01D}_0_${BT01D}.txt		# 4020_L_D
TABLE02D=${SETDIR}/set19/table_0_${BP02D}_0_${BT02D}.txt		# 4014_L_D
TABLE03D=${SETDIR}/set20/table_0_${BP03D}_0_${BT03D}.txt		# 4008_L_D
TABLE04D=${SETDIR}/set21/table_0_${BP04D}_0_${BT04D}.txt		# 4002_L_D
TABLE05D=${SETDIR}/set22/table_0_${BP05D}_0_${BT05D}.txt		# 3997_L_D
TABLE06D=${SETDIR}/set23/table_0_${BP06D}_0_${BT06D}.txt		# 3992_L_D
TABLE07D=${SETDIR}/set24/table_0_${BP07D}_0_${BT07D}.txt		# 3987_L_D
TABLE08D=${SETDIR}/set25/table_0_${BP08D}_0_${BT08D}.txt		# 4082_R_D
TABLE09D=${SETDIR}/set26/table_0_${BP09D}_0_${BT09D}.txt		# 4073_R_D
TABLE10D=${SETDIR}/set27/table_0_${BP10D}_0_${BT10D}.txt		# 4064_R_D
TABLE11D=${SETDIR}/set28/table_0_${BP11D}_0_${BT11D}.txt		# 4056_R_D
TABLE12D=${SETDIR}/set29/table_0_${BP12D}_0_${BT12D}.txt		# 4048_R_D
TABLE13D=${SETDIR}/set30/table_0_${BP13D}_0_${BT13D}.txt		# 4041_R_D
TABLE14D=${SETDIR}/set31/table_0_${BP14D}_0_${BT14D}.txt		# 4034_R_D

# Parameters files
PARAMPROCESS01A=$PATH_1650/Param_files/ALOS2/PF/${MODE01A}/LaunchMTparam_ALOS2_${MODE01A}_Full_Zoom1_ML8_MassProc.txt		# 6811_L_A
PARAMPROCESS02A=$PATH_1650/Param_files/ALOS2/PF/${MODE02A}/LaunchMTparam_ALOS2_${MODE02A}_Full_Zoom1_ML8_MassProc.txt		# 6806_L_A
PARAMPROCESS03A=$PATH_1650/Param_files/ALOS2/PF/${MODE03A}/LaunchMTparam_ALOS2_${MODE03A}_Full_Zoom1_ML8_MassProc.txt		# 6801_L_A
PARAMPROCESS04A=$PATH_1650/Param_files/ALOS2/PF/${MODE04A}/LaunchMTparam_ALOS2_${MODE04A}_Full_Zoom1_ML8_MassProc.txt		# 6796_L_A
PARAMPROCESS05A=$PATH_1650/Param_files/ALOS2/PF/${MODE05A}/LaunchMTparam_ALOS2_${MODE05A}_Full_Zoom1_ML8_MassProc.txt		# 6790_L_A
PARAMPROCESS06A=$PATH_1650/Param_files/ALOS2/PF/${MODE06A}/LaunchMTparam_ALOS2_${MODE06A}_Full_Zoom1_ML8_MassProc.txt		# 6784_L_A
PARAMPROCESS07A=$PATH_1650/Param_files/ALOS2/PF/${MODE07A}/LaunchMTparam_ALOS2_${MODE07A}_Full_Zoom1_ML8_MassProc.txt		# 6778_L_A
PARAMPROCESS08A=$PATH_1650/Param_files/ALOS2/PF/${MODE08A}/LaunchMTparam_ALOS2_${MODE08A}_Full_Zoom1_ML8_MassProc.txt		# 6764_R_A
PARAMPROCESS09A=$PATH_1650/Param_files/ALOS2/PF/${MODE09A}/LaunchMTparam_ALOS2_${MODE09A}_Full_Zoom1_ML8_MassProc.txt		# 6757_R_A
PARAMPROCESS10A=$PATH_1650/Param_files/ALOS2/PF/${MODE10A}/LaunchMTparam_ALOS2_${MODE10A}_Full_Zoom1_ML8_MassProc.txt		# 6749_R_A
PARAMPROCESS11A=$PATH_1650/Param_files/ALOS2/PF/${MODE11A}/LaunchMTparam_ALOS2_${MODE11A}_Full_Zoom1_ML8_MassProc.txt		# 6742_R_A
PARAMPROCESS12A=$PATH_1650/Param_files/ALOS2/PF/${MODE12A}/LaunchMTparam_ALOS2_${MODE12A}_Full_Zoom1_ML8_MassProc.txt		# 6733_R_A
PARAMPROCESS13A=$PATH_1650/Param_files/ALOS2/PF/${MODE13A}/LaunchMTparam_ALOS2_${MODE13A}_Full_Zoom1_ML8_MassProc.txt		# 6724_R_A

PARAMPROCESS01D=$PATH_1650/Param_files/ALOS2/PF/${MODE01D}/LaunchMTparam_ALOS2_${MODE01D}_Full_Zoom1_ML8_MassProc.txt		# 4020_L_D
PARAMPROCESS02D=$PATH_1650/Param_files/ALOS2/PF/${MODE02D}/LaunchMTparam_ALOS2_${MODE02D}_Full_Zoom1_ML8_MassProc.txt		# 4014_L_D
PARAMPROCESS03D=$PATH_1650/Param_files/ALOS2/PF/${MODE03D}/LaunchMTparam_ALOS2_${MODE03D}_Full_Zoom1_ML8_MassProc.txt		# 4008_L_D
PARAMPROCESS04D=$PATH_1650/Param_files/ALOS2/PF/${MODE04D}/LaunchMTparam_ALOS2_${MODE04D}_Full_Zoom1_ML8_MassProc.txt		# 4002_L_D
PARAMPROCESS05D=$PATH_1650/Param_files/ALOS2/PF/${MODE05D}/LaunchMTparam_ALOS2_${MODE05D}_Full_Zoom1_ML8_MassProc.txt		# 3997_L_D
PARAMPROCESS06D=$PATH_1650/Param_files/ALOS2/PF/${MODE06D}/LaunchMTparam_ALOS2_${MODE06D}_Full_Zoom1_ML8_MassProc.txt		# 3992_L_D
PARAMPROCESS07D=$PATH_1650/Param_files/ALOS2/PF/${MODE07D}/LaunchMTparam_ALOS2_${MODE07D}_Full_Zoom1_ML8_MassProc.txt		# 3987_L_D
PARAMPROCESS08D=$PATH_1650/Param_files/ALOS2/PF/${MODE08D}/LaunchMTparam_ALOS2_${MODE08D}_Full_Zoom1_ML8_MassProc.txt		# 4082_R_D
PARAMPROCESS09D=$PATH_1650/Param_files/ALOS2/PF/${MODE09D}/LaunchMTparam_ALOS2_${MODE09D}_Full_Zoom1_ML8_MassProc.txt		# 4073_R_D
PARAMPROCESS10D=$PATH_1650/Param_files/ALOS2/PF/${MODE10D}/LaunchMTparam_ALOS2_${MODE10D}_Full_Zoom1_ML8_MassProc.txt		# 4064_R_D
PARAMPROCESS11D=$PATH_1650/Param_files/ALOS2/PF/${MODE11D}/LaunchMTparam_ALOS2_${MODE11D}_Full_Zoom1_ML8_MassProc.txt		# 4056_R_D
PARAMPROCESS12D=$PATH_1650/Param_files/ALOS2/PF/${MODE12D}/LaunchMTparam_ALOS2_${MODE12D}_Full_Zoom1_ML8_MassProc.txt		# 4048_R_D
PARAMPROCESS13D=$PATH_1650/Param_files/ALOS2/PF/${MODE13D}/LaunchMTparam_ALOS2_${MODE13D}_Full_Zoom1_ML8_MassProc.txt		# 4041_R_D
PARAMPROCESS14D=$PATH_1650/Param_files/ALOS2/PF/${MODE14D}/LaunchMTparam_ALOS2_${MODE14D}_Full_Zoom1_ML8_MassProc.txt		# 4034_R_D


# Funstions 
###########

function LaunchMassProc()
	{
		MODE=$1			# mode e.g. ${MODE01A}
		SM=$2			# super master e.g. ${SM01A}
		TABLE=$3		# table file e.g. ${TABLE01A}
		PARAM=$4		# param file e.g  ${PARAMPROCESS01A}

		# Check that no other SuperMaster mass processing uses the LaunchMTparam_.txt yet
		PARAMNAME=`basename ${PARAM}`
		CHECK=`ps -eaf | ${PATHGNU}/grep SuperMaster_MassProc.sh | ${PATHGNU}/grep -v "grep "  | ${PATHGNU}/grep ${PARAMNAME} | wc -l`
	
		if [ ${CHECK} -lt 1 ] 
			then 
				# No process running yet
				echo "${MODE} run on ${TODAY}"  >>  $PATH_1660/SAR_MASSPROCESS/ALOS2/PF_${MODE}/SMNoCrop_SM_${SM}_Zoom1_ML8/_${MODE}_last_MassRun.txt
				
				## first restric pair table to data after March 2021 (i.e. from April)
				#RemovePairsFromFlist_WithImagesBefore.sh ${TABLE} 20210331
				## Run on restricted pairs 
				#$PATH_SCRIPTS/SCRIPTS_MT/SuperMaster_MassProc.sh ${TABLE}_After20210331_WithBaselines_${MMDDYYYY}.txt ${PARAM} > /dev/null 2>&1 &
				## To avoid new table at each run
				#mv ${TABLE}_After20210331_WithBaselines_${MMDDYYYY}.txt ${TABLE}_After20210331_WithBaselines.txt

				# Run on all pairs 
				$PATH_SCRIPTS/SCRIPTS_MT/SuperMaster_MassProc.sh ${TABLE} ${PARAM} > /dev/null 2>&1 &

			else 
				echo "${MODE} attempt aborted on ${TODAY} because other Mass Process in progress"  >>  $PATH_1660/SAR_MASSPROCESS/S1/PF_ALOS2_${MODE}/SMNoCrop_SM_${SM}_Zoom1_ML8/_${MODE}_last_aborted.txt
		fi
	}



# Check that cron step1 is finished
CHECKREAD=`ps -eaf | ${PATHGNU}/grep PF_ALOS2_Step1_Read_SMCoreg_Pairs.sh | ${PATHGNU}/grep -v "grep " | wc -l`

if [ ${CHECKREAD} -eq 0 ] 
	then 
		# OK, no more Step1 is running: 

		# Launch Asc if no other processing is running or log reason of not processing
		LaunchMassProc ${MODE01A} ${SM01A} ${TABLE01A} ${PARAMPROCESS01A} &		# 6811_L_A
		LaunchMassProc ${MODE02A} ${SM02A} ${TABLE02A} ${PARAMPROCESS02A} &		# 6806_L_A
		LaunchMassProc ${MODE03A} ${SM03A} ${TABLE03A} ${PARAMPROCESS03A} &		# 6801_L_A
		LaunchMassProc ${MODE04A} ${SM04A} ${TABLE04A} ${PARAMPROCESS04A} &		# 6796_L_A
		LaunchMassProc ${MODE05A} ${SM05A} ${TABLE05A} ${PARAMPROCESS05A} &		# 6790_L_A
		LaunchMassProc ${MODE06A} ${SM06A} ${TABLE06A} ${PARAMPROCESS06A} &		# 6784_L_A
#		LaunchMassProc ${MODE07A} ${SM07A} ${TABLE07A} ${PARAMPROCESS07A} &		# 6778_L_A  Not processed because low angle
		LaunchMassProc ${MODE08A} ${SM08A} ${TABLE08A} ${PARAMPROCESS08A} &		# 6764_R_A
		LaunchMassProc ${MODE09A} ${SM09A} ${TABLE09A} ${PARAMPROCESS09A} &		# 6757_R_A
		LaunchMassProc ${MODE10A} ${SM10A} ${TABLE10A} ${PARAMPROCESS10A} &		# 6749_R_A
		LaunchMassProc ${MODE11A} ${SM11A} ${TABLE11A} ${PARAMPROCESS11A} &		# 6742_R_A
		LaunchMassProc ${MODE12A} ${SM12A} ${TABLE12A} ${PARAMPROCESS12A} &		# 6733_R_A
		LaunchMassProc ${MODE13A} ${SM13A} ${TABLE13A} ${PARAMPROCESS13A} &		# 6724_R_A

		# Launch Desc if no other processing is running or log reason of not processing
#		LaunchMassProc ${MODE01D} ${SM01D} ${TABLE01D} ${PARAMPROCESS01D} &		# 4020_L_D  Not processed because low angle
		LaunchMassProc ${MODE02D} ${SM02D} ${TABLE02D} ${PARAMPROCESS02D} &		# 4014_L_D
		LaunchMassProc ${MODE03D} ${SM03D} ${TABLE03D} ${PARAMPROCESS03D} &		# 4008_L_D
		LaunchMassProc ${MODE04D} ${SM04D} ${TABLE04D} ${PARAMPROCESS04D} &		# 4002_L_D
		LaunchMassProc ${MODE05D} ${SM05D} ${TABLE05D} ${PARAMPROCESS05D} &		# 3997_L_D  BEWARE: no recent data !! 
		LaunchMassProc ${MODE06D} ${SM06D} ${TABLE06D} ${PARAMPROCESS06D} &		# 3992_L_D
		LaunchMassProc ${MODE07D} ${SM07D} ${TABLE07D} ${PARAMPROCESS07D} &		# 3987_L_D  BEWARE: very few recent data !! 
		LaunchMassProc ${MODE08D} ${SM08D} ${TABLE08D} ${PARAMPROCESS08D} &		# 4082_R_D
		LaunchMassProc ${MODE09D} ${SM09D} ${TABLE09D} ${PARAMPROCESS09D} &		# 4073_R_D
		LaunchMassProc ${MODE10D} ${SM10D} ${TABLE10D} ${PARAMPROCESS10D} &		# 4064_R_D
		LaunchMassProc ${MODE11D} ${SM11D} ${TABLE11D} ${PARAMPROCESS11D} &		# 4056_R_D
		LaunchMassProc ${MODE12D} ${SM12D} ${TABLE12D} ${PARAMPROCESS12D} &		# 4048_R_D
		LaunchMassProc ${MODE13D} ${SM13D} ${TABLE13D} ${PARAMPROCESS13D} &		# 4041_R_D
#		LaunchMassProc ${MODE14D} ${SM14D} ${TABLE14D} ${PARAMPROCESS14D} &		# 4034_R_D  Not processed because low angle
		wait
		
	else 
		# Step1 is still running: abort and wait for tomorrow
		echo "Step2 aborted on ${TODAY} because PF_ALOS2_Step1_Read_SMCoreg_Pairs.sh is still running: wait for tomorrow"  >>  $PATH_1660/SAR_MASSPROCESS/ALOS2/PF_ALOS2_${MODE01A}/SMNoCrop_SM_${SM01A}_Zoom1_ML8/_aborted_because_Read_inProgress.txt
		echo "Step2 aborted on ${TODAY} because PF_ALOS2_Step1_Read_SMCoreg_Pairs.sh is still running: wait for tomorrow"  >>  $PATH_1660/SAR_MASSPROCESS/ALOS2/PF_ALOS2_${MODE02A}/SMNoCrop_SM_${SM02A}_Zoom1_ML8/_aborted_because_Read_inProgress.txt
		echo "Step2 aborted on ${TODAY} because PF_ALOS2_Step1_Read_SMCoreg_Pairs.sh is still running: wait for tomorrow"  >>  $PATH_1660/SAR_MASSPROCESS/ALOS2/PF_ALOS2_${MODE03A}/SMNoCrop_SM_${SM03A}_Zoom1_ML8/_aborted_because_Read_inProgress.txt
		echo "Step2 aborted on ${TODAY} because PF_ALOS2_Step1_Read_SMCoreg_Pairs.sh is still running: wait for tomorrow"  >>  $PATH_1660/SAR_MASSPROCESS/ALOS2/PF_ALOS2_${MODE04A}/SMNoCrop_SM_${SM04A}_Zoom1_ML8/_aborted_because_Read_inProgress.txt
		echo "Step2 aborted on ${TODAY} because PF_ALOS2_Step1_Read_SMCoreg_Pairs.sh is still running: wait for tomorrow"  >>  $PATH_1660/SAR_MASSPROCESS/ALOS2/PF_ALOS2_${MODE05A}/SMNoCrop_SM_${SM05A}_Zoom1_ML8/_aborted_because_Read_inProgress.txt
		echo "Step2 aborted on ${TODAY} because PF_ALOS2_Step1_Read_SMCoreg_Pairs.sh is still running: wait for tomorrow"  >>  $PATH_1660/SAR_MASSPROCESS/ALOS2/PF_ALOS2_${MODE06A}/SMNoCrop_SM_${SM06A}_Zoom1_ML8/_aborted_because_Read_inProgress.txt
		echo "Step2 aborted on ${TODAY} because PF_ALOS2_Step1_Read_SMCoreg_Pairs.sh is still running: wait for tomorrow"  >>  $PATH_1660/SAR_MASSPROCESS/ALOS2/PF_ALOS2_${MODE07A}/SMNoCrop_SM_${SM07A}_Zoom1_ML8/_aborted_because_Read_inProgress.txt
		echo "Step2 aborted on ${TODAY} because PF_ALOS2_Step1_Read_SMCoreg_Pairs.sh is still running: wait for tomorrow"  >>  $PATH_1660/SAR_MASSPROCESS/ALOS2/PF_ALOS2_${MODE08A}/SMNoCrop_SM_${SM08A}_Zoom1_ML8/_aborted_because_Read_inProgress.txt
		echo "Step2 aborted on ${TODAY} because PF_ALOS2_Step1_Read_SMCoreg_Pairs.sh is still running: wait for tomorrow"  >>  $PATH_1660/SAR_MASSPROCESS/ALOS2/PF_ALOS2_${MODE09A}/SMNoCrop_SM_${SM09A}_Zoom1_ML8/_aborted_because_Read_inProgress.txt
		echo "Step2 aborted on ${TODAY} because PF_ALOS2_Step1_Read_SMCoreg_Pairs.sh is still running: wait for tomorrow"  >>  $PATH_1660/SAR_MASSPROCESS/ALOS2/PF_ALOS2_${MODE10A}/SMNoCrop_SM_${SM10A}_Zoom1_ML8/_aborted_because_Read_inProgress.txt
		echo "Step2 aborted on ${TODAY} because PF_ALOS2_Step1_Read_SMCoreg_Pairs.sh is still running: wait for tomorrow"  >>  $PATH_1660/SAR_MASSPROCESS/ALOS2/PF_ALOS2_${MODE11A}/SMNoCrop_SM_${SM11A}_Zoom1_ML8/_aborted_because_Read_inProgress.txt
		echo "Step2 aborted on ${TODAY} because PF_ALOS2_Step1_Read_SMCoreg_Pairs.sh is still running: wait for tomorrow"  >>  $PATH_1660/SAR_MASSPROCESS/ALOS2/PF_ALOS2_${MODE12A}/SMNoCrop_SM_${SM12A}_Zoom1_ML8/_aborted_because_Read_inProgress.txt
		echo "Step2 aborted on ${TODAY} because PF_ALOS2_Step1_Read_SMCoreg_Pairs.sh is still running: wait for tomorrow"  >>  $PATH_1660/SAR_MASSPROCESS/ALOS2/PF_ALOS2_${MODE13A}/SMNoCrop_SM_${SM13A}_Zoom1_ML8/_aborted_because_Read_inProgress.txt
		
		echo "Step2 aborted on ${TODAY} because PF_ALOS2_Step1_Read_SMCoreg_Pairs.sh is still running: wait for tomorrow"  >>  $PATH_1660/SAR_MASSPROCESS/ALOS2/PF_ALOS2_${MODE01D}/SMNoCrop_SM_${SM01D}_Zoom1_ML8/_aborted_because_Read_inProgress.txt
		echo "Step2 aborted on ${TODAY} because PF_ALOS2_Step1_Read_SMCoreg_Pairs.sh is still running: wait for tomorrow"  >>  $PATH_1660/SAR_MASSPROCESS/ALOS2/PF_ALOS2_${MODE02D}/SMNoCrop_SM_${SM02D}_Zoom1_ML8/_aborted_because_Read_inProgress.txt
		echo "Step2 aborted on ${TODAY} because PF_ALOS2_Step1_Read_SMCoreg_Pairs.sh is still running: wait for tomorrow"  >>  $PATH_1660/SAR_MASSPROCESS/ALOS2/PF_ALOS2_${MODE03D}/SMNoCrop_SM_${SM03D}_Zoom1_ML8/_aborted_because_Read_inProgress.txt
		echo "Step2 aborted on ${TODAY} because PF_ALOS2_Step1_Read_SMCoreg_Pairs.sh is still running: wait for tomorrow"  >>  $PATH_1660/SAR_MASSPROCESS/ALOS2/PF_ALOS2_${MODE04D}/SMNoCrop_SM_${SM04D}_Zoom1_ML8/_aborted_because_Read_inProgress.txt
		echo "Step2 aborted on ${TODAY} because PF_ALOS2_Step1_Read_SMCoreg_Pairs.sh is still running: wait for tomorrow"  >>  $PATH_1660/SAR_MASSPROCESS/ALOS2/PF_ALOS2_${MODE05D}/SMNoCrop_SM_${SM05D}_Zoom1_ML8/_aborted_because_Read_inProgress.txt
		echo "Step2 aborted on ${TODAY} because PF_ALOS2_Step1_Read_SMCoreg_Pairs.sh is still running: wait for tomorrow"  >>  $PATH_1660/SAR_MASSPROCESS/ALOS2/PF_ALOS2_${MODE06D}/SMNoCrop_SM_${SM06D}_Zoom1_ML8/_aborted_because_Read_inProgress.txt
		echo "Step2 aborted on ${TODAY} because PF_ALOS2_Step1_Read_SMCoreg_Pairs.sh is still running: wait for tomorrow"  >>  $PATH_1660/SAR_MASSPROCESS/ALOS2/PF_ALOS2_${MODE07D}/SMNoCrop_SM_${SM07D}_Zoom1_ML8/_aborted_because_Read_inProgress.txt
		echo "Step2 aborted on ${TODAY} because PF_ALOS2_Step1_Read_SMCoreg_Pairs.sh is still running: wait for tomorrow"  >>  $PATH_1660/SAR_MASSPROCESS/ALOS2/PF_ALOS2_${MODE08D}/SMNoCrop_SM_${SM08D}_Zoom1_ML8/_aborted_because_Read_inProgress.txt
		echo "Step2 aborted on ${TODAY} because PF_ALOS2_Step1_Read_SMCoreg_Pairs.sh is still running: wait for tomorrow"  >>  $PATH_1660/SAR_MASSPROCESS/ALOS2/PF_ALOS2_${MODE09D}/SMNoCrop_SM_${SM09D}_Zoom1_ML8/_aborted_because_Read_inProgress.txt
		echo "Step2 aborted on ${TODAY} because PF_ALOS2_Step1_Read_SMCoreg_Pairs.sh is still running: wait for tomorrow"  >>  $PATH_1660/SAR_MASSPROCESS/ALOS2/PF_ALOS2_${MODE10D}/SMNoCrop_SM_${SM10D}_Zoom1_ML8/_aborted_because_Read_inProgress.txt
		echo "Step2 aborted on ${TODAY} because PF_ALOS2_Step1_Read_SMCoreg_Pairs.sh is still running: wait for tomorrow"  >>  $PATH_1660/SAR_MASSPROCESS/ALOS2/PF_ALOS2_${MODE11D}/SMNoCrop_SM_${SM11D}_Zoom1_ML8/_aborted_because_Read_inProgress.txt
		echo "Step2 aborted on ${TODAY} because PF_ALOS2_Step1_Read_SMCoreg_Pairs.sh is still running: wait for tomorrow"  >>  $PATH_1660/SAR_MASSPROCESS/ALOS2/PF_ALOS2_${MODE12D}/SMNoCrop_SM_${SM12D}_Zoom1_ML8/_aborted_because_Read_inProgress.txt
		echo "Step2 aborted on ${TODAY} because PF_ALOS2_Step1_Read_SMCoreg_Pairs.sh is still running: wait for tomorrow"  >>  $PATH_1660/SAR_MASSPROCESS/ALOS2/PF_ALOS2_${MODE13D}/SMNoCrop_SM_${SM13D}_Zoom1_ML8/_aborted_because_Read_inProgress.txt
		echo "Step2 aborted on ${TODAY} because PF_ALOS2_Step1_Read_SMCoreg_Pairs.sh is still running: wait for tomorrow"  >>  $PATH_1660/SAR_MASSPROCESS/ALOS2/PF_ALOS2_${MODE14D}/SMNoCrop_SM_${SM14D}_Zoom1_ML8/_aborted_because_Read_inProgress.txt

		exit 0
fi

