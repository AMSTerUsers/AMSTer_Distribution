#!/bin/bash
######################################################################################
# This script check each dir in current directory and set 
#		- a red color bullet if it does not contains a jpg in /i12/InSARProducts
#		- a green color bullet if it does contains a jpg in /i12/InSARProducts
# This is used to check that the computation of the AMPLITUDES files were OK after running a ALL2GIGF.sh
#
# Parameters:	- none
#
#  color code:	0  No color
#				1  Orange
#				2  Red
#				3  Yellow
#				4  Blue
#				5  Purple
#				6  Green
#				7  Gray
#
# I know, it is a bit messy and can be improved.. when time. But it works..
# MasTer: InSAR Suite automated Mass processing Toolbox. 
# NdO (c) 2021/08/12 - could make better... when time.
# -----------------------------------------------------------------------------------------
PRG=`basename "$0"`
VER="Distro V1.0 MasTer script utilities"
AUT="Nicolas d'Oreye, (c)2016-2021, Last modified on Aug 12; 2021"
echo " "
echo "${PRG} ${VER}, ${AUT}"
echo " "

# Check OS and exit of not Mac
OS=`uname -a | cut -d " " -f 1 `

case ${OS} in 
	"Linux") 
		espeak "Can't change color tag with Linux; this is a Mac feature only." 
		exit 0 ;;
	"Darwin")
		say "Let's change color tag..." 	;;
	*)
		echo "No sure about your OS. Can't change color tag with Linux; this is a Mac feature only." 	
		exit 0 ;;
esac			

for DIRTOCHECK in `ls -d */ 2> /dev/null`
	do
			if ls ${DIRTOCHECK}i12/InSARProducts/*.jpg &>/dev/null 
				then
					echo "Jpg file found in ${DIRTOCHECK}i12/InSARProducts."
					MacColorFile.sh 6 ./${DIRTOCHECK} > /dev/null
				else
					echo "No jpg file found in ${DIRTOCHECK}i12/InSARProducts => tag in red."
					MacColorFile.sh 2 ./${DIRTOCHECK} > /dev/null
			fi
done

MacColorFile.sh 0 ./_AMPLI > /dev/null	

echo +++++++++++++++++++++++++++++++++
echo "COLOR CHANGED - HOPE IT WORKED"
echo +++++++++++++++++++++++++++++++++

