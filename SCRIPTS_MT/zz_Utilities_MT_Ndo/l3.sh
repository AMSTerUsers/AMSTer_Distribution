#!/bin/bash
######################################################################################
# This script list the 3 last S1 image from VVP; Lux and  Domuyo in Asc and Desc modes
# then the 3 last resampled, 
# then the last 3 mass processed (from Geocoded, i.e. maybe not finished yet)
# then the last 3 finished dir in MASSPROCESSED
# then the last 3 images included in msbas processing in Asc and Desc LOS and in UD-EW combi (incl. with and w/o Coh threshold when appropriate)
# Then it sort the results in a table
#
# New in Distro V 1.1:	- says is last image is already processed in LOS thought awaiting for MSBAS 2D
# New in Distro V 1.2: - remove stray \ before _ while calling grep to cope with new grep syntax and avoid waring
#
# I know, it is a bit messy and can be improved.. when time. But it works..
# MasTer: InSAR Suite automated Mass processing Toolbox. 
# NdO (c) 2019/12/05 - could make better... when time.
# -----------------------------------------------------------------------------------------
PRG=`basename "$0"`
VER="Distro V1.2 MasTer script utilities"
AUT="Nicolas d'Oreye, (c)2016-2019, Last modified on Sept 21, 2022"
echo " "
echo "${PRG} ${VER}, ${AUT}"
echo " "

#Clear 
NODATA="xxxx"

function IfNoVal()
	{
	unset VARTOTEST 
	VARTOTEST=$1
	if [ "${VARTOTEST}" == "" ] ; then echo "${NODATA}" ; else echo "${VARTOTEST}" ; fi
	}

# Get the 3 last S1A and S1B from TRK, where TRK is e.g. ARG_DOMU_LAGUNA_A_18, that is subdir where CSL data are
function GetLast()
	{
	unset TRK 
	TRK=$1
	cd $PATH_1650/SAR_CSL/S1/${TRK}/NoCrop
	LASTA1=`find . -maxdepth 1 -type d -name "S1A*" | sort | cut -d _ -f3 | tail -3 | head -1`
	LASTA1=`IfNoVal ${LASTA1}`
	LASTB1=`find . -maxdepth 1 -type d -name "S1B*" | sort | cut -d _ -f3 | tail -3 | head -1`
	LASTB1=`IfNoVal ${LASTB1}`
	
	LASTA2=`find . -maxdepth 1 -type d -name "S1A*" | sort | cut -d _ -f3 | tail -2 | head -1`
	LASTA2=`IfNoVal ${LASTA2}`
	LASTB2=`find . -maxdepth 1 -type d -name "S1B*" | sort | cut -d _ -f3 | tail -2 | head -1`
	LASTB2=`IfNoVal ${LASTB2}`
	
	LASTA3=`find . -maxdepth 1 -type d -name "S1A*" | sort | cut -d _ -f3 | tail -1 `
	LASTA3=`IfNoVal ${LASTA3}`
	LASTB3=`find . -maxdepth 1 -type d -name "S1B*" | sort | cut -d _ -f3 | tail -1 `
	LASTB3=`IfNoVal ${LASTB3}`
	}
function GetLastOther()
	{
	unset TRK 
	TRK=$1
	cd $PATH_3601/SAR_CSL_Other_Zones/S1/${TRK}/NoCrop
	LASTA1=`find . -maxdepth 1 -type d -name "S1A*" | sort | cut -d _ -f3 | tail -3 | head -1`
	LASTA1=`IfNoVal ${LASTA1}`
	LASTB1=`find . -maxdepth 1 -type d -name "S1B*" | sort | cut -d _ -f3 | tail -3 | head -1`
	LASTB1=`IfNoVal ${LASTB1}`
	
	LASTA2=`find . -maxdepth 1 -type d -name "S1A*" | sort | cut -d _ -f3 | tail -2 | head -1`
	LASTA2=`IfNoVal ${LASTA2}`
	LASTB2=`find . -maxdepth 1 -type d -name "S1B*" | sort | cut -d _ -f3 | tail -2 | head -1`
	LASTB2=`IfNoVal ${LASTB2}`
	
	LASTA3=`find . -maxdepth 1 -type d -name "S1A*" | sort | cut -d _ -f3 | tail -1 `
	LASTA3=`IfNoVal ${LASTA3}`
	LASTB3=`find . -maxdepth 1 -type d -name "S1B*" | sort | cut -d _ -f3 | tail -1 `
	LASTB3=`IfNoVal ${LASTB3}`
	}

