#!/bin/bash
# This script computes the file for the baseline plot makes a baseline plot for one dataset
#
# Parameters :
#		- working directory, with the table and initBaselines textfiles
#			Ex: .../set1
#		- Min, Max spatial and temporal baselines
#
# Dependencies:	- gnuplot 
#				- __HardCodedLines.sh
#
# Hard coded:	- Some hard coded info about plot style : title, range, font, color...
#
#
# New in Distro V 1.0:	- Based on developpement version and Beta V1.1
# New in Distro V 1.1:	- add creation date label
# New in Distro V 2.0:	- Use hard coded lines definition from __HardCodedLines.sh
# New in Distro V 3.0 20230830:	- Rename SCRIPTS_OK directory as SCRIPTS_MT 
#								- Replace CIS by MT in names 
#								- Renamed FUNCTIONS_FOR_MT.sh
#
# MasTer: InSAR Suite automated Mass processing Toolbox. 
# NdO (c) 2016/03/08 - could make better... when time.
# -----------------------------------------------------------------------------------------
PRG=`basename "$0"`
VER="Distro V3.0 MasTer script utilities"
AUT="Nicolas d'Oreye, (c)2016-2019, Last modified on Aug 30, 2023"
echo " "
echo "${PRG} ${VER}, ${AUT}"
echo " "

# vvv ----- Hard coded lines to check --- vvv 
source ${PATH_SCRIPTS}/SCRIPTS_MT/__HardCodedLines.sh
	# Get name of the institue $INSTITUTE where computation is performed (defined as a function in __HardCodedLines.sh)
	Institue
# ^^^ ----- Hard coded lines to check --- ^^^ 


RUNDIR=$1
MinBp=$2 
MaxBp=$3
MinBt=$4 
MaxBt=$5

cd ${RUNDIR}
PAIRSFILE=${RUNDIR}/table_${MinBp}_${MaxBp}_${MinBt}_${MaxBt}.txt

	echo "Pairs File : " ${PAIRSFILE}
	# Compute the file with info for the baselines plot
	echo "ComputeBaselinesPlotFile ${PAIRSFILE}"
	computeBaselinesPlotFile ${PAIRSFILE}
	
	# Change to gnuplot working directory
	echo "Working directory : ${RUNDIR}"
	cd ${RUNDIR}
	
	# X axis is in time format and delay must be given in second
	# Y axis origin is the position at the time of first acquisition
	${PATHGNU}/gnuplot << EOF
		set xdata time
		set timefmt "%Y%m%d"
		set format x "%d %m %Y"
		set title "Spatial and temporal baselines [Max ${MaxBp} m, ${MaxBt} days]"
		set xlabel "Time [dd/mm/yyyy] \n\n To add/remove pair: \n add/remove line in \"table-B_m_i_n-B_m_a_x-T_m_i_n-T_m_a_x.txt\""
		set ylabel "Position [m]"
		set autoscale
#		set yrange [-2000:2000] 
		
		set ytics font "Helvetica,20" 
		set xtics 5184000 font "Helvetica,20" rotate by 45 right     # every 2 months
#		set xtics 1209600 font "Helvetica,20" rotate by 45 right     # every 2 weeks
#		set xtics 3456000 font "Helvetica,20" rotate by 45 right     # every two months
#		set xtics 1728000 font "Helvetica,20" rotate by 45 right     # every month
		set mxtics 8 
						
		set output "span_FlatArrow_${MinBp}_${MaxBp}_${MinBt}_${MaxBt}.eps" 
		set term postscript color enhanced "Helvetica,20"

		set style arrow 1 heads back nofilled linetype 3 linecolor rgb "red"  linewidth 2.0 size screen 0.008,90.0,90.0
		
		set timestamp "Created by MasTer at ${INSTITUTE} on: %d/%m/%y %H:%M " font "Helvetica,8" textcolor rgbcolor "#2a2a2a" 
		
		#plot 'dataBaselinesPlot.txt' u 1:2:3:4 with vectors arrowstyle 1 title 'set1'
		plot 'dataBaselinesPlot.txt' u 1:2:3:4 with vectors arrowstyle 1 notitle 
EOF
	
	

	
