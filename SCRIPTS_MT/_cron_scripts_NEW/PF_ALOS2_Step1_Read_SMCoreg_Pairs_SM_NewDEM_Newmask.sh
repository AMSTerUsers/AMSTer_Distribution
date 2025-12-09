#!/bin/bash
# Script to run in cronjob for processing ALSO2 data at PITON DE LA FOURNAISE images:
# Read images, corigister them on a Global Primary (SuperMaster) and compute the compatible pairs.
# It also creates a common baseline plot for  ascending and descending modes. 
#
# Note: images were first checked and sorted using something like ()
#		ALOS2_UNZIP_Check_Sort.sh /Volumes/D3610/SAR_DATA/ALOS2/WHERE_RAW_DATA_ARE /Volumes/D3610/SAR_DATA/ALOS2_Reunion-UNZIP
#
# BEWARE: 
#	- links in images are for MAC (when 2 PATH NR)
#
# New in Distro V 1.1.0 202241230 :	- replace ${PATH_1650}/SAR_SM/MSBAS/PF_oldDEM with ${PATH_1650}/SAR_SM/MSBAS/PF
# New in Distro V 1.2 20250410:	- change SM for mode 4041 (13D)
#
# AMSTer: SAR & InSAR Automated Mass processing Software for Multidimensional Time series
# NdO (c) 2016/03/07 - could make better with more functions... when time.
# -----------------------------------------------------------------------------------------
PRG=`basename "$0"`
VER="Distro V1.2 AMSTer script utilities"
AUT="Nicolas d'Oreye, (c)2016-2019, Last modified on Apr 10, 2025"

source $HOME/.bashrc

RNDM=`echo $(( $RANDOM % 10000 ))`

# Some functions
function CheckPathNrPLusMinusOne()
{
	unset MODE
	local MODE=$1
	
	PATHNR=$(echo "${MODE}" | cut -d _ -f 1)
	GEOM=$(echo "${MODE}" | cut -d _ -f 2-3)
	
	PATHPLUSONE=$(echo "${PATHNR} + 1 " | bc)
	PATHMINUSONE=$(echo "${PATHNR} - 1 " | bc)
	MODEPLUSONE="${PATHPLUSONE}_${GEOM}"
	MODEMINUSONE="${PATHMINUSONE}_${GEOM}"
	
	if [ -d "${UNZIPDIR}/SPT_${MODEPLUSONE}" ]
		then 
			find "${UNZIPDIR}/SPT_${MODEPLUSONE}" -maxdepth 1 -mindepth 1 -type d ! -type l -name "*" 2> /dev/null > "${UNZIPDIR}/SPT_${MODEPLUSONE}"/tmp_${RNDM}.txt # take only dirs as yyyymmdd
			if [ -f "${UNZIPDIR}/SPT_${MODEPLUSONE}"/tmp_${RNDM}.txt ] && [ -s "${UNZIPDIR}/SPT_${MODEPLUSONE}"/tmp_${RNDM}.txt ] ; then 
				echo "// Unexpected PATH number."
				for IMG in `cat ${UNZIPDIR}/SPT_${MODEPLUSONE}/tmp_${RNDM}.txt`
					do
					IMGNOPATH=$(basename "${IMG}")
					echo "//  Move ${IMG} in ${UNZIPDIR}/SPT_${MODE}"
					mv "${IMG}" "${UNZIPDIR}/SPT_${MODE}"
					echo "// and link ${UNZIPDIR}/SPT_${MODE}/${IMGNOPATH} in ${IMG}"
					ln -s "${UNZIPDIR}/SPT_${MODE}/${IMGNOPATH}" "${IMG}"
				done
			fi
			rm -f "${UNZIPDIR}/SPT_${MODEPLUSONE}"/tmp_${RNDM}.txt 2> /dev/null 
	fi

	if [ -d "${UNZIPDIR}/SPT_${MODEMINUSONE}" ]
		then 
			find "${UNZIPDIR}/SPT_${MODEMINUSONE}" -maxdepth 1 -mindepth 1 -type d ! -type l -name "*" 2> /dev/null > "${UNZIPDIR}/SPT_${MODEMINUSONE}"/tmp_${RNDM}.txt  # take only dirs as yyyymmdd
			if [ -f "${UNZIPDIR}/SPT_${MODEMINUSONE}"/tmp_${RNDM}.txt ] && [ -s "${UNZIPDIR}/SPT_${MODEMINUSONE}"/tmp_${RNDM}.txt ] ; then 
				echo "// Unexpected PATH number."
				for IMG in `cat ${UNZIPDIR}/SPT_${MODEMINUSONE}/tmp_${RNDM}.txt`
					do
					IMGNOPATH=$(basename "${IMG}")
					echo "//  Move ${IMG} in ${UNZIPDIR}/SPT_${MODE}"
					mv "${IMG}" "${UNZIPDIR}/SPT_${MODE}"
					echo "// and link ${UNZIPDIR}/SPT_${MODE}/${IMGNOPATH} in ${IMG}"
					ln -s "${UNZIPDIR}/SPT_${MODE}/${IMGNOPATH}" "${IMG}"
				done
			fi
			rm -f "${UNZIPDIR}/SPT_${MODEMINUSONE}"/tmp_${RNDM}.txt 2> /dev/null 
	fi
	
}

# Some directories
FTPDIR=${PATH_3610}/SAR_DATA/ALOS2_Reunion-FTP/		# where raw, unsorted zip data are uploaded 
UNZIPDIR=${PATH_3610}/SAR_DATA/ALOS2_Reunion-UNZIP/		# where sorted, unzipped raw data are stored
CSLDIR=${PATH_1660}/SAR_CSL/ALOS2						# where images are read in CSL format 
# BEWARE: TEMPORARY LOCATION 
SETDIR=$PATH_1650/SAR_SM/MSBAS/PF						# where baseline plots are computed

