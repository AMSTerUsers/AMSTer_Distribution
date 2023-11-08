#!/bin/bash
# -----------------------------------------------------------------------------------------
# This script is aiming at plotting the baseline of all the pairs for which raster 
#   are stored in subdirs of MASSPROCESSPATHLONG/GeocodedRasters. 
#   Pairs characteristics are taken from Coh subdir. Why not?  
#
#  MUST BE RUN FROM GeocodedRasters
#  MUST COPY THERE THE initBaselines.txt FILE
#
# Parameters : - none
#
# Dependencies:	- gsed
#               - requires initBaselines.txt that was in MSBAS/set"i" dir 
#				- __HardCodedLines.sh
#
# Hard coded:	- Some hard coded info about plot style : title, range, font, color...
#
# New in Distro V 1.0:	- Based on developpement version and Beta V1.1
# New in Distro V 1.1:	- add creation date label
# New in Distro V 2.0:	- Use hard coded lines definition from __HardCodedLines.sh
# New in Distro V 3.0 20230830:	- Rename SCRIPTS_OK directory as SCRIPTS_MT 
#								- Replace CIS by MT in names 
#								- Renamed FUNCTIONS_FOR_MT.sh
# New in Distro V 4.0 20231030:	- Rename MasTer Toolbox as AMSTer Software
#								- rename Master and Slave as Primary and Secondary (though not possible in some variables and files)
#
# AMSTer: SAR & InSAR Automated Mass processing Software for Multidimensional Time series
# NdO (c) 2016/03/07 - could make better with more functions... when time.
# -----------------------------------------------------------------------------------------
PRG=`basename "$0"`
VER="Distro V4.0 AMSTer script utilities"
AUT="Nicolas d'Oreye, (c)2016-2019, Last modified on Oct 30, 2023"
echo " "
echo "${PRG} ${VER}, ${AUT}"
echo " "

# vvv ----- Hard coded lines to check --- vvv 
source ${PATH_SCRIPTS}/SCRIPTS_MT/__HardCodedLines.sh
	# Get name of the institue $INSTITUTE where computation is performed (defined as a function in __HardCodedLines.sh)
	Institue
# ^^^ ----- Hard coded lines to check --- ^^^ 


if [ ! -s initBaselines.txt ] ; then echo "No initBaselines.txt - can't run" ; exit 0 ; fi

RUNDIR="$(pwd)"

cd Coh

# test sat
SAT=`ls *.ras | head -1 | grep S1 | wc -w`  # 1 if S1, 0 instead

echo "	Master	Slave	Bperp		Delay" > ${RUNDIR}/TableFromRas.txt
echo ""  >> ${RUNDIR}/TableFromRas.txt

if [ ${SAT} == "1" ]
	then  # S1 naming
		for img in `ls *.ras`
			do 
				MASDATE=`echo ${img} | cut -d _ -f 7`
				SLVDATE=`echo ${img} | cut -d _ -f 8`
				BP=`echo ${img} | cut -d _ -f 9 | ${PATHGNU}/gsed "s/Bp//" | ${PATHGNU}/gsed "s/m//" | cut -d . -f 1 `
				BT=`echo ${img} | cut -d _ -f 11 | ${PATHGNU}/gsed "s/BT//" | ${PATHGNU}/gsed "s/days//"`
				echo "${MASDATE}	${SLVDATE}	${BP}		${BT}" >> ${RUNDIR}/TableFromRas.txt
		done 
	else  # all but S1 naming
		for img in `ls *.ras`
			do 
				MASDATE=`echo ${img} | cut -d _ -f 5`
				SLVDATE=`echo ${img} | cut -d _ -f 6`
				BP=`echo ${img} | cut -d _ -f 9 | ${PATHGNU}/gsed "s/Bp//" | ${PATHGNU}/gsed "s/m//" | cut -d . -f 1 `
				BT=`echo ${img} | cut -d _ -f 11 | ${PATHGNU}/gsed "s/BT//" | ${PATHGNU}/gsed "s/days//"`
				echo "${MASDATE}	${SLVDATE}	${BP}		${BT}" >> ${RUNDIR}/TableFromRas.txt
		done 
fi

cd ..

	echo "ComputeBaselinesPlotFile TableFromRas.txt"
	computeBaselinesPlotFile ${RUNDIR}/TableFromRas.txt
	
	# X axis is in time format and delay must be given in second
	# Y axis origin is the position at the time of first acquisition
	${PATHGNU}/gnuplot << EOF
		set xdata time
		set timefmt "%Y%m%d"
		set format x "%d %m %Y"
		set title "Spatial and temporal baselines"
		set xlabel "Time [dd/mm/yyyy] "
		set ylabel "Position [m]"
		set autoscale
#		set yrange [-2000:2000] 
		
		set ytics font "Helvetica,20" 
		set xtics 5184000 font "Helvetica,20" rotate by 45 right     # every 2 months
#		set xtics 1209600 font "Helvetica,20" rotate by 45 right     # every 2 weeks
#		set xtics 3456000 font "Helvetica,20" rotate by 45 right     # every two months
#		set xtics 1728000 font "Helvetica,20" rotate by 45 right     # every month
		set mxtics 8 
						
		set output "span_FlatArrow_${BP}m_${BT}days.eps" 
		set term postscript color enhanced "Helvetica,20"

		set style arrow 1 heads back nofilled linetype 3 linecolor rgb "red"  linewidth 2.0 size screen 0.008,90.0,90.0
		
		set timestamp "Created by AMSTer at ${INSTITUTE} on: %d/%m/%y %H:%M " font "Helvetica,8" textcolor rgbcolor "#2a2a2a" 
		
		#plot 'dataBaselinesPlot.txt' u 1:2:3:4 with vectors arrowstyle 1 title 'set1'
		plot 'dataBaselinesPlot.txt' u 1:2:3:4 with vectors arrowstyle 1 notitle 
EOF
	
