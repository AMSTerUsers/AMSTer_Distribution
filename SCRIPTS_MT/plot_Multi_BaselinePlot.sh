#!/bin/bash
# This script makes a common Baseline and imageSpatialLocalization plots for multiple data sets. 
# Note : If more than 5 different dataset, colors in imageSpatialLocalization will loop. 
#        But it would be unreadable anyway... Above 10, see yourself...
# Note: it search by itmself the Bp, Bt and Global Primary date of each set
# 
# It supposes that a first plot was already computed (see Prepa_MSBAS.sh) for each mode in order to generate 
#     the required data and gnuplot files
#
# Parameters = 
#		- file with the list of sets used in the order of Defo dir  (SETLIST)
# 		  which must contain lines such as :	$PATH_1650/SAR_SM/MSBAS/VVP/set6
#												$PATH_1650/SAR_SM/MSBAS/VVP/set7
#
# Dependencies:	- gnuplot
#
# Hard coded:	- 
#
# New in Distro V 1.0:	- based on baselinePlot.gnuplot issued by baselinePlot 
# New in Distro V 1.1:	- correct error to get Bp and Bt				
# New in Distro V 1.2: - replace if -s as -f -s && -f to be compatible with mac os if 
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

# vvv ----- Hard coded lines to check --- vvv 
source /$HOME/.bashrc 
# ^^^ ----- Hard coded lines to check --- ^^^ 
 
SETLIST=$1	# contains lines as:	$PATH_1650/SAR_SM/MSBAS/VVP/set6
			#						$PATH_1650/SAR_SM/MSBAS/VVP/set7

BASEDIR=`head -1 ${SETLIST}`
BASEDIR=`dirname ${BASEDIR}`
eval BASEDIR=${BASEDIR}
cd ${BASEDIR}
			
# Dump Command line used in CommandLine.txt
echo "$(dirname $0)/${PRG} run with following arguments : \n" > CommandLine_${PRG}.txt
index=1 
for arg in $*
do
  echo "$arg" >> CommandLine_${PRG}.txt
  let "index+=1"
done 

# get list of set nr and create dir where combined plot will be stored:
i=1
DIRSETLIST=""

for LINE in `cat -s ${SETLIST}`
do
	# get set number
	SETNR[$i]=`echo ${LINE} |  ${PATHGNU}/grep -Eo '[0-9]+$' `
	DIRSETLIST="${DIRSETLIST}_set${SETNR[$i]}"
	i=`expr ${i} + 1`	
done 
Nsets=`expr ${i} - 1`

mkdir -p BaselinePlots${DIRSETLIST}

i=1
for LINE in `cat -s ${SETLIST}`
do
	eval LINE=${LINE}
	# get set number
	SETNR[$i]=`echo ${LINE} |  ${PATHGNU}/grep -Eo '[0-9]+$' `
	if [ ! -f ${LINE}/acquisitionsRepartition.txt ] ; then echo "No  ${LINE}/acquisitionsRepartition.txt, can't use this script. May need to perform a Prepa_MSBAS.sh first with AMSTer Engine at least from 20220501" ; exit 0 ; fi
	cp ${LINE}/acquisitionsRepartition.txt BaselinePlots${DIRSETLIST}/acquisitionsRepartition${SETNR[$i]}.txt
	if [ -f "${LINE}/baselinePlot_ADD_PAIRS.gnuplot" ] && [ -s "${LINE}/baselinePlot_ADD_PAIRS.gnuplot" ]
		then
			cp ${LINE}/baselinePlot_ADD_PAIRS.gnuplot BaselinePlots${DIRSETLIST}/baselinePlot${SETNR[$i]}.gnuplot			
		else 
			cp ${LINE}/baselinePlot.gnuplot BaselinePlots${DIRSETLIST}/baselinePlot${SETNR[$i]}.gnuplot
	fi
	# get SpatialRepartition (e.g. selectedAcquisitionsSpatialRepartition_BpMax=20_BTMax=400[_ADD_PAIRS].txt) and copy file
	SPATIALREPARTITION=`grep "inputFile2" BaselinePlots${DIRSETLIST}/baselinePlot${SETNR[$i]}.gnuplot | head -1 | cut -d / -f 2  | cut -d . -f 1 `
	cp -f ${LINE}/${SPATIALREPARTITION}.txt BaselinePlots${DIRSETLIST}/${SPATIALREPARTITION}${SETNR[$i]}.txt
	# get Pair List (e.g. selectedPairsListing_BpMax=20_BTMax=400[_ADD_PAIRS].txt) and copy file
	SELECTEDPAIRLIST=`grep "inputFile3" BaselinePlots${DIRSETLIST}/baselinePlot${SETNR[$i]}.gnuplot | head -1 | cut -d / -f 2  | cut -d . -f 1 `
	cp -f ${LINE}/${SELECTEDPAIRLIST}.txt BaselinePlots${DIRSETLIST}/${SELECTEDPAIRLIST}${SETNR[$i]}.txt	
	i=`expr ${i} + 1`
