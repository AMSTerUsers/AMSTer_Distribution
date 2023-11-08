#!/bin/bash
######################################################################################
# This script remove either one file (as param) or all files in dir (if param = -d) and 
# sub-dirs (if param : -dd) from security quarantine sometimes automatically set by 
# Mac OSX for unknown reason... 
#
# Parameters:	- a file path or -d or -dd to de-quarantine a given file, all files in 
#				  the current dir only, or all files in the current dir and subdirs
#
# New in Distro V 1.1 (Jul 19, 2023): - replace if -s as -f -s && -f to be compatible with mac os if 
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

PARAM=$1	# either a path to a file or -d (or -dd) if you want to do it for all files in dir (and sub-dirs) 

if [ $# -lt 1 ] 
	then 
		echo "Syntax: ${PRG} [PARAM], where PARAM is either :"
		echo "    -> a path to a given file to de-quarantine, or "
		echo "    -> -d to de-quarantine all files in pwd, or "
		echo "    -> -dd to de-quarantine all files in pwd AND in SUB-DIRS "
		echo "CHECK PARAMETER"
		echo
		exit 0
fi

# Check OS and abort if not Mac
OS=`uname -a | cut -d " " -f 1 `

case ${OS} in 
	"Linux") 
		echo "This script is only required for Mac OSX based systems."
		exit 0
		;;
	"Darwin")
		echo "OK, running on ${OS}"
		;;
	*)
		echo "I can't figure out what is you opeating system. Please check"
		exit 0
		;;
esac	

case ${PARAM} in 
	"-d")
		echo "Shall de-quarantine all files in present directory (no sub-dirs), i.e.:"
		pwd
		while true; do
			read -p "Agree ? (Y/N):"  yn
			case $yn in
				[Yy]* ) 
					for FILES in `find . -maxdepth 1 -type f -name "*"`
						do 
						xattr -d com.apple.quarantine ${FILES} 2>/dev/null
					done
					break ;;
				[Nn]* ) 
	   				echo "OK, I give up."
	   				exit 1	;;
				* ) echo "Please answer yes or no.";;
			esac
		done
		;;
	"-dd")
		echo "Shall de-quarantine all files in present directory AND sub-dirs, i.e.:"
		pwd
		find . -type d -name "*"
		while true; do
			read -p "Agree ? (Y/N):"  yn
			case $yn in
				[Yy]* ) 
					for FILES in `find . -type f -name "*"`
						do 
						xattr -d com.apple.quarantine ${FILES} 2>/dev/null
					done
					break ;;
				[Nn]* ) 
					echo "OK, I give up."
	   				exit 1 ;;
				* ) echo "Please answer yes or no.";;
			esac
		done
		;;
	*) 
		echo "Shall de-quarantine only one file, that is ${PARAM}"
		if [ -f "${PARAM}" ] && [ -s "${PARAM}" ] 
			then 
				xattr -d com.apple.quarantine ${PARAM}  2>/dev/null
				echo "   File de-quarantined successfuly"
			else
				echo "The file doesn't exist. Please check path and provide it with path as input param."
				exit 0
		fi
		;;
esac

echo +++++++++++++++++++++++++++++++++++++++++++++++
echo "FILE(S) DE-QUARANTINED - HOPE IT WORKED"
echo +++++++++++++++++++++++++++++++++++++++++++++++

