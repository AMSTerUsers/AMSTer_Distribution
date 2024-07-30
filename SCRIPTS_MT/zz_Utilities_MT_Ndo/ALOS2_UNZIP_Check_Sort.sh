#!/bin/bash
# This script aims at being launched in a dir where the ALOS2 data are downloaded.
# 	This must be e.g. 
#   	..../SAR_DATA/ALOS2/Reunion_download/ 
#
# 	It will decompress (if zip format), check the ROW, GEOM and LOOKDIR (which are  
#	resp. the Row nr (i.e. track nr), Geometry (Asc or Desc) and Looking Direction (Right of Left). 
#
#	Then it sorts the data in a TARGET directory, in sub dirs with the corresponding 
#	characteristics, e.g.  
#		..../SAR_DATA/ALOS2_Reunion-UNZIP/SPT_ROW_GEOM_LOOKDIR
#
#	Original (compressed) data of more than 6 months will be stored in 
#		..../SAR_DATA/ALOS2_Reunion-ZIP.FORMER/yyyy  where yyyy is the year.
#
# Parameters: - path to dir where the data are stored. It must be something like 
#					..../SAR_DATA/ALOS2_Reunion_download/
#			  - path to dir where the data will be stored, e.g. 
#				..../SAR_DATA/ALOS2_Reunion-UNZIP
#
#
# Hardcoded: - 
#
# Dependencies:	- gsed and  gawk
#				- bc
#				- obsolate : solution with zipnote 3.1b (option -w crashed with v3.0) was removed and replaced by unzip and rezip - slower but more secure 
#
#
# New in Distro V 1.1 20240311:	- more robust if zip files contain zip files...
# New in Distro V 1.2 20240313:	- check that img does not exit yet also as link in case of frame + or - 1  
# New in Distro V 1.3 20240403:	- remove path in zip if images are zipped with path 
#
# AMSTer: SAR & InSAR Automated Mass processing Software for Multidimensional Time series
# NdO (c) 2024/01/09 - could make better with more functions... when time.
# -----------------------------------------------------------------------------------------
PRG=`basename "$0"`
VER="Distro V1.2 AMSTer script utilities"
AUT="Nicolas d'Oreye, (c)2016-2019, Last modified on Mar 13, 2024"

echo " "
echo "${PRG} ${VER}, ${AUT}"
echo " "

RAWDATAPATH=$1										# e.g. ..../SAR_DATA/ALOS2/Reunion-FTP/	where zip and non zip may be downloaded
DATATARGETPATH=$2									# e.g. ..../SAR_DATA/ALOS2_Reunion-UNZIP		where unzip img will be stored in /SPT_ROW_GEOM_LOOKDIR/YYYYMMDD

# prepare dir where data > 6 months will be archived  
ARCHIVEPATH=$(echo ${DATATARGETPATH} | ${PATHGNU}/gsed 's/UNZIP/ZIP.FORMER/')	# i.e. ..../SAR_DATA/ALOS2_Reunion-ZIP.FORMER	where zip archives will be stored in /YYYY
mkdir -p ${DATATARGETPATH}
mkdir -p ${ARCHIVEPATH}

BASEDIR=$(dirname ${RAWDATAPATH})					# e.g. ..../SAR_DATA/ALOS2/

# Info about date to check for >6 months archives
#################################################
YRNOW=`date "+ %Y"`
MMNOW=`date "+ %-m"`
DATENOW=`echo "${YRNOW} + ( ${MMNOW} / 12 )" | bc -l`
DATEHALFYRBFR=`echo "${DATENOW} - 0.5" | bc -l`

RNDM=`echo $(( $RANDOM %1000 ))`

