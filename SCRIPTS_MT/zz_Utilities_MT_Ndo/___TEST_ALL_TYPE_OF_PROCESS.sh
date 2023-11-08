#!/bin/bash
######################################################################################
# This script check several type of processing. Usefull to test in one batch AS in all cases. 
# Each processing will be done in a new termnal. Processes will be run on separate disks as 
# described in table below (defined from LaunchParam.txt, then moved to /$PATH_3602/TEST_ALL_TYPE_PROCESS/${RUNDATE}
#
# WAIT FOR USER TO ANSWER "n" (or "y") WHEN ASKED TO BENEFIT FROM PREVIOUS SM COREGISTRATION 
#
# It will test the following satellies as Single Pair and Single Pair coregistered on Global Primary (SuperMaster) :
#
#   				SATELLITE						|   on HD	|		mode				|	Rem
# ----------------------------------------------------------------------------------------------------
#	- S1 wide swath (Coreg on SM should be refused)	|	1650/MT_2	| Nyigo Crater D21			| No Mask (no SM)
#	- S1 Stripmap									|	3601/MT	| Tristan Asc				| No Mask & Crop
#	- CSK											|	3602/MT	| Virunga Desc				| Mask Coh
#	- ENVISAT										|	1650/MT	| ASARNyigo A114			| Mask Coh
# 	- Radarsat										|	3600/MT	| RS2F_UH_Asc36deg			| Mask Coh
#	- TSX											|	3601/MT	| GOMA_SAKE_NYIGO_StMp_D92	| Mask Water bodies
#	- ERS											|	3602/MT	| NYIGO_Asc					| Mask Coh
#	- TDX DEFO mode from Bistatic pairs	(m!=S)		|	3602/MT	| GOMA_SAKE_NYIGO_StMp_D92	| Mask only (no SM)
#	- TDX TOPO mode from Bistatic pairs	(m=s)		|	3602/MT	| GOMA_SAKE_NYIGO_StMp_D92	| Mask only (no SM)
#	- TDX TOPO mode from Bistatic pairs	(m!=S)		|	3602/MT	| GOMA_SAKE_NYIGO_StMp_D92	| Mask only (no SM)
#	- TDX DEFO mode from Pursuit pairs	(m!=S)		|	3602/MT	| NYIGO_MIKENO_StMp_Desc16	| Mask only (no SM)
#	- TDX TOPO mode from Pursuit pairs	(m=s)		|	3602/MT	| NYIGO_MIKENO_StMp_Desc16	| Mask only (no SM)
#	- TDX TOPO mode from Pursuit pairs	(m!=S)		|	3602/MT	| NYIGO_MIKENO_StMp_Desc16	| Mask only (no SM)
#
#
# Dependencies:	- gnu sed and awk for more compatibility. 
#               - Appel's osascript for opening terminal windows if OS is Mac
#               - x-termoinal-emulator for opening terminal windows if OS is Linux
#				- scripts SinglePair.sh and MasterDEM.sh 
#
#
# New in Distro V 1.1: - More modes
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


# Activate/Deactivate processing test for the following satellites
# if == "Yes", will test; anything else, will skip test
TSTS1WS=No 
TSTS1SM=No						
TSTCSK=No							
TSTENV=No							
TSTRS=No							
TSTTSX=No								
TSTERS=No	
TSTTDXDEFOBIS=Yes
TSTTDXTOPOBISSAMEDATE=Yes
TSTTDXTOPOBISDIFFDATE=Yes  # do not run at teh same time and with same dates as TSTTDXDEFOBIS
TSTTDXDEFOPM=Yes	
TSTTDXTOPOPMSAMEDATE=Yes
TSTTDXTOPOPMDIFFDATE=Yes # do not run at teh same time and with same dates as TSTTDXDEFOPM

