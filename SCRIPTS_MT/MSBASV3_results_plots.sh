#!/bin/bash
######################################################################################
# This script sort and plots results from msbas using 3D capabilities. 
#  It takes care of possible byte ordering prblms. 
#
# Parameters : - String PARAMNAME used to add to dir names where results will be stored. 
#                  This can help to remember eg some processing configs.
#  				   PARAMETER IS OPTIONAL BUT COMMENT IS USEFULL       
#
# Dependencies:	- a header.txt file (built with build_header_msbas_criteria.sh)
#				- gnu sed and awk for more compatibility. 
#               - gdal
#    			- cpxfiddle is usefull though not mandatory. This is part of Doris package (TU Delft) available here :
#        			    http://doris.tudelft.nl/Doris_download.html. 
#				- script : 
#					+ Add_hdr_Files.sh 
#					+ Plot_All_LOS_ts_inDir.sh if run sbas
#					+ Plot_All_EW_UP_ts_inDir.sh if run msbas
#
# New in Distro V 1.0:	- Based on developpement version and Beta V1.0
# New in Distro V 4.0 20231030:	- Rename MasTer Toolbox as AMSTer Software
#								- rename Master and Slave as Primary and Secondary (though not possible in some variables and files)
#
# AMSTer: SAR & InSAR Automated Mass processing Software for Multidimensional Time series
# NdO (c) 2016/03/07 - could make better with more functions... when time.
# -----------------------------------------------------------------------------------------
PRG=`basename "$0"`
VER="Distro V4.0 AMSTer script utilities"
AUT="Nicolas d'Oreye, (c)2016-2019, Last modified on Oct 30, 2023"
echo " "
echo "${PRG} ${VER}, ${AUT}"
echo "Processing launched on $(date) " 
echo " " 



PARAMNAME=$1		# Comment for dir naming

# Add header file and sort in dir 
ls *_EW.bin *_NS.bin *UD.bin > listdir.tmp
ls MSBAS_NORM_AXY.bin >> listdir.tmp
ls MSBAS_NORM_X.bin >> listdir.tmp	
ls MSBAS_ZSCORE.bin >> listdir.tmp	
mkdir -p zz_UD${PARAMNAME}
mkdir -p zz_EW${PARAMNAME} 
mkdir -p zz_NS${PARAMNAME}

# test in HDR if big or small endian
ENDIAN=`cat HDR.hdr | ${PATHGNU}/grep "byte order" | cut -d = -f 2`
echo "Endian is ${ENDIAN}"

if [ "${ENDIAN}" == "0" ]
	then  
		# if small endian, add hdr
		for filename in `cat -s listdir.tmp`
		   do
		   # create hdr
		   cp HDR.hdr ${filename}.hdr
		done
	else 
		# change HDR for further use
		${PATHGNU}/gsed "s/byte order = 1/byte order = 0/" HDR.hdr > HDR.small.hdr 
		# if big endian, change endian first
		for BIN in `cat -s listdir.tmp `
		do 
			mv -f ${BIN} ${BIN}.big
			cp HDR.hdr ${BIN}.big.hdr
			gdalwarp -of ENVI ${BIN}.big ${BIN}
			rm -f ${BIN}.big ${BIN}.big.hdr
		  	# create hdr
		  	cp -f HDR.small.hdr ${BIN}.hdr
		done 		
fi

mv *_EW.bin* zz_EW${PARAMNAME}/
mv *_NS.bin* zz_NS${PARAMNAME}/ 
mv *_UD.bin* zz_UD${PARAMNAME}/ 
echo "Move norms and log and dateTime file in EW${PARAMNAME}"	
mv MSBAS_NORM_X.bin* zz_EW${PARAMNAME}/ 
mv MSBAS_NORM_AXY.bin* zz_EW${PARAMNAME}/ 
mv MSBAS_ZSCORE.bin* zz_EW${PARAMNAME}/ 

mv MSBAS_*.txt zz_EW${PARAMNAME}/

rm -f *.hdr

cd zz_UD${PARAMNAME}
ls *.hdr | ${PATHGNU}/grep -v "RATE" > ../datesTime.txt
cd ..
sed -i 's/UD.bin.hdr//g' datesTime.txt
sed -i 's/MSBAS_//g' datesTime.txt
mv datesTime.txt zz_UD${PARAMNAME}/
#cp header.txt zz_UD${PARAMNAME}/
#if [ `ls -1 *.ts 2>/dev/null | wc -l` -gt 1 ] ; then mv *.ts zz_UD_EW_TS${PARAMNAME}/ ; fi


# Process EW
	cd zz_EW${PARAMNAME}
	WIDTH=`grep Samples MSBAS_LINEAR_RATE_EW.bin.hdr | cut -d = -f 2 | ${PATHGNU}/gsed "s/ //"`
	ls *.bin > listdir.tmp
	for FILE in `cat -s listdir.tmp`
		do
			cpxfiddle -w ${WIDTH} -q normal -o sunraster -c jet -M 1/1 -f r4 ${FILE} > ${FILE}.ras
	done
	rm listdir.tmp
	cd ..

# Process NS
	cd zz_NS${PARAMNAME}
	WIDTH=`grep Samples MSBAS_LINEAR_RATE_NS.bin.hdr | cut -d = -f 2 | ${PATHGNU}/gsed "s/ //"`
	ls *.bin > listdir.tmp
	for FILE in `cat -s listdir.tmp`
		do
			cpxfiddle -w ${WIDTH} -q normal -o sunraster -c jet -M 1/1 -f r4 ${FILE} > ${FILE}.ras
	done
	rm listdir.tmp
	cd ..

# Process UD
	cd zz_UD${PARAMNAME}
	ls *.bin > listdir.tmp
	for FILE in `cat -s listdir.tmp`
		do
			cpxfiddle -w ${WIDTH} -q normal -o sunraster -c jet -M 1/1 -f r4 ${FILE} > ${FILE}.ras
	done
	cd ..
	if [ `ls -1 zz_UD_EW_TS${PARAMNAME}/*.ts 2>/dev/null | wc -l` -gt 1 ] ; then 
		cd zz_UD_EW_TS${PARAMNAME} 
		Plot_All_EW_UP_ts_inDir.sh
	fi
	rm listdir.tmp



 echo "(m)sbas processed, files moved to resp. dir and date(Time).txt files created \n" 