echo "Starting $0" > ${CSLDIR}/Last_Run_Cron_Step1.txt
date >> ${CSLDIR}/Last_Run_Cron_Step1.txt

# Some variables
POL=HH

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
#BT2=50
#DATECHG=20220501

# NEWASCPATH
NEWASCPATH01A=$PATH_3610/SAR_SM/RESAMPLED/ALOS2/PF_${MODE01A}/SMNoCrop_SM_${SM01A}
NEWASCPATH02A=$PATH_3610/SAR_SM/RESAMPLED/ALOS2/PF_${MODE02A}/SMNoCrop_SM_${SM02A}
NEWASCPATH03A=$PATH_3610/SAR_SM/RESAMPLED/ALOS2/PF_${MODE03A}/SMNoCrop_SM_${SM03A}
NEWASCPATH04A=$PATH_3610/SAR_SM/RESAMPLED/ALOS2/PF_${MODE04A}/SMNoCrop_SM_${SM04A}
NEWASCPATH05A=$PATH_3610/SAR_SM/RESAMPLED/ALOS2/PF_${MODE05A}/SMNoCrop_SM_${SM05A}
NEWASCPATH06A=$PATH_3610/SAR_SM/RESAMPLED/ALOS2/PF_${MODE06A}/SMNoCrop_SM_${SM06A}
NEWASCPATH07A=$PATH_3610/SAR_SM/RESAMPLED/ALOS2/PF_${MODE07A}/SMNoCrop_SM_${SM07A}
NEWASCPATH08A=$PATH_3610/SAR_SM/RESAMPLED/ALOS2/PF_${MODE08A}/SMNoCrop_SM_${SM08A}
NEWASCPATH09A=$PATH_3610/SAR_SM/RESAMPLED/ALOS2/PF_${MODE09A}/SMNoCrop_SM_${SM09A}
NEWASCPATH10A=$PATH_3610/SAR_SM/RESAMPLED/ALOS2/PF_${MODE10A}/SMNoCrop_SM_${SM10A}
NEWASCPATH11A=$PATH_3610/SAR_SM/RESAMPLED/ALOS2/PF_${MODE11A}/SMNoCrop_SM_${SM11A}
NEWASCPATH12A=$PATH_3610/SAR_SM/RESAMPLED/ALOS2/PF_${MODE12A}/SMNoCrop_SM_${SM12A}
NEWASCPATH13A=$PATH_3610/SAR_SM/RESAMPLED/ALOS2/PF_${MODE13A}/SMNoCrop_SM_${SM13A}

# NEWDESCPATH
NEWDESCPATH01D=$PATH_3610/SAR_SM/RESAMPLED/ALOS2/PF_${MODE01D}/SMNoCrop_SM_${SM01D}
NEWDESCPATH02D=$PATH_3610/SAR_SM/RESAMPLED/ALOS2/PF_${MODE02D}/SMNoCrop_SM_${SM02D}
NEWDESCPATH03D=$PATH_3610/SAR_SM/RESAMPLED/ALOS2/PF_${MODE03D}/SMNoCrop_SM_${SM03D}
NEWDESCPATH04D=$PATH_3610/SAR_SM/RESAMPLED/ALOS2/PF_${MODE04D}/SMNoCrop_SM_${SM04D}
NEWDESCPATH05D=$PATH_3610/SAR_SM/RESAMPLED/ALOS2/PF_${MODE05D}/SMNoCrop_SM_${SM05D}
NEWDESCPATH06D=$PATH_3610/SAR_SM/RESAMPLED/ALOS2/PF_${MODE06D}/SMNoCrop_SM_${SM06D}
NEWDESCPATH07D=$PATH_3610/SAR_SM/RESAMPLED/ALOS2/PF_${MODE07D}/SMNoCrop_SM_${SM07D}
NEWDESCPATH08D=$PATH_3610/SAR_SM/RESAMPLED/ALOS2/PF_${MODE08D}/SMNoCrop_SM_${SM08D}
NEWDESCPATH09D=$PATH_3610/SAR_SM/RESAMPLED/ALOS2/PF_${MODE09D}/SMNoCrop_SM_${SM09D}
NEWDESCPATH10D=$PATH_3610/SAR_SM/RESAMPLED/ALOS2/PF_${MODE10D}/SMNoCrop_SM_${SM10D}
NEWDESCPATH11D=$PATH_3610/SAR_SM/RESAMPLED/ALOS2/PF_${MODE11D}/SMNoCrop_SM_${SM11D}
NEWDESCPATH12D=$PATH_3610/SAR_SM/RESAMPLED/ALOS2/PF_${MODE12D}/SMNoCrop_SM_${SM12D}
NEWDESCPATH13D=$PATH_3610/SAR_SM/RESAMPLED/ALOS2/PF_${MODE13D}/SMNoCrop_SM_${SM13D}
NEWDESCPATH14D=$PATH_3610/SAR_SM/RESAMPLED/ALOS2/PF_${MODE14D}/SMNoCrop_SM_${SM14D}

# UNZIP, Check and Sort ALOS2 images from ftp site
##################################################

ALOS2_UNZIP_Check_Sort.sh ${FTPDIR} ${UNZIPDIR}