mkdir -p /$PATH_3602/TEST_ALL_TYPE_PROCESS
RUNDATE=`date "+ %m_%d_%Y_%Hh%Mm" | ${PATHGNU}/gsed "s/ //g"`
STOREDIR=/$PATH_3602/TEST_ALL_TYPE_PROCESS/${RUNDATE}
eval STOREDIR=${STOREDIR}

# Check OS
OS=`uname -a | cut -d " " -f 1 `
echo "Running on ${OS}"
echo

function LaunchSingleTest()
	{
	local MAS=$1  	# Primary date
	local SLV=$2	# Secondary date 
	local SAT=$3	# sat
	local MODE=$4	# mode
	local PARAMFILE=$5 	# param file 
	local RUNDIR=$6		# rundir in param file, where all results are computed
	STOREDIR=$7	# where test script is launched

	mkdir -p ${STOREDIR}/${SAT}/${MODE}/SINGLEPAIR/
	cp $PATH_SCRIPTS/SCRIPTS_ME/SinglePair.sh ${STOREDIR}/SinglePair_${SAT}_${MODE}_NoSM_${MAS}_${SLV}.sh
	echo "mv ${RUNDIR} ${STOREDIR}/${SAT}/${MODE}/SINGLEPAIR/ " >> ${STOREDIR}/SinglePair_${SAT}_${MODE}_NoSM_${MAS}_${SLV}.sh
	#echo "n" | ${STOREDIR}/SinglePair_${SAT}_${MODE}_NoSM_${MAS}_${SLV}.sh ${MAS} ${SLV} ${PARAMFILE} _AUTOTEST > /dev/null &
	
	case ${OS} in 
		"Linux") 
			echo x-terminal-emulator -e LaunchTerminal.sh echo "n" | ${STOREDIR}/SinglePair_${SAT}_${MODE}_NoSM_${MAS}_${SLV}.sh ${MAS} ${SLV} ${PARAMFILE} _AUTOTEST &
			;;
		"Darwin")
			osascript -e 'tell app "Terminal" 
			do script "'"${STOREDIR}"'/SinglePair_'"${SAT}"'_'"${MODE}"'_NoSM_'"${MAS}"'_'"${SLV}"'.sh  '"${MAS} ${SLV} ${PARAMFILE} _AUTOTEST"'"
			end tell'
			;;
		*)
			echo "I can't figure out what is you opeating system. Please check"
			exit 0
			;;
	esac			
	echo "${SAT} ${MODE} NoSM ${MAS} ${SLV} done" 
	}
	
function LaunchSingleSMTest()
	{
	local MAS=$1
	local SLV=$2
	local SM=$3
	local SAT=$4
	local MODE=$5
	local PARAMFILE=$6
	local RUNDIR=$7
	STOREDIR=$8	# where test script is launched
	
	mkdir -p ${STOREDIR}/${SAT}/${MODE}/SINGLEPAIR_SM/
	cp $PATH_SCRIPTS/SCRIPTS_ME/SinglePair.sh ${STOREDIR}/SinglePair_${SAT}_${MODE}_SM_${MAS}_${SLV}.sh
	echo "mv ${RUNDIR} ${STOREDIR}/${SAT}/${MODE}/SINGLEPAIR_SM/ " >> ${STOREDIR}/SinglePair_${SAT}_${MODE}_SM_${MAS}_${SLV}.sh
	#${STOREDIR}/SinglePair_${SAT}_${MODE}_SM_${MAS}_${SLV}.sh ${MAS} ${SLV} ${PARAMFILE} _SM${SM}_AUTOTEST ${SM} > /dev/null &
	
	case ${OS} in 
		"Linux") 
			x-terminal-emulator -e LaunchTerminal.sh ${STOREDIR}/SinglePair_${SAT}_${MODE}_SM_${MAS}_${SLV}.sh ${MAS} ${SLV} ${PARAMFILE} _SM${SM}_AUTOTEST ${SM} &
			;;
		"Darwin")
			osascript -e 'tell app "Terminal"
			do script "'"${STOREDIR}"'/SinglePair_'"${SAT}"'_'"${MODE}"'_SM_'"${MAS}"'_'"${SLV}"'.sh '"${MAS} ${SLV} ${PARAMFILE} _SM${SM}_AUTOTEST ${SM}"'"
			end tell'		;;
		*)
			echo "I can't figure out what is you opeating system. Please check"
			exit 0
			;;
	esac			
	
	echo "${SAT} ${MODE} SM ${MAS} ${SLV} done" 
	}