function GetLastResampl()
	{
	unset TRK 
	unset SM
	TRK=$1
	SM=$2
	PATHTODIR=`echo $PATH_1650/SAR_SM/RESAMPLED/S1/${TRK}/SM*Crop_SM_${SM}*`
	cd ${PATHTODIR}
	LASTARES1=`find . -maxdepth 1 -type d -name "*S1A*" | sort | cut -d _ -f4 | tail -3 | head -1`
	LASTARES1=`IfNoVal ${LASTARES1}`
	LASTBRES1=`find . -maxdepth 1 -type d -name "*S1B*" | sort | cut -d _ -f4 | tail -3 | head -1`
	LASTBRES1=`IfNoVal ${LASTBRES1}`
		
	LASTARES2=`find . -maxdepth 1 -type d -name "*S1A*" | sort | cut -d _ -f4 | tail -2 | head -1`
	LASTARES2=`IfNoVal ${LASTARES2}`
	LASTBRES2=`find . -maxdepth 1 -type d -name "*S1B*" | sort | cut -d _ -f4 | tail -2 | head -1`
	LASTBRES2=`IfNoVal ${LASTBRES2}`
		
	LASTARES3=`find . -maxdepth 1 -type d -name "*S1A*" | sort | cut -d _ -f4 | tail -1 `
	LASTARES3=`IfNoVal ${LASTARES3}`
	LASTBRES3=`find . -maxdepth 1 -type d -name "*S1B*" | sort | cut -d _ -f4 | tail -1 `
	LASTBRES3=`IfNoVal ${LASTBRES3}`
	}
function GetLastResamplOther()
	{
	unset TRK 
	unset SM
	TRK=$1
	SM=$2
	PATHTODIR=`echo $PATH_3601/SAR_SM_Other_Zones/RESAMPLED/S1/${TRK}/SM*Crop_SM_${SM}*`
	cd ${PATHTODIR}
	LASTARES1=`find . -maxdepth 1 -type d -name "*S1A*" | sort | cut -d _ -f4 | tail -3 | head -1`
	LASTARES1=`IfNoVal ${LASTARES1}`
	LASTBRES1=`find . -maxdepth 1 -type d -name "*S1B*" | sort | cut -d _ -f4 | tail -3 | head -1`
	LASTBRES1=`IfNoVal ${LASTBRES1}`
		
	LASTARES2=`find . -maxdepth 1 -type d -name "*S1A*" | sort | cut -d _ -f4 | tail -2 | head -1`
	LASTARES2=`IfNoVal ${LASTARES2}`
	LASTBRES2=`find . -maxdepth 1 -type d -name "*S1B*" | sort | cut -d _ -f4 | tail -2 | head -1`
	LASTBRES2=`IfNoVal ${LASTBRES2}`
		
	LASTARES3=`find . -maxdepth 1 -type d -name "*S1A*" | sort | cut -d _ -f4 | tail -1 `
	LASTARES3=`IfNoVal ${LASTARES3}`
	LASTBRES3=`find . -maxdepth 1 -type d -name "*S1B*" | sort | cut -d _ -f4 | tail -1 `
	LASTBRES3=`IfNoVal ${LASTBRES3}`
	}
function GetLastMassPairs()
	{
	unset TRK 
	unset SM
	unset ML
	TRK=$1
	SM=$2
	ML=$3
	PATHTODIR=`echo $PATH_3601/SAR_MASSPROCESS/S1/${TRK}/SM*Crop_SM_${SM}_*Zoom1_ML${ML}`
	cd ${PATHTODIR}
	LASTAMP1=`find . -maxdepth 1 -type d -name "*_S1A*" | cut -d _ -f7 |  sort | uniq | tail -3 | head -1`
	LASTAMP1=`IfNoVal ${LASTAMP1}`
	LASTBMP1=`find . -maxdepth 1 -type d -name "*_S1B*" | cut -d _ -f7 |  sort | uniq | tail -3 | head -1`
	LASTBMP1=`IfNoVal ${LASTBMP1}`

	LASTAMP2=`find . -maxdepth 1 -type d -name "*_S1A*" | cut -d _ -f7 |  sort | uniq | tail -2 | head -1`
	LASTAMP2=`IfNoVal ${LASTAMP2}`
	LASTBMP2=`find . -maxdepth 1 -type d -name "*_S1B*" | cut -d _ -f7 |  sort | uniq | tail -2 | head -1`
	LASTBMP2=`IfNoVal ${LASTBMP2}`
	
	LASTAMP3=`find . -maxdepth 1 -type d -name "*_S1A*" | cut -d _ -f7 |  sort | uniq | tail -1`
	LASTAMP3=`IfNoVal ${LASTAMP3}`
	LASTBMP3=`find . -maxdepth 1 -type d -name "*_S1B*" | cut -d _ -f7 |  sort | uniq | tail -1`
	LASTBMP3=`IfNoVal ${LASTBMP3}`
	}
