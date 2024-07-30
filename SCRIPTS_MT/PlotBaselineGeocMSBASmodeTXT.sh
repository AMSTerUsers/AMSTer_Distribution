#!/bin/bash
# -----------------------------------------------------------------------------------------
# This script is aiming at plotting the baseline of all the pairs which are listd in text file
#   WHERE_MSBAS_IS_PROCESSED/Mode.txt (where Mode is e.g. DefoInterpolx2Detrend1) 
#   Pairs characteristics are taken from first Mode. 
#
# Parameters : - path to SAR_SM/MSBAS/REGION/set"i" where "i" is the set nr corresponding to the mode to process
#              - WHERE_MSBAS_IS_PROCESSED/Mode.txt
#
# Dependencies:	- gsed
#				- __HardCodedLines.sh
#
# Hard coded:	- Some hard coded info about plot style : title, range, font, color...
#
# New in Distro V 1.1:	- add creation date label
# New in Distro V 2.0:	- make baseline plot with recent tools (nicer plot...)
# New in Distro V 3.0:	- Use hard coded lines definition from __HardCodedLines.sh
# New in Distro V 4.0 20230830:	- Rename SCRIPTS_OK directory as SCRIPTS_MT 
#								- Replace CIS by MT in names 
#								- Renamed FUNCTIONS_FOR_MT.sh
# New in Distro V 5.0 20231030:	- Rename MasTer Toolbox as AMSTer Software
#								- rename Master and Slave as Primary and Secondary (though not possible in some variables and files)
#
# AMSTer: SAR & InSAR Automated Mass processing Software for Multidimensional Time series
# NdO (c) 2016/03/07 - could make better with more functions... when time.
# -----------------------------------------------------------------------------------------
PRG=`basename "$0"`
VER="Distro V5.0 AMSTer script utilities"
AUT="Nicolas d'Oreye, (c)2016-2019, Last modified on Oct 30, 2023"
echo " "
echo "${PRG} ${VER}, ${AUT}"
echo " "

# vvv ----- Hard coded lines to check --- vvv 
source ${PATH_SCRIPTS}/SCRIPTS_MT/__HardCodedLines.sh
	# Get name of the institue $INSTITUTE where computation is performed (defined as a function in __HardCodedLines.sh)
	Institue
# ^^^ ----- Hard coded lines to check --- ^^^ 


PATHTOSET=$1      	# e.g. /.../SAR_SM/MSBAS/Region/seti
PATHTOTXT=$2		# e.g. /.../MSBAS/_Domuyo_S1_Auto_20m_450days/DefoInterpolx2Detrend1_Full.txt

RUNDIR=`dirname ${PATHTOTXT}`
MODE=`basename ${PATHTOTXT}` 
MODENAME=`echo ${MODE} | cut -d . -f1`

cd ${RUNDIR}

echo "ComputeBaselinesPlotFile TableFromMode_${MODENAME}.txt"

if [ `baselinePlot | wc -l` -eq 0 ] 
	then 
		echo "// AMSTer Engine tools from May 2022 does not exist yet"
		echo "// Set Min Bp and Bt to zero and use old tools." 
		VERTOOL="OLD"
	else 
		VERTOOL="NEW"
fi

# Test if new tools exist 
if [ "${VERTOOL}" == "NEW" ]
	then 
		echo " using new tools"
		baselinePlot -r ${PATHTOSET} ${PATHTOTXT}
		
		mv ${PATHTOSET}/baselinePlot_${MODE}.png ${RUNDIR}/baselinePlot_${MODE}.png
		mv ${PATHTOSET}/imageSpatialLocalization_${MODE}.png ${RUNDIR}/imageSpatialLocalization_${MODE}.png
		mv ${PATHTOSET}/restrictedAcquisitionsRepartition.txt_${MODENAME}.txt ${RUNDIR}/restrictedAcquisitionsRepartition.txt_${MODENAME}.txt 
		mv ${PATHTOSET}/restrictedPairSelection_${MODENAME}.txt ${RUNDIR}/restrictedPairSelection_${MODENAME}.txt
 		mv ${PATHTOSET}/baselinePlot.gnuplot ${RUNDIR}/baselinePlot_TableFromMode_${MODENAME}.txt.gnuplot
		rm ${PATHTOSET}/selectedPairsListing.txt
		rm ${PATHTOSET}/selectedAcquisitionsSpatialRepartition.txt

		# make an eps version (renamed by MODENAME) of the png plot
		echo "create low resolution ${MODENAME}.eps version of full resolution baselinePlot_${MODE}.png "
		convert ${RUNDIR}/baselinePlot_${MODE}.png eps3:${RUNDIR}/${MODENAME}.eps		# without eps3: the file would be huge, though with best compatibility... 

	else 
		echo " using old tools"	
		cp ${PATHTOSET}/initBaselines.txt ${RUNDIR}/initBaselines.txt
		
		echo "	Master	Slave	Bperp		Delay" > ${RUNDIR}/TableFromMode_${MODENAME}.txt
		echo ""  >> ${RUNDIR}/TableFromMode_${MODENAME}.txt
		
		while read -r DEGFILE BPREAL MASDATE SLVDATE
			do 
				BT=${DEGFILE#*BT} 
				BT=`echo $BT | cut -d d -f 1`
				BP=`echo ${BPREAL} | cut -d . -f 1`
				echo "${MASDATE}	${SLVDATE}	${BP}		${BT}"  >> ${RUNDIR}/TableFromMode_${MODENAME}.txt
		
		done < ${PATHTOTXT}


		computeBaselinesPlotFile ${RUNDIR}/TableFromMode_${MODENAME}.txt

# X axis is in time format and delay must be given in second
# Y axis origin is the position at the time of first acquisition
${PATHGNU}/gnuplot << EOF
	set xdata time
	set timefmt "%Y%m%d"
	set format x "%d %m %Y"
	set title "Spatial and temporal baselines \nfrom ${MODENAME}"
	set xlabel "Time [dd/mm/yyyy] "
	set ylabel "Position [m]"
	set autoscale
#	set yrange [-2000:2000] 
	
	set ytics font "Helvetica,20" 
	set xtics 15552000 font "Helvetica,20" rotate by 45 right     # every 2 months
#	set xtics 5184000 font "Helvetica,20" rotate by 45 right     # every 2 months
#	set xtics 1209600 font "Helvetica,20" rotate by 45 right     # every 2 weeks
#	set xtics 3456000 font "Helvetica,20" rotate by 45 right     # every two months
#	set xtics 1728000 font "Helvetica,20" rotate by 45 right     # every month
	set mxtics 8 
						
	set output "${MODENAME}.eps" 
	set term postscript color enhanced "Helvetica,20"

	set style arrow 1 back nofilled nohead linetype 3 linecolor rgb "red"  linewidth 2.0 size screen 0.008,90.0,90.0

	set timestamp "Created by AMSTer at ${INSTITUTE} on: %d/%m/%y %H:%M " font "Helvetica,8" textcolor rgbcolor "#2a2a2a" 

	#plot 'dataBaselinesPlot.txt' u 1:2:3:4 with vectors arrowstyle 1 title 'set1'
	plot 'dataBaselinesPlot.txt' u 1:2:3:4 with vectors arrowstyle 1 notitle 
EOF

fi
	
rm -f ${RUNDIR}/initBaselines.txt