function GetParam()
	{
	unset PARAM 
	PARAM=$1
	PARAM=`grep -m 1 ${PARAM} ${PARAMFILE} | cut -f1 -d \# | ${PATHGNU}/gsed "s/	//g" | ${PATHGNU}/gsed "s/ //g"` 
	eval PARAM=${PARAM}
	echo ${PARAM}
	}



# Test Single Pair : 
####################
# S1 WIDESWATH : test using Nyigo Crater Desc 21 on 1650
if [ ${TSTS1WS} == "Yes" ] ; then
	MAS=20141007
	SLV=20141124
	SM=20151014
	PARAMFILE="/$PATH_1650/Param_files/S1/DRC_Nyigo_Nyam_Crater_Desc21/LaunchMTparam_S1_Nyigo_Nyam_CraterDesc_Zoom1_ML4_monitoring.txt"

	REGION=`GetParam "REGION,"`					# REGION, Text description of area for dir naming
	ZOOM=`GetParam "ZOOM,"`						# ZOOM, zoom factor used while cropping
	INTERFML=`GetParam "INTERFML,"`				#  multilook factor for final interferometric products
	PROROOTPATH=`GetParam PROROOTPATH`	
	SATDIR=`GetParam "SATDIR,"`					# Satellite system. E.g. RADARSAT (must be the same as dirname structure)
	TRKDIR=`GetParam "TRKDIR,"`					# Processing directory and dir where data are stored E.g. RS2_UF (must be the same as dirname structure)
	OUTPUTDIR=${PROROOTPATH}/${SATDIR}/${TRKDIR}/${MAS}_${SLV}_${REGION}_Zoom${ZOOM}_ML${INTERFML}

	# without SM
	LaunchSingleTest ${MAS} ${SLV} ${SATDIR} ${TRKDIR} ${PARAMFILE} ${OUTPUTDIR}_AUTOTEST ${STOREDIR}
	sleep 5
	# Not possible with SM 
	#LaunchSingleSMTest ${MAS} ${SLV} ${SM} ${SATDIR} ${TRKDIR} ${PARAMFILE} ${OUTPUTDIR}_SM${SM}_AUTOTEST ${STOREDIR}
fi

# S1 STRIPMAP : test using of Tristan Asc on 3601
if [ ${TSTS1SM} == "Yes" ] ; then
	MAS="20180416"
	SLV="20190622"
	SM="20180404"
	PARAMFILE="$PATH_1650/Param_files/S1/Tristan_Asc/LaunchMTparam_S1_Tristan_Asc_Zoom1_ML8_MassProc.txt"

	REGION=`GetParam "REGION,"`					# REGION, Text description of area for dir naming
	ZOOM=`GetParam "ZOOM,"`						# ZOOM, zoom factor used while cropping
	INTERFML=`GetParam "INTERFML,"`				#  multilook factor for final interferometric products
	PROROOTPATH=`GetParam PROROOTPATH`	
	SATDIR=`GetParam "SATDIR,"`					# Satellite system. E.g. RADARSAT (must be the same as dirname structure)
	TRKDIR=`GetParam "TRKDIR,"`					# Processing directory and dir where data are stored E.g. RS2_UF (must be the same as dirname structure)
	OUTPUTDIR=${PROROOTPATH}/${SATDIR}/${TRKDIR}/${MAS}_${SLV}_${REGION}_Zoom${ZOOM}_ML${INTERFML}

	# without SM
	LaunchSingleTest ${MAS} ${SLV} ${SATDIR} ${TRKDIR} ${PARAMFILE} ${OUTPUTDIR}_AUTOTEST ${STOREDIR}
	sleep 5
	# with SM 
	LaunchSingleSMTest ${MAS} ${SLV} ${SM} ${SATDIR} ${TRKDIR} ${PARAMFILE} ${OUTPUTDIR}_SM${SM}_AUTOTEST ${STOREDIR}
