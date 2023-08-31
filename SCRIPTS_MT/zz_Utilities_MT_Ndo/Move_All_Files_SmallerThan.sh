#!/bin/bash
######################################################################################
# This script move all dirs (or files if change hard coded lines) in pwd that are 
# smaller than a certain amount in Mb (or Bytes for files) in provided path.
#
# New in V1.1: 	- seems that former version was not compliant with some OS 
# New in V1.2: 	- offer herd coded option for checking files
#
# I know, it is a bit messy and can be improved.. when time. But it works..
# MasTer: InSAR Suite automated Mass processing Toolbox. 
# NdO (c) 2019/12/05 - could make better... when time.
# -----------------------------------------------------------------------------------------
PRG=`basename "$0"`
VER="Distro V1.2 MasTer script utilities"
AUT="Nicolas d'Oreye, (c)2016-2021, Last modified on Aug 08, 2022"
echo " "
echo "${PRG} ${VER}, ${AUT}"
echo " "


MAXSIZE=$1 			# Max dir size in Mb
WHERETOMOVE=$2 		# path where to move dirs

#find . -mindepth 1 -maxdepth 1 -type d -exec du -ms {} +  | ${PATHGNU}/gawk '$1 <= '${MAXSIZE}'' | cut -f 2- | xargs -I ARG mv ARG ${WHERETOMOVE}/

#find . -maxdepth 1 -type d | grep -v ^\\.$ | xargs -n 1 du -ms | while read size name ; do if [ $size -lt ${MAXSIZE} ] ; then mv $name ${WHERETOMOVE}/ ; echo "$name ($size Mb) moved to ${WHERETOMOVE}"; else echo "$name : $size Mb" ; fi done

# same to check all file size:
#find . -maxdepth 1 -type f | grep -v ^\\.$ | xargs -n 1 du -s | while read size name ; do if [ $size -lt ${MAXSIZE} ] ; then mv $name ${WHERETOMOVE}/ ; echo "$name ($size bytes) moved to ${WHERETOMOVE}"; else echo "$name : $size Bytes" ; fi done

# same to check all file named *deg and not of size:
find . -maxdepth 1 -type f -name "*deg" | grep -v ^\\.$ | xargs -n 1 du -s | while read size name ; do if [ $size -ne ${MAXSIZE} ] ; then mv $name ${WHERETOMOVE}/ ; mv $name.hdr ${WHERETOMOVE}/ ; echo "$name ($size bytes) moved to ${WHERETOMOVE}"; else echo "$name : $size Bytes" ; fi done


echo +++++++++++++++++++++++++++++++++++++++++++++++
echo "ALL DIR MOVED - HOPE IT WORKED"
echo +++++++++++++++++++++++++++++++++++++++++++++++

