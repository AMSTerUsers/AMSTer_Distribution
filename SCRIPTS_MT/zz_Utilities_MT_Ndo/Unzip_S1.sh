#!/bin/bash
######################################################################################
# This script unzip all S1 images from dir provided as parameter and store them in .UNZIP
# Note that it tests if alraedy unzipped and size is not as expected, it unzips it again. 
#
# Parameter : - path to dir with zipped images (usually something such as SAR_DATA/S1/S1-DATA-region-SLC)
#
# Dependencies: - gnu parallel 
#
# This was tested only on Mac...
#
# New in V1.1:	-	use gnu version of du to allow option -d 
# New in V1.2:	-	run in background to parallelise. Need to export variables and functions if using gnu parallel
# New in V1.3:	-	prevent path to finish by a slash 

# 
# I know, it is a bit messy and can be improved.. when time. But it works..
# N.d'Oreye, v 1.0 2016/04/07 -                         
######################################################################################
PRG=`basename "$0"`
VER="Distro V1.3 MasTer script utilities"
AUT="Nicolas d'Oreye, (c)2016-2019, Last modified on Jul 24, 2023"
echo " "
echo "${PRG} ${VER}, ${AUT}"
echo "Processing launched on $(date) " 
echo " " 

source $HOME/.bashrc

export ZIPDIRLOCAL=$1

ZIPDIRLOCAL="${ZIPDIRLOCAL%/}"	# Because if path ends with / it will move everything unzipped in .UNZIP instead of ${ZIPDIRLOCAL}.UNZIP


UnzipAndMove()
{
	local imgpath

	imgpath=$1 
  
	unzip ${imgpath}
	echo "//    and move ${imgename}.SAFE to ${UNZIPDIRLOCAL}..." 
	mv -f ${imgename}.SAFE ${UNZIPDIRLOCAL}/
}

CheckAndUnzip()
{
	local imgpath
	local zipimgename
	local imgename
	local imgsize
	local imgsizebytes
	local imgzipsize
	local imgexpected


	imgpath=$1 
  
	zipimgename="${imgpath##*/}"  # string after last /
	imgename=`echo "${zipimgename}" | cut -d . -f 1`
	# test if alraedy unzipped and size larger than zip
	if [ ! -d ${UNZIPDIRLOCAL}/${imgename}.SAFE ]
		then 
			echo "// Unzip ${zipimgename}" 
			UnzipAndMove ${imgpath}
		else 
			imgsize=`${PATHGNU}/gdu -ch ${UNZIPDIRLOCAL}/${imgename}.SAFE | tail -1 | cut -d t -f 1`
			imgsizebytes=`${PATHGNU}/gdu -sb ${UNZIPDIRLOCAL}/${imgename}.SAFE | tail -1 |  ${PATHGNU}/gsed 's@^[^0-9]*\([0-9]\+\).*@\1@'` # get only number from size in bytes
			imgzipsize=`${PATHGNU}/gdu -ch ${imgpath} | tail -1 | cut -d t -f 1`
			imgexpected=`unzip -l ${imgpath} | tail -1 | xargs | cut -d " " -f1` 
		 	if [ ${imgsizebytes} -lt ${imgexpected} ] 
		 		then 
		 			echo "// ${imgename}.SAFE is already unzipped in ${UNZIPDIRLOCAL} "
		 			echo "//    However, it must have been ${imgexpected}. Unzip again: "
	 	 			UnzipAndMove ${imgpath}
				else 
				    echo "// ${imgename}.SAFE is already unzipped in ${UNZIPDIRLOCAL} and its size is ok. "
		 	fi
	fi
	echo
}

cd ${ZIPDIRLOCAL}
echo ""
echo " Shall unzip images from ${ZIPDIRLOCAL}"
echo ""
export UNZIPDIRLOCAL=`echo "${ZIPDIRLOCAL}.UNZIP"`
mkdir -p ${UNZIPDIRLOCAL}

# Using background process: slightly slower and can't manage numer of parallel processes 

# for imgpath in `find . -type f -name "*.zip" `  # search in current dir and sub dirs
# 	do
# 		CheckAndUnzip ${imgpath} &
# done
# 
# wait



# Using gnu parallel ; can manage number of threads in absolute (e.g. -j 8) or % (e.g. -j 50%)
export -f UnzipAndMove
export -f CheckAndUnzip

# Full CPU capabilities
find . -type f -name '*.zip' -print0 | parallel -0 CheckAndUnzip {}	

# restrict to 90% capabilities
#find . -type f -name '*.zip' -print0 | parallel -j 90% -0 CheckAndUnzip {}		

unset ZIPDIRLOCAL
unset UNZIPDIRLOCAL

echo +++++++++++++++++++++++++++++++++++++++++++++++
echo "ALL FILES MODIFIED - HOPE IT WORKED"
echo +++++++++++++++++++++++++++++++++++++++++++++++