# functions 
###########
function GetInfoFromUNZIP()
	{
	unset UNZIPIMG
	local UNZIPIMG=$1

	ROW=$(cat ${UNZIPIMG}/summary.txt | ${PATHGNU}/grep "SceneID" | ${PATHGNU}/gawk -F'-' '{print substr($1, length($1)-3, 4)}')		# ROW; get the 4 last digits before the -
	GEOM=$(cat ${UNZIPIMG}/summary.txt | ${PATHGNU}/grep "ProductID" | ${PATHGNU}/ggrep -oP 'SBS\K.')		# GEOM; get the letter after SBS
	LOOKDIR=$(cat ${UNZIPIMG}/summary.txt | ${PATHGNU}/grep "ProductID" | ${PATHGNU}/ggrep -oP '__\K.')	# LOOKDIR; get the letter after __

	ACQYYYY=$(cat ${UNZIPIMG}/summary.txt | ${PATHGNU}/grep "SceneCenterDateTime" | ${PATHGNU}/ggrep -oP 'Img_SceneCenterDateTime="\K\d{4}') 	# Acquisition year; get the 4 digits after Img_SceneCenterDateTime="
	ACQMM=$(cat ${UNZIPIMG}/summary.txt | ${PATHGNU}/grep "SceneCenterDateTime" | cut -d '"' -f 2 | cut -c 5-6)		# Month; get the digits 5-6 after Img_SceneCenterDateTime=" 	
	ACQDD=$(cat ${UNZIPIMG}/summary.txt | ${PATHGNU}/grep "SceneCenterDateTime" | cut -d '"' -f 2 | cut -c 7-8)	# Day; get the digits 7-8 after Img_SceneCenterDateTime="  	

	if [ "${ROW}" == "" ] || [ "${GEOM}" == "" ]  || [ "${LOOKDIR}" == "" ] || [ "${ACQYYYY}" == "" ] || [ "${ACQMM}" == "" ] || [ "${ACQDD}" == "" ]
		then 
			echo "// There is a problem reading info from summary.txt in decompressed image ${UNZIPIMG}"
			echo "// Can't continiue, please check. Exiting...'"
			exit 0	
	fi

	# maybe not needed
	#ACQhh=$(cat ${UNZIPIMG}/summary.txt | ${PATHGNU}/grep "SceneCenterDateTime" | cut -d ':' -f 1  | cut -d ' ' -f 2)	# hour; get the 2 digits before the first :
	#ACQmm=$(cat ${UNZIPIMG}/summary.txt | ${PATHGNU}/grep "SceneCenterDateTime" | cut -d ':' -f 2 )	# min; get the 2 digits before 2nd :
	}