done

echo "# Spatial baseline plot" > BaselinePlots${DIRSETLIST}/baselinePlot_${DIRSETLIST}.gnuplot
echo "#" >> BaselinePlots${DIRSETLIST}/baselinePlot_${DIRSETLIST}.gnuplot
echo "# WorkingDirectory:" >> BaselinePlots${DIRSETLIST}/baselinePlot_${DIRSETLIST}.gnuplot
echo "workingDir = sprintf(\"${BASEDIR}/BaselinePlots${DIRSETLIST}\")" >> BaselinePlots${DIRSETLIST}/baselinePlot_${DIRSETLIST}.gnuplot
echo "" >> BaselinePlots${DIRSETLIST}/baselinePlot_${DIRSETLIST}.gnuplot

echo "# Input files:" >> BaselinePlots${DIRSETLIST}/baselinePlot_${DIRSETLIST}.gnuplot
	i=1
	for LINE in `cat -s ${SETLIST}`
	do
		eval LINE=${LINE}
		# get set number
		SETNR[$i]=`echo ${LINE} |  ${PATHGNU}/grep -Eo '[0-9]+$' `
		echo "inputFile${i} = sprintf(\"%s/acquisitionsRepartition${SETNR[$i]}.txt\", workingDir)" >> BaselinePlots${DIRSETLIST}/baselinePlot_${DIRSETLIST}.gnuplot
		i=`expr ${i} + 1`
	done
	j=${i}
	# do not reset $i
	for LINE in `cat -s ${SETLIST}`
	do
		eval LINE=${LINE}
		# get set number
		SETNR[$i]=`echo ${LINE} |  ${PATHGNU}/grep -Eo '[0-9]+$' `
		ACQFILETOGET=`find BaselinePlots${DIRSETLIST}/ -maxdepth 1 -type f -name "selectedAcquisitionsSpatialRepartition*${SETNR[$i]}.txt" | cut -d / -f 2`
		PAIRFILETOGET=`find BaselinePlots${DIRSETLIST}/ -maxdepth 1 -type f -name "selectedPairsListing*${SETNR[$i]}.txt" | cut -d / -f 2`
		echo "inputFile${i} = sprintf(\"%s/${ACQFILETOGET}\", workingDir)" >> BaselinePlots${DIRSETLIST}/baselinePlot_${DIRSETLIST}.gnuplot
		i=`expr ${i} + 1`
		echo "inputFile${i} = sprintf(\"%s/${PAIRFILETOGET}\", workingDir)" >> BaselinePlots${DIRSETLIST}/baselinePlot_${DIRSETLIST}.gnuplot
		i=`expr ${i} + 1`
	done
echo "" >> BaselinePlots${DIRSETLIST}/baselinePlot_${DIRSETLIST}.gnuplot

echo "# Set output file:" >> BaselinePlots${DIRSETLIST}/baselinePlot_${DIRSETLIST}.gnuplot
echo "outputFile = sprintf(\"%s/imageSpatialLocalization.png\", workingDir)" >> BaselinePlots${DIRSETLIST}/baselinePlot_${DIRSETLIST}.gnuplot
echo "set output outputFile" >> BaselinePlots${DIRSETLIST}/baselinePlot_${DIRSETLIST}.gnuplot
echo "set terminal png size 1280, 720 #transparent truecolor" >> BaselinePlots${DIRSETLIST}/baselinePlot_${DIRSETLIST}.gnuplot

