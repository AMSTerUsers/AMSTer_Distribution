#!/bin/bash
# Create file with dates inverted if master date is after slave date in list.
# Dates are supposed to be provided as Mas in col1 and Slv in col 2
# Col 3 and 4 are set to 0 for comp
#
# For an up to date and detailed list of dependencies (and sub-dependencies), 
#    run the following command (add option -v to also list the commands and calls):
#  		Search_Dependencies /Path/to/This/script 
# 	 (Results are displayed at the Terminal; redirect them to a file with > file.txt if wished)
#
# New in Distro V 2.0 20231030:	- Rename MasTer Toolbox as AMSTer Software
#								- rename Master and Slave as Primary and Secondary (though not possible in some variables and files)
# New in Distro V 2.1 20261013:	- Recommend using Search_Dependencies.sh for 
#								  an updated list of dependencies
#									  
#
# AMSTer: SAR & InSAR Automated Mass processing Software for Multidimensional Time series
# NdO (c) 2016/03/07 - could make better with more functions... when time.
# -----------------------------------------------------------------------------------------
PRG=`basename "$0"`
VER="Distro V2.1 AMSTer script utilities"
AUT="Nicolas d'Oreye, (c)2016-2019, Last modified on oct 13, 2026"
echo " "
echo "${PRG} ${VER}, ${AUT}"
echo "Processing launched on $(date) " 
echo " " 

FILETOCHECK=$1

tail -n +3 ${FILETOCHECK}  > ${FILETOCHECK}.Unsorted_tmp.txt

awk ' {$1; $2 ; $3 = 0 ; $4 = 0 ; print; } ' ${FILETOCHECK}.Unsorted_tmp.txt > ${FILETOCHECK}.Unsorted.txt
awk ' $1>$2{x=$2;$2=$1;$1=x;0;0}1' ${FILETOCHECK}.Unsorted.txt > ${FILETOCHECK}.Sorted.txt
rm ${FILETOCHECK}.Unsorted_tmp.txt

diff ${FILETOCHECK}.Unsorted.txt ${FILETOCHECK}.Sorted.txt