fi

# CSK : test with Virunga_Desc on 3602
if [ ${TSTCSK} == "Yes" ] ; then
	MAS=20110417
	SLV=20110714
	SM=20160105
	PARAMFILE="/$PATH_1650/Param_files/CSK/Virunga_Desc/LaunchMTparam_SuperMaster_CSK_Virunga_Desc_Full_Zoom1_ML47_MassPro.txt"

	REGION=`GetParam "REGION,"`					# REGION, Text description of area for dir naming
	ZOOM=`GetParam "ZOOM,"`						# ZOOM, zoom factor used while cropping
	INTERFML=`GetParam "INTERFML,"`				#  multilook factor for final interferometric products
	PROROOTPATH=`GetParam PROROOTPATH`	
	SATDIR=`GetParam "SATDIR,"`					# Satellite system. E.g. RADARSAT (must be the same as dirname structure)
	TRKDIR=`GetParam "TRKDIR,"`					# Processing directory and dir where data are stored E.g. RS2_UF (must be the same as dirname structure)
	OUTPUTDIR=${PROROOTPATH}/${SATDIR}/${TRKDIR}/${MAS}_${SLV}_${REGION}_Zoom${ZOOM}_ML${INTERFML}

	# without SM
	LaunchSingleTest ${MAS} ${SLV} ${SATDIR} ${TRKDIR} ${PARAMFILE} ${OUTPUTDIR}_AUTOTEST ${STOREDIR} 
	sleep 5
	# with SM 
	LaunchSingleSMTest ${MAS} ${SLV} ${SM} ${SATDIR} ${TRKDIR} ${PARAMFILE} ${OUTPUTDIR}_SM${SM}_AUTOTEST ${STOREDIR}
fi 

# ENVI : test using ASARNyiragongo_A114 on 1650
if [ ${TSTENV} == "Yes" ] ; then
	MAS=20110702
	SLV=20110831
	SM=20110930
	PARAMFILE=/$PATH_1650/Param_files/ENVISAT/ASARNyiragongo_A114/LaunchMTparam_Envi_Asc114_Full_Zoom1_ML8_MassProc.txt

	REGION=`GetParam "REGION,"`					# REGION, Text description of area for dir naming
	ZOOM=`GetParam "ZOOM,"`						# ZOOM, zoom factor used while cropping
	INTERFML=`GetParam "INTERFML,"`				#  multilook factor for final interferometric products
	PROROOTPATH=`GetParam PROROOTPATH`	
	SATDIR=`GetParam "SATDIR,"`					# Satellite system. E.g. RADARSAT (must be the same as dirname structure)
	TRKDIR=`GetParam "TRKDIR,"`					# Processing directory and dir where data are stored E.g. RS2_UF (must be the same as dirname structure)
	OUTPUTDIR=${PROROOTPATH}/${SATDIR}/${TRKDIR}/${MAS}_${SLV}_${REGION}_Zoom${ZOOM}_ML${INTERFML}

	# without SM
	LaunchSingleTest ${MAS} ${SLV} ${SATDIR} ${TRKDIR} ${PARAMFILE} ${OUTPUTDIR}_AUTOTEST ${STOREDIR} 
	sleep 5
	# with SM 
	LaunchSingleSMTest ${MAS} ${SLV} ${SM} ${SATDIR} ${TRKDIR} ${PARAMFILE} ${OUTPUTDIR}_SM${SM}_AUTOTEST ${STOREDIR}
fi

