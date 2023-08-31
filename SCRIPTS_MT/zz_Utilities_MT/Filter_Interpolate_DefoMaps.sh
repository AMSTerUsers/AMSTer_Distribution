#!/bin/bash
######################################################################################
# This script aims at filterfing/filling gaps in defo maps. It must be run in the dir 
#    where defo maps are stored. 
#
# Hard coded:	- extension of the files to filter, i.e. ".rev" here (cfr line 26)
#				- width of the median filter, i.e. 11 here (cfr line 25)
#
# Dependencies:
#	 - gmt
# 
# New in Distro V 1.0:	- Based on developpement version and Beta V1.0
#
# MasTer: InSAR Suite automated Mass processing Toolbox. 
# N.d'Oreye, v 1.0 2016/04/07 -                         
######################################################################################
echo
PRG=`basename "$0"`
VER="Distro V1.0 MasTer script utilities"
AUT="Nicolas d'Oreye, (c)2016-2019, Last modified on Jul 15, 2019"
echo " "
echo "${PRG} ${VER}, ${AUT}"
echo " "

FILTVAL=11   # width of median filter

ls *.rev > Files_To_fill.txt

for FILE in `cat Files_To_fill.txt`
do 
  fout=${FILE}_filt${FILTVAL}.rev
  gmt grdfilter ${FILE} -Dp -Fm${FILTVAL} -G${fout}=gd:ENVI
  mv ${FILE} ${FILE}_NoFilt
  cp ${fout} ${FILE}
done 

#rm Files_To_fill.txt

echo +++++++++++++++++++++++++++++++++++++++++++++++
echo "ALL DONE- HOPE IT WORKED"
echo +++++++++++++++++++++++++++++++++++++++++++++++