echo "# Constants:" >> BaselinePlots${DIRSETLIST}/baselinePlot_${DIRSETLIST}.gnuplot
echo "xShift =     0.00" >> BaselinePlots${DIRSETLIST}/baselinePlot_${DIRSETLIST}.gnuplot
echo "yShift =     0.00" >> BaselinePlots${DIRSETLIST}/baselinePlot_${DIRSETLIST}.gnuplot
echo "BpShift =     0.00" >> BaselinePlots${DIRSETLIST}/baselinePlot_${DIRSETLIST}.gnuplot
echo "" >> BaselinePlots${DIRSETLIST}/baselinePlot_${DIRSETLIST}.gnuplot

echo "# Settings:" >> BaselinePlots${DIRSETLIST}/baselinePlot_${DIRSETLIST}.gnuplot
# main dot style in space plot
echo "set style line 1 pointsize 2 pointtype 7  linecolor rgb \"red\" " >> BaselinePlots${DIRSETLIST}/baselinePlot_${DIRSETLIST}.gnuplot	
echo "set style line 2 pointsize 2 pointtype 7  linecolor rgb \"blue\" " >> BaselinePlots${DIRSETLIST}/baselinePlot_${DIRSETLIST}.gnuplot	
echo "set style line 3 pointsize 2 pointtype 7  linecolor rgb \"purple\" " >> BaselinePlots${DIRSETLIST}/baselinePlot_${DIRSETLIST}.gnuplot	
echo "set style line 4 pointsize 2 pointtype 7  linecolor rgb \"coral\" " >> BaselinePlots${DIRSETLIST}/baselinePlot_${DIRSETLIST}.gnuplot	
echo "set style line 5 pointsize 2 pointtype 7  linecolor rgb \"turquoise\" " >> BaselinePlots${DIRSETLIST}/baselinePlot_${DIRSETLIST}.gnuplot	
echo "" >> BaselinePlots${DIRSETLIST}/baselinePlot_${DIRSETLIST}.gnuplot
# axis
echo "set xzeroaxis linetype 4 linewidth 2" >> BaselinePlots${DIRSETLIST}/baselinePlot_${DIRSETLIST}.gnuplot
echo "set yzeroaxis linetype 4 linewidth 2" >> BaselinePlots${DIRSETLIST}/baselinePlot_${DIRSETLIST}.gnuplot
# circle style in space plot
echo "set style circle radius screen 0.004" >> BaselinePlots${DIRSETLIST}/baselinePlot_${DIRSETLIST}.gnuplot
echo "set style fill transparent solid 0.5 noborder" >> BaselinePlots${DIRSETLIST}/baselinePlot_${DIRSETLIST}.gnuplot
# label
echo "set key  left tmargin  box title \"Acquisitions spatial repartition\"" >> BaselinePlots${DIRSETLIST}/baselinePlot_${DIRSETLIST}.gnuplot
echo "set label at xShift, yShift "" point pointtype 69 pointsize 4 linecolor rgb \"red\" linewidth 2" >> BaselinePlots${DIRSETLIST}/baselinePlot_${DIRSETLIST}.gnuplot
echo "" >> BaselinePlots${DIRSETLIST}/baselinePlot_${DIRSETLIST}.gnuplot

echo "plot \\" >> BaselinePlots${DIRSETLIST}/baselinePlot_${DIRSETLIST}.gnuplot
	i=1
	k=1
	for LINE in `cat -s ${SETLIST}`
	do
		if [ ${k} -gt 5 ] ; then k=`expr ${k} - 5 `; else k=${i} ; fi
		echo "inputFile${i} using 2:3 with points ls ${k} notitle, \\" >> BaselinePlots${DIRSETLIST}/baselinePlot_${DIRSETLIST}.gnuplot
		echo "inputFile${i} using 2:3:1  with labels rotate by 15 offset screen 0.03,0.03 font \"Times,10\" notitle, \\" >> BaselinePlots${DIRSETLIST}/baselinePlot_${DIRSETLIST}.gnuplot
		i=`expr ${i} + 1`
		k=`expr ${k} + 1`
	done

	i=${j}
	for LINE in `cat -s ${SETLIST}`
	do
		echo "inputFile${i} using 2:3 with points pointsize 1 pointtype 4 notitle, \\" >> BaselinePlots${DIRSETLIST}/baselinePlot_${DIRSETLIST}.gnuplot
		i=`expr ${i} + 1`
		echo "inputFile${i} using (\$3):(\$4):(\$5 - \$3):(\$6 - \$4) with vectors notitle, \\" >> BaselinePlots${DIRSETLIST}/baselinePlot_${DIRSETLIST}.gnuplot
		i=`expr ${i} + 1`
	done