# Because ALOS2 images can have a Path nr +/- 1, move those which are + or -1 to expected Path nr dir and link them to original dir to avoid re-reading next time 
# Asc
CheckPathNrPLusMinusOne "${MODE01A}"
CheckPathNrPLusMinusOne "${MODE02A}"
CheckPathNrPLusMinusOne "${MODE03A}"
CheckPathNrPLusMinusOne "${MODE04A}"
CheckPathNrPLusMinusOne "${MODE05A}"
CheckPathNrPLusMinusOne "${MODE06A}"
CheckPathNrPLusMinusOne "${MODE07A}"
CheckPathNrPLusMinusOne "${MODE08A}"
CheckPathNrPLusMinusOne "${MODE09A}"
CheckPathNrPLusMinusOne "${MODE10A}"
CheckPathNrPLusMinusOne "${MODE11A}"
CheckPathNrPLusMinusOne "${MODE12A}"
CheckPathNrPLusMinusOne "${MODE13A}"
# Desc
CheckPathNrPLusMinusOne "${MODE01D}"
CheckPathNrPLusMinusOne "${MODE02D}"
CheckPathNrPLusMinusOne "${MODE03D}"
CheckPathNrPLusMinusOne "${MODE04D}"
CheckPathNrPLusMinusOne "${MODE05D}"
CheckPathNrPLusMinusOne "${MODE06D}"
CheckPathNrPLusMinusOne "${MODE07D}"
CheckPathNrPLusMinusOne "${MODE08D}"
CheckPathNrPLusMinusOne "${MODE09D}"
CheckPathNrPLusMinusOne "${MODE10D}"
CheckPathNrPLusMinusOne "${MODE11D}"
CheckPathNrPLusMinusOne "${MODE12D}"
CheckPathNrPLusMinusOne "${MODE13D}"
CheckPathNrPLusMinusOne "${MODE14D}"


# Read all ALOS2 images for that footprint (No need to specify RESAMDIR and MASSPROCDIR because there is no orbite update)
##########################################

# 13 ASC modes
$PATH_SCRIPTS/SCRIPTS_MT/Read_All_Img.sh "${UNZIPDIR}"/SPT_"${MODE01A}" "${CSLDIR}"/PF_"${MODE01A}"/NoCrop ALOS2 "${POL}" #"${RESAMDIR}" ${MASSPROCDIR}  > /dev/null 2>&1
$PATH_SCRIPTS/SCRIPTS_MT/Read_All_Img.sh "${UNZIPDIR}"/SPT_"${MODE02A}" "${CSLDIR}"/PF_"${MODE02A}"/NoCrop ALOS2 "${POL}" #"${RESAMDIR}" ${MASSPROCDIR}  > /dev/null 2>&1
$PATH_SCRIPTS/SCRIPTS_MT/Read_All_Img.sh "${UNZIPDIR}"/SPT_"${MODE03A}" "${CSLDIR}"/PF_"${MODE03A}"/NoCrop ALOS2 "${POL}" #"${RESAMDIR}" ${MASSPROCDIR}  > /dev/null 2>&1
$PATH_SCRIPTS/SCRIPTS_MT/Read_All_Img.sh "${UNZIPDIR}"/SPT_"${MODE04A}" "${CSLDIR}"/PF_"${MODE04A}"/NoCrop ALOS2 "${POL}" #"${RESAMDIR}" ${MASSPROCDIR}  > /dev/null 2>&1
$PATH_SCRIPTS/SCRIPTS_MT/Read_All_Img.sh "${UNZIPDIR}"/SPT_"${MODE05A}" "${CSLDIR}"/PF_"${MODE05A}"/NoCrop ALOS2 "${POL}" #"${RESAMDIR}" ${MASSPROCDIR}  > /dev/null 2>&1
$PATH_SCRIPTS/SCRIPTS_MT/Read_All_Img.sh "${UNZIPDIR}"/SPT_"${MODE06A}" "${CSLDIR}"/PF_"${MODE06A}"/NoCrop ALOS2 "${POL}" #"${RESAMDIR}" ${MASSPROCDIR}  > /dev/null 2>&1
$PATH_SCRIPTS/SCRIPTS_MT/Read_All_Img.sh "${UNZIPDIR}"/SPT_"${MODE07A}" "${CSLDIR}"/PF_"${MODE07A}"/NoCrop ALOS2 "${POL}" #"${RESAMDIR}" ${MASSPROCDIR}  > /dev/null 2>&1
$PATH_SCRIPTS/SCRIPTS_MT/Read_All_Img.sh "${UNZIPDIR}"/SPT_"${MODE08A}" "${CSLDIR}"/PF_"${MODE08A}"/NoCrop ALOS2 "${POL}" #"${RESAMDIR}" ${MASSPROCDIR}  > /dev/null 2>&1
$PATH_SCRIPTS/SCRIPTS_MT/Read_All_Img.sh "${UNZIPDIR}"/SPT_"${MODE09A}" "${CSLDIR}"/PF_"${MODE09A}"/NoCrop ALOS2 "${POL}" #"${RESAMDIR}" ${MASSPROCDIR}  > /dev/null 2>&1
$PATH_SCRIPTS/SCRIPTS_MT/Read_All_Img.sh "${UNZIPDIR}"/SPT_"${MODE10A}" "${CSLDIR}"/PF_"${MODE10A}"/NoCrop ALOS2 "${POL}" #"${RESAMDIR}" ${MASSPROCDIR}  > /dev/null 2>&1
$PATH_SCRIPTS/SCRIPTS_MT/Read_All_Img.sh "${UNZIPDIR}"/SPT_"${MODE11A}" "${CSLDIR}"/PF_"${MODE11A}"/NoCrop ALOS2 "${POL}" #"${RESAMDIR}" ${MASSPROCDIR}  > /dev/null 2>&1
$PATH_SCRIPTS/SCRIPTS_MT/Read_All_Img.sh "${UNZIPDIR}"/SPT_"${MODE12A}" "${CSLDIR}"/PF_"${MODE12A}"/NoCrop ALOS2 "${POL}" #"${RESAMDIR}" ${MASSPROCDIR}  > /dev/null 2>&1
$PATH_SCRIPTS/SCRIPTS_MT/Read_All_Img.sh "${UNZIPDIR}"/SPT_"${MODE13A}" "${CSLDIR}"/PF_"${MODE13A}"/NoCrop ALOS2 "${POL}" #"${RESAMDIR}" ${MASSPROCDIR}  > /dev/null 2>&1