function GetLastMassPairs2()
	{
	unset TRK 
	unset SM
	unset ML
	TRK=$1
	SM=$2
	ML=$3
	PATHTODIR=`echo $PATH_3602/SAR_MASSPROCESS_2/S1/${TRK}/SM*Crop_SM_${SM}_*Zoom1_ML${ML}`
	cd ${PATHTODIR}
	LASTAMP1=`find . -maxdepth 1 -type d -name "*_S1A*" | cut -d _ -f7 |  sort | uniq | tail -3 | head -1`
	LASTAMP1=`IfNoVal ${LASTAMP1}`
	LASTBMP1=`find . -maxdepth 1 -type d -name "*_S1B*" | cut -d _ -f7 |  sort | uniq | tail -3 | head -1`
	LASTBMP1=`IfNoVal ${LASTBMP1}`

	LASTAMP2=`find . -maxdepth 1 -type d -name "*_S1A*" | cut -d _ -f7 |  sort | uniq | tail -2 | head -1`
	LASTAMP2=`IfNoVal ${LASTAMP2}`
	LASTBMP2=`find . -maxdepth 1 -type d -name "*_S1B*" | cut -d _ -f7 |  sort | uniq | tail -2 | head -1`
	LASTBMP2=`IfNoVal ${LASTBMP2}`
	
	LASTAMP3=`find . -maxdepth 1 -type d -name "*_S1A*" | cut -d _ -f7 |  sort | uniq | tail -1`
	LASTAMP3=`IfNoVal ${LASTAMP3}`
	LASTBMP3=`find . -maxdepth 1 -type d -name "*_S1B*" | cut -d _ -f7 |  sort | uniq | tail -1`
	LASTBMP3=`IfNoVal ${LASTBMP3}`
	}
function GetLastMassProcessGeoc()
	{
	unset TRK 
	unset SM
	unset ML
	TRK=$1
	SM=$2
	ML=$3
	PATHTODIR=`echo $PATH_3601/SAR_MASSPROCESS/S1/${TRK}/SM*Crop_SM_${SM}_*Zoom1_ML${ML}/Geocoded/DefoInterpolx2Detrend`
	cd ${PATHTODIR}
	LASTMPG1=`find . -maxdepth 1 -type f -name "*deg"  | ${PATHGNU}/grep -Eo "_[0-9]{8}_[0-9]{8}_" | cut -d _ -f3 |  sort | uniq | tail -3 | head -1`
	LASTMPG2=`find . -maxdepth 1 -type f -name "*deg"  | ${PATHGNU}/grep -Eo "_[0-9]{8}_[0-9]{8}_" | cut -d _ -f3 |  sort | uniq | tail -2 | head -1`
	LASTMPG3=`find . -maxdepth 1 -type f -name "*deg"  | ${PATHGNU}/grep -Eo "_[0-9]{8}_[0-9]{8}_" | cut -d _ -f3 |  sort | uniq | tail -1`
	}
function GetLastMassProcessGeoc2()
	{
	unset TRK 
	unset SM
	unset ML
	TRK=$1
	SM=$2
	ML=$3
	PATHTODIR=`echo $PATH_3602/SAR_MASSPROCESS_2/S1/${TRK}/SM*Crop_SM_${SM}_*Zoom1_ML${ML}/Geocoded/DefoInterpolx2Detrend`
	cd ${PATHTODIR}
	LASTMPG1=`find . -maxdepth 1 -type f -name "*deg"  | ${PATHGNU}/grep -Eo "_[0-9]{8}_[0-9]{8}_" | cut -d _ -f3 |  sort | uniq | tail -3 | head -1`
	LASTMPG2=`find . -maxdepth 1 -type f -name "*deg"  | ${PATHGNU}/grep -Eo "_[0-9]{8}_[0-9]{8}_" | cut -d _ -f3 |  sort | uniq | tail -2 | head -1`
	LASTMPG3=`find . -maxdepth 1 -type f -name "*deg"  | ${PATHGNU}/grep -Eo "_[0-9]{8}_[0-9]{8}_" | cut -d _ -f3 |  sort | uniq | tail -1`
	}
	
function GetLastMSBAS()
	{
	unset AUTOMSBASDIR  # e.g. _Domuyo_S1_Auto_20m_450days
	unset MODE			# e.g. zz_EW_Auto_3_0.04_Domuyo
	AUTOMSBASDIR=$1
	MODE=$2
	cd $PATH_3602/MSBAS/${AUTOMSBASDIR}/${MODE}
	LASTMB1=`find . -maxdepth 1 -type f -name "*.bin" | ${PATHGNU}/grep -Eo "_[0-9]{8}" | cut -d _ -f2 |  sort | uniq | tail -3 | head -1`
	LASTMB2=`find . -maxdepth 1 -type f -name "*.bin" | ${PATHGNU}/grep -Eo "_[0-9]{8}" | cut -d _ -f2 |  sort | uniq | tail -2 | head -1`
	LASTMB3=`find . -maxdepth 1 -type f -name "*.bin" | ${PATHGNU}/grep -Eo "_[0-9]{8}" | cut -d _ -f2 |  sort | uniq | tail -1`
	}