# must remove last \ in plot list
${PATHGNU}/gsed -i '$ s/.$//' BaselinePlots${DIRSETLIST}/baselinePlot_${DIRSETLIST}.gnuplot
${PATHGNU}/gsed -i '$ s/.$//' BaselinePlots${DIRSETLIST}/baselinePlot_${DIRSETLIST}.gnuplot
# and the last ,
${PATHGNU}/gsed -i '$ s/.$//' BaselinePlots${DIRSETLIST}/baselinePlot_${DIRSETLIST}.gnuplot


echo "" >> BaselinePlots${DIRSETLIST}/baselinePlot_${DIRSETLIST}.gnuplot
echo "" >> BaselinePlots${DIRSETLIST}/baselinePlot_${DIRSETLIST}.gnuplot

echo "# Second plot settings:" >> BaselinePlots${DIRSETLIST}/baselinePlot_${DIRSETLIST}.gnuplot
echo "" >> BaselinePlots${DIRSETLIST}/baselinePlot_${DIRSETLIST}.gnuplot

echo "outputFile = sprintf(\"%s/baselinePlot.png\", workingDir)" >> BaselinePlots${DIRSETLIST}/baselinePlot_${DIRSETLIST}.gnuplot
echo "set output outputFile" >> BaselinePlots${DIRSETLIST}/baselinePlot_${DIRSETLIST}.gnuplot
echo "" >> BaselinePlots${DIRSETLIST}/baselinePlot_${DIRSETLIST}.gnuplot

echo "# Defining title" >> BaselinePlots${DIRSETLIST}/baselinePlot_${DIRSETLIST}.gnuplot
# Get Bp and Bt for each data set
	i=1
	TITLEBP=""
	for LINE in `cat -s ${SETLIST}`
	do
		eval LINE=${LINE}
		# get set number
		SETNR[$i]=`echo ${LINE} |  ${PATHGNU}/grep -Eo '[0-9]+$' `
		TARGETFILE=`find BaselinePlots${DIRSETLIST}/ -maxdepth 1 -type f -name "selectedPairsListing*${SETNR[$i]}.txt"`
		BP[$i]=`${PATHGNU}/grep "Maximal perpendicular baseline" ${TARGETFILE} | cut -d : -f 2 `
		BT[$i]=`${PATHGNU}/grep "Maximal time base" ${TARGETFILE} | cut -d : -f 2`
		SM[$i]=`${PATHGNU}/grep "superMasterDate" BaselinePlots${DIRSETLIST}/baselinePlot${SETNR[$i]}.gnuplot | head -1 | cut -d = -f 2`
		echo "superMasterDate${SETNR[$i]} = ${SM[$i]}" >> BaselinePlots${DIRSETLIST}/baselinePlot_${DIRSETLIST}.gnuplot
		echo "BpMax${SETNR[$i]} = ${BP[$i]}" >> BaselinePlots${DIRSETLIST}/baselinePlot_${DIRSETLIST}.gnuplot
		echo "BTMax${SETNR[$i]} = ${BT[$i]}" >> BaselinePlots${DIRSETLIST}/baselinePlot_${DIRSETLIST}.gnuplot
		#TITLEBP="${TITLEBP}Baseline plot of data set ${SETNR[$i]} : Bp Max=${BP[$i]}; BT Max=${BT[$i]}; superMasterDate=${SM[$i]} \\n"
		TITLEBP="${TITLEBP}Baseline plot of data set ${SETNR[$i]} : Bp Max=${BP[$i]}; BT Max=${BT[$i]}; GlobalPrimaryDate=${SM[$i]} \\n"
		i=`expr ${i} + 1`
	done
# remove trailing CR in title
TITLEBP=`echo "${TITLEBP}" | rev | cut -c3- | rev `

echo "theTitle = sprintf(\"${TITLEBP}\")" >> BaselinePlots${DIRSETLIST}/baselinePlot_${DIRSETLIST}.gnuplot

