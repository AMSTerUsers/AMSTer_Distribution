#!/bin/bash
# ****************************************************************************************
#The script will change the link to cope with possible different mount name of external HD
# as it occurs between Linux and Mac
#
# We suppose that the link is correct but for the two first dir levels, 
#     that is the external mounted disk that we want to change
#
# Parameters:	- Path to dir where all the links are (e.g. /Volumes/hp-D3602-Data_RAID5/MSBAS/VVP_S1_June2019/DefoInterpolx2Detrend1/)
#				- Disk to where links must point to (e.g. /Volumes/hp-1650-Data_Share1 or /mnt/1650 or /mnt/nfs1650)
#				- String of ending name of links to search and correct (e.g. deg) 
#
# Example: suppose we have links in MSBAS/sat/crop/Defomode/ that points toward 
#  /Volumes/hp-D3601-Data_RAID6/SAR_MASSPROCESS/sat/crop/Geocoded/Defomode  (i.e. computed on Mac)
# but we need to run it from a computer where $PATH_3601 is 
#  /mnt/1650 
# instead of /Volumes/hp-D3601-Data_RAID6, that in a disk monuted from Linux
# Then we will change all the links to that new mount point
#
# In the example use to illustrate the script below we use the following link
# ls -l /Volumes/hp-D3602-Data_RAID5/MSBAS/VVP_S1_June2019/DefoInterpolx2Detrend1/deformationMap.interpolated.flattened.UTM.100x100.bil.interpolated_S1_DRC_VVP_A_174-37.0deg_20141110_20141204_Bp70.48m_HA-201.m_BT24days_Head102.1deg 
# lrwx------ 1 doris staff 254 May 27 08:30 /Volumes/hp-D3602-Data_RAID5/MSBAS/VVP_S1_June2019/DefoInterpolx2Detrend1/deformationMap.interpolated.flattened.UTM.100x100.bil.interpolated_S1_DRC_VVP_A_174-37.0deg_20141110_20141204_Bp70.48m_HA-201.m_BT24days_Head102.1deg -> /mnt/3601/SAR_MASSPROCESS/S1/DRC_VVP_A_174/SMNoCrop_SM_20150310_Zoom1_ML8/Geocoded/DefoInterpolx2Detrend/deformationMap.interpolated.flattened.UTM.100x100.bil.interpolated_S1_DRC_VVP_A_174-37.0deg_20141110_20141204_Bp70.48m_HA-201.m_BT24days_Head102.1deg
#
# Dependencies: None
#
# New in Distro V 1.1 (Oct 12, 2021):	- add description of arguments
#						- For robustness, change detection of links based on nameing i.e. with a third param. 
# New in Distro V 2.0 20231030:	- Rename MasTer Toolbox as AMSTer Software
#								- rename Master and Slave as Primary and Secondary (though not possible in some variables and files)
#
# AMSTer: SAR & InSAR Automated Mass processing Software for Multidimensional Time series
# NdO (c) 2016/03/07 - could make better with more functions... when time.
# -----------------------------------------------------------------------------------------
PRG=`basename "$0"`
VER="Distro V2.0 AMSTer script utilities"
AUT="Nicolas d'Oreye, (c)2016-2019, Last modified on Oct 30, 2023"

echo " "
echo "${PRG} ${VER}, ${AUT}"
echo "Processing launched on $(date) " 
echo " " 


#dir where all the links are
INIDIRTLINK=$1													# e.g. /Volumes/hp-D3602-Data_RAID5/MSBAS/VVP_S1_June2019/DefoInterpolx2Detrend1/
#disk to where links must point to 
DESTDISCKLINK=$2												# e.g. /Volumes/hp-1650-Data_Share1 or /mnt/1650 or /mnt/nfs1650
# String of ending name of links to search and correct (e.g. deg) 
STRINGLINK=$3

# function to determine source disk
getlink()
{
	MOUNTDISK=`ls -l "$1" | cut -d ">" -f2 | cut -d "/" -f1-3`	# e.g. /Volumes/hp-D3601-Data_RAID6
	PATHTOFILE=`ls -l "$1" | cut -d ">" -f2 | cut -d "/" -f 4-`	# e.g. SAR_MASSPROCESS/S1/DRC_VVP_A_174/SMNoCrop_..._ML8/Geocoded/DefoInterpolx2Detrend/deformationMap...Head102.1deg
	NAMEFILE="${PATHTOFILE##*/}"

	if [ "${MOUNTDISK}" != ${DESTDISCKLINK} ]
		then
			#echo "ln -s -f ${DESTDISCKLINK}/${PATHTOFILE} ${INIDIRTLINK}/${PATHTOFILE}"
			ln -s -f ${DESTDISCKLINK}/${PATHTOFILE} ${INIDIRTLINK}/${NAMEFILE}
	fi
}


cd ${INIDIRTLINK}
#Find files and then send to function.
# find . -type l -print | while read filename
find . -maxdepth 1 -name "*${STRINGLINK}" -print | while read filename
 do
          if [ `ls -l  ${filename} 2>/dev/null | ${PATHGNU}/grep "\->" | wc -c ` -gt 0 ] 
          	then 
          		echo "${filename} is a link ; let's rebulid it" 
         		getlink "${filename}"
         	else 
         		echo "${filename} is NOT a link ; do nothing" 
         	fi
 done

