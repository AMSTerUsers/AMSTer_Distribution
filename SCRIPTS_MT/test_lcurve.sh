#!/bin/bash
# -----------------------------------------------------------------------------------------
# This script is aiming at running multiple msbas processes to evaluate what are the 
#     most appropriate regularisation parameters for each order of regularisation (1-3).
#	  It will produce a plot for each regularisation order. 
#	  The most appropriate lambda is usually where there is a kink in the curve. 
#
# It must be launched:	- after build_header_msbas_criteria.sh which creates a header.txt
#  						- in the dir where msbas is run. 
#   
# Parameters are : none
#
# Dependencies:	- a file with the steps wished to evaluate the l-curve named Steps_LCurve.txt
#				- scripts: 
#					+ MSBAS.sh
#					+ plot_lcurve.sh
#				- python
#				- python script Norm.py
# 
# Hard coded:	- 
# 
# New in Distro V 1.0:	- Based on developpement version 1.0 and Beta V1.2
# New in Distro V 1.1:	- path to Steps_LCurve.txt not hard coded anymore
# New in Distro V 2.0:	- add param to header.txt to cope with only the new version of msbas (after Oct 2020; i.e. v4)
# New in Distro V 3.0 20230830:	- Rename SCRIPTS_OK directory as SCRIPTS_MT 
#								- Replace CIS by MT in names 
#								- Renamed FUNCTIONS_FOR_MT.sh
#
# MasTer: InSAR Suite automated Mass processing Toolbox. 
# NdO (c) 2016/03/08 - could make better... when time.
# -----------------------------------------------------------------------------------------
PRG=`basename "$0"`
VER="Distro V3.0 MasTer script utilities"
AUT="Nicolas d'Oreye, (c)2016-2019, Last modified on Aug 30, 2023"
echo " "
echo "${PRG} ${VER}, ${AUT}"
echo "Processing launched on $(date) " 
echo " " 

  
# Check OS
OS=`uname -a | cut -d " " -f 1 `
echo "Running on ${OS}"
echo

CHECKMSBASV1=`which msbas | wc -l`
CHECKMSBASV2=`which msbasv2 | wc -l`
CHECKMSBASV3=`which msbasv3 | wc -l`
CHECKMSBASV4=`which msbasv4 | wc -l`

if [ ${CHECKMSBASV1} -gt 0 ] ; then MSBAS="msbas" ; fi  	
if [ ${CHECKMSBASV2} -gt 0 ] ; then MSBAS="msbasv2" ; fi  	
if [ ${CHECKMSBASV3} -gt 0 ] ; then MSBAS="msbasv3" ; fi  		
if [ ${CHECKMSBASV4} -gt 0 ] ; then MSBAS="msbasv4" ; fi  	

# Path to Lambda values to test for l-curve: file must be in SCRIPTS_MT
LCUR=${PATH_SCRIPTS}/SCRIPTS_MT/Steps_LCurve.txt

# Get the parameters that do not need to change 
FORMAT=`grep "FORMAT" header.txt`
FSIZE=`grep "FILE_SIZE" header.txt`
WSIZE=`grep "WINDOW_SIZE" header.txt`
TFAG=`grep "T_FLAG" header.txt`
CFLAG=`grep "C_FLAG" header.txt`
IFLAG=`grep "I_FLAG" header.txt`
if [ "${MSBAS}" == "msbasv4" ] ; then VFLAG=`grep "V_FLAG" header.txt` ; fi	

#CR=$(printf '\r')  # carriage return is missing in header.txt ?
SETS=`grep "SET" header.txt `
	


for ORDER in `seq 1 3`; do 
	echo "Test order ${ORDER}"
	rm -f lcurve_${ORDER}.txt
	for i in  `cat ${LCUR}`; do
		echo "Test order ${ORDER} with lambda $i:"
		echo "${FORMAT}" > header.txt
		echo "${FSIZE}" >> header.txt  
		echo "${WSIZE}" >> header.txt
		echo "R_FLAG =  ${ORDER}, $i" >> header.txt
		echo "${TFAG}" >> header.txt
		if [ "${MSBAS}" == "msbasv4" ] ; then echo "${VLFAG}" >> header.txt ; fi		
		echo "${CFLAG}" >> header.txt
		echo "${IFLAG}"  >> header.txt
		echo "${SETS}" >> header.txt
		
		MSBAS.sh _Reg_${ORDER}_${i} #pixlist.txt

		if [ -d zz_EW_Reg_${ORDER}_${i} ] ; then 
			cd zz_EW_Reg_${ORDER}_${i}
			Norm.py > ../NORM_LOG.txt 
			cd ..
		fi
		if [ -d zz_LOS_Reg_${ORDER}_${i} ] ; then 
			cd zz_LOS_Reg_${ORDER}_${i}
			Norm.py > ../NORM_LOG.txt 
			cd ..
		fi
	
		NORMSLOG=`cat NORM_LOG.txt  | ${PATHGNU}/grep "||x||" | awk '{print log($2), log($4)}'`
		echo "${i} ${NORMSLOG}" >> lcurve_${ORDER}.txt
	done
done

for ORDER in `seq 1 3`; do 
	plot_lcurve.sh ${ORDER}
done 
