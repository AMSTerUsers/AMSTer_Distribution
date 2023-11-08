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
# V1.0 (Aug 12; 2021)
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

