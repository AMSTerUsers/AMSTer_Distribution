#!/bin/bash
# -----------------------------------------------------------------------------------------
# This script is aiming at plotting the baseline of all the pairs for which links to deformation 
#   are stored in subdirs of WHERE_MSBAS_IS_PROCESSED/Modes. 
#   Pairs characteristics are taken from first Mode. 
#
#  MUST BE RUN FROM WHERE_MSBAS_IS_PROCESSED
#
# Parameters : - path to SAR_SM/MSBAS/REGION/set"i" where "i" is the first mode in MSBAS processing
#              - mode (as for Prepa_MSBAS.sh; e.g. DefoInterpolx2Detrend)
#              - number of mode in MSBAS processing (given by the number at the end of MODE subdir)
#
# Dependencies:	- gsed
#				- __HardCodedLines.sh
#
# Hard coded:	- Some hard coded info about plot style : title, range, font, color...
#
# New in Distro V 1.0:	- Based on developpement version and Beta V1.2
# New in Distro V 1.1:	- add creation date label
# New in Distro V 2.0:	- make baseline plot with recent tools (nicer plot...)
#						- parallelise the creation of baseline table
#						- rename TableFromMode as TableFromDirMode to clarify that the table is built based on the files in Dir Mode 
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



PATHTOSET=$1      # e.g. /Volumes/hp-1650-Data_Share1/SAR_SM/MSBAS/VVP/set6
MODE=$2		# e.g. DefoInterpolx2Detrend
IEMODE=$3	# e.g. 1

RUNDIR="$(pwd)"
cp ${PATHTOSET}/initBaselines.txt ${RUNDIR}/initBaselines.txt

MODENAME=${MODE}${IEMODE}

cd ${RUNDIR}/${MODENAME}


if [ `baselinePlot | wc -l` -eq 0 ] 
	then 
		echo "// AMSTer Engine tools from May 2022 does not exist yet"
		echo "// Set Min Bp and Bt to zero and use old tools." 
		VERTOOL="OLD"
	else 
		VERTOOL="NEW"
fi

# test sat
#SAT=`ls *deg | head -1 | grep S1 | wc -w`  # 1 if S1, 0 instead

# test nr of CPUs
# Check OS
OS=`uname -a | cut -d " " -f 1 `

case ${OS} in 
	"Linux") 
		NCPU=`nproc` 	;;
	"Darwin")
		NCPU=`sysctl -n hw.ncpu` 
		
		# must define a function because old bash on Mac does not know wait -n option
		waitn ()
		{ StartJobs="$(jobs -p)"
		  CurJobs="$(jobs -p)"
		  while diff -q  <(echo -e "$StartJobs") <(echo -e "$CurJobs") >/dev/null
		  do
		    sleep 1
		    CurJobs="$(jobs -p)"
		  done
		}
		
		;;
esac			

CPU=$((NCPU-1))
echo "Run max ${CPU} processes at a time "



echo "	Master	Slave	Bperp		Delay" > ${RUNDIR}/TableFromDirMode_${MODENAME}.txt
echo ""  >> ${RUNDIR}/TableFromDirMode_${MODENAME}.txt