function CheckMassProcess()
	{
	unset LAST  
	unset ORB
	LAST=$1
	ORB=$2
			# last img seems processed up to dir in MassProcessing; check if in Geocoded and MSBAS
			if [ "${LASTMPG1}" != "${NODATA}" ] && [ "${LAST}" != "${NODATA}" ] ; then
				if [ ${LAST} -ge ${LASTMPG1} ] ; then 
					if [ "${LAST}" != "${LASTMPG1}" ] && [ "${LAST}" != "${LASTMPG2}" ] && [ "${LAST}" != "${LASTMPG3}" ] ; then echo -e "    $(tput setaf 3)Awaiting for a MassProcessing with ${LAST} to be saved in /Geocoded$(tput sgr 0)" ; fi
				fi	
			fi
			if [ "${LASTMB1}" != "${NODATA}" ] && [ "${LAST}" != "${NODATA}" ] ; then
				if [ ${LAST} -ge ${LASTMB1} ] ; then 
					if [ "${LAST}" != "${LASTMB1}" ] && [ "${LAST}" != "${LASTMB2}" ] && [ "${LAST}" != "${LASTMB3}" ] ; then 
						#echo -e "    $(tput setaf 3)Awaiting for 2D MSBAS processing with ${LAST}$(tput sgr 0)" 
						case ${ORB} in
							"A")
								if [ "${LAST}" == "${ASC1}" ] || [ "${LAST}" == "${ASC2}" ] || [ "${LAST}" == "${ASC3}" ] 
									then 
										echo -e "    $(tput setaf 3)${LAST}: Awaiting for 2D MSBAS processing, but already in SBAS Asc (i.e. wait for common/symetric time span for 2D). $(tput sgr 0)" 
									else 
										echo -e "    $(tput setaf 3)${LAST}: Awaiting for Asc LOS SBAS and 2D MSBAS processing. $(tput sgr 0)" 
								fi
								;;
							"D")
								if [ "${LAST}" == "${DESC1}" ] || [ "${LAST}" == "${DESC2}" ] || [ "${LAST}" == "${DESC3}" ] 
									then 
										echo -e "    $(tput setaf 3)${LAST}: Awaiting for 2D MSBAS processing, but already in SBAS Desc (i.e. wait for common/symetric time span for 2D). $(tput sgr 0)" 
									else 
										echo -e "    $(tput setaf 3)${LAST}: Awaiting for Desc LOS SBAS and 2D MSBAS processing. $(tput sgr 0)" 
								fi
							 
								;;
						esac	 		
					fi 
				fi
			fi
	}



echo "Last DOMUYO processing:"
echo "-----------------------"
echo "-----------------------"
GetLastMSBAS _Domuyo_S1_Auto_20m_450days zz_LOS_Asc_Auto_3_0.04_Domuyo
ASC1=${LASTMB1}
ASC2=${LASTMB2}
ASC3=${LASTMB3}
GetLastMSBAS _Domuyo_S1_Auto_20m_450days zz_LOS_Desc_Auto_3_0.04_Domuyo
DESC1=${LASTMB1}
DESC2=${LASTMB2}
DESC3=${LASTMB3}
GetLastMSBAS _Domuyo_S1_Auto_20m_450days zz_EW_Auto_3_0.04_Domuyo
EW1=${LASTMB1}
EW2=${LASTMB2}
EW3=${LASTMB3}
#echo "Domuyo No Coh Threshold"
GetLastMSBAS _Domuyo_S1_Auto_20m_450days zz_EW_Auto_3_0.04_Domuyo_NoCohThresh
EWNCT1=${LASTMB1}
EWNCT2=${LASTMB2}
EWNCT3=${LASTMB3}