# RS : test with RS2F_UH_Asc36deg on 3600
if [ ${TSTRS} == "Yes" ] ; then
	MAS=20120303
	SLV=20120701
	SM=20140410
	PARAMFILE=/$PATH_1650/Param_files/RS/RS2F_UH_Asc36deg/LaunchMTparameters_RS2_UH_SuperMaster_Full_Zoom1_ML46_MassProc.txt

	REGION=`GetParam "REGION,"`					# REGION, Text description of area for dir naming
	ZOOM=`GetParam "ZOOM,"`						# ZOOM, zoom factor used while cropping
	INTERFML=`GetParam "INTERFML,"`				#  multilook factor for final interferometric products
	PROROOTPATH=`GetParam PROROOTPATH`	
	SATDIR=`GetParam "SATDIR,"`					# Satellite system. E.g. RADARSAT (must be the same as dirname structure)
	TRKDIR=`GetParam "TRKDIR,"`					# Processing directory and dir where data are stored E.g. RS2_UF (must be the same as dirname structure)
	OUTPUTDIR=${PROROOTPATH}/${SATDIR}/${TRKDIR}/${MAS}_${SLV}_${REGION}_Zoom${ZOOM}_ML${INTERFML}

	# without SM
	LaunchSingleTest ${MAS} ${SLV} ${SATDIR} ${TRKDIR} ${PARAMFILE} ${OUTPUTDIR}_AUTOTEST ${STOREDIR} 
	sleep 5
	# with SM 
	LaunchSingleSMTest ${MAS} ${SLV} ${SM} ${SATDIR} ${TRKDIR} ${PARAMFILE} ${OUTPUTDIR}_SM${SM}_AUTOTEST ${STOREDIR}
fi 

# TSX : test with GOMA_SAKE_NYIGO_StMp_Desc92_VV on 3601
if [ ${TSTTSX} == "Yes" ] ; then
	MAS=20110806
	SLV=20120712
	SM=20120803
	PARAMFILE=/$PATH_1650/Param_files/TSX/GOMA_SAKE_NYIGO_StMp_Desc92_VV/LaunchMTparameters_TSX_SM_D92_Goma_Sake_Nyigo_Full_Zoom1_ML38_MassProc.txt

	REGION=`GetParam "REGION,"`					# REGION, Text description of area for dir naming
	ZOOM=`GetParam "ZOOM,"`						# ZOOM, zoom factor used while cropping
	INTERFML=`GetParam "INTERFML,"`				#  multilook factor for final interferometric products
	PROROOTPATH=`GetParam PROROOTPATH`	
	SATDIR=`GetParam "SATDIR,"`					# Satellite system. E.g. RADARSAT (must be the same as dirname structure)
	TRKDIR=`GetParam "TRKDIR,"`					# Processing directory and dir where data are stored E.g. RS2_UF (must be the same as dirname structure)
	OUTPUTDIR=${PROROOTPATH}/${SATDIR}/${TRKDIR}/${MAS}_${SLV}_${REGION}_Zoom${ZOOM}_ML${INTERFML}

	# without SM
	LaunchSingleTest ${MAS} ${SLV} ${SATDIR} ${TRKDIR} ${PARAMFILE} ${OUTPUTDIR}_AUTOTEST ${STOREDIR} 
	sleep 5
	# with SM 
	LaunchSingleSMTest ${MAS} ${SLV} ${SM} ${SATDIR} ${TRKDIR} ${PARAMFILE} ${OUTPUTDIR}_SM${SM}_AUTOTEST ${STOREDIR}
fi
	