# 14 DESC modes
$PATH_SCRIPTS/SCRIPTS_MT/Read_All_Img.sh "${UNZIPDIR}"/SPT_"${MODE01D}" "${CSLDIR}"/PF_"${MODE01D}"/NoCrop ALOS2 "${POL}" #"${RESAMDIR}" ${MASSPROCDIR}  > /dev/null 2>&1
$PATH_SCRIPTS/SCRIPTS_MT/Read_All_Img.sh "${UNZIPDIR}"/SPT_"${MODE02D}" "${CSLDIR}"/PF_"${MODE02D}"/NoCrop ALOS2 "${POL}" #"${RESAMDIR}" ${MASSPROCDIR}  > /dev/null 2>&1
$PATH_SCRIPTS/SCRIPTS_MT/Read_All_Img.sh "${UNZIPDIR}"/SPT_"${MODE03D}" "${CSLDIR}"/PF_"${MODE03D}"/NoCrop ALOS2 "${POL}" #"${RESAMDIR}" ${MASSPROCDIR}  > /dev/null 2>&1
$PATH_SCRIPTS/SCRIPTS_MT/Read_All_Img.sh "${UNZIPDIR}"/SPT_"${MODE04D}" "${CSLDIR}"/PF_"${MODE04D}"/NoCrop ALOS2 "${POL}" #"${RESAMDIR}" ${MASSPROCDIR}  > /dev/null 2>&1
$PATH_SCRIPTS/SCRIPTS_MT/Read_All_Img.sh "${UNZIPDIR}"/SPT_"${MODE05D}" "${CSLDIR}"/PF_"${MODE05D}"/NoCrop ALOS2 "${POL}" #"${RESAMDIR}" ${MASSPROCDIR}  > /dev/null 2>&1
$PATH_SCRIPTS/SCRIPTS_MT/Read_All_Img.sh "${UNZIPDIR}"/SPT_"${MODE06D}" "${CSLDIR}"/PF_"${MODE06D}"/NoCrop ALOS2 "${POL}" #"${RESAMDIR}" ${MASSPROCDIR}  > /dev/null 2>&1
$PATH_SCRIPTS/SCRIPTS_MT/Read_All_Img.sh "${UNZIPDIR}"/SPT_"${MODE07D}" "${CSLDIR}"/PF_"${MODE07D}"/NoCrop ALOS2 "${POL}" #"${RESAMDIR}" ${MASSPROCDIR}  > /dev/null 2>&1
$PATH_SCRIPTS/SCRIPTS_MT/Read_All_Img.sh "${UNZIPDIR}"/SPT_"${MODE08D}" "${CSLDIR}"/PF_"${MODE08D}"/NoCrop ALOS2 "${POL}" #"${RESAMDIR}" ${MASSPROCDIR}  > /dev/null 2>&1
$PATH_SCRIPTS/SCRIPTS_MT/Read_All_Img.sh "${UNZIPDIR}"/SPT_"${MODE09D}" "${CSLDIR}"/PF_"${MODE09D}"/NoCrop ALOS2 "${POL}" #"${RESAMDIR}" ${MASSPROCDIR}  > /dev/null 2>&1
$PATH_SCRIPTS/SCRIPTS_MT/Read_All_Img.sh "${UNZIPDIR}"/SPT_"${MODE10D}" "${CSLDIR}"/PF_"${MODE10D}"/NoCrop ALOS2 "${POL}" #"${RESAMDIR}" ${MASSPROCDIR}  > /dev/null 2>&1
$PATH_SCRIPTS/SCRIPTS_MT/Read_All_Img.sh "${UNZIPDIR}"/SPT_"${MODE11D}" "${CSLDIR}"/PF_"${MODE11D}"/NoCrop ALOS2 "${POL}" #"${RESAMDIR}" ${MASSPROCDIR}  > /dev/null 2>&1
$PATH_SCRIPTS/SCRIPTS_MT/Read_All_Img.sh "${UNZIPDIR}"/SPT_"${MODE12D}" "${CSLDIR}"/PF_"${MODE12D}"/NoCrop ALOS2 "${POL}" #"${RESAMDIR}" ${MASSPROCDIR}  > /dev/null 2>&1
$PATH_SCRIPTS/SCRIPTS_MT/Read_All_Img.sh "${UNZIPDIR}"/SPT_"${MODE13D}" "${CSLDIR}"/PF_"${MODE13D}"/NoCrop ALOS2 "${POL}" #"${RESAMDIR}" ${MASSPROCDIR}  > /dev/null 2>&1
$PATH_SCRIPTS/SCRIPTS_MT/Read_All_Img.sh "${UNZIPDIR}"/SPT_"${MODE14D}" "${CSLDIR}"/PF_"${MODE14D}"/NoCrop ALOS2 "${POL}" #"${RESAMDIR}" ${MASSPROCDIR}  > /dev/null 2>&1