echo "Asc:	Img_A		Img_B    | Rspl_A	Rspl_B   |  MP_Dir_A	MP_Dir_B | Geoc		| MSBASlos(CohThresh)	MSBAS(CohTh)	MSBAS_NoCohThresh"
echo "---------------------------------------------------------------------------------------------------------------------------------------------------------"
GetLast ARG_DOMU_LAGUNA_A_18
GetLastMassProcessGeoc ARG_DOMU_LAGUNA_A_18 20180512 4
GetLastResampl ARG_DOMU_LAGUNA_A_18 20180512
GetLastMassPairs ARG_DOMU_LAGUNA_A_18 20180512 4
echo "	${LASTA1}	${LASTB1} | ${LASTARES1}	${LASTBRES1} | ${LASTAMP1}	${LASTBMP1} | ${LASTMPG1}	|	${ASC1}	${EW1}	${EWNCT1}"
echo "	${LASTA2}	${LASTB2} | ${LASTARES2}	${LASTBRES2} | ${LASTAMP2}	${LASTBMP2} | ${LASTMPG2}	|	${ASC2}	${EW2}	${EWNCT2}"
echo "	${LASTA3}	${LASTB3} | ${LASTARES3}	${LASTBRES3} | ${LASTAMP3}	${LASTBMP3} | ${LASTMPG3}	|	${ASC3}	${EW3}	${EWNCT3}"
CheckMassProcess ${LASTA1} A
CheckMassProcess ${LASTA2} A
CheckMassProcess ${LASTA3} A
CheckMassProcess ${LASTB1} A
CheckMassProcess ${LASTB2} A
CheckMassProcess ${LASTB3} A
echo "Desc:	"
echo "----------------------------------------------------------------------------------------------------------------------------------------------------------"
GetLast ARG_DOMU_LAGUNA_D_83
GetLastMassProcessGeoc ARG_DOMU_LAGUNA_D_83 20180222 4
GetLastResampl ARG_DOMU_LAGUNA_D_83 20180222
GetLastMassPairs ARG_DOMU_LAGUNA_D_83 20180222 4
echo "	${LASTA1}	${LASTB1} | ${LASTARES1}	${LASTBRES1} | ${LASTAMP1}	${LASTBMP1} | ${LASTMPG1}	|	${DESC1}	${EW1}	${EWNCT1}	"
echo "	${LASTA2}	${LASTB2} | ${LASTARES2}	${LASTBRES2} | ${LASTAMP2}	${LASTBMP2} | ${LASTMPG2}	|	${DESC2}	${EW2}	${EWNCT2}	"
echo "	${LASTA3}	${LASTB3} | ${LASTARES3}	${LASTBRES3} | ${LASTAMP3}	${LASTBMP3} | ${LASTMPG3}	|	${DESC3}	${EW3}	${EWNCT3}	"
CheckMassProcess ${LASTA1} D
CheckMassProcess ${LASTA2} D
CheckMassProcess ${LASTA3} D
CheckMassProcess ${LASTB1} D
CheckMassProcess ${LASTB2} D
CheckMassProcess ${LASTB3} D
echo

echo "Last VVP processing:"
echo "--------------------"
echo "--------------------"
GetLastMSBAS _VVP_S1_Auto_20m_400days zz_LOS_Asc_Auto_2_0.04_VVP
ASC1=${LASTMB1}
ASC2=${LASTMB2}
ASC3=${LASTMB3}
GetLastMSBAS _VVP_S1_Auto_20m_400days zz_LOS_Desc_Auto_2_0.04_VVP
DESC1=${LASTMB1}
DESC2=${LASTMB2}
DESC3=${LASTMB3}
GetLastMSBAS _VVP_S1_Auto_20m_400days zz_EW_Auto_2_0.04_VVP
EW1=${LASTMB1}
EW2=${LASTMB2}
EW3=${LASTMB3}

echo "Asc:	Img_A		Img_B    | Rspl_A	Rspl_B   |  MP_Dir_A	MP_Dir_B | Geoc		|	MSBASlos	MSBAS	"
echo "---------------------------------------------------------------------------------------------------------------------------------"
GetLast DRC_VVP_A_174
GetLastMassProcessGeoc DRC_VVP_A_174 20150310 8
GetLastResampl DRC_VVP_A_174 20150310
GetLastMassPairs DRC_VVP_A_174 20150310 8
echo "	${LASTA1}	${LASTB1} | ${LASTARES1}	${LASTBRES1} | ${LASTAMP1}	${LASTBMP1} | ${LASTMPG1}	|	${ASC1}	${EW1}"
echo "	${LASTA2}	${LASTB2} | ${LASTARES2}	${LASTBRES2} | ${LASTAMP2}	${LASTBMP2} | ${LASTMPG2}	|	${ASC2}	${EW2}"
echo "	${LASTA3}	${LASTB3} | ${LASTARES3}	${LASTBRES3} | ${LASTAMP3}	${LASTBMP3} | ${LASTMPG3}	|	${ASC3}	${EW3}"
CheckMassProcess ${LASTA1} A
CheckMassProcess ${LASTA2} A
CheckMassProcess ${LASTA3} A
CheckMassProcess ${LASTB1} A
CheckMassProcess ${LASTB2} A
CheckMassProcess ${LASTB3} A
echo "Desc:	"
echo "---------------------------------------------------------------------------------------------------------------------------------"
GetLast DRC_VVP_D_21
GetLastMassProcessGeoc DRC_VVP_D_21 20151014 8
GetLastResampl DRC_VVP_D_21 20151014
GetLastMassPairs DRC_VVP_D_21 20151014 8
echo "	${LASTA1}	${LASTB1} | ${LASTARES1}	${LASTBRES1} | ${LASTAMP1}	${LASTBMP1} | ${LASTMPG1}	|	${DESC1}	${EW1}"
echo "	${LASTA2}	${LASTB2} | ${LASTARES2}	${LASTBRES2} | ${LASTAMP2}	${LASTBMP2} | ${LASTMPG2}	|	${DESC2}	${EW2}"
echo "	${LASTA3}	${LASTB3} | ${LASTARES3}	${LASTBRES3} | ${LASTAMP3}	${LASTBMP3} | ${LASTMPG3}	|	${DESC3}	${EW3}"
CheckMassProcess ${LASTA1} D
CheckMassProcess ${LASTA2} D
CheckMassProcess ${LASTA3} D
CheckMassProcess ${LASTB1} D
CheckMassProcess ${LASTB2} D
CheckMassProcess ${LASTB3} D
echo