function GetInfoFromZip()
	{
	unset ZIPFILE
	local ZIPFILE=$1

	NROFFILESINZIP=$(unzip -qq -l ${ZIPFILE}  | wc -l)	# counts the nr of files in zip file
	echo "// Nr of zipped files: ${NROFFILESINZIP}"
	
    if [[ ${NROFFILESINZIP} -eq 1 ]] 
		then 
			# contains only 1 file, i.e. most probably a double zip 
			unzip ${ZIPFILE} 
			ZIPFILINZIP=$(unzip -qq -l ${ZIPFILE}  | ${PATHGNU}/gawk '{print $NF}') 					# only gets the name.zip of zip file in zip file 
			#ZIPFILINZIP=$(unzip -qq -l ${ZIPFILE}  | ${PATHGNU}/gawk '{split($NF,a,"."); print a[1]}'	# only gets the name without .zip extension of zip file in zip file 
			ZIPFILEPATH=$(dirname ZIPFILE)
			mkdir -p ${ZIPFILEPATH}/_DoubleZip
			mv -f ${ZIPFILE} ${ZIPFILEPATH}/_DoubleZip 	 		
			ZIPFILE="${ZIPFILEPATH}/${ZIPFILINZIP}"	# in fct
			ZIPIMG="${ZIPFILEPATH}/${ZIPFILINZIP}"	# in prgm
		elif [[ ${NROFFILESINZIP} -eq 7 ]] && [[ $(unzip -qq -l "${ZIPFILE}" | head -1) == *"/"* ]] ; then 
			# zipped with subpath, i.e. contains a subpath/
			#SUBPATH=$(unzip -qq -l "${ZIPFILE}" | head -1 | ${PATHGNU}/gawk '{gsub(/[[:blank:]]+/," "); print $4}')			#  gets the name of dir in zip file
			SUBPATH=$(unzip -qq -l "${ZIPFILE}" | head -1 | ${PATHGNU}/gawk '{gsub(/[[:blank:]]+/," "); if($0~/\//) sub(/\/$/,"",$4); print $4}')			# gets the name of dir in zip file without trailing /
			# hence need to remove that subpath from the attributes

			# Do not use zipnote as option -w crashes with v3.0
			## Extract the existing comment from the ZIP archive
			#zipnote "${ZIPFILE}" > zipcomment.txt
			## Remove the subpath from the comment using sed
			#${PATHGNU}/gsed "s|${SUBPATH}\/||g" zipcomment.txt > modified_zipcomment.txt
			## Update the comment of the ZIP archive with the modified comment
			#zipnote -w "${ZIPFILE}" < modified_zipcomment.txt
			## Rename the files within the ZIP archive to remove the subpath
			#zip -q "${ZIPFILE}" '*/*' -x '*'
			##rm zipcomment.txt modified_zipcomment.txt

			# Create a new ZIP file with files from the original archive without preserving paths
			mkdir -p "tmp_${RNDM}"
			unzip "${ZIPFILE}" -d "tmp_${RNDM}"
			cd tmp_${RNDM}/${SUBPATH}
			zip "${ZIPFILE}" *
			mv "${ZIPFILE}" ${RAWDATAPATH}	
			cd ${RAWDATAPATH}
			rm -Rf "tmp_${RNDM}"
	fi

	ROW=$(unzip -p ${ZIPFILE} summary.txt | ${PATHGNU}/grep "SceneID" | ${PATHGNU}/gawk -F'-' '{print substr($1, length($1)-3, 4)}')		# ROW; get the 4 last digits before the -
	GEOM=$(unzip -p ${ZIPFILE} summary.txt | ${PATHGNU}/grep "ProductID" | ${PATHGNU}/ggrep -oP 'SBS\K.')		# GEOM; get the letter after SBS
	LOOKDIR=$(unzip -p ${ZIPFILE} summary.txt | ${PATHGNU}/grep "ProductID" | ${PATHGNU}/ggrep -oP '__\K.')	# LOOKDIR; get the letter after __
	
	ACQYYYY=$(unzip -p ${ZIPFILE} summary.txt | ${PATHGNU}/grep "SceneCenterDateTime" | ${PATHGNU}/ggrep -oP 'Img_SceneCenterDateTime="\K\d{4}') 	# Acquisition year; get the 4 digits after Img_SceneCenterDateTime="
	ACQMM=$(unzip -p ${ZIPFILE} summary.txt | ${PATHGNU}/grep "SceneCenterDateTime" | cut -d '"' -f 2 | cut -c 5-6)		# Month; get the digits 5-6 after Img_SceneCenterDateTime=" 	
	ACQDD=$(unzip -p ${ZIPFILE} summary.txt | ${PATHGNU}/grep "SceneCenterDateTime" | cut -d '"' -f 2 | cut -c 7-8)	# Day; get the digits 7-8 after Img_SceneCenterDateTime="  	



	if [ "${ROW}" == "" ] || [ "${GEOM}" == "" ]  || [ "${LOOKDIR}" == "" ] || [ "${ACQYYYY}" == "" ] || [ "${ACQMM}" == "" ] || [ "${ACQDD}" == "" ]
		then 
			echo "// There is a problem reading info from summary.txt in zip image ${ZIPFILE}"
			echo "// Try to unzip manually the image"
			echo "// Can't continiue, please check. Exiting...'"
	
			exit 0	
	fi
	}


