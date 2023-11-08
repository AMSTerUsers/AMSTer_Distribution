#!/bin/bash
######################################################################################
# This script check all the envi format files in dir and search for all or any NAN.
#  If found, file name is output in text file 
#
# Parameters: - ALL (if want to search for files filled with only NaN) 
#				or ANY (if want to search for files with at least one NaN)
#			  - input file format (byte or float32)
#
# Must be launnched in where all envi files are (link or files)
#
# New in V 2.0:	- allows searching for all or any NaN and works with byte or flaot32 files
# New in V 2.1: - replace if -s as -f -s && -f to be compatible with mac os if 
# New in Distro V 3.0 20231030:	- Rename MasTer Toolbox as AMSTer Software
#								- rename Master and Slave as Primary and Secondary (though not possible in some variables and files)
#
# AMSTer: SAR & InSAR Automated Mass processing Software for Multidimensional Time series
# NdO (c) 2016/03/07 - could make better with more functions... when time.
# -----------------------------------------------------------------------------------------
PRG=`basename "$0"`
VER="Distro V3.0 AMSTer script utilities"
AUT="Nicolas d'Oreye, (c)2016-2019, Last modified on Oct 30, 2023"
echo " "
echo "${PRG} ${VER}, ${AUT}"
echo "Processing launched on $(date) " 
echo " " 

TYPEOFSEARCH=$1
TYPEOFFILES=$2

case ${TYPEOFFILES} in 
	"byte")
		echo "OK, search in byte files"
		;;
	"float32")
		echo "OK, search in float32 files"
		;;		
		*)	
		echo "Sorry, I can't understand the input file format you want. Please take byte or float32"
		exit
		;;
esac

case ${TYPEOFSEARCH} in 
	"ALL")
		rm -f _AllNan_In_Files.txt

		find . -maxdepth 1 -name "*deg" | ${PATHGNU}/gsed "s/\.\///g" > All_Defo.txt

		for PAIR in `cat All_Defo.txt`
		do 
			NAN=`checkOnlyNaN.py ${PAIR} ${TYPEOFFILES}`
			echo "Test ${PAIR}. Nan or min value ? : 		${NAN}" 
			if [ "${NAN}" == "nan" ]
				then 
					echo "${PAIR}" >> _AllNan_In_Files.txt

			fi
		done 

		echo "-----------------------------"
		if [ -f _Nan_In_Files.txt ] && [ -s _Nan_In_Files.txt ]  
			then 
				echo "At least some files were filled with only NaN."
				echo "Check _AllNan_In_Files.txt and remove files e.g. from MSBAS processing " 
				echo
		fi
		;;
	"ANY")	
		rm -f _Nan_In_Files.txt

		find . -maxdepth 1 -name "*deg" | ${PATHGNU}/gsed "s/\.\///g" > All_Defo.txt

		for PAIR in `cat All_Defo.txt`
		do 
			NAN=`checkNaN.py ${PAIR} ${TYPEOFFILES}`
			echo "Test ${PAIR}. Nan or min value ? : 		${NAN}" 
			if [ "${NAN}" == "nan" ]
				then 
					echo "${PAIR}" >> _Nan_In_Files.txt

			fi
		done 

		echo "-----------------------------"
		if [ -f _Nan_In_Files.txt ] && [ -s _Nan_In_Files.txt ] 
			then 
				echo "At least some files contains at least one NaN."
				echo "Check _Nan_In_Files.txt " 
				echo
		fi
		;;
	*)
		echo "Please specify as param1 ALL or ANY if want to search resp. for files filled with only NaN or files with at least one NaN"
		exit ;;
esac



#rm -f  All_Defo.txt

echo "All done. "