echo "Last LUX processing:"
echo "--------------------"
echo "--------------------"
GetLastMSBAS _LUX_S1_Auto_20m_400days zz_LOS_Asc_Auto_2_0.04_Lux
ASC1=${LASTMB1}
ASC2=${LASTMB2}
ASC3=${LASTMB3}
GetLastMSBAS _LUX_S1_Auto_20m_400days zz_LOS_Desc_Auto_2_0.04_Lux
DESC1=${LASTMB1}
DESC2=${LASTMB2}
DESC3=${LASTMB3}
GetLastMSBAS _LUX_S1_Auto_20m_400days zz_EW_Auto_2_0.04_Lux
EW1=${LASTMB1}
EW2=${LASTMB2}
EW3=${LASTMB3}

echo "Asc:	Img_A		Img_B    | Rspl_A	Rspl_B   |  MP_Dir_A	MP_Dir_B | Geoc		|	MSBASlos	MSBAS	"
echo "---------------------------------------------------------------------------------------------------------------------------------"
GetLast LUX_A_88
GetLastMassProcessGeoc LUX_A_88 20170627 4
GetLastResampl LUX_A_88 20170627
GetLastMassPairs LUX_A_88 20170627 4
echo "	${LASTA1}	${LASTB1} | ${LASTARES1}	${LASTBRES1} | ${LASTAMP1}	${LASTBMP1} | ${LASTMPG1}	|	${ASC1}	${EW1}"
echo "	${LASTA2}	${LASTB2} | ${LASTARES2}	${LASTBRES2} | ${LASTAMP2}	${LASTBMP2} | ${LASTMPG2}	|	${ASC2}	${EW2}"
echo "	${LASTA3}	${LASTB3} | ${LASTARES3}	${LASTBRES3} | ${LASTAMP3}	${LASTBMP3} | ${LASTMPG3}	|	${ASC3}	${EW3}"
CheckMassProcess ${LASTA1} A
CheckMassProcess ${LASTA2} A
CheckMassProcess ${LASTA3} A
CheckMassProcess ${LASTB1} A
CheckMassProcess ${LASTB2} A
CheckMassProcess ${LASTB3} A
echo "Desc:	"
echo "---------------------------------------------------------------------------------------------------------------------------------"
GetLast LUX_D_139
GetLastMassProcessGeoc LUX_D_139 20161109 4
GetLastResampl LUX_D_139 20161109
GetLastMassPairs LUX_D_139 20161109 4
echo "	${LASTA1}	${LASTB1} | ${LASTARES1}	${LASTBRES1} | ${LASTAMP1}	${LASTBMP1} | ${LASTMPG1}	|	${DESC1}	${EW1}"
echo "	${LASTA2}	${LASTB2} | ${LASTARES2}	${LASTBRES2} | ${LASTAMP2}	${LASTBMP2} | ${LASTMPG2}	|	${DESC2}	${EW2}"
echo "	${LASTA3}	${LASTB3} | ${LASTARES3}	${LASTBRES3} | ${LASTAMP3}	${LASTBMP3} | ${LASTMPG3}	|	${DESC3}	${EW3}"
CheckMassProcess ${LASTA1} D
CheckMassProcess ${LASTA2} D
CheckMassProcess ${LASTA3} D
CheckMassProcess ${LASTB1} D
CheckMassProcess ${LASTB2} D
CheckMassProcess ${LASTB3} D
echo


echo "Last PF processing:"
echo "--------------------"
echo "--------------------"
GetLastMSBAS _PF_S1_Auto_70m_70_50days zz_LOS_IWAsc_Auto_2_0.04_PF
ASC1=${LASTMB1}
ASC2=${LASTMB2}
ASC3=${LASTMB3}
GetLastMSBAS _PF_S1_Auto_70m_70_50days zz_LOS_IWDesc_Auto_2_0.04_PF
DESC1=${LASTMB1}
DESC2=${LASTMB2}
DESC3=${LASTMB3}