function TestIfSameAsUnzipExist()
	{
	unset ZIPFILE
	local ZIPFILE=$1

	# check if same image exists as decompressed dir and is not empty 
	ZIPWITHOUTEXTENTION="${ZIPFILE%.*}"
	if [ -d "${ZIPWITHOUTEXTENTION}" ] && [ "$(ls -A "${ZIPWITHOUTEXTENTION}")" ]
		then
			# decompressed image exists also
			UNZIPIMGALSO="YES"
		else
			# decompressed image do not exist
			UNZIPIMGALSO="NO"
	fi
	}


function TestIfImgInUnzipDirYYYYMMDD()
	{
	ROWPLUSONE=$(echo "${ROW} + 1 " | bc)
	ROWMINUSONE=$(echo "${ROW} - 1 " | bc)

	if  [ -d "${DATATARGETPATH}/SPT_${ROW}_${GEOM}_${LOOKDIR}/${ACQYYYY}${ACQMM}${ACQDD}" ] && [ "$(ls -A "${DATATARGETPATH}/SPT_${ROW}_${GEOM}_${LOOKDIR}/${ACQYYYY}${ACQMM}${ACQDD}")" ] ; then 
			# data are in uzipped dir ROW
			DATAINUNZIPDIR="YES"
		elif [[ -L "${DATATARGETPATH}/SPT_${ROW}_${GEOM}_${LOOKDIR}/${ACQYYYY}${ACQMM}${ACQDD}" ]] ; then 
			# data are in unzip as link in ROW
			DATAINUNZIPDIR="YES"
		elif [ -d "${DATATARGETPATH}/SPT_${ROWPLUSONE}_${GEOM}_${LOOKDIR}/${ACQYYYY}${ACQMM}${ACQDD}" ] && [ "$(ls -A "${DATATARGETPATH}/SPT_${ROWPLUSONE}_${GEOM}_${LOOKDIR}/${ACQYYYY}${ACQMM}${ACQDD}")" ] ; then  
			# data are in uzipped dir ROW +1
			DATAINUNZIPDIR="YES"
		elif [ -d "${DATATARGETPATH}/SPT_${ROWMINUSONE}_${GEOM}_${LOOKDIR}/${ACQYYYY}${ACQMM}${ACQDD}" ] && [ "$(ls -A "${DATATARGETPATH}/SPT_${ROWMINUSONE}_${GEOM}_${LOOKDIR}/${ACQYYYY}${ACQMM}${ACQDD}")" ] ; then 
			# data are in uzipped dir ROW -1
			DATAINUNZIPDIR="YES"
		elif [[ -L "${DATATARGETPATH}/SPT_${ROWPLUSONE}_${GEOM}_${LOOKDIR}/${ACQYYYY}${ACQMM}${ACQDD}" ]] ; then 
			# data are in unzip as link in ROW +1 
			DATAINUNZIPDIR="YES"
		elif [[ -L "${DATATARGETPATH}/SPT_${ROWMINUSONE}_${GEOM}_${LOOKDIR}/${ACQYYYY}${ACQMM}${ACQDD}" ]] ; then 
			# data are in unzip as link in ROW -1 
			DATAINUNZIPDIR="YES"
		else 
			# data are nowhere in unzip dir...
			DATAINUNZIPDIR="NO"
	fi
	}

function TestIfImgInZipFormer()
	{
	unset ZIPFILE
	local ZIPFILE=$1

	if  [ -f "${ARCHIVEPATH}/${ACQYYYY}/${ZIPFILE}" ] && [ -s "${ARCHIVEPATH}/${ACQYYYY}/${ZIPFILE}" ]
		then 
			# Zip data are archived in > 6 months dir
			DATAINMORE6MONTHS="YES"
		else 
			# Zip data are not archived in > 6 months dir
			DATAINMORE6MONTHS="NO"
	fi
	}