# ERS : test using NYIGO_Asc on 3602
if [ ${TSTERS} == "Yes" ] ; then
	MAS=19970604
	SLV=19971022
	SM=20020807
	PARAMFILE=/$PATH_1650/Param_files/ERS/NYIGO_Asc/LaunchMTparam_ERS_Asc_Full_Zoom1_ML5_MassProc.txt

	REGION=`GetParam "REGION,"`					# REGION, Text description of area for dir naming
	ZOOM=`GetParam "ZOOM,"`						# ZOOM, zoom factor used while cropping
	INTERFML=`GetParam "INTERFML,"`				#  multilook factor for final interferometric products
	PROROOTPATH=`GetParam PROROOTPATH`	
	SATDIR=`GetParam "SATDIR,"`					# Satellite system. E.g. RADARSAT (must be the same as dirname structure)
	TRKDIR=`GetParam "TRKDIR,"`					# Processing directory and dir where data are stored E.g. RS2_UF (must be the same as dirname structure)
	OUTPUTDIR=${PROROOTPATH}/${SATDIR}/${TRKDIR}/${MAS}_${SLV}_${REGION}_Zoom${ZOOM}_ML${INTERFML}

	# without SM
	LaunchSingleTest ${MAS} ${SLV} ${SATDIR} ${TRKDIR} ${PARAMFILE} ${OUTPUTDIR}_AUTOTEST ${STOREDIR} 
	sleep 5
	# with SM 
	LaunchSingleSMTest ${MAS} ${SLV} ${SM} ${SATDIR} ${TRKDIR} ${PARAMFILE} ${OUTPUTDIR}_SM${SM}_AUTOTEST ${STOREDIR}
fi 

# NO NEED TO MAKE MASS PROCESS WITH SM WITH TDX BECAUSE THESE IMAGES ARE ALSO IN TSX... 

# TDX defo bistatic : test on RDC_GOMA_SAKE_NYIGO_StMp_Desc92_Bistat_150Mhz
if [ ${TSTTDXDEFOBIS} == "Yes" ] ; then
	MAS=20120712
	SLV=20120905
	#SM=
	PARAMFILE=/$PATH_1650/Param_files/TDX/RDC_GOMA_SAKE_NYIGO_StMp_Desc92_Bistat_150Mhz/LaunchMTparameters_TDX_SM_D92_Bis_Goma_Kake_Nyigo_Full_Zoom1_ML38_MassProc.txt

	REGION=`GetParam "REGION,"`					# REGION, Text description of area for dir naming
	ZOOM=`GetParam "ZOOM,"`						# ZOOM, zoom factor used while cropping
	INTERFML=`GetParam "INTERFML,"`				#  multilook factor for final interferometric products
	PROROOTPATH=`GetParam PROROOTPATH`	
	SATDIR=`GetParam "SATDIR,"`					# Satellite system. E.g. RADARSAT (must be the same as dirname structure)
	TRKDIR=`GetParam "TRKDIR,"`					# Processing directory and dir where data are stored E.g. RS2_UF (must be the same as dirname structure)
	OUTPUTDIR=${PROROOTPATH}/${SATDIR}/${TRKDIR}/${MAS}_${SLV}_${REGION}_Zoom${ZOOM}_ML${INTERFML}

	# without SM
	LaunchSingleTest ${MAS} ${SLV} ${SATDIR} ${TRKDIR} ${PARAMFILE} ${OUTPUTDIR}_AUTOTEST ${STOREDIR} 
	sleep 5
	# with SM 
	#LaunchSingleSMTest ${MAS} ${SLV} ${SM} ${SATDIR} ${TRKDIR} ${PARAMFILE} ${OUTPUTDIR}_SM${SM}_AUTOTEST ${STOREDIR}
fi