# Search for pairs - proceed by batches of 6 or 7 to avoid overloading the computer
##################
# Link all images to corresponding set dir for 13 ascending
$PATH_SCRIPTS/SCRIPTS_MT/lns_All_Img.sh "${CSLDIR}"/PF_"${MODE01A}"/NoCrop ${SETDIR}/set5 ALOS2 > /dev/null 2>&1  &
$PATH_SCRIPTS/SCRIPTS_MT/lns_All_Img.sh "${CSLDIR}"/PF_"${MODE02A}"/NoCrop ${SETDIR}/set6 ALOS2 > /dev/null 2>&1  &
$PATH_SCRIPTS/SCRIPTS_MT/lns_All_Img.sh "${CSLDIR}"/PF_"${MODE03A}"/NoCrop ${SETDIR}/set7 ALOS2 > /dev/null 2>&1  &
$PATH_SCRIPTS/SCRIPTS_MT/lns_All_Img.sh "${CSLDIR}"/PF_"${MODE04A}"/NoCrop ${SETDIR}/set8 ALOS2 > /dev/null 2>&1  &
$PATH_SCRIPTS/SCRIPTS_MT/lns_All_Img.sh "${CSLDIR}"/PF_"${MODE05A}"/NoCrop ${SETDIR}/set9 ALOS2 > /dev/null 2>&1  &
$PATH_SCRIPTS/SCRIPTS_MT/lns_All_Img.sh "${CSLDIR}"/PF_"${MODE06A}"/NoCrop ${SETDIR}/set10 ALOS2 > /dev/null 2>&1  &
$PATH_SCRIPTS/SCRIPTS_MT/lns_All_Img.sh "${CSLDIR}"/PF_"${MODE07A}"/NoCrop ${SETDIR}/set11 ALOS2 > /dev/null 2>&1  &
wait
$PATH_SCRIPTS/SCRIPTS_MT/lns_All_Img.sh "${CSLDIR}"/PF_"${MODE08A}"/NoCrop ${SETDIR}/set12 ALOS2 > /dev/null 2>&1  &
$PATH_SCRIPTS/SCRIPTS_MT/lns_All_Img.sh "${CSLDIR}"/PF_"${MODE09A}"/NoCrop ${SETDIR}/set13 ALOS2 > /dev/null 2>&1  &
$PATH_SCRIPTS/SCRIPTS_MT/lns_All_Img.sh "${CSLDIR}"/PF_"${MODE10A}"/NoCrop ${SETDIR}/set14 ALOS2 > /dev/null 2>&1  &
$PATH_SCRIPTS/SCRIPTS_MT/lns_All_Img.sh "${CSLDIR}"/PF_"${MODE11A}"/NoCrop ${SETDIR}/set15 ALOS2 > /dev/null 2>&1  &
$PATH_SCRIPTS/SCRIPTS_MT/lns_All_Img.sh "${CSLDIR}"/PF_"${MODE12A}"/NoCrop ${SETDIR}/set16 ALOS2 > /dev/null 2>&1  &
$PATH_SCRIPTS/SCRIPTS_MT/lns_All_Img.sh "${CSLDIR}"/PF_"${MODE13A}"/NoCrop ${SETDIR}/set17 ALOS2 > /dev/null 2>&1  &

# Link all images to corresponding set dir for 14 descending
$PATH_SCRIPTS/SCRIPTS_MT/lns_All_Img.sh "${CSLDIR}"/PF_"${MODE01D}"/NoCrop ${SETDIR}/set18 ALOS2 > /dev/null 2>&1  &
$PATH_SCRIPTS/SCRIPTS_MT/lns_All_Img.sh "${CSLDIR}"/PF_"${MODE02D}"/NoCrop ${SETDIR}/set19 ALOS2 > /dev/null 2>&1  &
$PATH_SCRIPTS/SCRIPTS_MT/lns_All_Img.sh "${CSLDIR}"/PF_"${MODE03D}"/NoCrop ${SETDIR}/set20 ALOS2 > /dev/null 2>&1  &
$PATH_SCRIPTS/SCRIPTS_MT/lns_All_Img.sh "${CSLDIR}"/PF_"${MODE04D}"/NoCrop ${SETDIR}/set21 ALOS2 > /dev/null 2>&1  &
$PATH_SCRIPTS/SCRIPTS_MT/lns_All_Img.sh "${CSLDIR}"/PF_"${MODE05D}"/NoCrop ${SETDIR}/set22 ALOS2 > /dev/null 2>&1  &
$PATH_SCRIPTS/SCRIPTS_MT/lns_All_Img.sh "${CSLDIR}"/PF_"${MODE06D}"/NoCrop ${SETDIR}/set23 ALOS2 > /dev/null 2>&1  &
$PATH_SCRIPTS/SCRIPTS_MT/lns_All_Img.sh "${CSLDIR}"/PF_"${MODE07D}"/NoCrop ${SETDIR}/set24 ALOS2 > /dev/null 2>&1  &
wait
$PATH_SCRIPTS/SCRIPTS_MT/lns_All_Img.sh "${CSLDIR}"/PF_"${MODE08D}"/NoCrop ${SETDIR}/set25 ALOS2 > /dev/null 2>&1  &
$PATH_SCRIPTS/SCRIPTS_MT/lns_All_Img.sh "${CSLDIR}"/PF_"${MODE09D}"/NoCrop ${SETDIR}/set26 ALOS2 > /dev/null 2>&1  &
$PATH_SCRIPTS/SCRIPTS_MT/lns_All_Img.sh "${CSLDIR}"/PF_"${MODE10D}"/NoCrop ${SETDIR}/set27 ALOS2 > /dev/null 2>&1  &
$PATH_SCRIPTS/SCRIPTS_MT/lns_All_Img.sh "${CSLDIR}"/PF_"${MODE11D}"/NoCrop ${SETDIR}/set28 ALOS2 > /dev/null 2>&1  &
$PATH_SCRIPTS/SCRIPTS_MT/lns_All_Img.sh "${CSLDIR}"/PF_"${MODE12D}"/NoCrop ${SETDIR}/set29 ALOS2 > /dev/null 2>&1  &
$PATH_SCRIPTS/SCRIPTS_MT/lns_All_Img.sh "${CSLDIR}"/PF_"${MODE13D}"/NoCrop ${SETDIR}/set30 ALOS2 > /dev/null 2>&1  &
$PATH_SCRIPTS/SCRIPTS_MT/lns_All_Img.sh "${CSLDIR}"/PF_"${MODE14D}"/NoCrop ${SETDIR}/set31 ALOS2 > /dev/null 2>&1  &
wait