for img in `ls *deg`
	do 
		if test "$(jobs | wc -l)" -ge ${CPU} 
			then
				case ${OS} in 
					"Linux") 
						wait -n 	;;
					"Darwin")
						waitn		;;
				esac	
		fi
		# Run tests in pseudo parallelism
		{

		MASDATE=${img#*deg_} 
		MASDATE=`echo $MASDATE | cut -d _ -f 1`

		SLVDATE=${img#*deg_} 
		SLVDATE=`echo $SLVDATE | cut -d _ -f 2`

		BP=${img#*Bp} ; 
		BP=`echo $BP | cut -d m -f 1  | xargs printf "%.*f\n" 0`

		BT=${img#*BT} 
		BT=`echo $BT | cut -d d -f 1`

		if [ "${VERTOOL}" == "NEW" ]
			then 
				echo "Dummy	${BP}	${MASDATE}	${SLVDATE}" >> ${RUNDIR}/TableFromDirMode_${MODENAME}.txt
			else 
				echo "${MASDATE}	${SLVDATE}	${BP}		${BT}" >> ${RUNDIR}/TableFromDirMode_${MODENAME}.txt
		fi
		} &
done 
wait 

cd ${RUNDIR}

if [ "${VERTOOL}" == "NEW" ]
	then 
		echo "Compute baselinesPlot from TableFromDirMode_${MODENAME}.txt using new tools"
		baselinePlot -r ${PATHTOSET} ${RUNDIR}/TableFromDirMode_${MODENAME}.txt
		
 		mv ${PATHTOSET}/baselinePlot_TableFromDirMode_${MODENAME}.txt.png ${RUNDIR}/baselinePlot_TableFromDirMode_${MODENAME}.txt.png
 		mv ${PATHTOSET}/imageSpatialLocalization_TableFromDirMode_${MODENAME}.txt.png ${RUNDIR}/imageSpatialLocalization_TableFromDirMode_${MODE}.png
 		mv ${PATHTOSET}/restrictedAcquisitionsRepartition.txt_TableFromDirMode_${MODENAME}.txt ${RUNDIR}/restrictedAcquisitionsRepartition.txt_TableFromDirMode_${MODENAME}.txt 
 		mv ${PATHTOSET}/restrictedPairSelection_TableFromDirMode_${MODENAME}.txt ${RUNDIR}/restrictedPairSelection_TableFromDirMode_${MODENAME}.txt
  		mv ${PATHTOSET}/baselinePlot.gnuplot ${RUNDIR}/baselinePlot_TableFromDirMode_${MODENAME}.txt.gnuplot
 		rm ${PATHTOSET}/selectedPairsListing.txt
 		rm ${PATHTOSET}/selectedAcquisitionsSpatialRepartition.txt

		# make an eps version (renamed by MODENAME) of the png plot
		echo "create low resiolution ${MODENAME}.eps version of full resolution baselinePlot_${MODE}.png "
		convert ${RUNDIR}/baselinePlot_TableFromDirMode_${MODENAME}.txt.png eps3:${RUNDIR}/${MODENAME}_TableFromDirMode.eps		# without eps3: the file would be huge, though with best compatibility... 
		
	else 
		echo "ComputeBaselinesPlotFile TableFromDirMode_${MODENAME}.txt using old tools"
		computeBaselinesPlotFile ${RUNDIR}/TableFromDirMode_${MODENAME}.txt
	
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
#		set yrange [-2000:2000] 
		
		set ytics font "Helvetica,20" 
		set xtics 5184000 font "Helvetica,20" rotate by 45 right     # every 2 months
#		set xtics 1209600 font "Helvetica,20" rotate by 45 right     # every 2 weeks
#		set xtics 3456000 font "Helvetica,20" rotate by 45 right     # every two months
#		set xtics 1728000 font "Helvetica,20" rotate by 45 right     # every month
		set mxtics 8 
						
		set output "span_FlatArrow_${BP}m_${BT}days_${MODENAME}.eps" 
		set term postscript color enhanced "Helvetica,20"

		set style arrow 1 back nofilled nohead linetype 3 linecolor rgb "red"  linewidth 2.0 size screen 0.008,90.0,90.0

		set timestamp "Created by AMSTer at ${INSTITUTE} on: %d/%m/%y %H:%M " font "Helvetica,8" textcolor rgbcolor "#2a2a2a" 

		#plot 'dataBaselinesPlot.txt' u 1:2:3:4 with vectors arrowstyle 1 title 'set1'
		plot 'dataBaselinesPlot.txt' u 1:2:3:4 with vectors arrowstyle 1 notitle 
EOF
	
	rm  ${RUNDIR}/initBaselines.txt
fi



