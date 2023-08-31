#!/bin/bash
# -----------------------------------------------------------------------------------------
# This script is aiming at creating a symbolic link from csl data from where they are 
#      stored to where they will be used by the cis automated scripts. 
#
# Parameters : - path to dir with the csl archives are stored.   
#              - path to dir where link will be copied (something like .../seti  where i is integer)
#              - SAT (required for TSX/TDX to get down to BTX dir)
#
# Dependencies:	- none
#
# New in Distro V 1.0:	- Based on developpement version 1.1 and Beta V1.3
# New in Distro V 1.1:	- OK for TDX (ensure that ARCHIVE dir is the mode _TX) 
# New in Distro V 1.2: - remove stray \ before _ while calling grep to cope with new grep syntax and avoid waring
#
# MasTer: InSAR Suite automated Mass processing Toolbox. 
# NdO (c) 2016/03/14 - could make better... when time.
# -----------------------------------------------------------------------------------------
PRG=`basename "$0"`
VER="Distro V1.2 MasTer script utilities"
AUT="Nicolas d'Oreye, (c)2016-2019, Last modified on Sept 21, 2022"
echo " "
echo "${PRG} ${VER}, ${AUT}"
echo "Processing launched on $(date) " 
echo " " 

ARCHIVES=$1					# path to dir where the csl archives are stored (for TDX, it must be the _TX dir that is used)
LINKTOCSL=$2				# path to dir where link will be copied (e.g. set"i")
SAT=$3						# required for TSX/TDX to get down to BTX dir

if [ $# -lt 2 ] ; then echo “Usage $0 PATH_TO_ARCHIVES PATH_TO_LINK [SATifTDX]”; exit; fi

echo ""
# Check required dir:
#####################
# Path to original raw data 
if [ -d "${ARCHIVES}/" ]
then
   echo " OK: a directory exist where I guess csl archives are stored." 
   echo "      I guess images are in ${ARCHIVES}."    
else
   echo " "
   echo " NO directory ${ARCHIVES}/ where I can find raw data. Can't run..." 
   echo "   I expect something like /...your_path.../SAR_CSL/SAT/TRKDIR/NoCrop"
   exit 1
fi
# Path where to store data in csl format 
if [ -d "${LINKTOCSL}" ]
then
   echo " OK: a directory exist where I can make a link to data in csl format." 
   echo "     They will be strored in ${LINKTOCSL}"
else
   echo " "
   echo " NO expected ${LINKTOCSL} directory."
   echo " I will create a new one. I guess it is the first run for that mode." 
   mkdir -p ${LINKTOCSL}
fi

# Let's Go:
###########	

# read existing csl archives (usually in /...your_path.../SAR_CSL/SAT/TRKDIR/NoCrop)
case ${SAT} in
 	"TDX") 
		# suppose that BRX is ok if BTX is present
		cd ${ARCHIVES}			
		#ls -d *.csl > ${ARCHIVES}/List_raw.txt
		find . -type d -name "*.csl" ! -name '9*' | ${PATHGNU}/gsed 's/.\///' > ${ARCHIVES}/List_raw.txt  # avoid looking at linked dir that start with 9 and that are fake slave for bistatic processing and remove leading ./
		# actually avoiding testing statrt with 9 is not necessary because those are link and not dir, but do it just in case... 
		;;
	*) 	
		cd ${ARCHIVES}				
		ls -d *.csl  > List_raw.txt;;
esac
# If S1, get list of csl images dates
if [ ${SAT} == "S1" ] ; then 
	for ARCH in `cat -s ${ARCHIVES}/List_raw.txt`
	do	
		DATES=`echo "${ARCH}" | ${PATHGNU}/grep -Eo "_[0-9]{8}_" | cut -d_ -f2 | cut -d. -f1` # select _date_ where date is 8 numbers
		echo ${DATES} >> ${ARCHIVES}/List_Dates_raw.txt
	done
fi

# read existing link in dir where MSBAS routines will be used
cd ${LINKTOCSL}
if [ `ls -d *.csl 2>/dev/null | wc -w` -ge "1" ]
	then
		ls -d *.csl > ${ARCHIVES}/List_csl.txt
		# If S1, get list of exiting links dates
		if [ ${SAT} == "S1" ] ; then 
			for ARCH in `cat -s ${ARCHIVES}/List_csl.txt`
			do	
				DATES=`echo "${ARCH}" | ${PATHGNU}/grep -Eo "[0-9]{8}" | cut -d_ -f2` # select _date_ where date is 8 numbers
				echo ${DATES} >> ${ARCHIVES}/List_Dates_csl.txt
			done
		fi
	else
		touch ${ARCHIVES}/List_csl.txt
		touch ${ARCHIVES}/List_Dates_csl.txt
fi


cd ${ARCHIVES}

# Search for only the new ones to be processed:
#    In List_csl.txt names are date.csl, 
#    while in List_raw.txt names are a complex dir name that includes date somewhere
if [ ${SAT} == "S1" ] 
	then 
		cp -f List_Dates_raw.txt Img_To_Read.txt
		for LINE in `cat -s List_Dates_csl.txt`
			do	
				grep -v ${LINE} Img_To_Read.txt > Img_To_Read_tmp.txt
				cp -f Img_To_Read_tmp.txt Img_To_Read.txt
			done
	else 
		cp -f List_raw.txt Img_To_Read.txt
		for LINE in `cat -s List_csl.txt`
			do	
				grep -v ${LINE} Img_To_Read.txt > Img_To_Read_tmp.txt
				cp -f Img_To_Read_tmp.txt Img_To_Read.txt
			done
fi
rm -f Img_To_Read_tmp.txt

# Create link
for LINE in `cat -s Img_To_Read.txt`
	do	
		case ${SAT} in
			"TDX") 
				# suppose that BRX is ok if BTX is present
				ln -s ${ARCHIVES}/BTX/${LINE} ${LINKTOCSL}/${LINE}
				echo "Link ${LINE} created";;
			"S1") 
				FILELINE=`grep ${LINE} List_raw.txt `
				ln -s ${ARCHIVES}/${FILELINE} ${LINKTOCSL}/${LINE}.csl
				echo "Link ${LINE} created";;
			*) 	
				ln -s ${ARCHIVES}/${LINE} ${LINKTOCSL}/${LINE}
				echo "Link ${LINE} created";;
		esac		

	done

rm ${ARCHIVES}/List_raw.txt ${ARCHIVES}/List_csl.txt ${ARCHIVES}/Img_To_Read.txt
if [ "${SAT}" == "S1" ] ; then rm ${ARCHIVES}/List_Dates_csl.txt ${ARCHIVES}/List_Dates_raw.txt ; fi

# Remove possible broken links 
for LINKS in `ls -d ${LINKTOCSL}/*.csl 2> /dev/null`
	do
		find -L ${LINKS} -type l ! -exec test -e {} \; -exec rm {} \; # first part stays silent if link is ok (or is not a link but a file or dir); answer the name of the link if the link is broken. Second part removes link if broken 
done


echo "All links done." 