function TestMore6Months()
	{
	DATEFILE=`echo "${ACQYYYY} + ( ${ACQMM} / 12 ) - 0.0001" | bc -l` # 0.0001 to avoid next year in december

	TST=`echo "${DATEFILE} < ${DATEHALFYRBFR}" | bc -l`
	if [ ${TST} -eq 1 ]
		then
			# data are older than 6 months
			MORE6MM="YES"
		else 
			# data are younger than 6 months
			MORE6MM="NO"
	fi
	}


cd ${RAWDATAPATH}	
							
# Start reading the ZIP data
# (unzip will be read after)
############################
echo "////////////////////////////"
echo "// Read compressed image...."
echo "////////////////////////////" 
for ZIPIMG in `${PATHGNU}/gfind . -maxdepth 1 -type f -name "*.zip" -printf '%f\n'`	# get the name without leading ./ 
do 
	# check if decompressed image exists as a dir in pwd and is not empty 
	# and read info from summary.txt
	TestIfSameAsUnzipExist "${ZIPIMG}"
	if [ "${UNZIPIMGALSO}" == "YES" ]
		then 
			echo "// Read image info from ${ZIPWITHOUTEXTENTION}/summary.txt."
			# get ROW, GEOM, LOOKDIR, YYYY, MM and DD from img
			GetInfoFromUNZIP "${ZIPWITHOUTEXTENTION}" 
		else 
			echo "// Read image info from summary.txt in ${ZIPIMG}."
			# get ROW, GEOM, LOOKDIR, YYYY, MM and DD from zip img
			GetInfoFromZip "${ZIPIMG}"
	fi

	# Check that image is not yet read (decompressed) in ${TARGETDIR}/${ACQYYYY}${ACQMM}${ACQDD}
	TARGETDIR=${DATATARGETPATH}/SPT_${ROW}_${GEOM}_${LOOKDIR}/${ACQYYYY}${ACQMM}${ACQDD}
	TestIfImgInUnzipDirYYYYMMDD "${TARGETDIR}"
	
		
	if [ "${DATAINUNZIPDIR}" == "YES" ]
		then 
			echo "// Data are already read in ${TARGETDIR}. No need to decompress the data. "
		else 
			echo "// Data are not yet in ${TARGETDIR}. "
			mkdir -p "${TARGETDIR}"
			# if not decompressed yet, do it and move to TARGETDIR
			# if decompressed, move it to TARGETDIR
			if [ "${UNZIPIMGALSO}" == "NO" ]
				then 
					unzip "${ZIPIMG}" -d "${ZIPWITHOUTEXTENTION}"
			fi
			mv ${ZIPWITHOUTEXTENTION}/* ${TARGETDIR}
			echo "Original directory name: ${ZIPWITHOUTEXTENTION}" > ${TARGETDIR}/${ZIPWITHOUTEXTENTION}.txt
			rm -rf ${ZIPWITHOUTEXTENTION}
			
	fi
	
	# test if >6 months 
	TestMore6Months
	
	if [ "${MORE6MM}" == "YES" ]
		then
			# Test if already zip file in zip archive dir
			TestIfImgInZipFormer "${ZIPIMG}"
			if [ "${DATAINMORE6MONTHS}" == "YES" ]
				then 
					echo "// Data are archived as zip file in ${ARCHIVEPATH}/${ACQYYYY}/"
					echo "//  => hence can safely remove ${ZIPIMG} from ${RAWDATAPATH}"
					rm -f ${ZIPIMG}
					# Remove also possible decompressed dir just in case 
					rm -rf ${ZIPWITHOUTEXTENTION} 2>/dev/null 
				else 
					echo "// Move zip file in ${ARCHIVEPATH}/${ACQYYYY}/"
					mkdir -p ${ARCHIVEPATH}/${ACQYYYY}/
					mv -f ${ZIPIMG} ${ARCHIVEPATH}/${ACQYYYY}/
					# Remove also possible decompressed dir just in case 
					rm -rf ${ZIPWITHOUTEXTENTION} 2>/dev/null 
			fi
		else 
			echo "// Data are less than 6 months. Keep zip (and possible decompressed dir) in ${RAWDATAPATH}"
	fi
	echo 
done 


# Start reading the UNZIP data
# (if zip exist also, it was already tested)
##############################
echo
echo "//////////////////////////////"
echo "// Read decompressed image...."
echo "//////////////////////////////" 
for DIRIMG in `${PATHGNU}/gfind . -maxdepth 1 -type d -name "*ALOS2*" -printf '%f\n'`	# get the name without leading ./ 
do 
	# if ${DIRIMG}.zip exist, the image was already processed here above
	if [ -f "${DIRIMG}" ] 
		then 
			break
	fi

	echo "// Read image info from ${DIRIMG}/summary.txt."
	# get ROW, GEOM, LOOKDIR, YYYY, MM and DD from img
	GetInfoFromUNZIP "${DIRIMG}" 

	TARGETDIR=${DATATARGETPATH}/SPT_${ROW}_${GEOM}_${LOOKDIR}/${ACQYYYY}${ACQMM}${ACQDD}
	mkdir -p ${TARGETDIR}

	# test if >6 months (must be performed before moving data to TARGETDIR)
	TestMore6Months
	
	if [ "${MORE6MM}" == "YES" ]
		then
			# Test if already zip file in zip archive dir
			TestIfImgInZipFormer "${DIRIMG}.zip"
			if [ "${DATAINMORE6MONTHS}" == "YES" ]
				then 
					echo "// Data are archived as zip file in ${ARCHIVEPATH}/${ACQYYYY}/"
				else 
					echo "// Compress and move zip file in ${ARCHIVEPATH}/${ACQYYYY}/"
					zip -r "${DIRIMG}.zip" "${DIRIMG}"
					mkdir -p ${ARCHIVEPATH}/${ACQYYYY}/
					mv -f "${DIRIMG}.zip" ${ARCHIVEPATH}/${ACQYYYY}/
			fi
		else 
			echo "// Data are less than 6 months. Keep decompressed dir in ${RAWDATAPATH}"
	fi

	# Check that image is not yet read (decompressed) in ${TARGETDIR}/${ACQYYYY}${ACQMM}${ACQDD}
	TestIfImgInUnzipDirYYYYMMDD "${TARGETDIR}"
		
	if [ "${DATAINUNZIPDIR}" == "YES" ]
		then 
			echo "// Data are already read in ${TARGETDIR}. "
			if [ "${MORE6MM}" == "YES" ]
				then
					echo "//  and are more than 6 months old"
					echo "//  => hence can safely remove ${DIRIMG}"
					rm -rf ${DIRIMG}
				else
					echo "//  but are less than 6 months old"
					echo "//  => hence keep ${DIRIMG}"
			fi
		else 
			echo "// Data are not yet in ${TARGETDIR}"
			if [ "${MORE6MM}" == "YES" ]
				then
					echo "//  and are more than 6 months old"
					echo "//  => hence can move them"
					mv ${DIRIMG}/* ${TARGETDIR}
					echo "Original directory name: ${DIRIMG}" > ${TARGETDIR}/${DIRIMG}.txt
					rm -rf ${DIRIMG}
				else
					echo "//  but are less than 6 months old"
					echo "//  => hence copy them in ${TARGETDIR}"
					echo "//     and keep decompressed data"
					cp ${DIRIMG}/* ${TARGETDIR}
					echo "Original directory name: ${DIRIMG}" > ${TARGETDIR}/${DIRIMG}.txt
			fi
	fi
	
	echo
done

echo "////////////////////////////" 
echo "// All ALOS2 image sorted //"
echo "////////////////////////////" 
