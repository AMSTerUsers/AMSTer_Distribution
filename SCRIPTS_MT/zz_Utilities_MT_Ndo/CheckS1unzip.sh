#!/bin/bash
# script to test if directories with S1 unzipped images in UNZIPDIR already exist in 
# S1-DATA-TARGET-SLC.UNZIP_FORMER/_YYYY directroy and has the same size. 
# If not it displays the nr of files and the total size for comparison. 
# Note that it will test that the UNZIPDIR might also be in S1-DATA-TARGET-SLC.UNZIP
#
# Parameters : - path to dir with the unzipped S1 images (eg after decompressing using Unzip_S1.sh when downloaded from LSA)   
#              - path to dir where S1 images must be archived when > 6 months, e.g. /Volumes/hp-D3600-Data_Share1/SAR_DATA/S1/S1-DATA-LUXEMBOURG-SLC.UNZIP_FORMER 
#
#
# Dependencies:	- gnu sed and awk for more compatibility
#   			- MacColorFile.sh 
#
# Hard coded:	- 
#
# New in Distro V 1.1 (Sept 21, 2022): - remove stray \ before _ while calling grep to cope with new grep syntax and avoid waring
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

UNZIPDIR=$1		# e.g. /Volumes/hp-D3602-Data_RAID5/SAR_DATA_Other_Zones_2/S1/S1-DATA-LUXEMBOURG_BE-SLC/RETRIEVAL_13/Part_5.UNZIP
TARGETDIR=$2	# e.g. /Volumes/hp-D3600-Data_Share1/SAR_DATA/S1/S1-DATA-LUXEMBOURG-SLC.UNZIP_FORMER 

TARGETDIRNOFORMER=`echo ${TARGETDIR} | ${PATHGNU}/gsed 's/\_FORMER//' `


function CheckConsistency()
	{
	unset LOCALTARGETDIR 
	local LOCALTARGETDIR
	LOCALTARGETDIR=$1
	
	# number of files and size in DIRSAFE
	NRFILESTARGET=`du -ac ${LOCALTARGETDIR}/${DIRSAFE} | wc -l`													
	SIZETARGET=`du -ac ${LOCALTARGETDIR}/${DIRSAFE} | tail -1 | ${PATHGNU}/gsed 's@^[^0-9]*\([0-9]\+\).*@\1@' `

	if [ ${NRFILESUNZIP} -ne ${NRFILESTARGET} ]
		then 
			echo -e "$(tput setaf 1)$(tput setab 7)Not the same nr of files in ${DIRSAFE}$(tput sgr 0)" # msg in red
			echo "	Number of files in ${DIRSAFE} : ${NRFILESUNZIP} " 
			echo "	Number of files in ${LOCALTARGETDIR}/${DIRSAFE} : ${NRFILESTARGET} " 
			MacColorFile.sh 1 ${UNZIPDIR}/${DIRSAFE}  > /dev/null # 1 orange ; 2 red ; 6 green
		else 
			if [ ${SIZEUNZIP} -ne ${SIZETARGET} ]
				then 
					echo -e "$(tput setaf 1)$(tput setab 7)Not the same size for ${DIRSAFE}$(tput sgr 0)" # msg in red
					echo "	Size of all files in ${DIRSAFE} : ${SIZEUNZIP} " 
					echo "	Size of all files in ${LOCALTARGETDIR}/${DIRSAFE} : ${SIZETARGET} " 
					echo
					MacColorFile.sh 1 ${UNZIPDIR}/${DIRSAFE}  > /dev/null # 1 orange ; 2 red ; 6 green
				else 
					echo "Dir ${DIRSAFE} exist in ${LOCALTARGETDIR} and is OK" 
					MacColorFile.sh 7 ${UNZIPDIR}/${DIRSAFE}  > /dev/null # 1 orange ; 2 red ; 6 green ; 7 grey
			fi
	fi
	}

cd ${UNZIPDIR}
for DIRSAFE in `ls -d *.SAFE`
	do
		DATEFILE=`echo "${DIRSAFE}" | ${PATHGNU}/grep -Eo "_[0-9]{8}T" | head -1 | cut -c 1-5 2>/dev/null ` # select _date where date is 8 numbers

		NRFILESUNZIP=`du -ac ${UNZIPDIR}/${DIRSAFE} | wc -l`
		SIZEUNZIP=`du -ac ${UNZIPDIR}/${DIRSAFE} | tail -1 | sed 's@^[^0-9]*\([0-9]\+\).*@\1@' `
		
		if [ `ls -d ${TARGETDIR}/${DATEFILE}/${DIRSAFE} 2>/dev/null | wc -c` -le 0 ] 
			then
				echo "Dir ${DIRSAFE} does not exist in ${TARGETDIR}/${DATEFILE} "
				
				if [ `ls -d ${TARGETDIRNOFORMER}/${DIRSAFE} 2>/dev/null | wc -c` -le 0 ] 
					then 
						echo "	nor in ${TARGETDIRNOFORMER} : cp it in ${TARGETDIR}/${DATEFILE}"
						mkdir -p ${TARGETDIR}/${DATEFILE}
						echo -e "$(tput setaf 1)$(tput setab 7)	Please run eg.:  cp -R ${UNZIPDIR}/${DIRSAFE} ${TARGETDIR}/${DATEFILE}$(tput sgr 0)"
					else 
						echo "	but does exist in ${TARGETDIRNOFORMER}"
						CheckConsistency ${TARGETDIRNOFORMER}
				fi
			else 
				CheckConsistency ${TARGETDIR}/${DATEFILE}
		fi
done
