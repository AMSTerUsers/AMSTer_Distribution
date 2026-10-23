#!/bin/bash
# Remove externalSlantRangeDEM in subdir if smaller than a given size
#
# For an up to date and detailed list of dependencies (and sub-dependencies), 
#    run the following command (add option -v to also list the commands and calls):
#  		Search_Dependencies /Path/to/This/script 
# 	 (Results are displayed at the Terminal; redirect them to a file with > file.txt if wished)
#
# New in Distro V 1.1 20261013:	- Recommend using Search_Dependencies.sh for 
#								  an updated list of dependencies
#									  
#
# AMSTer: SAR & InSAR Automated Mass processing Software for Multidimensional Time series
# NdO (c) 2016/03/07 - could make better with more functions... when time.
# -----------------------------------------------------------------------------------------
PRG=`basename "$0"`
VER="Distro V1.1 AMSTer script utilities"
AUT="Nicolas d'Oreye, (c)2016-2019, Last modified on oct 13, 2026"
echo " "
echo "${PRG} ${VER}, ${AUT}"
echo "Processing launched on $(date) " 
echo " " 

SIZE=$1 	# size in b

echo "List dates of missing files from prensent dir/subdirs: "

for dem in `find . -name externalSlantRangeDEM`
   do
 		demsize=$(stat -c%s "$dem")
 		if [ -f "${dem}" ] && [ ${demsize} -lt ${SIZE} ]
			then 
				echo "${dem} is ${demsize} => del"
				rm -f ${dem}
			else 
				echo "${dem} is ${demsize} => ok"
		fi

done

echo +++++++++++++++++++++++++++++++++++++++++++++++
echo "ALL FILES CHECKED - HOPE IT WORKED"
echo +++++++++++++++++++++++++++++++++++++++++++++++