echo "set key left tmargin  box title theTitle" >> BaselinePlots${DIRSETLIST}/baselinePlot_${DIRSETLIST}.gnuplot
echo "timeFormat = \"%Y%m%d\"" >> BaselinePlots${DIRSETLIST}/baselinePlot_${DIRSETLIST}.gnuplot
echo "timeString(n) = sprintf(\"%d\", n)" >> BaselinePlots${DIRSETLIST}/baselinePlot_${DIRSETLIST}.gnuplot
echo "set xdata time" >> BaselinePlots${DIRSETLIST}/baselinePlot_${DIRSETLIST}.gnuplot
echo "set timefmt timeFormat" >> BaselinePlots${DIRSETLIST}/baselinePlot_${DIRSETLIST}.gnuplot
echo "set format x \"%d/%m\n%Y\"" >> BaselinePlots${DIRSETLIST}/baselinePlot_${DIRSETLIST}.gnuplot
echo "set grid" >> BaselinePlots${DIRSETLIST}/baselinePlot_${DIRSETLIST}.gnuplot
echo "set key left" >> BaselinePlots${DIRSETLIST}/baselinePlot_${DIRSETLIST}.gnuplot

# vertical axes for the Global primary in baseline plot
	i=1
	k=`expr ${Nsets} + 2`
	TITLEBP=""
	for LINE in `cat -s ${SETLIST}`
	do
		eval LINE=${LINE}
		# get set number
		SETNR[$i]=`echo ${LINE} |  ${PATHGNU}/grep -Eo '[0-9]+$' `
		echo "set arrow ${i} from strptime(timeFormat, timeString(superMasterDate${SETNR[$i]})), graph 0 to strptime(timeFormat, timeString(superMasterDate${SETNR[$i]})), graph 1 linecolor ${k} lw 2 nohead" >> BaselinePlots${DIRSETLIST}/baselinePlot_${DIRSETLIST}.gnuplot
		i=`expr ${i} + 1`
		k=`expr ${k} + 2`
	done
echo "" >> BaselinePlots${DIRSETLIST}/baselinePlot_${DIRSETLIST}.gnuplot

# test mlabels
	i=1
	for LINE in `cat -s ${SETLIST}`
	do
		eval LINE=${LINE}
		# get set number
		SETNR[$i]=`echo ${LINE} |  ${PATHGNU}/grep -Eo '[0-9]+$' `
		echo "set label ${i} \"Set${SETNR[$i]}\" at strptime(timeFormat, timeString(superMasterDate${SETNR[$i]})),graph 0.01 front nopoint tc rgb \"black\" " >> BaselinePlots${DIRSETLIST}/baselinePlot_${DIRSETLIST}.gnuplot
		i=`expr ${i} + 1`
	done		
#

echo "plot \\" >> BaselinePlots${DIRSETLIST}/baselinePlot_${DIRSETLIST}.gnuplot
	i=`expr ${Nsets} + 2`
	for LINE in `cat -s ${SETLIST}`
	do
		echo "inputFile${i} using 1:(\$7 - BpShift) with circles fillcolor \"grey\" notitle, \\" >> BaselinePlots${DIRSETLIST}/baselinePlot_${DIRSETLIST}.gnuplot
		echo "inputFile${i} using 2:(\$7 - BpShift + \$8) with circles fillcolor \"grey\" notitle, \\" >> BaselinePlots${DIRSETLIST}/baselinePlot_${DIRSETLIST}.gnuplot
		echo "inputFile${i} using 1:(\$7 - BpShift):(strptime(timeFormat, timeString(\$2)) - strptime(timeFormat, timeString(\$1))):8 with vectors linewidth 1 linecolor ${i} notitle, \\" >> BaselinePlots${DIRSETLIST}/baselinePlot_${DIRSETLIST}.gnuplot
		i=`expr ${i} + 2`
	done
# must remove last \ in plot list
${PATHGNU}/gsed -i '$ s/.$//' BaselinePlots${DIRSETLIST}/baselinePlot_${DIRSETLIST}.gnuplot
${PATHGNU}/gsed -i '$ s/.$//' BaselinePlots${DIRSETLIST}/baselinePlot_${DIRSETLIST}.gnuplot
# and the last ,
${PATHGNU}/gsed -i '$ s/.$//' BaselinePlots${DIRSETLIST}/baselinePlot_${DIRSETLIST}.gnuplot

gnuplot BaselinePlots${DIRSETLIST}/baselinePlot_${DIRSETLIST}.gnuplot