# Coregister all images on the super master - proceed by batches of 4 modes to avoid overloading the computer
###########################################
# 13 Ascending mode 
$PATH_SCRIPTS/SCRIPTS_MT/SuperMasterCoreg.sh $PATH_1650/Param_files/ALOS2/PF/${MODE01A}/LaunchMTparam_ALOS2_${MODE01A}_Full_Zoom1_ML8_Coreg_NewDEM_Newmask.txt &
$PATH_SCRIPTS/SCRIPTS_MT/SuperMasterCoreg.sh $PATH_1650/Param_files/ALOS2/PF/${MODE02A}/LaunchMTparam_ALOS2_${MODE02A}_Full_Zoom1_ML8_Coreg_NewDEM_Newmask.txt &
$PATH_SCRIPTS/SCRIPTS_MT/SuperMasterCoreg.sh $PATH_1650/Param_files/ALOS2/PF/${MODE03A}/LaunchMTparam_ALOS2_${MODE03A}_Full_Zoom1_ML8_Coreg_NewDEM_Newmask.txt &
$PATH_SCRIPTS/SCRIPTS_MT/SuperMasterCoreg.sh $PATH_1650/Param_files/ALOS2/PF/${MODE04A}/LaunchMTparam_ALOS2_${MODE04A}_Full_Zoom1_ML8_Coreg_NewDEM_Newmask.txt &
wait
$PATH_SCRIPTS/SCRIPTS_MT/SuperMasterCoreg.sh $PATH_1650/Param_files/ALOS2/PF/${MODE05A}/LaunchMTparam_ALOS2_${MODE05A}_Full_Zoom1_ML8_Coreg_NewDEM_Newmask.txt &
$PATH_SCRIPTS/SCRIPTS_MT/SuperMasterCoreg.sh $PATH_1650/Param_files/ALOS2/PF/${MODE06A}/LaunchMTparam_ALOS2_${MODE06A}_Full_Zoom1_ML8_Coreg_NewDEM_Newmask.txt &
$PATH_SCRIPTS/SCRIPTS_MT/SuperMasterCoreg.sh $PATH_1650/Param_files/ALOS2/PF/${MODE07A}/LaunchMTparam_ALOS2_${MODE07A}_Full_Zoom1_ML8_Coreg_NewDEM_Newmask.txt &
$PATH_SCRIPTS/SCRIPTS_MT/SuperMasterCoreg.sh $PATH_1650/Param_files/ALOS2/PF/${MODE08A}/LaunchMTparam_ALOS2_${MODE08A}_Full_Zoom1_ML8_Coreg_NewDEM_Newmask.txt &
wait
$PATH_SCRIPTS/SCRIPTS_MT/SuperMasterCoreg.sh $PATH_1650/Param_files/ALOS2/PF/${MODE09A}/LaunchMTparam_ALOS2_${MODE09A}_Full_Zoom1_ML8_Coreg_NewDEM_Newmask.txt &
$PATH_SCRIPTS/SCRIPTS_MT/SuperMasterCoreg.sh $PATH_1650/Param_files/ALOS2/PF/${MODE10A}/LaunchMTparam_ALOS2_${MODE10A}_Full_Zoom1_ML8_Coreg_NewDEM_Newmask.txt &
$PATH_SCRIPTS/SCRIPTS_MT/SuperMasterCoreg.sh $PATH_1650/Param_files/ALOS2/PF/${MODE11A}/LaunchMTparam_ALOS2_${MODE11A}_Full_Zoom1_ML8_Coreg_NewDEM_Newmask.txt &
$PATH_SCRIPTS/SCRIPTS_MT/SuperMasterCoreg.sh $PATH_1650/Param_files/ALOS2/PF/${MODE12A}/LaunchMTparam_ALOS2_${MODE12A}_Full_Zoom1_ML8_Coreg_NewDEM_Newmask.txt &
wait
$PATH_SCRIPTS/SCRIPTS_MT/SuperMasterCoreg.sh $PATH_1650/Param_files/ALOS2/PF/${MODE13A}/LaunchMTparam_ALOS2_${MODE13A}_Full_Zoom1_ML8_Coreg_NewDEM_Newmask.txt &