GetLastMSBAS _PF_S1_Auto_70m_70_50days zz_EW_Auto_2_0.04_PF
EW1=${LASTMB1}
EW2=${LASTMB2}
EW3=${LASTMB3}

echo "AscIW:   Img_A		Img_B | Rspl_A Rspl_B |  MP_Dir_A MP_Dir_B | Geoc		|	MSBASlos	MSBAS	"
echo "---------------------------------------------------------------------------------------------------------------------------------"
GetLast PF_IW_A_144
GetLastMassProcessGeoc PF_IW_A_144 20180831 2
GetLastResampl PF_IW_A_144 20180831
GetLastMassPairs PF_IW_A_144 20180831 2
echo "	${LASTA1}	${LASTB1} | ${LASTARES1}	${LASTBRES1} | ${LASTAMP1}	${LASTBMP1} 	| ${LASTMPG1}		|	${ASC1}	${EW1}"
echo "	${LASTA2}	${LASTB2} | ${LASTARES2}	${LASTBRES2} | ${LASTAMP2}	${LASTBMP2} 	| ${LASTMPG2}		|	${ASC2}	${EW2}"
echo "	${LASTA3}	${LASTB3} | ${LASTARES3}	${LASTBRES3} | ${LASTAMP3}	${LASTBMP3} 	| ${LASTMPG3}		|	${ASC3}	${EW3}"
CheckMassProcess ${LASTA1} A
CheckMassProcess ${LASTA2} A
CheckMassProcess ${LASTA3} A
CheckMassProcess ${LASTB1} A
CheckMassProcess ${LASTB2} A
CheckMassProcess ${LASTB3} A
echo "DescIW:	"
echo "---------------------------------------------------------------------------------------------------------------------------------"
GetLast PF_IW_D_151
GetLastMassProcessGeoc PF_IW_D_151 20200622 2
GetLastResampl PF_IW_D_151 20200622
GetLastMassPairs PF_IW_D_151 20200622 2
echo "	${LASTA1}	${LASTB1} | ${LASTARES1}	${LASTBRES1} | ${LASTAMP1}	${LASTBMP1} 	| ${LASTMPG1}		|	${DESC1}	${EW1}"
echo "	${LASTA2}	${LASTB2} | ${LASTARES2}	${LASTBRES2} | ${LASTAMP2}	${LASTBMP2} 	| ${LASTMPG2}		|	${DESC2}	${EW2}"
echo "	${LASTA3}	${LASTB3} | ${LASTARES3}	${LASTBRES3} | ${LASTAMP3}	${LASTBMP3} 	| ${LASTMPG3}		|	${DESC3}	${EW3}"
CheckMassProcess ${LASTA1} D
CheckMassProcess ${LASTA2} D
CheckMassProcess ${LASTA3} D
CheckMassProcess ${LASTB1} D
CheckMassProcess ${LASTB2} D
CheckMassProcess ${LASTB3} D
echo




GetLastMSBAS _PF_S1_Auto_70m_70_50days zz_LOS_SMAsc_Auto_2_0.04_PF
ASC1=${LASTMB1}
ASC2=${LASTMB2}
ASC3=${LASTMB3}
GetLastMSBAS _PF_S1_Auto_70m_70_50days zz_LOS_SMDesc_Auto_2_0.04_PF
DESC1=${LASTMB1}
DESC2=${LASTMB2}
DESC3=${LASTMB3}

echo "AscSM:   Img_A		Img_B | Rspl_A Rspl_B |  MP_Dir_A MP_Dir_B | Geoc		|	MSBASlos	MSBAS	"
echo "---------------------------------------------------------------------------------------------------------------------------------"
GetLast PF_SM_A_144
GetLastMassProcessGeoc PF_SM_A_144 20190808 8
GetLastResampl PF_SM_A_144 20190808
GetLastMassPairs PF_SM_A_144 20190808 8
echo "	${LASTA1}	${LASTB1} | ${LASTARES1}	${LASTBRES1} | ${LASTAMP1}	${LASTBMP1} 	| ${LASTMPG1}		|	${ASC1}	${EW1}"
echo "	${LASTA2}	${LASTB2} | ${LASTARES2}	${LASTBRES2} | ${LASTAMP2}	${LASTBMP2} 	| ${LASTMPG2}		|	${ASC2}	${EW2}"
echo "	${LASTA3}	${LASTB3} | ${LASTARES3}	${LASTBRES3} | ${LASTAMP3}	${LASTBMP3} 	| ${LASTMPG3}		|	${ASC3}	${EW3}"
CheckMassProcess ${LASTA1} A
CheckMassProcess ${LASTA2} A
CheckMassProcess ${LASTA3} A
CheckMassProcess ${LASTB1} A
CheckMassProcess ${LASTB2} A
CheckMassProcess ${LASTB3} A
echo "DescSM:	"
echo "---------------------------------------------------------------------------------------------------------------------------------"
GetLast PF_SM_D_151
GetLastMassProcessGeoc PF_SM_D_151 20181013 8
GetLastResampl PF_SM_D_151 20181013
GetLastMassPairs PF_SM_D_151 20181013 8
echo "	${LASTA1}	${LASTB1} | ${LASTARES1}	${LASTBRES1} | ${LASTAMP1}	${LASTBMP1} 	| ${LASTMPG1}		|	${DESC1}	${EW1}"
echo "	${LASTA2}	${LASTB2} | ${LASTARES2}	${LASTBRES2} | ${LASTAMP2}	${LASTBMP2} 	| ${LASTMPG2}		|	${DESC2}	${EW2}"
echo "	${LASTA3}	${LASTB3} | ${LASTARES3}	${LASTBRES3} | ${LASTAMP3}	${LASTBMP3} 	| ${LASTMPG3}		|	${DESC3}	${EW3}"
CheckMassProcess ${LASTA1} D
CheckMassProcess ${LASTA2} D
CheckMassProcess ${LASTA3} D
CheckMassProcess ${LASTB1} D
CheckMassProcess ${LASTB2} D
CheckMassProcess ${LASTB3} D
echo


