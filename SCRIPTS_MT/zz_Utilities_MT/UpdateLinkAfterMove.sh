#!/bin/bash
# Script to update link of S1 resampled files in INPUTDATA/ after moving them from 
#     where they were computed to where the mass processing wants them to be stored. 
#
# Need to be run in dir where all /MAS_SLV/i12/InSARProducts were moved (i.e. OUTPUTDATA), 
#   e.g. /.../SAR_SM/RESAMPLED/SAT/TRK/CROPDIR/
#
# Parameters : - None
#
# Dependencies:	- None.  
#
# New in Distro V 1.0:	- Based on developpement version and Beta V1.0.1
#
# MasTer: InSAR Suite automated Mass processing Toolbox. 
# NdO (c) 2016/03/08 - could make better... when time.
# -----------------------------------------------------------------------------------------
PRG=`basename "$0"`
VER="Distro V1.0 MasTer script utilities"
AUT="Nicolas d'Oreye, (c)2016-2019, Last modified on Jul 15, 2019"
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



