#!/bin/bash
######################################################################################
# This script convert binary def map from MSBAS processing to jpg then combine all jpg   
# into a gif movie
# using : convert -delay 10 *jpg movie.gif
#
# Parameters :	- path to directory where MSBAS_????????T??????_*.bin and .hdr are
#		
# Hard Coded : color scaling
# Dependencies:	- convert 
# 
# New in Distro V 1.0:	- Based on developpement version 1.1 and Beta V1.0.2
# 
# MasTer: InSAR Suite automated Mass processing Toolbox. 
# D.Smittarello, v 1.0 2020/10/06 -  
######################################################################################
PRG=`basename "$0"`
VER="Distro V1.0 MasTer script utilities"
AUT="Delphine Smittarello, (c)2016-2019, Last modified on Oct 08, 2020"
echo " "
echo "${PRG} ${VER}, ${AUT}"
echo " "


WORKDIR=$1
MINCOLSC=$2
MAXCOLSC=$3

CROPXMIN=$4
CROPXMAX=$5
CROPYMIN=$6
CROPYMAX=$7

PATHTOFILE=`pwd`

# vvv ----- Hard coded lines to check --- vvv 
# See Fiji command and options at the end
# ^^^ ----- Hard coded lines to check -- ^^^ 


#FILEBIN=$4
cd ${WORKDIR}

compteur="first"
for FILEBIN in MSBAS_????????T??????_*.bin ; do 
	if [ ${compteur} = "first" ] 
	then
		compteur="other"
		DATE1=`echo ${FILEBIN} | cut -c 7-14`
		MODE=`echo ${WORKDIR} | cut -c 4-`
		echo ${MODE}
	fi
	DATE2=`echo ${FILEBIN} | cut -c 7-14`
	FILETOCONVERT=${PATHTOFILE}/${WORKDIR}/${FILEBIN}
	WIDTH=`cat ${FILEBIN}.hdr | ${PATHGNU}/grep -i samples | ${PATHGNU}/gsed 's@^[^0-9]*\([0-9]\+\).*@\1@'`
	HEIGHT=`cat ${FILEBIN}.hdr | ${PATHGNU}/grep -i lines | ${PATHGNU}/gsed 's@^[^0-9]*\([0-9]\+\).*@\1@'`

	FILE=$(basename ${FILETOCONVERT})
	echo "run('Raw...', 'open=${FILETOCONVERT} image=[32-bit Real] width=${WIDTH} height=${HEIGHT} little-endian');" > ${FILE}FijiMacroFig.txt
	echo "run('Green');">> ${FILE}FijiMacroFig.txt
	echo "setMinAndMax(${MINCOLSC}, ${MAXCOLSC});">> ${FILE}FijiMacroFig.txt
	if [ $# -gt 3 ] # if a rectangle is provided, use it for crop
		then 
			echo "makeRectangle(${CROPXMIN}, ${CROPXMAX}, ${CROPYMIN}, ${CROPYMAX});" >> ${FILE}FijiMacroFig.txt
			echo "run("Crop");" >> ${FILE}FijiMacroFig.txt
	fi
	echo "run('Calibration Bar...', 'location=[Upper Right] fill=White label=Black number=5 decimal=3 font=14 zoom=3 bold overlay');" >> ${FILE}FijiMacroFig.txt
	echo "saveAs('Jpeg', '${FILE}temp.jpg');" >> ${FILE}FijiMacroFig.txt
	echo "run('Quit');"  >> ${FILE}FijiMacroFig.txt
	${PATHGNU}/gsed -i "s/'/\"/g" ${FILE}FijiMacroFig.txt 

	# Check OS
	OS=`uname -a | cut -d " " -f 1 `
	case ${OS} in 
		"Linux") 
#			${PATHFIJI}/ImageJ-linux64  --headless -batch ${FILE}FijiMacroFig.txt ;; ## bug headless and Calibration bar
			${PATHFIJI}/ImageJ-linux64 -batch ${FILE}FijiMacroFig.txt ;;
		"Darwin")
			#${PATHFIJI}/ImageJ-macosx  --headless -batch ${FILE}FijiMacroFig.txt 	;;
			${PATHFIJI}/ImageJ-macosx -batch ${FILE}FijiMacroFig.txt 	;;
	esac			
	# Keep script if one wants to change paramerters of the plot
		#rm ${FILE}FijiMacroFig.txt 
# resize
#	${PATHCONV}/convert -format jpg -quality 100% -sharpen 0.1 -contrast-stretch 0.15x0.5% -resize '2640>' ${RUNDIR}/i12/InSARProducts/${SLAVEPOLNAME}.mod.${FLP}.ras ${RUNDIR}/i12/InSARProducts/${SLAVEPOLNAME}.mod.${FLP}_temp.jpg 2> /dev/null
# add and Mode and dates

	if [ $# -gt 3 ] # if a rectangle is provided, use it for crop
		then 
			CROP=_${CROPXMIN}_${CROPXMAX}_${CROPYMIN}_${CROPYMAX}
		else 
			CROP=""
	fi
	OUTPUTFILENAME=${FILE}defo${CROP}.jpg
	
	# do not add quotes to echo here 
	echo $PATHCONV/convert -gravity SouthWest -undercolor white -font Helvetica -pointsize 52 -fill black -draw \'text 100 100 \"${MODE} ${DATE1}-${DATE2}\"\' ${FILE}temp.jpg ${OUTPUTFILENAME} > addannot.sh
	chmod u+x addannot.sh
	./addannot.sh

	rm ${FILE}temp.jpg 
	echo "${FILETOCONVERT}.jpg created" 

done

rm addannot.sh
rm *FijiMacroFig.txt 	

${PATHCONV}/convert -delay 10 *defo${CROP}.jpg _movie_${WORKDIR}${CROP}.gif

echo "_movie_${WORKDIR}.gif created"

cd ..



