#!/bin/bash
######################################################################################
# This script runs the (m)sbas, store results in sub dir and creates figs 
#
# Parameters : - String PARAMNAME used to add to dir names where results will be stored. 
#                  This can help to remember eg some processing configs.
#			   - path and name of file containing the list of pixels (as COL RAW RADIUS) 
#				   for which one wants to output time series.
#			   - if a last param is given as --msbasvi (where i = version nr), then takes 
#					that one (if exist); if no, it takes the highest version of msbas available 
#
# ALL PARAMETERS ARE OPTIONAL BUT COMMENT IS MANDATORY IF ONE USE THE PIX LIST OUTPUT OR FORCE MSBAS VERSION      
#
# Dependencies:	- a header.txt file (built with build_header_msbas_criteria.sh)
#				- gnu sed and awk for more compatibility. 
#				- msbas, msbasv2 or msbasv3 
#    			- cpxfiddle is usefull though not mandatory. This is part of Doris package (TU Delft) available here :
#        			    http://doris.tudelft.nl/Doris_download.html. 
#				- script : 
#					+ Add_hdr_Files(_Less_Ras).sh 
#					+ Plot_All_LOS_ts_inDir.sh if run sbas
#					+ Plot_All_EW_UP_ts_inDir.sh if run msbas
#					+ Envi2ColorKmz.sh
#			    - seq
#
# New in Distro V 1.0:	- Based on developpement version 2.1 and Beta V1.5
#				V 1.1:  - keep log of msbas processing 
# New in Distro V 2.0:	- create rasters within script Add_hdr_Files.sh
#						- better test if TS dirs are empty before deleting
# New in Distro V 2.1:	- do not create raster for all the deformation map. If need it, replace 
#							Add_hdr_Files_Less_Ras.sh with Add_hdr_Files.sh below
# New in Distro V 2.2:	- accounts for usage with msbasv4, i.e. that requires additional info in header files 
# New in Distro V 2.3:	- check header.txt if it exist and ensure compatibility with msbas version
# New in Distro V 3.0:	- if last param = --msbasvi (where i = version nr), then takes that one (if exist); if no 
#						  3rd param, takes the highest version of msbas available 
# New in Distro V 3.1:	- search for msbas version was missing in case of 2 param
#						- and an exit for test was left in the script...
# New in Distro V 3.2:	- search for msbas version was missing in case of 0 param
# New in Distro V 4.0 20231030:	- Rename MasTer Toolbox as AMSTer Software
#								- rename Master and Slave as Primary and Secondary (though not possible in some variables and files)
# New in Distro V 4.1 20240109:	- When launched with only 1 param, it was not able to find the last version of msbas
#								- improve check empty dir at the end
#
# AMSTer: SAR & InSAR Automated Mass processing Software for Multidimensional Time series
# NdO (c) 2016/03/07 - could make better with more functions... when time.
# -----------------------------------------------------------------------------------------
PRG=`basename "$0"`
VER="Distro V4.1 AMSTer script utilities"
AUT="Nicolas d'Oreye, (c)2016-2019, Last modified on Jan 09, 2024"
echo " "
echo "${PRG} ${VER}, ${AUT}"
echo "Processing launched on $(date) " 
echo " " 

PARAMNAME=$1		# Comment for dir naming
#PIXFILELIST=$2 		# path and filename for list of pixels (COL RAW RADIUS) for which one wants to output time series

# Function to search the last version of msbas 
	LastMsbasV()
		{
		#Loop v1-20; though v1 has no version nr
		CHECKMSBASV1=`which msbas | wc -l`
		if [ ${CHECKMSBASV1} -gt 0 ] ; then MSBAS="msbas" ; fi 
	
		for i in $(seq 2 20) 
			do 
				CHECKMSBASV[${i}]=`which msbasv${i} | wc -l`	
				if [ ${CHECKMSBASV[${i}]} -gt 0 ] 
					then 
						MSBAS="msbasv${i}" 
				fi 
		done
		}
	
