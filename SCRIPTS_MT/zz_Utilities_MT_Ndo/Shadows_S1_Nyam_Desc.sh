#!/bin/bash
# This scripts aims at makin jpg and gif images for Nyamulagira crater with S1 daat in Descending mode. 
# Since Nyam volcano is on the same image as Nyigo for that sat/mode, no need to recompute all the processing. 
# We only take jpg images from S1 Ascending mode and make a new date tag and crop
# 
# The script must be launched in 
#
# New in V1.0.1 Beta:	- take state variable for PATHGNU etc
# New in V1.0.2 Beta:	- path naming for linux and mac
#        V1.0.3 Bbeta: 	- check OK muste be after sourcing bashrc 
#        V1.0.4 Bbeta (Jan 17, 2019): 	- use state variable for external disk path and remove OS check
# New in Distro V 2.0 20231030:	- Rename MasTer Toolbox as AMSTer Software
#								- rename Master and Slave as Primary and Secondary (though not possible in some variables and files)
# New in Distro V 2.1 20250227:	- replace cp -n with if [ ! -e DEST ] ; then cp SRC DEST ; fi 
#
# AMSTer: SAR & InSAR Automated Mass processing Software for Multidimensional Time series
# NdO (c) 2016/03/07 - could make better with more functions... when time.
# -----------------------------------------------------------------------------------------
PRG=`basename "$0"`
VER="Distro V2.1 AMSTer script utilities"
AUT="Nicolas d'Oreye, (c)2016-2019, Last modified on Feb 27, 2025"
echo " "
echo "${PRG} ${VER}, ${AUT}"
echo " "

# vvv ----- Hard coded lines to check --- vvv 
echo
source ${HOME}/.bashrc 

SOURCEDIR=$PATH_1650/SAR_SM/AMPLITUDES/S1/DRC_NyigoCrater_D_21/Nyigo_Nyam_crater_originalForm/_AMPLI/
TARGETDIR=$PATH_1650/SAR_SM/AMPLITUDES/S1/DRC_NyamCrater_D_21/_AMPLI/

SAT=S1
TRK=DRC_NyamCrater_D_21
REGION=Nyigo_Nyam_crater_originalForm
# see also size and position of crop below

# ^^^ ----- Hard coded lines to check -- ^^^ 


#echo "Copy jpg files..." 
#cp -f /Volumes/hp-1650-Data_Share1/SAR_SM/AMPLITUDES/S1/DRC_NyigoCrater_D_21/Nyigo_Nyam_crater_originalForm/_AMPLI/*.jpg /Volumes/hp-1650-Data_Share1/SAR_SM/AMPLITUDES/S1/DRC_NyamCrater_D_21/_AMPLI/

cd ${SOURCEDIR}

echo "Link envi files from SOURCEDIR to TARGETDIR..." 
for ENVI in `ls *flop* | ${PATHGNU}/grep -v "jpg"`
do 
	ln -f -s ${SOURCEDIR}/${ENVI} ${TARGETDIR}/${ENVI}
done

echo "Copy jpg files from SOURCEDIR to TARGETDIR..." 
for JPG in `ls *.jpg`
do 
	#cp -n ${SOURCEDIR}/${JPG} ${TARGETDIR}/${JPG}
	if [ ! -e "${TARGETDIR}/${JPG}" ] ; then cp "${SOURCEDIR}/${JPG}" "${TARGETDIR}/${JPG}" ; fi 
done

DATECELL=" -gravity SouthWest -undercolor white -font Helvetica -pointsize 12 -fill black -annotate"
LABELX=3040
LABELY=980

POSDATECELL=" +${LABELX}+${LABELY} "

cd ${TARGETDIR}

echo "Tag jpg files with date and copy in TARGETDIR..." 
for JPGDIR in `ls *.jpg`
do 
	DATE=`echo ${JPGDIR} | cut -d _ -f 2`
	#cp -f ${JPGDIR} ${JPGDIR}_tmp
	${PATHCONV}/convert ${DATECELL}${POSDATECELL} "${DATE}" ${JPGDIR} ${TARGETDIR}/${JPGDIR} 2> /dev/null
	#rm ${JPGDIR}_tmp
done

echo "Convert jpg to gif..." 
jpg2movie_gif.sh ${SAT} ${TRK} ${REGION}

echo "Crop gif..." 
${PATHCONV}/convert _movie_${SAT}_${TRK}_${REGION}.gif -coalesce -crop 290x290+3015+165 +repage _movie_${SAT}_${TRK}_${REGION}_Crop_NyamCrater.gif

rm -f _movie_${SAT}_${TRK}_${REGION}.gif

echo "All done..." 