# 14 Descending mode 
$PATH_SCRIPTS/SCRIPTS_MT/SuperMasterCoreg.sh $PATH_1650/Param_files/ALOS2/PF/${MODE01D}/LaunchMTparam_ALOS2_${MODE01D}_Full_Zoom1_ML8_Coreg_NewDEM_Newmask.txt &
$PATH_SCRIPTS/SCRIPTS_MT/SuperMasterCoreg.sh $PATH_1650/Param_files/ALOS2/PF/${MODE02D}/LaunchMTparam_ALOS2_${MODE02D}_Full_Zoom1_ML8_Coreg_NewDEM_Newmask.txt &
$PATH_SCRIPTS/SCRIPTS_MT/SuperMasterCoreg.sh $PATH_1650/Param_files/ALOS2/PF/${MODE03D}/LaunchMTparam_ALOS2_${MODE03D}_Full_Zoom1_ML8_Coreg_NewDEM_Newmask.txt &
wait
$PATH_SCRIPTS/SCRIPTS_MT/SuperMasterCoreg.sh $PATH_1650/Param_files/ALOS2/PF/${MODE04D}/LaunchMTparam_ALOS2_${MODE04D}_Full_Zoom1_ML8_Coreg_NewDEM_Newmask.txt &
$PATH_SCRIPTS/SCRIPTS_MT/SuperMasterCoreg.sh $PATH_1650/Param_files/ALOS2/PF/${MODE05D}/LaunchMTparam_ALOS2_${MODE05D}_Full_Zoom1_ML8_Coreg_NewDEM_Newmask.txt &
$PATH_SCRIPTS/SCRIPTS_MT/SuperMasterCoreg.sh $PATH_1650/Param_files/ALOS2/PF/${MODE06D}/LaunchMTparam_ALOS2_${MODE06D}_Full_Zoom1_ML8_Coreg_NewDEM_Newmask.txt &
$PATH_SCRIPTS/SCRIPTS_MT/SuperMasterCoreg.sh $PATH_1650/Param_files/ALOS2/PF/${MODE07D}/LaunchMTparam_ALOS2_${MODE07D}_Full_Zoom1_ML8_Coreg_NewDEM_Newmask.txt &
wait
$PATH_SCRIPTS/SCRIPTS_MT/SuperMasterCoreg.sh $PATH_1650/Param_files/ALOS2/PF/${MODE08D}/LaunchMTparam_ALOS2_${MODE08D}_Full_Zoom1_ML8_Coreg_NewDEM_Newmask.txt &
$PATH_SCRIPTS/SCRIPTS_MT/SuperMasterCoreg.sh $PATH_1650/Param_files/ALOS2/PF/${MODE09D}/LaunchMTparam_ALOS2_${MODE09D}_Full_Zoom1_ML8_Coreg_NewDEM_Newmask.txt &
$PATH_SCRIPTS/SCRIPTS_MT/SuperMasterCoreg.sh $PATH_1650/Param_files/ALOS2/PF/${MODE10D}/LaunchMTparam_ALOS2_${MODE10D}_Full_Zoom1_ML8_Coreg_NewDEM_Newmask.txt &
$PATH_SCRIPTS/SCRIPTS_MT/SuperMasterCoreg.sh $PATH_1650/Param_files/ALOS2/PF/${MODE11D}/LaunchMTparam_ALOS2_${MODE11D}_Full_Zoom1_ML8_Coreg_NewDEM_Newmask.txt &
wait
$PATH_SCRIPTS/SCRIPTS_MT/SuperMasterCoreg.sh $PATH_1650/Param_files/ALOS2/PF/${MODE12D}/LaunchMTparam_ALOS2_${MODE12D}_Full_Zoom1_ML8_Coreg_NewDEM_Newmask.txt &
$PATH_SCRIPTS/SCRIPTS_MT/SuperMasterCoreg.sh $PATH_1650/Param_files/ALOS2/PF/${MODE13D}/LaunchMTparam_ALOS2_${MODE13D}_Full_Zoom1_ML8_Coreg_NewDEM_Newmask.txt &
$PATH_SCRIPTS/SCRIPTS_MT/SuperMasterCoreg.sh $PATH_1650/Param_files/ALOS2/PF/${MODE14D}/LaunchMTparam_ALOS2_${MODE14D}_Full_Zoom1_ML8_Coreg_NewDEM_Newmask.txt &

# Compute pairs 
# Compute pairs only if new data is identified in ASCENDING
if [ ! -s ${NEWASCPATH01A}/_No_New_Data_Today.txt ] ; then 
	echo "n" | Prepa_MSBAS.sh ${SETDIR}/set5  ${BP01A} ${BT01A} ${SM01A}  > /dev/null 2>&1  & # ${BP2} ${BT2} ${DATECHG}
fi
if [ ! -s ${NEWASCPATH02A}/_No_New_Data_Today.txt ] ; then 
	echo "n" | Prepa_MSBAS.sh ${SETDIR}/set6  ${BP02A} ${BT02A} ${SM02A}  > /dev/null 2>&1  & # ${BP2} ${BT2} ${DATECHG}
fi
if [ ! -s ${NEWASCPATH03A}/_No_New_Data_Today.txt ] ; then 
	echo "n" | Prepa_MSBAS.sh ${SETDIR}/set7  ${BP03A} ${BT03A} ${SM03A}  > /dev/null 2>&1  & # ${BP2} ${BT2} ${DATECHG}
fi
if [ ! -s ${NEWASCPATH04A}/_No_New_Data_Today.txt ] ; then 
	echo "n" | Prepa_MSBAS.sh ${SETDIR}/set8  ${BP04A} ${BT04A} ${SM04A}  > /dev/null 2>&1  & # ${BP2} ${BT2} ${DATECHG}
fi
if [ ! -s ${NEWASCPATH05A}/_No_New_Data_Today.txt ] ; then 
	echo "n" | Prepa_MSBAS.sh ${SETDIR}/set9  ${BP05A} ${BT05A} ${SM05A}  > /dev/null 2>&1  & # ${BP2} ${BT2} ${DATECHG}
fi
if [ ! -s ${NEWASCPATH06A}/_No_New_Data_Today.txt ] ; then 
	echo "n" | Prepa_MSBAS.sh ${SETDIR}/set10 ${BP06A} ${BT06A} ${SM06A}  > /dev/null 2>&1  & # ${BP2} ${BT2} ${DATECHG}
fi
if [ ! -s ${NEWASCPATH07A}/_No_New_Data_Today.txt ] ; then 
	echo "n" | Prepa_MSBAS.sh ${SETDIR}/set11 ${BP07A} ${BT07A} ${SM07A}  > /dev/null 2>&1  & # ${BP2} ${BT2} ${DATECHG}
fi
if [ ! -s ${NEWASCPATH08A}/_No_New_Data_Today.txt ] ; then 
	echo "n" | Prepa_MSBAS.sh ${SETDIR}/set12 ${BP08A} ${BT08A} ${SM08A}  > /dev/null 2>&1  & # ${BP2} ${BT2} ${DATECHG}
fi
if [ ! -s ${NEWASCPATH09A}/_No_New_Data_Today.txt ] ; then 
	echo "n" | Prepa_MSBAS.sh ${SETDIR}/set13 ${BP09A} ${BT09A} ${SM09A}  > /dev/null 2>&1  & # ${BP2} ${BT2} ${DATECHG}
fi
if [ ! -s ${NEWASCPATH10A}/_No_New_Data_Today.txt ] ; then 
	echo "n" | Prepa_MSBAS.sh ${SETDIR}/set14 ${BP10A} ${BT10A} ${SM10A}  > /dev/null 2>&1  & # ${BP2} ${BT2} ${DATECHG}