# assign parameters
if [ $# -eq 2 ] ; then 
	# If one of the parameters contains the string --msbasv, which would mean that you want to use a given version of msbas
	if [[ "${@#--msbasv}" = "$@" ]]
		then
			echo "2nd param seems to be the pix list."
			PIXFILELIST="$2"
			LastMsbasV
		else
			echo "Request specific msbas version $@."
			MSBAS=`echo $@ | cut -d - -f3`
			# Check if exist
			CHECKMSBAS=`which ${MSBAS} | wc -l`
			if [ ${CHECKMSBAS} -eq 0 ] 
				then 
					echo "Though it does not exist. Let's take the most recent version then..."
					LastMsbasV
			fi 
	fi
fi

if [ $# -eq 3 ] ; then 
	if [[ "$2" != *"--msbasv"* ]];
		then
			echo "2nd param seems to be the pix list."
			PIXFILELIST="$2"
			
			echo "and 3rd must be the msbas version"
			MSBAS=`echo $3 | cut -d - -f3`
			# Check if exist
			CHECKMSBAS=`which ${MSBAS} | wc -l`
			if [ ${CHECKMSBAS} -eq 0 ] 
				then 
					echo "Though it does not exist. Let's take the most recent version then..."
					LastMsbasV
			fi 			 
		else
			echo "2nd param seems to be the msbas version"
			MSBAS=`echo $2 | cut -d - -f3`
			# Check if exist
			CHECKMSBAS=`which ${MSBAS} | wc -l`
			if [ ${CHECKMSBAS} -eq 0 ] 
				then 
					echo "Though it does not exist. Let's take the most recent version then..."
					LastMsbasV
			fi 			 
			echo "and 3rd param seems to be the pix list."
			PIXFILELIST="$3"
	fi
fi

if [ $# -eq 0 ] || [ $# -eq 1 ] ; then 
	LastMsbasV
fi

echo
echo "Comment is: ${PARAMNAME}"
echo "msbas is: ${MSBAS}"
echo "pixlist is: ${PIXFILELIST}"

if [ ! -f header_original.txt ] ; then cp header.txt header_original.txt ; fi

if [ "${PIXFILELIST}" == "" ] ; then 
		echo "No pixel list provided. Will run without pixel time series."
		echo "  If you want to output time series for given pixels, also add a Comment for dir naming. See script."
	else 
		${PATHGNU}/gsed -i "s%I_FLAG = 0%I_FLAG = 2, ${PIXFILELIST}%" header.txt
fi

##msbasv2 header.txt 					# run (m)sbas
#CHECKMSBASV1=`which msbas | wc -l`
#CHECKMSBASV2=`which msbasv2 | wc -l`
#CHECKMSBASV3=`which msbasv3 | wc -l`
#CHECKMSBASV4=`which msbasv4 | wc -l`
#
#if [ ${CHECKMSBASV1} -gt 0 ] ; then MSBAS="msbas" ; fi  	
#if [ ${CHECKMSBASV2} -gt 0 ] ; then MSBAS="msbasv2" ; fi  	
#if [ ${CHECKMSBASV3} -gt 0 ] ; then MSBAS="msbasv3" ; fi  		
#if [ ${CHECKMSBASV4} -gt 0 ] ; then MSBAS="msbasv4" ; fi  	

LOG_FILE=_MSBAS_log.txt

echo "MSBAS processing started on :" > ${LOG_FILE}
date >> ${LOG_FILE}
echo ""  >> ${LOG_FILE}


# Functions to ensure that header.txt is indeed in the form expected by the msbas version
headerv4to3 ()
{
	# Transform header.txt for msbasv4 in the form or msbasv3 or lower
	
	# ensure that header.txt does not contain the string "V_FLAG=0"
	if [ `${PATHGNU}/grep "V_FLAG" header.txt | wc -l` -gt 0 ] ; then 
		echo "header.txt seems formated for msbas v4; remove V_FLAG "
		${PATHGNU}/gsed -i '/V_FLAG/d' header.txt	# remove line with V_FLAG
	fi
	
	# ensure  that header.txt contains the string SET = ACQTIM, AVGHEAD, AVGINCID, MODEi.txt
	# search all lines in header.txt that contains the string SET and 7 words. If any, remove 0,
	while IFS= read -r line 
	do 
		if [ `echo $line | ${PATHGNU}/grep "SET" | wc -w` -eq 7 ] 
			then 
				NEWLINE=`echo "${line}" | ${PATHGNU}/gsed "s/SET = 0,/SET = /"` 
				${PATHGNU}/gsed -i "s/$line/${NEWLINE}/" header.txt 
		fi 
	done < header.txt	
}

headerv3to4 ()
{
	# Transform header.txt for msbasv3 or lower in the form or msbasv4
	
	# ensure that header.txt contains the string "V_FLAG=0"; if not, add it after I_FLAG line
	if [ `${PATHGNU}/grep "V_FLAG" header.txt | wc -l` -eq 0 ] ; then 
		echo "header.txt seems formated for msbas v < 4; add V_FLAG = 0 after line with I_FLAG"
		${PATHGNU}/gsed -i '/.*I_FLAG.*/a V_FLAG = 0 '${PATH_VARIABLES_IF_ANY}'\/WATCHOUTFORSLASHES' header.txt
	fi
	# ensure  that header.txt contains the string SET = 0, ACQTIME, AVGHEAD, AVGINCID, MODEi.txt
	# search all lines in header.txt that contains the string SET and 6 words. If any, add a 0,
	while IFS= read -r line 
	do 
		if [ `echo $line | ${PATHGNU}/grep "SET" | wc -w` -eq 6 ] 
			then 
				NEWLINE=`echo "${line}" | ${PATHGNU}/gsed "s/SET =/SET = 0,/"` 
				${PATHGNU}/gsed -i "s/$line/${NEWLINE}/" header.txt 
		fi 
	done < header.txt
}

# run (m)sbas
case ${MSBAS} in 
	msbas)
		echo "run msbas V1"
		headerv4to3
		;;
	msbasv2)
		echo "run msbas V2"
		headerv4to3
		;;
	msbasv3)
		echo "run msbas V3"
		headerv4to3
		;;
	msbasv4)
		echo "run msbas V4"
		headerv3to4
		;;
	msbasv1*)
		echo "run msbas =< V10"
		headerv3to4
		;;