# TDX topo bistatic with master = slave : test with RDC_BUKAVU_StMp_Asc69_Bistat_100Mhz
if [ ${TSTTDXTOPOBISSAMEDATE} == "Yes" ] ; then
	MAS=20121110
	SLV=20121110
	PARAMFILE=/$PATH_1650/Param_files/TDX/RDC_GOMA_SAKE_NYIGO_StMp_Desc92_Bistat_150Mhz/LaunchMTparameters_TDX_SM_D92_Bis_Goma_Kake_Nyigo_Full_Zoom1_ML38_TOPO.txt
	
	REGION=`GetParam "REGION,"`					# REGION, Text description of area for dir naming
	ZOOM=`GetParam "ZOOM,"`						# ZOOM, zoom factor used while cropping
	INTERFML=`GetParam "INTERFML,"`				#  multilook factor for final interferometric products
	PROROOTPATH=`GetParam PROROOTPATH`	
	SATDIR=`GetParam "SATDIR,"`					# Satellite system. E.g. RADARSAT (must be the same as dirname structure)
	TRKDIR=`GetParam "TRKDIR,"`					# Processing directory and dir where data are stored E.g. RS2_UF (must be the same as dirname structure)
	OUTPUTDIR=${PROROOTPATH}/${SATDIR}/${TRKDIR}/${MAS}_${SLV}_${REGION}_Zoom${ZOOM}_ML${INTERFML}

	# without SM
	LaunchSingleTest ${MAS} ${SLV} ${SATDIR} ${TRKDIR} ${PARAMFILE} ${OUTPUTDIR}_AUTOTEST ${STOREDIR} 
	sleep 5
fi

# TDX topo bistatic with master not the same as slave : test with RDC_BUKAVU_StMp_Asc69_Bistat_100Mhz
if [ ${TSTTDXTOPOBISSAMEDATE} == "Yes" ] ; then
	MAS=20121110
	SLV=20121213
	PARAMFILE=/$PATH_1650/Param_files/TDX/RDC_GOMA_SAKE_NYIGO_StMp_Desc92_Bistat_150Mhz/LaunchMTparameters_TDX_SM_D92_Bis_Goma_Kake_Nyigo_Full_Zoom1_ML38_TOPO.txt
	
	REGION=`GetParam "REGION,"`					# REGION, Text description of area for dir naming
	ZOOM=`GetParam "ZOOM,"`						# ZOOM, zoom factor used while cropping
	INTERFML=`GetParam "INTERFML,"`				#  multilook factor for final interferometric products
	PROROOTPATH=`GetParam PROROOTPATH`	
	SATDIR=`GetParam "SATDIR,"`					# Satellite system. E.g. RADARSAT (must be the same as dirname structure)
	TRKDIR=`GetParam "TRKDIR,"`					# Processing directory and dir where data are stored E.g. RS2_UF (must be the same as dirname structure)
	OUTPUTDIR=${PROROOTPATH}/${SATDIR}/${TRKDIR}/${MAS}_${SLV}_${REGION}_Zoom${ZOOM}_ML${INTERFML}

	# without SM
	LaunchSingleTest ${MAS} ${SLV} ${SATDIR} ${TRKDIR} ${PARAMFILE} ${OUTPUTDIR}_AUTOTEST ${STOREDIR} 
	sleep 5
fi

# TDX defo Pursuite : test with RDC_NYIGO_MIKENO_StMp_Desc16_Purs_100Mhz_100Mhz_PM_D_012_RX
if [ ${TSTTDXDEFOPM} == "Yes" ] ; then
	MAS=20141021
	SLV=20141101
	PARAMFILE=/$PATH_1650/Param_files/TDX/RDC_NYIGO_MIKENO_StMp_Desc16_Purs_100Mhz/LaunchMTparameters_TDX_SM_D16_Purs_Nyigo_Mikeno_Full_Zoom1_ML24_MassProc.txt
	
	REGION=`GetParam "REGION,"`					# REGION, Text description of area for dir naming
	ZOOM=`GetParam "ZOOM,"`						# ZOOM, zoom factor used while cropping
	INTERFML=`GetParam "INTERFML,"`				#  multilook factor for final interferometric products
	PROROOTPATH=`GetParam PROROOTPATH`	
	SATDIR=`GetParam "SATDIR,"`					# Satellite system. E.g. RADARSAT (must be the same as dirname structure)
	TRKDIR=`GetParam "TRKDIR,"`					# Processing directory and dir where data are stored E.g. RS2_UF (must be the same as dirname structure)
	OUTPUTDIR=${PROROOTPATH}/${SATDIR}/${TRKDIR}/${MAS}_${SLV}_${REGION}_Zoom${ZOOM}_ML${INTERFML}

	# without SM
	LaunchSingleTest ${MAS} ${SLV} ${SATDIR} ${TRKDIR} ${PARAMFILE} ${OUTPUTDIR}_AUTOTEST ${STOREDIR} 
	sleep 5