fi
if [ ! -s ${NEWASCPATH11A}/_No_New_Data_Today.txt ] ; then 
	echo "n" | Prepa_MSBAS.sh ${SETDIR}/set15 ${BP11A} ${BT11A} ${SM11A}  > /dev/null 2>&1  & # ${BP2} ${BT2} ${DATECHG}
fi
if [ ! -s ${NEWASCPATH12A}/_No_New_Data_Today.txt ] ; then 
	echo "n" | Prepa_MSBAS.sh ${SETDIR}/set16 ${BP12A} ${BT12A} ${SM12A}  > /dev/null 2>&1  & # ${BP2} ${BT2} ${DATECHG}
fi
if [ ! -s ${NEWASCPATH13A}/_No_New_Data_Today.txt ] ; then 
	echo "n" | Prepa_MSBAS.sh ${SETDIR}/set17 ${BP13A} ${BT13A} ${SM13A}  > /dev/null 2>&1  & # ${BP2} ${BT2} ${DATECHG}
fi


# Compute pairs only if new data is identified in DESCENDING
if [ ! -s ${NEWASCPATH01D}/_No_New_Data_Today.txt ] ; then 
	echo "n" | Prepa_MSBAS.sh ${SETDIR}/set18  ${BP01D} ${BT01D} ${SM01D}  > /dev/null 2>&1  & # ${BP2} ${BT2} ${DATECHG}
fi
if [ ! -s ${NEWASCPATH02D}/_No_New_Data_Today.txt ] ; then 
	echo "n" | Prepa_MSBAS.sh ${SETDIR}/set19  ${BP02D} ${BT02D} ${SM02D}  > /dev/null 2>&1  & # ${BP2} ${BT2} ${DATECHG}
fi
if [ ! -s ${NEWASCPATH03D}/_No_New_Data_Today.txt ] ; then 
	echo "n" | Prepa_MSBAS.sh ${SETDIR}/set20  ${BP03D} ${BT03D} ${SM03D}  > /dev/null 2>&1  & # ${BP2} ${BT2} ${DATECHG}
fi
if [ ! -s ${NEWASCPATH04D}/_No_New_Data_Today.txt ] ; then 
	echo "n" | Prepa_MSBAS.sh ${SETDIR}/set21  ${BP04D} ${BT04D} ${SM04D}  > /dev/null 2>&1  & # ${BP2} ${BT2} ${DATECHG}
fi
if [ ! -s ${NEWASCPATH05D}/_No_New_Data_Today.txt ] ; then 
	echo "n" | Prepa_MSBAS.sh ${SETDIR}/set22  ${BP05D} ${BT05D} ${SM05D}  > /dev/null 2>&1  & # ${BP2} ${BT2} ${DATECHG}
fi
if [ ! -s ${NEWASCPATH06D}/_No_New_Data_Today.txt ] ; then 
	echo "n" | Prepa_MSBAS.sh ${SETDIR}/set23 ${BP06D} ${BT06D} ${SM06D}  > /dev/null 2>&1  & # ${BP2} ${BT2} ${DATECHG}
fi
if [ ! -s ${NEWASCPATH07D}/_No_New_Data_Today.txt ] ; then 
	echo "n" | Prepa_MSBAS.sh ${SETDIR}/set24 ${BP07D} ${BT07D} ${SM07D}  > /dev/null 2>&1  & # ${BP2} ${BT2} ${DATECHG}
fi
if [ ! -s ${NEWASCPATH08D}/_No_New_Data_Today.txt ] ; then 
	echo "n" | Prepa_MSBAS.sh ${SETDIR}/set25 ${BP08D} ${BT08D} ${SM08D}  > /dev/null 2>&1  & # ${BP2} ${BT2} ${DATECHG}
fi
if [ ! -s ${NEWASCPATH09D}/_No_New_Data_Today.txt ] ; then 
	echo "n" | Prepa_MSBAS.sh ${SETDIR}/set26 ${BP09D} ${BT09D} ${SM09D}  > /dev/null 2>&1  & # ${BP2} ${BT2} ${DATECHG}
fi
if [ ! -s ${NEWASCPATH10D}/_No_New_Data_Today.txt ] ; then 
	echo "n" | Prepa_MSBAS.sh ${SETDIR}/set27 ${BP10D} ${BT10D} ${SM10D}  > /dev/null 2>&1  & # ${BP2} ${BT2} ${DATECHG}
fi
if [ ! -s ${NEWASCPATH11D}/_No_New_Data_Today.txt ] ; then 
	echo "n" | Prepa_MSBAS.sh ${SETDIR}/set28 ${BP11D} ${BT11D} ${SM11D}  > /dev/null 2>&1  & # ${BP2} ${BT2} ${DATECHG}
fi
if [ ! -s ${NEWASCPATH12D}/_No_New_Data_Today.txt ] ; then 
	echo "n" | Prepa_MSBAS.sh ${SETDIR}/set29 ${BP12D} ${BT12D} ${SM12D}  > /dev/null 2>&1  & # ${BP2} ${BT2} ${DATECHG}
fi
if [ ! -s ${NEWASCPATH13D}/_No_New_Data_Today.txt ] ; then 
	echo "n" | Prepa_MSBAS.sh ${SETDIR}/set30 ${BP13D} ${BT13D} ${SM13D}  > /dev/null 2>&1  & # ${BP2} ${BT2} ${DATECHG}
fi
if [ ! -s ${NEWASCPATH14D}/_No_New_Data_Today.txt ] ; then 
	echo "n" | Prepa_MSBAS.sh ${SETDIR}/set31 ${BP14D} ${BT14D} ${SM14D}  > /dev/null 2>&1  & # ${BP2} ${BT2} ${DATECHG}
fi
wait


echo "Ending $0" >> ${CSLDIR}/Last_Run_Cron_Step1.txt
date >> ${CSLDIR}/Last_Run_Cron_Step1.txt