esac

${MSBAS} header.txt

echo "MSBAS processing stopped on :" >> ${LOG_FILE}
date >> ${LOG_FILE}
echo ""  >> ${LOG_FILE}

Add_hdr_Files_Less_Ras.sh ${PARAMNAME}		# sort files in dir 
# 
# if [ -d zz_LOS${PARAMNAME} ] ; then 
# 	cp header.txt zz_LOS${PARAMNAME}/
# 	cd zz_LOS${PARAMNAME}
# 	WIDTH=`${PATHGNU}/grep Samples MSBAS_LINEAR_RATE_LOS.bin.hdr | cut -d = -f 2 | ${PATHGNU}/gsed "s/ //"`
# 	ls *.bin > listdir.tmp
# 	for FILE in `cat -s listdir.tmp`
# 		do
# 			cpxfiddle -w ${WIDTH} -q normal -o sunraster -c jet -M 1/1 -f r4 ${FILE} > ${FILE}.ras
# 	done
# 	rm listdir.tmp
# 	# make kmz of linear rate
# 	Envi2ColorKmz.sh MSBAS_LINEAR_RATE_LOS.bin
# 	cd ..
# 	if [ `ls -1 zz_LOS_TS${PARAMNAME}/*.ts 2>/dev/null | wc -l` -gt 1 ] ; then 
# 		cd zz_LOS_TS${PARAMNAME} 
# 		Plot_All_LOS_ts_inDir.sh
# 	fi
# fi
# 
# if [ -d zz_EW${PARAMNAME} ] ; then 
# 	cp header.txt zz_EW${PARAMNAME}/
# 	cd zz_EW${PARAMNAME}
# 	WIDTH=`${PATHGNU}/grep Samples MSBAS_LINEAR_RATE_EW.bin.hdr | cut -d = -f 2 | ${PATHGNU}/gsed "s/ //"`
# 	ls *.bin > listdir.tmp
# 	for FILE in `cat -s listdir.tmp`
# 		do
# 			cpxfiddle -w ${WIDTH} -q normal -o sunraster -c jet -M 1/1 -f r4 ${FILE} > ${FILE}.ras
# 	done
# 	rm listdir.tmp
# 	# make kmz of linear rate
# 	Envi2ColorKmz.sh MSBAS_LINEAR_RATE_EW.bin
# 	cd ..
# fi
# 
# if [ -d zz_UD${PARAMNAME} ] ; then 
# 	cd zz_UD${PARAMNAME}
# 	ls *.bin > listdir.tmp
# 	for FILE in `cat -s listdir.tmp`
# 		do
# 			cpxfiddle -w ${WIDTH} -q normal -o sunraster -c jet -M 1/1 -f r4 ${FILE} > ${FILE}.ras
# 	done
# 	rm listdir.tmp
# 	# make kmz of linear rate
# 	Envi2ColorKmz.sh MSBAS_LINEAR_RATE_UD.bin
# 	cd ..
# 	if [ `ls -1 zz_UD_EW_TS${PARAMNAME}/MSBAS_*.txt 2>/dev/null | wc -l` -gt 1 ] ; then 
# 		cd zz_UD_EW_TS${PARAMNAME} 
# 		Plot_All_EW_UP_ts_inDir.sh
# 	fi
# 
# fi
# 
 if [ "$#" -eq 1 ] ; then 
 	# delete unecessary TS dir
	if [ -d "zz_LOS_TS${PARAMNAME}" ] && [ "$(ls -A zz_LOS_TS${PARAMNAME})" ]; then
			echo "zz_LOS_TS${PARAMNAME} is not Empty. Keep it."
		else
			echo "zz_LOS_TS${PARAMNAME} does not exist or is Empty. Remove it if appropriate."
			rm -Rf zz_LOS_TS${PARAMNAME} 2>/dev/null
	fi

	if [ -d "zz_UD_EW_TS${PARAMNAME}" ] && [ "$(ls -A zz_UD_EW_TS${PARAMNAME})" ]; then
			 echo "zz_UD_EW_TS${PARAMNAME} is not Empty. Keep it."
		else
			echo "zz_UD_EW_TS${PARAMNAME} does not exist or is Empty. Remove it if appropriate."
			rm -Rf zz_UD_EW_TS${PARAMNAME} 2>/dev/null
	fi
 
 	if [ -d "zz_UD_EW_NS_TS${PARAMNAME}" ] && [ "$(ls -A zz_UD_EW_NS_TS${PARAMNAME})" ]; then
			echo "zz_UD_EW_NS_TS${PARAMNAME} is not Empty. Keep it."
		else
			echo "zz_UD_EW_NS_TS${PARAMNAME} does not exist or is Empty. Remove it if appropriate."
			rm -Rf zz_UD_EW_TS${PARAMNAME} 2>/dev/null
	fi

 	
 #	rm -Rf zz_LOS_TS${PARAMNAME} zz_UD_EW_TS${PARAMNAME}
 fi

echo "(m)sbas processed, files moved to resp. dir and date(Time).txt files created \n" 

echo "MSBAS files moved to resp. dir and date(Time).txt files created" >> ${LOG_FILE}
echo "End of MSBAS.sh on:" >> ${LOG_FILE}
date >> ${LOG_FILE}

