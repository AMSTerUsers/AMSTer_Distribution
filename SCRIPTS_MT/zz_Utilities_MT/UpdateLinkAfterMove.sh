#!/bin/bash
# Script to update link of S1 resampled files in INPUTDATA/ after moving them from 
#     where they were computed to where the mass processing wants them to be stored. 
#
# Need to be run in dir where all /PRM_SCD/i12/InSARProducts were moved (i.e. OUTPUTDATA), 
#   e.g. /.../SAR_SM/RESAMPLED/SAT/TRK/CROPDIR/
#
# Parameters : - None
#
# Dependencies:	- None.  
#
# New in Distro V 1.0 (Jul 15, 2019):	- Based on developpement version and Beta V1.0.1
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
echo " " 

OUTPUTDATA="$(pwd)"

for DIR in `ls -d ????????_?1?_*` 
do 
	cd ${DIR}/i12/InSARProducts
	LINKTOCHANGE=`ls *.interpolated`
	SUPERMASTER=`echo ${DIR} | cut -d _ -f 1`
	SLVNAME=`echo ${DIR} | cut -d _ -f 2-5`
	POLSLV=`echo ${LINKTOCHANGE} | cut -d . -f 2`
	rm ${LINKTOCHANGE}
	ln -s ${OUTPUTDATA}/${SUPERMASTER}_${SLVNAME}/i12/InSARProducts/${SLVNAME}.interpolated.csl/Data/SLCData.${POLSLV} ${OUTPUTDATA}/${SUPERMASTER}_${SLVNAME}/i12/InSARProducts/${SLVNAME}.${POLSLV}.interpolated
	cd ${OUTPUTDATA}
done 