fi
# TDX topo Pursuite with master same as slave : test with RDC_NYIGO_MIKENO_StMp_Desc16_Purs_100Mhz_100Mhz_PM_D_012_RX
if [ ${TSTTDXTOPOPMSAMEDATE} == "Yes" ] ; then
	MAS=20141010
	SLV=20141010
	PARAMFILE=/$PATH_1650/Param_files/TDX/RDC_NYIGO_MIKENO_StMp_Desc16_Purs_100Mhz/LaunchMTparameters_TDX_SM_D16_Purs_Nyigo_Mikeno_Full_Zoom1_ML24_TOPO.txt
	
	REGION=`GetParam "REGION,"`					# REGION, Text description of area for dir naming
	ZOOM=`GetParam "ZOOM,"`						# ZOOM, zoom factor used while cropping
	INTERFML=`GetParam "INTERFML,"`				#  multilook factor for final interferometric products
	PROROOTPATH=`GetParam PROROOTPATH`	
	SATDIR=`GetParam "SATDIR,"`					# Satellite system. E.g. RADARSAT (must be the same as dirname structure)
	TRKDIR=`GetParam "TRKDIR,"`					# Processing directory and dir where data are stored E.g. RS2_UF (must be the same as dirname structure)
	OUTPUTDIR=${PROROOTPATH}/${SATDIR}/${TRKDIR}/${MAS}_${SLV}_${REGION}_Zoom${ZOOM}_ML${INTERFML}

	# without SM
	LaunchSingleTest ${MAS} ${SLV} ${SATDIR} ${TRKDIR} ${PARAMFILE} ${OUTPUTDIR}_AUTOTEST ${STOREDIR} 
	sleep 5
fi

# TDX topo Pursuite with master not the same as slave : test with RDC_NYIGO_MIKENO_StMp_Desc16_Purs_100Mhz_100Mhz_PM_D_012_RX
if [ ${TSTTDXTOPOPMDIFFDATE} == "Yes" ] ; then
	MAS=20141010
	SLV=20141021
	PARAMFILE=/$PATH_1650/Param_files/TDX/RDC_NYIGO_MIKENO_StMp_Desc16_Purs_100Mhz/LaunchMTparameters_TDX_SM_D16_Purs_Nyigo_Mikeno_Full_Zoom1_ML24_TOPO.txt
	
	REGION=`GetParam "REGION,"`					# REGION, Text description of area for dir naming
	ZOOM=`GetParam "ZOOM,"`						# ZOOM, zoom factor used while cropping
	INTERFML=`GetParam "INTERFML,"`				#  multilook factor for final interferometric products
	PROROOTPATH=`GetParam PROROOTPATH`	
	SATDIR=`GetParam "SATDIR,"`					# Satellite system. E.g. RADARSAT (must be the same as dirname structure)
	TRKDIR=`GetParam "TRKDIR,"`					# Processing directory and dir where data are stored E.g. RS2_UF (must be the same as dirname structure)
	OUTPUTDIR=${PROROOTPATH}/${SATDIR}/${TRKDIR}/${MAS}_${SLV}_${REGION}_Zoom${ZOOM}_ML${INTERFML}

	# without SM
	LaunchSingleTest ${MAS} ${SLV} ${SATDIR} ${TRKDIR} ${PARAMFILE} ${OUTPUTDIR}_AUTOTEST ${STOREDIR} 
	sleep 5
fi



# Test SuperMasterCoreg : 
#########################



# Test SuperMaster_MassProc: 
############################



echo " All done. Results are in /$PATH_3602/TEST_ALL_TYPE_PROCESS/${RUNDATE}"