echo "Last HAWAII processing:"
echo "--------------------"
echo "--------------------"
#GetLastMSBAS _LUX_S1_Auto_20m_400days zz_LOS_Asc_Auto_2_0.04_Lux
# ASC1=${LASTMB1}
# ASC2=${LASTMB2}
# ASC3=${LASTMB3}
# GetLastMSBAS _LUX_S1_Auto_20m_400days zz_LOS_Desc_Auto_2_0.04_Lux
# DESC1=${LASTMB1}
# DESC2=${LASTMB2}
# DESC3=${LASTMB3}
# GetLastMSBAS _LUX_S1_Auto_20m_400days zz_EW_Auto_2_0.04_Lux
# EW1=${LASTMB1}
# EW2=${LASTMB2}
# EW3=${LASTMB3}

echo "Asc:	Img_A		Img_B    | Rspl_A	Rspl_B   |  MP_Dir_A	MP_Dir_B | Geoc		|	MSBASlos	MSBAS	"
echo "---------------------------------------------------------------------------------------------------------------------------------"
GetLastOther Hawaii_LL_A_124
#GetLastMassProcessGeoc Hawaii_LL_A_124 20170706 4
GetLastResampl Hawaii_LL_A_124 20170706
GetLastMassPairs Hawaii_LL_A_124 20170706 4
echo "	${LASTA1}	${LASTB1} | ${LASTARES1}	${LASTBRES1} | ${LASTAMP1}	${LASTBMP1} | ${LASTMPG1}	|	${ASC1}	${EW1}"
echo "	${LASTA2}	${LASTB2} | ${LASTARES2}	${LASTBRES2} | ${LASTAMP2}	${LASTBMP2} | ${LASTMPG2}	|	${ASC2}	${EW2}"
echo "	${LASTA3}	${LASTB3} | ${LASTARES3}	${LASTBRES3} | ${LASTAMP3}	${LASTBMP3} | ${LASTMPG3}	|	${ASC3}	${EW3}"
# CheckMassProcess ${LASTA1} A
# CheckMassProcess ${LASTA2} A
# CheckMassProcess ${LASTA3} A
# CheckMassProcess ${LASTB1} A
# CheckMassProcess ${LASTB2} A
# CheckMassProcess ${LASTB3} A
echo "Desc:	"
echo "---------------------------------------------------------------------------------------------------------------------------------"
GetLastOther Hawaii_LL_D_87
#GetLastMassProcessGeoc2 Hawaii_LL_D_87 20170428 4
GetLastResampl Hawaii_LL_D_87 20170428
GetLastMassPairs Hawaii_LL_D_87 20170428 4
echo "	${LASTA1}	${LASTB1} | ${LASTARES1}	${LASTBRES1} | ${LASTAMP1}	${LASTBMP1} | ${LASTMPG1}	|	${DESC1}	${EW1}"
echo "	${LASTA2}	${LASTB2} | ${LASTARES2}	${LASTBRES2} | ${LASTAMP2}	${LASTBMP2} | ${LASTMPG2}	|	${DESC2}	${EW2}"
echo "	${LASTA3}	${LASTB3} | ${LASTARES3}	${LASTBRES3} | ${LASTAMP3}	${LASTBMP3} | ${LASTMPG3}	|	${DESC3}	${EW3}"
# CheckMassProcess ${LASTA1} D
# CheckMassProcess ${LASTA2} D
# CheckMassProcess ${LASTA3} D
# CheckMassProcess ${LASTB1} D
# CheckMassProcess ${LASTB2} D
# CheckMassProcess ${LASTB3} D
echo



