#!/bin/bash
# In a dir that contains MSBAS results in more than one component in sub dir (EW and UD [and NS]), the script will 
# extract the displacement of a given pixel and generate a 3 col txt file : DATE TIME DISPL. 
# A graph is then generated with gnuplot with all the components. It can be plotted on the time series:
#	a line fit, a linear rate and/or a tag with direction of deformation and position of pixels, and 
#   plot several types of events as lines and/or rectangles on the plots (see param below for explanation). 
# If two pixels are provided, it computes also a plot with the double difference.
# Note: Events are plotted only for double differences)
#
# Script must be launched in dir above where msbas data are and naming must be provided.
#
# Note: NS plots were not tested for a while... and not all the options are set for NS
#
# Parameters :	- Remark that was used at the time of running MSBAS.sh and that is used to name the UD and EW dirs
#					i.e. name of zz_comp_REMARKDIR (i.e. _REMARKDIR)
# 				- coordinates of the desired pixel in lines and pixels (as given for instance with Preview)
#              	- if two pixels are generated, it will plot the time series of both pixels as well as the double difference
#				- last parameters are an optional (unsorted) combination of 
#					-f (to add linear trend on plot), 
#					-r (to display the trend rate in cm/yr on plot), 
#					-t (to display a tag with direction of displacement for double difference), 
#					-g (delete gnuplot scripts)
#					-png (create png versions of some plots)
#					-d (delete text files of TS values for both pixels),
#					-D (delete text files of TS values for both pixels AND  text file of TS values for Double Difference), or 
#					-events=PATHTOEVENTSDIR where PATHTOEVENTSDIR is a dir that contains files with ascii tables listing the various type of events to
#					 add on the plot; e.g. /.../EVENTS_TABLES/VVP that contains EQ_VVP.txt, Eruptions_VVP.txt etc.... 
#					 Note: Events tables must be named as one or more of the following where NAME is the name of the area (must be the name of 
#					      the DIR that contains all the event files, e.g. ../EVENTS_TABLES/NAME/): 
# 						  Events are pin pointed on the plot in the form of vertical lines or rectangles based on 
# 						  provided ascii tables, i.e. (Site is a param related target name) :
# 							- Eruptions_NAME.txt	(vertical red rectangles) 
# 							- EQ_Swarms_NAME.txt	(vertical blue rectangles) 
# 							- Asymetric_Acquisition_NAME.txt	(vertical light grey rectangles) 
# 							- EQ_NAME.txt			(vertical blue dashed lines)  
#							- Other_events_NAME.txt	(vertical grey dashed lines)
#						  Note that these tables MUST be in the form of "Name	StartDate	StopDate" where dates are YYYYMMDD and fields are separated by tab
# 						  Additinal marks can be plotted horizontally based on additional tables i.e.: 
# 							- Sat_Cover_NAME.txt	(horizontal red and blue rectangles for Asc and Desc respectively) 
# 							- Polarisation_Change_NAME.txt (horizontal grey rectangles)
# 						  Note that these tables MUST be in the form of "Name	Date" where date is YYYYMMDD and fields are separated by tab
# 						  and were Name MUST be WHATEVER_Asc or WHATEVER_Desc to be detected as sat geometry and color coded accordingly
#					-start=YYYYMMDD -stop=YYYYMMDD restricts the plot to corresponding time span 
#					-coh=option (to draw mean coh as pseudo error bars or boxes on single pixel eps figs), where option is either 
#						  avgavg, avgmin, avgminmax or avgavgminmax (to plot data +- Mean and/or Min and/or Max coherence. Coh is /100 for scaling on fig). Larger the box is the best.
#						  Note that it does not plot that for the double difference because it would be too messy in the plot.
#						  The nr of pairs used for coherence statistics is color coded as squared points at y=0.
#						  This may be a very slow uption when run for first time. Faster after because it is incremental. 
#
#
# Dependencies : - function getLineThroughStack (MasTer Engine utilities)
#                - gnuplot
#                - gnu plot template  plotTS_template_multi.gnu or  plotTS_template_multi_fit.gnu
#				And for adding Legend with direction of deformation
#				 - TS_AddLegend_LOS.sh, TimeSeriesInfo_HP.sh, AmpDefo_map.sh
#				 - Python + Numpy + script: CreateColorFrame.py, Mask_Builder.py
#				 - figures and paramerters file in ${PATH_SCRIPTS}/SCRIPTS_MT/TSCombiFiles/
#				 - gnu stat (gstat) e.g. from coreutils
#				- __HardCodedLines.sh
#
# Hard coded:	- Some hard coded info about plot style : title, range, font, color...
#				- path to template (plotTS_template_multi...). One may want to change also plot style in there
#
# New in Distro V 1.0:	- Based on developpement version and Beta V2.0
# New in Distro V 1.1:	- perform linear fit if option -f added at the end
# New in Distro V 1.2:	- bug fix for -f and add last date in title 
# New in Distro V 1.3:	- ensure that time series is not null when request fit. If yes, do not fit
# New in Distro V 2.0:	- better compare min/max to avoid prblm when curve is negative only
#		 Distro V 2.1:	- remove transparency option "-alpha remove" from convert (because may crash on linux; maybe must be "-alapha off" on recent convert versions)
#		 Distro V 3.0:	- Add tag with direction of displacement for double difference (by M. Jaspard)
#		 Distro V 3.1:	- Display Linear trend on plot (cm/yr) if option -t (attention year is rounded to 31.536.000 sec, i.e. neglect leap year) 
#						- Set optional tag for doubble difference  
#						- clean fit.log
#		 Distro V 4.0:	- allows adding tags with events
#						- change option -e in -r to avoid possible confusion
#						- change way to detect options -f -r -t 
#		 Distro V 4.1:	- less gnu template; small bugs in option testing
#						- secure fit.log to avoid overwritng or mixing if several run at the same time 
#		 Distro V 4.2:	- allows limiting time span of displayed time series using -start= and -stop= otpions 
#						- improve vertical bar for events
#		 Distro V 5.0:	- add option to draw coh as error bars using param -coh in EW comp of first pixel only
#		 Distro V 5.1:	- add option to draw coh as error bars and/or boxes using param -coh=option, where option is either avgavg, avgmin, avgminmax or avgavgminmax (to plot data +- Mean, Min or Max coh /100)
#						- do it for second pixel as well, but not for double difference because it would be too messy in the plot
#		 Distro V 5.2:	- add time series with nr of pairs used for coherence statistics if -coh=option is chosen. This is color coded as a time series of squared pixels at y=0
#		 Distro V 6.0:	- path to GNUTEMPLATENOFIT and GNUTEMPLATEFIT the same way now for Mac and Linux
#		 Distro V 6.1:	- limit search of EPSFILE to dir and not subdir
# New in Distro V 6.2: - remove stray \ before _ while calling grep to cope with new grep syntax and avoid waring
#		 Distro V 6.3: - use gdate instead of date. Just in case. 
# New in Distro V 7.0:	- Use hard coded lines definition from __HardCodedLines.sh
# New in Distro V 7.1: - replace if -s as -f -s && -f to be compatible with mac os if 
# New in Distro V 8.0 20230830:	- Rename SCRIPTS_OK directory as SCRIPTS_MT 
#								- Replace CIS by MT in names 
#								- Renamed FUNCTIONS_FOR_MT.sh
#
# MasTer: InSAR Suite automated Mass processing Toolbox. 
# NdO (c) 2016/03/08 - could make better... when time.
# -----------------------------------------------------------------------------------------
PRG=`basename "$0"`
VER="Distro V8.0 MasTer script utilities"
AUT="Nicolas d'Oreye, (c)2016-2019, Last modified on Aug 30, 2023"
echo " "
echo "${PRG} ${VER}, ${AUT}"
echo " "

# vvv ----- Hard coded lines to check --- vvv 
source ${PATH_SCRIPTS}/SCRIPTS_MT/__HardCodedLines.sh
	# Get name of the institue $INSTITUTE where computation is performed (defined as a function in __HardCodedLines.sh)
	Institue
	# Get the templates for plotting with or without fit
	TemplatesGnuForPlotMultiWOfit
# ^^^ ----- Hard coded lines to check --- ^^^ 

# Check OS
OS=`uname -a | cut -d " " -f 1 `
echo "Running on ${OS}"
echo

RNDM=`echo $(( $RANDOM % 10000 ))`

if [ $# -lt 3 ] ; then 
	echo "Usage $0 REMARKDIR LIN PIX [LIN PIX] [-f -r -t -events=PATH -d -D -g -png] " 
	echo " Where options are:"
	echo "	-f : fit a linear trend "
	echo "	-r : display the annual rate "
	echo "	-t : add a tag with direction of displacement and pixels location"
	echo "	-d : delete text files of TS values for both pixels after completion"
	echo "	-D : delete text files of TS values for both pixels AND  text file of TS values for Double Difference after completion"
	echo "	-g : delete gnuplot scripts after completion "
	echo "	-png : create png versions of some plots "	
	echo " 	-events=PATH : path to ascii table of events to plot on figures, where PATH is e.g. ../EVENTS_TABLES/NAME/ and NAME is the name of area which is also in events table names"
	echo "	-start=YYYYMMDD -stop=YYYYMMDD restricts the plot to corresponding time span "	
	echo "  -coh=option : add coh as error bars and/or boxes (lagrer is the best!); option is either avgavg, avgmin, avgminmax or avgavgminmax to plot data +- Mean and/or Min and/or Max coh. Coh is /100 for scaling"
	echo ""
	exit
fi


RUNDIR=`pwd`

REMARKDIR=$1

# Filst pixel
if [[ $2 =~ ^[0-9]+$ ]] ; then LIN1=$2 ; else echo "Must provide a Line coord in Parameter 2" ; exit 0 ; fi
if [[ $3 =~ ^[0-9]+$ ]] ; then PIX1=$3 ; else echo "Must provide a Pixel coord in Parameter 3" ; exit 0 ; fi

# second pixel (optional)
if [ $# -eq 3 ] ; then TWOPIXELS="NO" ; fi
if [[ $4 =~ ^[0-9]+$ ]] ; then LIN2=$4 ; else TWOPIXELS="NO" ; fi
if [[ $5 =~ ^[0-9]+$ ]] ; then PIX2=$5 ; TWOPIXELS="YES" ; else TWOPIXELS="NO" ; fi

# Search for options 
#####################
	# first let's see if one of the param contains the string -event=, which would mean that you want to plot tags with events on the time series
	if [[ "${@#-events=}" = "$@" ]]
		then
			echo "Do not request plotting events on TS plot"
			ADDEVENTS="NO"
		else
			echo "Request plotting events on TS plot" #Found -events= hence extract string after =
			#param=`echo "$@" | cut -d "=" -f 2  | cut -d " " -f 1`  			# not robust if there is another = in string of param
			EVENTSPATH=`echo "$@" | ${PATHGNU}/gsed  's/.*-events=//'  | cut -d " " -f 1`	# get everything after -events= and before next " "
			echo "List of events are supposed to be in ${EVENTSPATH}"
			# events info
			SITENAME=`basename ${EVENTSPATH}`
			ADDEVENTS="YES"
	fi

	# check if request fit
	if [[ "${@#-f}" = "$@" ]]
		then
			echo "Do not request linear fit"
			LINFIT="NO"
			LINRATE="NO"
		else
			echo "Request linear fit"
			LINFIT="YES"
	# check if request rate 
			if [[ "${@#-r}" = "$@" ]]
				then
					echo "Do not request linear fit rate"
					LINRATE="NO"
				else
					echo "Request linear fit rate"
					LINRATE="YES"
			fi
	fi

	# check if request tag with direction of defo and position of pixels
	if [[ "${@#-t}" = "$@" ]]
		then
			echo "Do not request tag"
			TAG="NO"
		else
			echo "Request tag"
			TAG="YES"
	fi


	# check if delete only text files of separate TS
	if [[ "${@#-D}" = "$@" ]]
		then
			# check if delete only text files of separate TS
			if [[ "${@#-d}" = "$@" ]]
				then
					echo "Do not request deleting pixels' time series values"
					DELPIXVAL="NO"
					DELDDVAL="NO"
				else
					echo "Request deleting pixels' time series values"
					DELPIXVAL="YES"
					DELDDVAL="NO"
			fi
		else
			echo "Request deleting double difference and separate pixels' time series values"
			DELPIXVAL="YES"
			DELDDVAL="YES"
	fi

	# check if delete gnu scripts used to make the plots
	if [[ "${@#-g}" = "$@" ]]
		then
			echo "Do not request deleting gnuplot scripts"
			DELGNU="NO"
		else
			echo "Request deleting gnuplot scripts"
			DELGNU="YES"
	fi

	# check if need png plots
	if [[ "${@#-png}" = "$@" ]]
		then
			echo "Do not request png plots"
			PNGPLOT="NO"
		else
			echo "Request png plots"
			PNGPLOT="YES"
	fi

	# check if need restricting time span
	if [[ "${@#-start=}" = "$@" ]] 
		then
			SPAN1="NO"
			STARTSPAN="BEGINNING OF RECORDS"
			STARTSPANSEC="\*"
		else
			SPAN1="YES"
			STARTSPAN=`echo "$@" | ${PATHGNU}/gsed  's/.*-start=//'  | cut -d " " -f 1`	# get everything after -start= and before next " "
			STARTSPANSEC=`${PATHGNU}/gdate -d "${STARTSPAN}" +%s --utc`
	fi

	if [[ "${@#-stop=}" = "$@" ]] 
		then
			SPAN2="NO"
			STOPSPAN="END OF RECORDS"
			STOPSPANSEC="\*"
		else
			SPAN2="YES"
			STOPSPAN=`echo "$@" | ${PATHGNU}/gsed  's/.*-stop=//'  | cut -d " " -f 1`	# get everything after -stop= and before next " "
			STOPSPANSEC=`${PATHGNU}/gdate -d "${STOPSPAN}" +%s --utc`
	fi
	if [ ${SPAN1} == "YES" ] || [ ${SPAN2} == "YES" ]
		then 
			SPAN="YES"
			echo "Request restricting time span of TS plot from ${STARTSPAN} to ${STOPSPAN}"
		else 
			SPAN="NO"
	fi

	# check if need coh error bars
	if [[ "${@#-coh=}" = "$@" ]]
		then
			echo "Do not request coh as error bars"
			ERR="NO"
		else
			echo "Request coh as error bars. Beware: it can be very slow at first run ! Process is incremental and do not recompute coh when already present though"
			ERR="YES"
			OPTERR=`echo "$@" | ${PATHGNU}/gsed  's/.*-coh=//'  | cut -d " " -f 1`  # get everything after -coh= and before next " ", either avgavg, avgmin, avgminmax or avgavgminmax
			# list all coh dirs ; one per mode
			#nr of modes
			NRMODES=`${PATHGNU}/gfind . -maxdepth 1 -type d -name "Defo*" | wc -l`
			MODES=`${PATHGNU}/gfind . -maxdepth 1 -type d -name "Defo*" | head -1 | ${PATHGNU}/gsed 's/[0-9]\+$//' | cut -d "/" -f2`  # remove trailing numbers
			#echo "Search coh for ${NRMODES} modes ${MODES} "

			# search path to coh files for each mode
			for i in $(seq 1 ${NRMODES})	
				do
					#search first file to get the path to coh dir
					FIRST=`files=(${RUNDIR}/${MODES}${i}/deformationMap*) ; echo "${files[0]}"`
					COHDIRFILE[${i}]=`readlink -f  ${FIRST}`
					COHDIR=`dirname ${COHDIRFILE[${i}]}`
					COHDIR[${i}]=`echo ${COHDIR} | ${PATHGNU}/gsed 's/'${MODES}'/Coh/'`
			done

			# create a dir (if not done yet) wzere to store the coh files
			mkdir -p ${RUNDIR}/zzz_coh_per_pixels
	fi

echo ""

# Define some functions for plotting events 
############################################

	# Function to plot vertical rectangles
	function LoadRectangles()
		{
		unset DATEFILES 
		unset COLOR
		unset KEY
		DATEFILES=$1
		COLOR=$2 	# eg red
		KEY=$3		# eg ERUPTIONS_TABLE
	
		if [ -f "${DATEFILES}" ] && [ -s "${DATEFILES}" ] 
			then 
				# Table exists. Read it and transform each date (@ 12h) in sec using 
				# then store all things to cat in gnu template as TMPTABLE_${RNDM}.txt to be inserted in gnu template where KEY string is located
				#rm -f TMPTABLE_${RNDM}.txt
				while IFS=$'\t' read -r EVENTNAME STARTDATE STOPDATE  # i.e. read tab separated columns
					do 
						STOPDATESEC=`${PATHGNU}/gdate -d "${STOPDATE} 12:00:00" +%s --utc`
						if [ "${STARTDATE}" == "${STOPDATE}" ]
							then
								STARTDATESEC=`${PATHGNU}/gdate -d "${STARTDATE}" +%s --utc`
								# make color stronger when very short duration to be spotted on plot
								echo "set obj rect from ${STARTDATESEC}, graph 0 to ${STOPDATESEC}, graph 1 fc rgbcolor \"${COLOR}\" fs solid 0.95 noborder behind " >> TMPTABLE_${RNDM}.txt
							else 
								# make color lighter when long duration
								STARTDATESEC=`${PATHGNU}/gdate -d "${STARTDATE} 12:00:00" +%s --utc`
								echo "set obj rect from ${STARTDATESEC}, graph 0 to ${STOPDATESEC}, graph 1 fc rgbcolor \"${COLOR}\" fs solid 0.35 noborder behind" >> TMPTABLE_${RNDM}.txt
						fi
						# If you want to add a label:
						# remove underscores which would be interpreted by gnoplot
						EVENTNAME=`echo ${EVENTNAME} | ${PATHGNU}/gsed 's/_/ /g' `
						echo "set label \"${EVENTNAME}\" at  ${STARTDATESEC}, graph 0.25 rotate by 90 right" >> TMPTABLE_${RNDM}.txt
					
				done < ${DATEFILES}

				# inserted TMPTABLE_${RNDM}.txt in gnu template where ERUPTION_TABLE string is located
				${PATHGNU}/gawk '/'\#${KEY}'/{system("cat TMPTABLE_'${RNDM}'.txt");next}1' plotTS_${LIN1}_${PIX1}_${LIN2}_${PIX2}_multi${REMARKDIR}_events.gnu > plotTS_${LIN1}_${PIX1}_${LIN2}_${PIX2}_multi${REMARKDIR}_events.gnu.tmp
				mv plotTS_${LIN1}_${PIX1}_${LIN2}_${PIX2}_multi${REMARKDIR}_events.gnu.tmp plotTS_${LIN1}_${PIX1}_${LIN2}_${PIX2}_multi${REMARKDIR}_events.gnu
				rm -f  TMPTABLE_${RNDM}.txt
		fi
		}

	# Function to plot vertical rectangles
	function LoadRectanglesHoriz()
		{
		unset DATEFILES 
		unset KEY
		unset VERTOFFSET
		DATEFILES=$1
		KEY=$2			# e.g. SATCOVER_TABLE
		VERTOFFSET=$3	# e.g. 0.98
		
		if [ -f "${DATEFILES}" ] && [ -s "${DATEFILES}" ] 
			then 
				# Table exists. Read it and transform each date (@ 12h) in sec using 
				# then store all things to cat in gnu template as TMPTABLE_${RNDM}.txt to be inserted in gnu template where KEY string is located
				#rm -f TMPTABLE_${RNDM}.txt
				while IFS=$'\t' read -r EVENTNAME STARTDATE STOPDATE  # i.e. read tab separated columns
					do 
						GEOM=`echo ${EVENTNAME} | cut -d_ -f 2`
						# remove underscores which would be interpreted by gnoplot
						EVENTNAME=`echo ${EVENTNAME} | ${PATHGNU}/gsed 's/_/ /g' `
						if [  "${GEOM}" == "Asc" ]
							then 
								echo "${EVENTNAME} is Ascending, hence color will be blue"
								COLOR="#0000FF"
								RECTOFFSET=0.02
							elif [ "${GEOM}" == "Desc" ] ; then
								echo "${EVENTNAME} is Descending, hence color will be red"
								COLOR="#8B2252"
								RECTOFFSET=0.02
							else 
								echo "${EVENTNAME} is Not a sat orbit, hence color will be black"
								COLOR="#000000"
								ROTATE="rotate by 90 right"
								RECTOFFSET=0
						fi
						#echo "DEBUG ${DATEFILES} : ${STARTDATE} -lt ${FIRSTDATE} or ${STOPDATE} -gt ${LASTDATE}"
						if [ ${STARTDATE} -lt ${FIRSTDATE} ] ; then STARTDATE=${FIRSTDATE} ; fi
						if [ ${STOPDATE} -gt ${LASTDATE} ] ; then STOPDATE=${LASTDATE} ; fi
						STARTDATESEC=`${PATHGNU}/gdate -d "${STARTDATE} 12:00:00" +%s --utc`
						STOPDATESEC=`${PATHGNU}/gdate -d "${STOPDATE} 12:00:00" +%s --utc`
					
						# make color stronger when very short duration to be spotted on plot
						VERTOFFSET=`echo "${VERTOFFSET} - ( ${RECTOFFSET} )" | bc -l`
						VERTOFFSETMAX=`echo "${VERTOFFSET} + 0.02 " | bc -l`
						echo "set obj rect from ${STARTDATESEC}, graph 0${VERTOFFSET} to ${STOPDATESEC}, graph 0${VERTOFFSETMAX} fc rgb \"${COLOR}\" fs solid 0.15 noborder behind" >> TMPTABLE_${RNDM}.txt
						LABELVERTOFFSET=`echo "${VERTOFFSET} + 0.01" | bc`
						LABELHORIZOFFSET=`echo "${STARTDATESEC} + (( ${STOPDATESEC} - ${STARTDATESEC} ) /2 ) " | bc`
						echo "set label \"${EVENTNAME}\" at  ${LABELHORIZOFFSET}, graph 0${LABELVERTOFFSET} ${ROTATE}" >> TMPTABLE_${RNDM}.txt
						LASTOFFSET=`echo "${VERTOFFSET} - ( ${RECTOFFSET} )" | bc -l`
				done < ${DATEFILES}

				# inserted TMPTABLE_${RNDM}.txt in gnu template where ERUPTION_TABLE string is located
				${PATHGNU}/gawk '/'\#${KEY}'/{system("cat TMPTABLE_'${RNDM}'.txt");next}1' plotTS_${LIN1}_${PIX1}_${LIN2}_${PIX2}_multi${REMARKDIR}_events.gnu > plotTS_${LIN1}_${PIX1}_${LIN2}_${PIX2}_multi${REMARKDIR}_events.gnu.tmp
				mv plotTS_${LIN1}_${PIX1}_${LIN2}_${PIX2}_multi${REMARKDIR}_events.gnu.tmp plotTS_${LIN1}_${PIX1}_${LIN2}_${PIX2}_multi${REMARKDIR}_events.gnu
				rm -f  TMPTABLE_${RNDM}.txt
		fi
		}


	# Function to plot vertical bars
	function LoadVerticalBar()
		{
		unset DATEFILES 
		unset KEY
		unset COLOR
		DATEFILES=$1
		KEY=$2		# e.g. EQ_TABLE
		COLOR=$3	# e.g. 0.98
	
		if [ -f "${DATEFILES}" ] && [ -s "${DATEFILES}" ] 
			then 
				# Table exists. Read it and transform each date (@ 12h) in sec using 
				# then store all things to cat in gnu template as TMPTABLE_${RNDM}.txt to be inserted in gnu template where KEY string is located
				#rm -f TMPTABLE_${RNDM}.txt
				while IFS=$'\t' read -r EVENTNAME STARTDATE   # i.e. read tab separated columns
					do 
						STARTDATESEC=`${PATHGNU}/gdate -d "${STARTDATE} 12:00:00" +%s --utc`
					
						#echo "set obj rect from ${STARTDATESEC}, graph 0${VERTOFFSET} to ${STOPDATESEC}, graph 0${VERTOFFSETMAX} fc rgb \"${COLOR}\" fs solid 0.15 behind" >> TMPTABLE_${RNDM}.txt
#						echo "set arrow from ${STARTDATESEC},${MIN} to ${STARTDATESEC},${MAX} nohead lc rgb \"${COLOR}\" lt 1 lw 2 dt 2  " >> TMPTABLE_${RNDM}.txt
						echo "set arrow from ${STARTDATESEC}, graph 0 to ${STARTDATESEC}, graph 1 nohead lc rgb \"${COLOR}\" lt 1 lw 2 dt 2  " >> TMPTABLE_${RNDM}.txt
						
						# remove underscores which would be interpreted by gnoplot
						EVENTNAME=`echo ${EVENTNAME} | ${PATHGNU}/gsed 's/_/ /g' `
						echo "set label \"${EVENTNAME}\" at  ${STARTDATESEC}, graph 0.15 ${ROTATE}" >> TMPTABLE_${RNDM}.txt
				done < ${DATEFILES}

				# inserted TMPTABLE_${RNDM}.txt in gnu template where ERUPTION_TABLE string is located
				${PATHGNU}/gawk '/'\#${KEY}'/{system("cat TMPTABLE_'${RNDM}'.txt");next}1' plotTS_${LIN1}_${PIX1}_${LIN2}_${PIX2}_multi${REMARKDIR}_events.gnu > plotTS_${LIN1}_${PIX1}_${LIN2}_${PIX2}_multi${REMARKDIR}_events.gnu.tmp
				mv plotTS_${LIN1}_${PIX1}_${LIN2}_${PIX2}_multi${REMARKDIR}_events.gnu.tmp plotTS_${LIN1}_${PIX1}_${LIN2}_${PIX2}_multi${REMARKDIR}_events.gnu
				rm -f  TMPTABLE_${RNDM}.txt
		fi
		}

	# Function to Launch Event plotting
	function PlotEvents()
		{
		if [ ${ADDEVENTS} == "YES" ] ; then 
			# Vertical rectangles
			# Eruptions
			LoadRectangles ${EVENTSPATH}/Eruptions_${SITENAME}.txt red ERUPTIONS_TABLE
			# EQ swarms
			LoadRectangles ${EVENTSPATH}/EQ_Swarms_${SITENAME}.txt blue EQSWARMS_TABLE
			# Asymetric acquisition geometry, i.e. Asc or Desc weak
			LoadRectangles ${EVENTSPATH}/Asymetric_Acquisition_${SITENAME}.txt grey ASYMACQ_TABLE

			# Horizontal rectangles
			# Sat Cover
			LoadRectanglesHoriz ${EVENTSPATH}/Sat_Cover_${SITENAME}.txt SATCOVER_TABLE 0.98
			# Pol Change
			if [ `echo ${LASTOFFSET} | wc -c` -eq 1 ] ; then LASTOFFSET="0.96" ; fi
			LoadRectanglesHoriz ${EVENTSPATH}/Polarisation_Change_${SITENAME}.txt POLCHANGE_TABLE ${LASTOFFSET}  # get offset from previous set of label, i.e. Sat_Cover 

			# Vertical bars
			# EQ list
			LoadVerticalBar ${EVENTSPATH}/EQ_${SITENAME}.txt EQ_TABLE \#1E90FF  # get offset from previous set of label, i.e. Sat_Cover 
			# Other events
			LoadVerticalBar ${EVENTSPATH}/Other_events_${SITENAME}.txt OTHER_TABLE \#008B8B  # get offset from previous set of label, i.e. Sat_Cover 
		else 
			echo "No Plot Events"
		fi 
		}

	# Function to Launch Event plotting
	function GetMeanCohAtPix()
		{
		unset LIN 
		unset PIX
		unset MODETS
		unset LINB 
		unset PIXB
		LIN=$1
		PIX=$2		
		MODETS=$3

		# given the time to get the coherences, it is more efficent to do the two pixels in one function if required
		if [ ${TWOPIXELS} == "YES" ] ; then
			LINB=$4
			PIXB=$5		
		fi
	
		mkdir -p ${RUNDIR}/_TMP.$$

		while IFS="	" read -r EACHDATE DUMMY1 DUMMY2
		do	
			echo "Process ${EACHDATE} "
			if [ `cat ${RUNDIR}/zzz_coh_per_pixels/coh_${LIN}_${PIX}${REMARKDIR}.txt 2>/dev/null | wc -l` -eq 0 ] 
				then 
					echo "zzz_coh_per_pixels/coh_${LIN}_${PIX}${REMARKDIR}.txt does ot exist; Create it and add header" 
					echo "IMG      AVGcoh   MAS       SLV     MINcoh   MAS        SLV     MAXcoh   NUMpairs" > ${RUNDIR}/zzz_coh_per_pixels/coh_${LIN}_${PIX}${REMARKDIR}.txt
			
			fi 
			
			if [ ${TWOPIXELS} == "YES" ] ; then
				if [ `cat ${RUNDIR}/zzz_coh_per_pixels/coh_${LINB}_${PIXB}${REMARKDIR}.txt 2>/dev/null | wc -l` -eq 0 ] 
					then 
						echo "zzz_coh_per_pixels/coh_${LINB}_${PIXB}${REMARKDIR}.txt does ot exist; Create it and add header" 
						echo "IMG      AVGcoh   MAS       SLV     MINcoh   MAS        SLV     MAXcoh   NUMpairs" > ${RUNDIR}/zzz_coh_per_pixels/coh_${LINB}_${PIXB}${REMARKDIR}.txt
			
				fi 
			fi
			
			if [ `cat ${RUNDIR}/zzz_coh_per_pixels/coh_${LIN}_${PIX}${REMARKDIR}.txt 2>/dev/null | cut -c 1-8 | ${PATHGNU}/grep ${EACHDATE} | wc -l` -gt 0 ] 
				then 
					echo "${EACHDATE} already in zzz_coh_per_pixels/coh_${LIN}_${PIX}${REMARKDIR}.txt; skip computing avg "
					if [ ${TWOPIXELS} == "YES" ] 
						then 
							if [ `cat ${RUNDIR}/zzz_coh_per_pixels/coh_${LINB}_${PIXB}${REMARKDIR}.txt 2>/dev/null | cut -c 1-8 | ${PATHGNU}/grep ${EACHDATE} | wc -l` -eq 0 ] 
								then 
									echo "${EACHDATE} OK for pix 1 but not yet in zzz_coh_per_pixels/coh_${LINB}_${PIXB}${REMARKDIR}.txt; computing avg "
									RECOMP="YES"
								else
									echo "${EACHDATE} already in zzz_coh_per_pixels/coh_${LINB}_${PIXB}${REMARKDIR}.txt; skip computing avg "
									RCOMP="NO"
							fi
						else
							RECOMP="NO"	
					fi
				else 
					RECOMP="YES"
			fi
			if [ "${RECOMP}" == "YES" ] ; then
				# i.e. if image not tested yet
					# get the coh files using at least one of the image in pair at date in each mode
					for i in $(seq 1 ${NRMODES})	
						do
							echo "  in mode ${COHDIR[${i}]}"
							for COHFILES in `${PATHGNU}/gfind ${COHDIR[${i}]} -maxdepth 1 -type f -name "*${EACHDATE}*" 2> /dev/null`
								do
									echo "...Search coh in file ${COHFILES}"
									PAIR=`echo "${COHFILES}" | ${PATHGNU}/grep -Eo "_[0-9]{8}_[0-9]{8}" ` # select _date_date_ where date is 8 numbers
									extension="${COHFILES##*.}"
									if [ "${extension}" == "hdr"  ]
										then 
											cp ${COHFILES} ${RUNDIR}/_TMP.$$/MSBAS${PAIR}.bin.hdr
										else 
											cp ${COHFILES} ${RUNDIR}/_TMP.$$/MSBAS${PAIR}.bin
									fi
							done

					done 
		
					# get the coh value of each of these coh images at pixel and store in timeMine_${LIN1}_${PIX1}.txt
					getLineThroughStack ${RUNDIR}/_TMP.$$ ${LIN} ${PIX}
					# get the average value of coh for that pixel in each coh map using the date
					TARGET=`echo ${RUNDIR}/_TMP.$$/timeLine${LIN}_${PIX}.txt`
					#AVG=`${PATHGNU}/gawk -v target="${TARGET}" '{sum+=$3} END {print sum/NR} target' `
					AVG=`${PATHGNU}/gawk -F '	' '{sum+=$3} END {print sum/NR}'  ${TARGET} `
					MAXCOH=`cat ${TARGET} | sort -nk3,3 | tail -1` # get max of 3rd col
					MINCOH=`cat ${TARGET} | sort -nk3,3 | head -1 | ${PATHGNU}/gsed "s% 0.000000 % nan %g" ` # get min of 3rd col and repalce null coh by nan if any
					NUMCOH=`cat ${TARGET} | wc -l` # get nr of lines, i.e. nr of coh files
					echo "AVG for ${EACHDATE} pixel 1 is ${AVG}"		
					# store results in file
					echo "${EACHDATE} ${AVG} ${MINCOH} ${MAXCOH} ${NUMCOH} " >> ${RUNDIR}/zzz_coh_per_pixels/coh_${LIN}_${PIX}${REMARKDIR}.txt  # i.e. DATE AVGcoh  MAS SLV MINcoh MAS SLV MAXcoh NUMPAIRS, where MAS SLV are dates of pair for which coh is min or max ; note that SLV is given without DD because of getLineThroughStack which normally delivers TIME as HHMMSS
					
					if [ ${TWOPIXELS} == "YES" ] ; then 
						# get the coh value of each of these coh images at pixel and store in timeMine_${LIN1}_${PIX1}.txt
						getLineThroughStack ${RUNDIR}/_TMP.$$ ${LINB} ${PIXB}
						# get the average value of coh for that pixel in each coh map using the date
						TARGETB=`echo ${RUNDIR}/_TMP.$$/timeLine${LINB}_${PIXB}.txt`
						#AVG=`${PATHGNU}/gawk -v target="${TARGET}" '{sum+=$3} END {print sum/NR} target' `
						AVGB=`${PATHGNU}/gawk -F '	' '{sum+=$3} END {print sum/NR}'  ${TARGETB} `
						MAXCOHB=`cat ${TARGETB} | sort -nk3,3 | tail -1` # get max of 3rd col
						MINCOHB=`cat ${TARGETB} | sort -nk3,3 | head -1 | ${PATHGNU}/gsed "s% 0.000000 % nan %g" ` # get min of 3rd col and repalce null coh by nan if any
						NUMCOHB=`cat ${TARGETB} | wc -l` # get nr of lines, i.e. nr of coh files
						echo "AVG for ${EACHDATE} pixel 2 is ${AVGB}"		
						# store results in file
						echo "${EACHDATE} ${AVGB} ${MINCOHB} ${MAXCOHB} ${NUMCOHB} " >> ${RUNDIR}/zzz_coh_per_pixels/coh_${LINB}_${PIXB}${REMARKDIR}.txt  # i.e. DATE AVGcoh  MAS SLV MINcoh MAS SLV MAXcoh NUMPAIRS, where MAS SLV are dates of pair for which coh is min or max ; note that SLV is given without DD because of getLineThroughStack which normally delivers TIME as HHMMSS
					fi
					
					rm -f ${RUNDIR}/_TMP.$$/*			
			fi
			
		done < zz_${MODETS}${REMARKDIR}/timeLine_${MODETS}_${LIN}_${PIX}${REMARKDIR}.txt  # only one pix is enough because it only needs the date, wich is teh same for Pix1 and Pix2
		sort -n -u -o ${RUNDIR}/zzz_coh_per_pixels/coh_${LIN}_${PIX}${REMARKDIR}.txt ${RUNDIR}/zzz_coh_per_pixels/coh_${LIN}_${PIX}${REMARKDIR}.txt  # sort by numbers (-n) in place  (-o)
		if [ ${TWOPIXELS} == "YES" ] ; then  
			sort -n -u -o ${RUNDIR}/zzz_coh_per_pixels/coh_${LINB}_${PIXB}${REMARKDIR}.txt ${RUNDIR}/zzz_coh_per_pixels/coh_${LINB}_${PIXB}${REMARKDIR}.txt  # sort by numbers (-n) in place  (-o)
		fi
		
		rm -Rf ${RUNDIR}/_TMP.$$
		
		}		


	function TitleCmdLineMeanCohAtPix()
		{
		unset LIN 
		unset PIX
		LIN=$1
		PIX=$2		

		# Note the double or triple backslashes to avoid being interpreted during string manipulation in the script
		# NOTE: syntax for usage with boxes and bars 1:2:3:4:5 is 1=x (time here), 2=bottom of box (EW data here), 3=bottom of bar (data - MinCoh here), 4=top of bar (data + MaxCoh here) ,5=top of box (data +AvgCoh here)
		# remember that file with data conatains: DATE HHMMSS EW DATE AVGcoh MINcoh MAXcoh NRcoh
		echo "You chose coh plotting option: ${OPTERR}."
		case ${OPTERR} in 
			"avgavg")   
				#with symetric error bars using 1/AVGcoh
				TITLE="Ground displacement EW+UD and linear fit; pixel ${LIN} ${PIX} as in ${REMARKDIR} - Last date is ${LASTDATE}. \\\n\\\n Bars are [-AvgCoh,+ AvgCoh] with coh/100 (LARGER IS THE BEST !!)"
				CMD_LINE=`echo "plot 'PATH_TO_EW_EPS.txt' u 1:3 with lines title 'EW' ls 1, f(x) ls 4 title 'Lin Fit EW', 'PATH_TO_EW_EPS.txt' u 1:3:5 with yerrorlines title 'coh/100 (larger is best)' ls 1 ,'PATH_TO_EW_EPS.txt' u 1:(0):8  with points pt 5 palette notitle, 'PATH_TO_UD_EPS.txt' u 1:3 with linespoints title 'UD' ls 3, g(x) ls 6 title 'Lin Fit UD'"`
				;;
			"avgmin")    
				#with asymetric error bars using  AVGcoh above data and MINcoh below data
				TITLE="Ground displacement EW+UD and linear fit; pixel ${LIN} ${PIX} as in ${REMARKDIR} - Last date is ${LASTDATE}. \\\n\\\n Bars are [-MinCoh,+ AvgCoh] with coh/100 (LARGER IS THE BEST !!)"
				CMD_LINE=`echo "plot 'PATH_TO_EW_EPS.txt' u 1:3 with lines title 'EW' ls 1, f(x) ls 4 title 'Lin Fit EW', 'PATH_TO_EW_EPS.txt' u 1:3:(\\$3-\\$6):(\\$3+\\$5) with yerrorlines title 'coh/100 (larger is best)' ls 1, 'PATH_TO_EW_EPS.txt' u 1:(0):8  with points pt 5 palette notitle, 'PATH_TO_UD_EPS.txt' u 1:3 with linespoints title 'UD' ls 3, g(x) ls 6 title 'Lin Fit UD'"`
				;;
			"avgminmax")    
				# with boxes (+ AVG above data) and error bars (min below and max above data)
				TITLE="Ground displacement EW+UD and linear fit; pixel ${LIN} ${PIX} as in ${REMARKDIR} - Last date is ${LASTDATE}. \\\n\\\n Boxes are [.,+AvgCoh], bars are [-MinCoh,+ MaxCoh] with coh/100 (LARGER IS THE BEST !!)"
				CMD_LINE=`echo "plot 'PATH_TO_EW_EPS.txt' u 1:3 with lines title 'EW' ls 1, f(x) ls 4 title 'Lin Fit EW', 'PATH_TO_EW_EPS.txt' u 1:3:(\\$3-\\$6):(\\$3+\\$7):(\\$3+\\$5) with candlestick title 'coh/100 (larger is best)' ls 1 whiskerbars, 'PATH_TO_EW_EPS.txt' u 1:(0):8  with points pt 5 palette notitle, 'PATH_TO_UD_EPS.txt' u 1:3 with linespoints title 'UD' ls 3, g(x) ls 6 title 'Lin Fit UD'"`
				;;
			"avgavgminmax")    
				# with boxes (+- AVG around data) and error bars (min below and max above data) - not very clear though and not more informative as avgminmax
				TITLE="Ground displacement EW+UD and linear fit; pixel ${LIN} ${PIX} as in ${REMARKDIR} - Last date is ${LASTDATE}. \\\n\\\n Boxes are [-AvgCoh,+AvgCoh], bars are [-MinCoh,+ MaxCoh] with coh/100 (LARGER IS THE BEST !!)"
				#CMD_LINE=`echo "plot 'PATH_TO_EW_EPS.txt' u 1:3 with lines title 'EW' ls 1, f(x) ls 4 title 'Lin Fit EW', 'PATH_TO_EW_EPS.txt' u 1:(\\$3-\\$5):(\\$3-\\$6):(\\$3+\\$7):(\\$3+\\$5) with candlestick title 'coh/100 (larger is best)' ls 1 whiskerbars, 'PATH_TO_EW_EPS.txt' u 1:((\\$3/\\$3)-1):8  with points pt 5 palette notitle, 'PATH_TO_UD_EPS.txt' u 1:3 with linespoints title 'UD' ls 3, g(x) ls 6 title 'Lin Fit UD'"`
				CMD_LINE=`echo "plot 'PATH_TO_EW_EPS.txt' u 1:3 with lines title 'EW' ls 1, f(x) ls 4 title 'Lin Fit EW', 'PATH_TO_EW_EPS.txt' u 1:(\\$3-\\$5):(\\$3-\\$6):(\\$3+\\$7):(\\$3+\\$5) with candlestick title 'coh/100 (larger is best)' ls 1 whiskerbars, 'PATH_TO_EW_EPS.txt' u 1:(0):8  with points pt 5 palette notitle, 'PATH_TO_UD_EPS.txt' u 1:3 with linespoints title 'UD' ls 3, g(x) ls 6 title 'Lin Fit UD'"`
				;;
			*)   
				echo "Not a valid -coh option. Must be either avgavg, avgmin, avgminmax or avgavgminmax. Process without error bars"	
				TITLE="Ground displacement EW+UD and linear fit; pixel ${LIN} ${PIX} as in ${REMARKDIR} - Last date is ${LASTDATE}"
				CMD_LINE=`echo "plot 'PATH_TO_EW_EPS.txt' u 1:3 with linespoints title 'EW' ls 1, f(x) ls 4 title 'Lin Fit EW','PATH_TO_UD_EPS.txt' u 1:3 with linespoints title 'UD' ls 3, g(x) ls 6 title 'Lin Fit UD'"`
				;;	
		esac
		}	

	function TitleCmdLineMeanCohAtPixNoFit()
		{
		unset LIN 
		unset PIX
		LIN=$1
		PIX=$2		

		# Note the double or triple backslashes to avoid being interpreted during string manipulation in the script
		# NOTE: syntax for usage with boxes and bars 1:2:3:4:5 is 1=x (time here), 2=bottom of box (EW data here), 3=bottom of bar (data - MinCoh here), 4=top of bar (data + MaxCoh here) ,5=top of box (data +AvgCoh here)
		# remember that file with data conatains: DATE HHMMSS EW DATE AVGcoh MINcoh MAXcoh NRcoh
		echo "You chose coh plotting option: ${OPTERR}."
		case ${OPTERR} in 
			"avgavg")   
				#with symetric error bars using 1/AVGcoh
				TITLE="Ground displacement EW+UD ; pixel ${LIN} ${PIX} as in ${REMARKDIR} - Last date is ${LASTDATE}. \\\n\\\n Bars are [-AvgCoh,+ AvgCoh] with coh/100 (LARGER IS THE BEST !!)"
				CMD_LINE=`echo "plot 'PATH_TO_EW_EPS.txt' u 1:3 with lines title 'EW' ls 1, 'PATH_TO_EW_EPS.txt' u 1:3:5 with yerrorlines title 'coh/100 (larger is best)' ls 1 ,'PATH_TO_EW_EPS.txt' u 1:(0):8  with points pt 5 palette notitle, 'PATH_TO_UD_EPS.txt' u 1:3 with linespoints title 'UD' ls 3"`
				;;
			"avgmin")    
				#with asymetric error bars using  AVGcoh above data and MINcoh below data
				TITLE="Ground displacement EW+UD ; pixel ${LIN} ${PIX} as in ${REMARKDIR} - Last date is ${LASTDATE}. \\\n\\\n Bars are [-MinCoh,+ AvgCoh] with coh/100 (LARGER IS THE BEST !!)"
				CMD_LINE=`echo "plot 'PATH_TO_EW_EPS.txt' u 1:3 with lines title 'EW' ls 1, 'PATH_TO_EW_EPS.txt' u 1:3:(\\$3-\\$6):(\\$3+\\$5) with yerrorlines title 'coh/100 (larger is best)' ls 1, 'PATH_TO_EW_EPS.txt' u 1:(0):8  with points pt 5 palette notitle, 'PATH_TO_UD_EPS.txt' u 1:3 with linespoints title 'UD' ls 3"`
				;;
			"avgminmax")    
				# with boxes (+ AVG above data) and error bars (min below and max above data)
				TITLE="Ground displacement EW+UD ; pixel ${LIN} ${PIX} as in ${REMARKDIR} - Last date is ${LASTDATE}. \\\n\\\n Boxes are [.,+AvgCoh], bars are [-MinCoh,+ MaxCoh] with coh/100 (LARGER IS THE BEST !!)"
				CMD_LINE=`echo "plot 'PATH_TO_EW_EPS.txt' u 1:3 with lines title 'EW' ls 1, 'PATH_TO_EW_EPS.txt' u 1:3:(\\$3-\\$6):(\\$3+\\$7):(\\$3+\\$5) with candlestick title 'coh/100 (larger is best)' ls 1 whiskerbars, 'PATH_TO_EW_EPS.txt' u 1:(0):8  with points pt 5 palette notitle, 'PATH_TO_UD_EPS.txt' u 1:3 with linespoints title 'UD' ls 3"`
				;;
			"avgavgminmax")    
				# with boxes (+- AVG around data) and error bars (min below and max above data) - not very clear though and not more informative as avgminmax
				TITLE="Ground displacement EW+UD ; pixel ${LIN} ${PIX} as in ${REMARKDIR} - Last date is ${LASTDATE}. \\\n\\\n Boxes are [-AvgCoh,+AvgCoh], bars are [-MinCoh,+ MaxCoh] with coh/100 (LARGER IS THE BEST !!)"
				#CMD_LINE=`echo "plot 'PATH_TO_EW_EPS.txt' u 1:3 with lines title 'EW' ls 1, f(x) ls 4 title 'Lin Fit EW', 'PATH_TO_EW_EPS.txt' u 1:(\\$3-\\$5):(\\$3-\\$6):(\\$3+\\$7):(\\$3+\\$5) with candlestick title 'coh/100 (larger is best)' ls 1 whiskerbars, 'PATH_TO_EW_EPS.txt' u 1:((\\$3/\\$3)-1):8  with points pt 5 palette notitle, 'PATH_TO_UD_EPS.txt' u 1:3 with linespoints title 'UD' ls 3, g(x) ls 6 title 'Lin Fit UD'"`
				CMD_LINE=`echo "plot 'PATH_TO_EW_EPS.txt' u 1:3 with lines title 'EW' ls 1, 'PATH_TO_EW_EPS.txt' u 1:(\\$3-\\$5):(\\$3-\\$6):(\\$3+\\$7):(\\$3+\\$5) with candlestick title 'coh/100 (larger is best)' ls 1 whiskerbars, 'PATH_TO_EW_EPS.txt' u 1:(0):8  with points pt 5 palette notitle, 'PATH_TO_UD_EPS.txt' u 1:3 with linespoints title 'UD' ls 3"`
				;;
			*)   
				echo "Not a valid -coh option. Must be either avgavg, avgmin, avgminmax or avgavgminmax. Process without error bars"	
				TITLE="Ground displacement EW+UD and linear fit; pixel ${LIN} ${PIX} as in ${REMARKDIR} - Last date is ${LASTDATE}"
				CMD_LINE=`echo "plot 'PATH_TO_EW_EPS.txt' u 1:3 with linespoints title 'EW' ls 1, f(x) ls 4 title 'Lin Fit EW','PATH_TO_UD_EPS.txt' u 1:3 with linespoints title 'UD' ls 3, g(x) ls 6 title 'Lin Fit UD'"`
				;;	
		esac
		}

# Define gnu plot template
##########################
if [ ${LINFIT} == "YES" ] 
	then 
		GNUTEMPLATE=${GNUTEMPLATEFIT}
	else 
		GNUTEMPLATE=${GNUTEMPLATENOFIT}
fi 


# Let's go...
###############
# FIRST TIME SERIES
####################
cd zz_EW${REMARKDIR}
	HDR=`ls *.hdr | head -1` 
	if [ ! -s ${HDR} ] ; then echo "No hdr file - please check your dir."; exit; fi

	# Get first time series 
	RUNDIREW=`pwd`
	getLineThroughStack ${RUNDIREW} ${LIN1} ${PIX1}

	sort -n -u timeLine${LIN1}_${PIX1}.txt > timeLine${LIN1}_${PIX1}.tmp.txt
	rm timeLine${LIN1}_${PIX1}.txt
	mv timeLine${LIN1}_${PIX1}.tmp.txt timeLine_EW_${LIN1}_${PIX1}${REMARKDIR}.txt

	# Get first and last date 
	FIRSTDATE=`head -1 timeLine_EW_${LIN1}_${PIX1}${REMARKDIR}.txt | cut -c 1-8`
	LASTDATE=`tail -1 timeLine_EW_${LIN1}_${PIX1}${REMARKDIR}.txt | cut -c 1-8`
	echo "Full time series runs from ${FIRSTDATE} to ${LASTDATE}"
	
	#Get min max of values in col3
	MINEWPIX1=`${PATHGNU}/gawk '{print $3}' timeLine_EW_${LIN1}_${PIX1}${REMARKDIR}.txt | tail -1`
	MAXEWPIX1=`${PATHGNU}/gawk '{print $3}' timeLine_EW_${LIN1}_${PIX1}${REMARKDIR}.txt | head -1`
	if [ "${MINEWPIX1}" == "${MAXEWPIX1}" ] ; then echo "Empty time series 1" ; exit 0 ; fi
	if [ `echo "${MINEWPIX1} > ${MAXEWPIX1}" | bc` -eq 1 ]
		then 
			TMP=${MINEWPIX1}
			MINEWPIX1=${MAXEWPIX1}
			MAXEWPIX1=${TMP} 
	fi
	echo "Time series 1 EW goes from ${MINEWPIX1} to ${MAXEWPIX1}"

	# Get infos
	#SENSOR=`cat ${HDR} | ${PATHGNU}/grep "sensor" | cut -d = -f 3 `
	#HEADING=`cat ${HDR} | ${PATHGNU}/grep "Heading" | cut -d = -f 2 | cut -d " " -f 2 `
cd .. 

if [ -d  zz_NS${REMARKDIR} ] ; then
	cd zz_NS${REMARKDIR}

		HDR=`ls *.hdr | head -1` 
		if [ ! -s ${HDR} ] ; then echo "No hdr file - please check your dir."; exit; fi

		# Get first time series 
		RUNDIRNS=`pwd`
		getLineThroughStack ${RUNDIRNS} ${LIN1} ${PIX1}

		sort -n -u timeLine${LIN1}_${PIX1}.txt > timeLine${LIN1}_${PIX1}.tmp.txt
#		rm timeLine${LIN1}_${PIX1}.txt
		mv timeLine${LIN1}_${PIX1}.tmp.txt timeLine_NS_${LIN1}_${PIX1}${REMARKDIR}.txt

	cd .. 
fi
cd zz_UD${REMARKDIR}

	HDR=`ls *.hdr | head -1` 
	if [ ! -s ${HDR} ] ; then echo "No hdr file - please check your dir."; exit; fi

	# Get first time series 
	RUNDIRUD=`pwd`
	getLineThroughStack ${RUNDIRUD} ${LIN1} ${PIX1}

	sort -n -u timeLine${LIN1}_${PIX1}.txt > timeLine${LIN1}_${PIX1}.tmp.txt
	rm timeLine${LIN1}_${PIX1}.txt
	mv timeLine${LIN1}_${PIX1}.tmp.txt timeLine_UD_${LIN1}_${PIX1}${REMARKDIR}.txt

	#Get min max of values in col3
	MINUDPIX1=`${PATHGNU}/gawk '{print $3}' timeLine_UD_${LIN1}_${PIX1}${REMARKDIR}.txt | tail -1`
	MAXUDPIX1=`${PATHGNU}/gawk '{print $3}' timeLine_UD_${LIN1}_${PIX1}${REMARKDIR}.txt | head -1`
	if [ "${MINUDPIX1}" == "${MAXUDPIX1}" ] ; then echo "Empty time series 1" ; exit 0 ; fi
	if [ `echo "${MINUDPIX1} > ${MAXUDPIX1}"  | bc` -eq 1  ]
		then 
			TMP=${MINUDPIX1}
			MINUDPIX1=${MAXUDPIX1}
			MAXUDPIX1=${TMP} 
	fi
	echo "Time series 1 UD goes from ${MINUDPIX1} to ${MAXUDPIX1}"
	echo ""
cd .. 

# get coh as error bars if requested 
if [ "${ERR}" == "YES" ] 
	then
		# for each date
		if [ ${TWOPIXELS} == "YES" ] 
			then 
				GetMeanCohAtPix ${LIN1} ${PIX1} EW ${LIN2} ${PIX2}
			else
				GetMeanCohAtPix ${LIN1} ${PIX1} EW
		fi
		# prepare file for plot
		# remove header (FNR >1), modifies coh as (coh)/100 and keep date, avg, min, max and nr (with same coh transfo, that is /100) 
		${PATHGNU}/gawk 'FNR >1 { print $1, $2/100, $5/100, $8/100, $9 }' <${RUNDIR}/zzz_coh_per_pixels/coh_${LIN}_${PIX}${REMARKDIR}.txt >${RUNDIR}/zzz_coh_per_pixels/coh_${LIN}_${PIX}${REMARKDIR}_NoHeader.txt
		sort -n -u -o ${RUNDIR}/zzz_coh_per_pixels/coh_${LIN}_${PIX}${REMARKDIR}_NoHeader.txt ${RUNDIR}/zzz_coh_per_pixels/coh_${LIN}_${PIX}${REMARKDIR}_NoHeader.txt
		# add EW sisplacement; ie. get DATE HHMMSS EW DATE AVGcoh MINcoh MAXcoh NRcoh		
		sort -n -u -o ${RUNDIREW}/timeLine_EW_${LIN1}_${PIX1}${REMARKDIR}.txt ${RUNDIREW}/timeLine_EW_${LIN1}_${PIX1}${REMARKDIR}.txt
		paste ${RUNDIREW}/timeLine_EW_${LIN1}_${PIX1}${REMARKDIR}.txt ${RUNDIR}/zzz_coh_per_pixels/coh_${LIN}_${PIX}${REMARKDIR}_NoHeader.txt -d " " > ${RUNDIR}/zzz_coh_per_pixels/timeLine_EW_COH_${LIN1}_${PIX1}${REMARKDIR}.txt
		rm -f ${RUNDIR}/zzz_coh_per_pixels/coh_${LIN}_${PIX}${REMARKDIR}_NoHeader.txt
		# Search for nan or 0 AVG, MAX or MIN coh and repalce by extreme value
		${PATHGNU}/gsed -i "s% nan % 999999999 %g" ${RUNDIR}/zzz_coh_per_pixels/timeLine_EW_COH_${LIN1}_${PIX1}${REMARKDIR}.txt # this will create a hughe bar in plot pointing out to the erroneous date
		${PATHGNU}/gsed -i "s% 0 % 999999999 %g" ${RUNDIR}/zzz_coh_per_pixels/timeLine_EW_COH_${LIN1}_${PIX1}${REMARKDIR}.txt   # this will create a hughe bar in plot pointing out to the erroneous date

		EWFILETOPLOT=${RUNDIR}/zzz_coh_per_pixels/timeLine_EW_COH_${LIN1}_${PIX1}${REMARKDIR}

		
	else 
		EWFILETOPLOT=${RUNDIREW}/timeLine_EW_${LIN1}_${PIX1}${REMARKDIR}
fi

# PLOT (without tags for events)
cp ${GNUTEMPLATE} plotTS_${LIN1}_${PIX1}_multi${REMARKDIR}.gnu

if [ -d  zz_NS${REMARKDIR} ] 
	then
		# Change title
		TITLE="Ground displacement EW+NS+UD; pixel ${LIN1} ${PIX1} as in ${REMARKDIR} - Last date is ${LASTDATE}"
		CMD_LINE=`echo "plot 'PATH_TO_EW_EPS.txt' u 1: 3 with linespoints title 'EW' ls 1,'PATH_TO_NS_EPS.txt' u 1: 3 with linespoints title 'NS' ls 2,'PATH_TO_UD_EPS.txt' u 1: 3 with linespoints title 'UD' ls 3"`
		${PATHGNU}/gsed -i "s%CMD_LINE%${CMD_LINE}%" plotTS_${LIN1}_${PIX1}_multi${REMARKDIR}.gnu
		${PATHGNU}/gsed -i "s%PATH_TO_NS_EPS%${RUNDIRNS}\/timeLine_NS_${LIN1}_${PIX1}${REMARKDIR}%" plotTS_${LIN1}_${PIX1}_multi${REMARKDIR}.gnu
	else 
		# Change title
		if [ "${LINFIT}" == "YES" ]
			then
				${PATHGNU}/gsed -i '1i set fit logfile "'${RUNDIR}'/fit_'${RNDM}'1.log"' plotTS_${LIN1}_${PIX1}_multi${REMARKDIR}.gnu
				
				# if coh as error bars if requested 
				if [ "${ERR}" == "YES" ] 
					then
					
						# set the titme and command line
						TitleCmdLineMeanCohAtPix ${LIN1} ${PIX1}

						${PATHGNU}/gsed -i '12 i set palette model RGB defined (0 \"red\",1 \"blue\", 2 \"green\")' plotTS_${LIN1}_${PIX1}_multi${REMARKDIR}.gnu
						${PATHGNU}/gsed -i '13 i set cblabel \"Nr of n pairs used for coherence statistics\" font \"Helvetica, 8\"  rotate by -90' plotTS_${LIN1}_${PIX1}_multi${REMARKDIR}.gnu
	
					else			
						TITLE="Ground displacement EW+UD and linear fit; pixel ${LIN1} ${PIX1} as in ${REMARKDIR} - Last date is ${LASTDATE}"
						CMD_LINE=`echo "plot 'PATH_TO_EW_EPS.txt' u 1:3 with linespoints title 'EW' ls 1, f(x) ls 4 title 'Lin Fit EW','PATH_TO_UD_EPS.txt' u 1:3 with linespoints title 'UD' ls 3, g(x) ls 6 title 'Lin Fit UD'"`
				fi

				if [ ${LINRATE} == "YES" ] ; then
					${PATHGNU}/gsed -i "s/# ANNUALRATEEW/set label sprintf('EW Linear rate = %.2f cm\/yr', annualrateEW(b) ) at  graph 0.82,0.04 front /" plotTS_${LIN1}_${PIX1}_multi${REMARKDIR}.gnu
					${PATHGNU}/gsed -i "s/# ANNUALRATEUD/set label sprintf('UD Linear rate = %.2f cm\/yr', annualrateUD(d) ) at  graph 0.82,0.02 front /" plotTS_${LIN1}_${PIX1}_multi${REMARKDIR}.gnu
				fi

			else 
				
				if [ "${ERR}" == "YES" ] 
					then
						# set the titme and command line
						TitleCmdLineMeanCohAtPixNoFit ${LIN1} ${PIX1}

						${PATHGNU}/gsed -i '12 i set palette model RGB defined (0 \"red\",1 \"blue\", 2 \"green\")' plotTS_${LIN1}_${PIX1}_multi${REMARKDIR}.gnu
						${PATHGNU}/gsed -i '13 i set cblabel \"Nr of n pairs used for coherence statistics\" font \"Helvetica, 8\"  rotate by -90' plotTS_${LIN1}_${PIX1}_multi${REMARKDIR}.gnu
	
					else			
						TITLE="Ground displacement EW+UD; pixel ${LIN1} ${PIX1} as in ${REMARKDIR} - Last date is ${LASTDATE}"
						CMD_LINE=`echo "plot 'PATH_TO_EW_EPS.txt' u 1: 3 with linespoints title 'EW' ls 1,'PATH_TO_UD_EPS.txt' u 1: 3 with linespoints title 'UD' ls 3"`
				fi

				
		fi	
		${PATHGNU}/gsed -i "s%CMD_LINE%${CMD_LINE}%" plotTS_${LIN1}_${PIX1}_multi${REMARKDIR}.gnu
fi
# Change output name
${PATHGNU}/gsed -i "s%PATH_TO_EPS%timeLines_${LIN1}_${PIX1}${REMARKDIR}%" plotTS_${LIN1}_${PIX1}_multi${REMARKDIR}.gnu
# Change input time series txt name
#${PATHGNU}/gsed -i "s%PATH_TO_EW_EPS%${EWFILETOPLOT}\/timeLine_EW_${LIN1}_${PIX1}${REMARKDIR}%" plotTS_${LIN1}_${PIX1}_multi${REMARKDIR}.gnu
${PATHGNU}/gsed -i "s%PATH_TO_EW_EPS%${EWFILETOPLOT}%g" plotTS_${LIN1}_${PIX1}_multi${REMARKDIR}.gnu
${PATHGNU}/gsed -i "s%PATH_TO_UD_EPS%${RUNDIRUD}\/timeLine_UD_${LIN1}_${PIX1}${REMARKDIR}%g" plotTS_${LIN1}_${PIX1}_multi${REMARKDIR}.gnu

${PATHGNU}/gsed -i "s%TITLE%${TITLE}%" plotTS_${LIN1}_${PIX1}_multi${REMARKDIR}.gnu

# Change INSTITUTE name 
${PATHGNU}/gsed -i "s%INSTITUTE%${INSTITUTE}%" plotTS_${LIN1}_${PIX1}_multi${REMARKDIR}.gnu


# Change time span
if [ ${SPAN} == "YES" ]
	then 
		${PATHGNU}/gsed -i "s%# XRANGE%set xrange [${STARTSPANSEC}:${STOPSPANSEC}]%" plotTS_${LIN1}_${PIX1}_multi${REMARKDIR}.gnu
fi

gnuplot plotTS_${LIN1}_${PIX1}_multi${REMARKDIR}.gnu

# # Get second time series if needed
######################################
if [ ${TWOPIXELS} == "YES" ] ; then 

	cd zz_EW${REMARKDIR}
		getLineThroughStack ${RUNDIREW} ${LIN2} ${PIX2}

		sort -n -u timeLine${LIN2}_${PIX2}.txt > timeLine${LIN2}_${PIX2}.tmp.txt
		rm timeLine${LIN2}_${PIX2}.txt
		mv timeLine${LIN2}_${PIX2}.tmp.txt timeLine_EW_${LIN2}_${PIX2}${REMARKDIR}.txt

		#Get min max of values in col3
		MINEWPIX2=`${PATHGNU}/gawk '{print $3}' timeLine_EW_${LIN2}_${PIX2}${REMARKDIR}.txt | tail -1`
		MAXEWPIX2=`${PATHGNU}/gawk '{print $3}' timeLine_EW_${LIN2}_${PIX2}${REMARKDIR}.txt | head -1`
		# If INFIT requested, must first ensure that time series is not null.
		if [ "${MINEWPIX2}" == "${MAXEWPIX2}" ] ; then echo "Empty time series 2" ; exit 0 ; fi
		if [ `echo "${MINEWPIX2} > ${MAXEWPIX2}" | bc` -eq 1  ]
			then 
				TMP=${MINEWPIX2}
				MINEWPIX2=${MAXEWPIX2}
				MAXEWPIX2=${TMP} 
		fi
		echo "Time series 2 EW goes from ${MINEWPIX2} to ${MAXEWPIX2}"

	cd .. 

	if [ -d  zz_NS${REMARKDIR} ] ; then
		cd zz_NS${REMARKDIR}
			getLineThroughStack ${RUNDIRNS} ${LIN2} ${PIX2}

			sort -n -u timeLine${LIN2}_${PIX2}.txt > timeLine${LIN2}_${PIX2}.tmp.txt
			rm timeLine${LIN2}_${PIX2}.txt
			mv timeLine${LIN2}_${PIX2}.tmp.txt timeLine_NS_${LIN2}_${PIX2}${REMARKDIR}.txt
		cd .. 
	fi
	
	cd zz_UD${REMARKDIR}
		getLineThroughStack ${RUNDIRUD} ${LIN2} ${PIX2}

		sort -n -u timeLine${LIN2}_${PIX2}.txt > timeLine${LIN2}_${PIX2}.tmp.txt
		rm timeLine${LIN2}_${PIX2}.txt
		mv timeLine${LIN2}_${PIX2}.tmp.txt timeLine_UD_${LIN2}_${PIX2}${REMARKDIR}.txt

		#Get min max of values in col3
		MINUDPIX2=`${PATHGNU}/gawk '{print $3}' timeLine_UD_${LIN2}_${PIX2}${REMARKDIR}.txt | tail -1`
		MAXUDPIX2=`${PATHGNU}/gawk '{print $3}' timeLine_UD_${LIN2}_${PIX2}${REMARKDIR}.txt | head -1`
		if [ "${MINUDPIX2}" == "${MAXUDPIX2}" ] ; then echo "Empty time series 2" ; exit 0 ; fi
		if [ `echo "${MINUDPIX2} > ${MAXUDPIX2}" | bc` -eq 1  ]
			then 
				TMP=${MINUDPIX2}
				MINUDPIX2=${MAXUDPIX2}
				MAXUDPIX2=${TMP} 
		fi
		echo "Time series 2 UD goes from ${MINUDPIX2} to ${MAXUDPIX2}"
		echo ""

	cd .. 

if [ "${ERR}" == "YES" ] 
	then
		# for each date
		#GetMeanCohAtPix is already performed at the time of PIX1
	
		# prepare file for plot
		# remove header (FNR >1), modifies coh as (coh)/100 and keep date, avg, min, max and nr (with same coh transfo, that is /100) 
		${PATHGNU}/gawk 'FNR >1 { print $1, $2/100, $5/100, $8/100, $9 }' <${RUNDIR}/zzz_coh_per_pixels/coh_${LIN2}_${PIX2}${REMARKDIR}.txt >${RUNDIR}/zzz_coh_per_pixels/coh_${LIN2}_${PIX2}${REMARKDIR}_NoHeader.txt
		sort -n -u -o ${RUNDIR}/zzz_coh_per_pixels/coh_${LIN2}_${PIX2}${REMARKDIR}_NoHeader.txt ${RUNDIR}/zzz_coh_per_pixels/coh_${LIN2}_${PIX2}${REMARKDIR}_NoHeader.txt
		# add EW sisplacement; ie. get DATE HHMMSS EW DATE AVGcoh MINcoh MAXcoh NRcoh		
		sort -n -u -o ${RUNDIREW}/timeLine_EW_${LIN2}_${PIX2}${REMARKDIR}.txt ${RUNDIREW}/timeLine_EW_${LIN2}_${PIX2}${REMARKDIR}.txt
		paste ${RUNDIREW}/timeLine_EW_${LIN2}_${PIX2}${REMARKDIR}.txt ${RUNDIR}/zzz_coh_per_pixels/coh_${LIN2}_${PIX2}${REMARKDIR}_NoHeader.txt -d " " > ${RUNDIR}/zzz_coh_per_pixels/timeLine_EW_COH_${LIN2}_${PIX2}${REMARKDIR}.txt
		rm -f ${RUNDIR}/zzz_coh_per_pixels/coh_${LIN2}_${PIX2}${REMARKDIR}_NoHeader.txt
		# Search for nan or 0 AVG, MAX or MIN coh and repalce by extreme value
		${PATHGNU}/gsed -i "s% nan % 999999999 %g" ${RUNDIR}/zzz_coh_per_pixels/timeLine_EW_COH_${LIN2}_${PIX2}${REMARKDIR}.txt # this will create a hughe bar in plot pointing out to the erroneous date
		${PATHGNU}/gsed -i "s% 0 % 999999999 %g" ${RUNDIR}/zzz_coh_per_pixels/timeLine_EW_COH_${LIN2}_${PIX2}${REMARKDIR}.txt   # this will create a hughe bar in plot pointing out to the erroneous date

		EWFILETOPLOT=${RUNDIR}/zzz_coh_per_pixels/timeLine_EW_COH_${LIN2}_${PIX2}${REMARKDIR}
	else 
		EWFILETOPLOT=${RUNDIREW}/timeLine_EW_${LIN2}_${PIX2}${REMARKDIR}
fi

	# PLOT (without tags for events)
	cp ${GNUTEMPLATE} plotTS_${LIN2}_${PIX2}_multi${REMARKDIR}.gnu

	if [ -d  zz_NS${REMARKDIR} ] 
		then
			TITLE="Ground displacement EW+NS+UD; pixel ${LIN2} ${PIX2} as in ${REMARKDIR} - Last date is ${LASTDATE}"
			CMD_LINE=`echo "plot 'PATH_TO_EW_EPS.txt' u 1: 3 with linespoints title 'EW' ls 1,'PATH_TO_NS_EPS.txt' u 1: 3 with linespoints title 'NS' ls 2,'PATH_TO_UD_EPS.txt' u 1: 3 with linespoints title 'UD' ls 3"`
			${PATHGNU}/gsed -i "s%CMD_LINE%${CMD_LINE}%" plotTS_${LIN2}_${PIX2}_multi${REMARKDIR}.gnu
			${PATHGNU}/gsed -i "s%PATH_TO_NS_EPS%${RUNDIRNS}\/timeLine_NS_${LIN2}_${PIX2}${REMARKDIR}%" plotTS_${LIN2}_${PIX2}_multi${REMARKDIR}.gnu
		else 
			# Change title
			if [ "${LINFIT}" == "YES" ]
				then
					${PATHGNU}/gsed -i '1i set fit logfile "'${RUNDIR}'/fit_'${RNDM}'2.log"' plotTS_${LIN2}_${PIX2}_multi${REMARKDIR}.gnu
			
					# if coh as error bars if requested 
					if [ "${ERR}" == "YES" ] 
						then
							# set the titme and command line
							TitleCmdLineMeanCohAtPix ${LIN2} ${PIX2}

							${PATHGNU}/gsed -i '12 i set palette model RGB defined (0 \"red\",1 \"blue\", 2 \"green\")' plotTS_${LIN2}_${PIX2}_multi${REMARKDIR}.gnu
							${PATHGNU}/gsed -i '13 i set cblabel \"Nr of n pairs used for coherence statistics\" font \"Helvetica, 8\"  rotate by -90' plotTS_${LIN2}_${PIX2}_multi${REMARKDIR}.gnu

						else			
							TITLE="Ground displacement EW+UD and linear fit; pixel ${LIN2} ${PIX2} as in ${REMARKDIR} - Last date is ${LASTDATE}"
							CMD_LINE=`echo "plot 'PATH_TO_EW_EPS.txt' u 1:3 with linespoints title 'EW' ls 1, f(x) ls 4 title 'Lin Fit EW','PATH_TO_UD_EPS.txt' u 1:3 with linespoints title 'UD' ls 3, g(x) ls 6 title 'Lin Fit UD'"`
					fi

					if [ ${LINRATE} == "YES" ] ; then
						${PATHGNU}/gsed -i "s/# ANNUALRATEEW/set label sprintf('EW Linear rate = %.2f cm\/yr', annualrateEW(b) ) at  graph 0.82,0.04 front /" plotTS_${LIN2}_${PIX2}_multi${REMARKDIR}.gnu
						${PATHGNU}/gsed -i "s/# ANNUALRATEUD/set label sprintf('UD Linear rate = %.2f cm\/yr', annualrateUD(d) ) at  graph 0.82,0.02 front /" plotTS_${LIN2}_${PIX2}_multi${REMARKDIR}.gnu
					fi

				else 

					if [ "${ERR}" == "YES" ] 
						then
							# set the titme and command line
							TitleCmdLineMeanCohAtPixNoFit ${LIN2} ${PIX2}

							${PATHGNU}/gsed -i '12 i set palette model RGB defined (0 \"red\",1 \"blue\", 2 \"green\")' plotTS_${LIN2}_${PIX2}_multi${REMARKDIR}.gnu
							${PATHGNU}/gsed -i '13 i set cblabel \"Nr of n pairs used for coherence statistics\" font \"Helvetica, 8\"  rotate by -90' plotTS_${LIN2}_${PIX2}_multi${REMARKDIR}.gnu
	
						else			
							TITLE="Ground displacement EW+UD; pixel ${LIN2} ${PIX2} as in ${REMARKDIR} - Last date is ${LASTDATE}"
							CMD_LINE=`echo "plot 'PATH_TO_EW_EPS.txt' u 1: 3 with linespoints title 'EW' ls 1,'PATH_TO_UD_EPS.txt' u 1: 3 with linespoints title 'UD' ls 3"`
					fi
					
			fi	
		
			${PATHGNU}/gsed -i "s%CMD_LINE%${CMD_LINE}%" plotTS_${LIN2}_${PIX2}_multi${REMARKDIR}.gnu
	fi
	${PATHGNU}/gsed -i "s%TITLE%${TITLE}%" plotTS_${LIN2}_${PIX2}_multi${REMARKDIR}.gnu

	# Change INSTITUTE name 
	${PATHGNU}/gsed -i "s%INSTITUTE%${INSTITUTE}%" plotTS_${LIN2}_${PIX2}_multi${REMARKDIR}.gnu


	# Change output name
	${PATHGNU}/gsed -i "s%PATH_TO_EPS%timeLines_${LIN2}_${PIX2}${REMARKDIR}%" plotTS_${LIN2}_${PIX2}_multi${REMARKDIR}.gnu
	# Change input time series txt name
	${PATHGNU}/gsed -i "s%PATH_TO_EW_EPS%${EWFILETOPLOT}%g" plotTS_${LIN2}_${PIX2}_multi${REMARKDIR}.gnu

	#${PATHGNU}/gsed -i "s%PATH_TO_EW_EPS%${RUNDIREW}\/timeLine_EW_${LIN2}_${PIX2}${REMARKDIR}%g" plotTS_${LIN2}_${PIX2}_multi${REMARKDIR}.gnu
	${PATHGNU}/gsed -i "s%PATH_TO_UD_EPS%${RUNDIRUD}\/timeLine_UD_${LIN2}_${PIX2}${REMARKDIR}%g" plotTS_${LIN2}_${PIX2}_multi${REMARKDIR}.gnu

	# Change time span
	if [ ${SPAN} == "YES" ]
		then 
			${PATHGNU}/gsed -i "s%# XRANGE%set xrange [${STARTSPANSEC}:${STOPSPANSEC}]%" plotTS_${LIN2}_${PIX2}_multi${REMARKDIR}.gnu
	fi

	gnuplot plotTS_${LIN2}_${PIX2}_multi${REMARKDIR}.gnu

	# find min max for whole plot
	#############################
	if [ `echo "${MINUDPIX1} > ${MINUDPIX2}" | bc` -eq 1 ] ; then MINUD=${MINUDPIX2} ; else MINUD=${MINUDPIX1} ; fi
	if [ `echo "${MINEWPIX1} > ${MINEWPIX2}" | bc` -eq 1 ] ; then MINEW=${MINEWPIX2} ; else MINEW=${MINEWPIX1} ; fi
	if [ `echo "${MINUD} > ${MINEW}" | bc` -eq 1 ] ; then MIN=${MINEW} ; else MIN=${MINUD} ; fi
	#MIN=`echo "${MIN} -0.1" | bc -l`

	if [ `echo "${MAXUDPIX1} > ${MAXUDPIX2}" | bc` -eq 1 ] ; then MAXUD=${MAXUDPIX1} ; else MAXUD=${MAXUDPIX2} ; fi
	if [ `echo "${MAXEWPIX1} > ${MAXEWPIX2}" | bc` -eq 1 ] ; then MAXEW=${MAXEWPIX1} ; else MAXEW=${MAXEWPIX2} ; fi
	if [ `echo "${MAXUD} > ${MAXEW}" | bc` -eq 1 ] ; then MAX=${MAXUD} ; else MAX=${MAXEW} ; fi
	#MAX=`echo "${MAX} +0.1" | bc -l`
	echo "min max are ${MIN} and ${MAX}"

	
	# Get the double difference
	################################

			if [ ${ADDEVENTS} == "YES" ] ; then GNUNAME=plotTS_${LIN1}_${PIX1}_${LIN2}_${PIX2}_multi${REMARKDIR}_events.gnu ; else GNUNAME=plotTS_${LIN1}_${PIX1}_${LIN2}_${PIX2}_multi${REMARKDIR}.gnu ; fi 

			cp ${GNUTEMPLATE} ${GNUNAME}

			#merge line by lines the two txt files
			paste ${RUNDIREW}/timeLine_EW_${LIN1}_${PIX1}${REMARKDIR}.txt ${RUNDIREW}/timeLine_EW_${LIN2}_${PIX2}${REMARKDIR}.txt > timeLine_EW_${LIN1}_${PIX1}_${LIN2}_${PIX2}${REMARKDIR}.txt
			paste ${RUNDIRUD}/timeLine_UD_${LIN1}_${PIX1}${REMARKDIR}.txt ${RUNDIRUD}/timeLine_UD_${LIN2}_${PIX2}${REMARKDIR}.txt > timeLine_UD_${LIN1}_${PIX1}_${LIN2}_${PIX2}${REMARKDIR}.txt
			if [ -d  zz_NS${REMARKDIR} ] 
				then
					paste ${RUNDIRNS}/timeLine_NS_${LIN1}_${PIX1}${REMARKDIR}.txt ${RUNDIRNS}/timeLine_NS_${LIN2}_${PIX2}${REMARKDIR}.txt > timeLine_NS_${LIN1}_${PIX1}_${LIN2}_${PIX2}${REMARKDIR}.txt
					TITLE="Ground displacement EW+NS+UD; pixel ${LIN1} ${PIX1} - pixel ${LIN2} ${PIX2} as in ${REMARKDIR} - Last date is ${LASTDATE}"
# NOT TESTED		# Add events
					PlotEvents		

					CMD_LINE=`echo "plot 'PATH_TO_EW_EPS.txt' u 1: 3 with linespoints title 'EW' ls 1,'PATH_TO_NS_EPS.txt' u 1: 3 with linespoints title 'NS' ls 2,'PATH_TO_UD_EPS.txt' u 1: 3 with linespoints title 'UD' ls 3"`
					${PATHGNU}/gsed -i "s%CMD_LINE%${CMD_LINE}%" ${GNUNAME}
					${PATHGNU}/gsed -i "s%PATH_TO_NS_EPS%timeLine_NS_${LIN1}_${PIX1}_${LIN2}_${PIX2}${REMARKDIR}%" ${GNUNAME}
				else 
					if [ "${LINFIT}" == "YES" ] 
						then
							${PATHGNU}/gsed -i '1i set fit logfile "'${RUNDIR}'/fit_'${RNDM}'3.log"' ${GNUNAME}
							TITLE="Ground displacement EW+UD and linear fit; pixel ${LIN1} ${PIX1} - pixel ${LIN2} ${PIX2} as in ${REMARKDIR} - Last date is ${LASTDATE}"
							# Add events
							PlotEvents

							CMD_LINE=`echo "plot 'PATH_TO_EW_EPS.txt' u 1:3 with linespoints title 'EW' ls 1, f(x) ls 4 title 'Lin Fit EW','PATH_TO_UD_EPS.txt' u 1:3 with linespoints title 'UD' ls 3, g(x) ls 6 title 'Lin Fit UD'"`

							if [ ${LINRATE} == "YES" ] ; then
								${PATHGNU}/gsed -i "s/# ANNUALRATEEW/set label sprintf('EW Linear rate = %.2f cm\/yr', annualrateEW(b) ) at  graph 0.82,0.04 front /" ${GNUNAME}
								${PATHGNU}/gsed -i "s/# ANNUALRATEUD/set label sprintf('UD Linear rate = %.2f cm\/yr', annualrateUD(d) ) at  graph 0.82,0.02 front /" ${GNUNAME}
							fi

						else 
							TITLE="Ground displacement EW+UD; pixel ${LIN1} ${PIX1} - pixel ${LIN2} ${PIX2} as in ${REMARKDIR} - Last date is ${LASTDATE}"
							# Add events
							PlotEvents
						
							CMD_LINE=`echo "plot 'PATH_TO_EW_EPS.txt' u 1:3 with linespoints title 'EW' ls 1,'PATH_TO_UD_EPS.txt' u 1: 3 with linespoints title 'UD' ls 3"`
					fi	
					${PATHGNU}/gsed -i "s%CMD_LINE%${CMD_LINE}%" ${GNUNAME}
			fi
			${PATHGNU}/gsed -i "s%u 1:3%u 1: (\$3 - \$6)%g" ${GNUNAME} # several syntax may be possible
			${PATHGNU}/gsed -i "s%u 1: 3%u 1: (\$3 - \$6)%g" ${GNUNAME}
			${PATHGNU}/gsed -i "s%using 1:3%using 1: (\$3 - \$6)%g" ${GNUNAME} # several syntax may be possible
			${PATHGNU}/gsed -i "s%using 1: 3%using 1: (\$3 - \$6)%g"  ${GNUNAME}
			
			${PATHGNU}/gsed -i "s%TITLE%${TITLE}%" ${GNUNAME}
			
			# Change INSTITUTE name 
			${PATHGNU}/gsed -i "s%INSTITUTE%${INSTITUTE}%" ${GNUNAME}

			# Change output name
			${PATHGNU}/gsed -i "s%PATH_TO_EPS%timeLines_${LIN1}_${PIX1}_${LIN2}_${PIX2}${REMARKDIR}%" ${GNUNAME}
			# Change input time series txt name
			${PATHGNU}/gsed -i "s%PATH_TO_EW_EPS%timeLine_EW_${LIN1}_${PIX1}_${LIN2}_${PIX2}${REMARKDIR}%" ${GNUNAME}
			${PATHGNU}/gsed -i "s%PATH_TO_UD_EPS%timeLine_UD_${LIN1}_${PIX1}_${LIN2}_${PIX2}${REMARKDIR}%" ${GNUNAME}

			# Change time span
			if [ ${SPAN} == "YES" ]
				then 
					${PATHGNU}/gsed -i "s%# XRANGE%set xrange [${STARTSPANSEC}:${STOPSPANSEC}]%" ${GNUNAME}
			fi

			gnuplot ${GNUNAME}
			
fi  # end of if for 2 pixels

# Some optional cleaning 
########################
# Cleaning text files with individual TS values
if [ ${DELPIXVAL} == "YES" ] || [ ${DELDDVAL} == "YES" ] ; then rm -f ${RUNDIREW}/timeLine_EW_${LIN1}_${PIX1}${REMARKDIR}.txt ${RUNDIREW}/timeLine_EW_${LIN2}_${PIX2}${REMARKDIR}.txt ; fi
if [ ${DELPIXVAL} == "YES" ] || [ ${DELDDVAL} == "YES" ] ; then rm -f ${RUNDIRUD}/timeLine_UD_${LIN1}_${PIX1}${REMARKDIR}.txt ${RUNDIRUD}/timeLine_UD_${LIN2}_${PIX2}${REMARKDIR}.txt ; fi
if [ ${DELPIXVAL} == "YES" ] || [ ${DELDDVAL} == "YES" ] ; then rm -f ${RUNDIRNS}/timeLine_NS_${LIN1}_${PIX1}${REMARKDIR}.txt ${RUNDIRNS}/timeLine_NS_${LIN2}_${PIX2}${REMARKDIR}.txt ; fi
# Cleaning text files with Double Difference TS values
if [ ${DELDDVAL} == "YES" ] ; then rm -f timeLine_EW_${LIN1}_${PIX1}_${LIN2}_${PIX2}${REMARKDIR}.txt timeLine_UD_${LIN1}_${PIX1}_${LIN2}_${PIX2}${REMARKDIR}.txt timeLine_NS_${LIN1}_${PIX1}_${LIN2}_${PIX2}${REMARKDIR}.txt ; fi
# Cleaning gnuplot scripts 
if [ ${DELGNU} == "YES" ] ; then rm -f plotTS_${LIN1}_${PIX1}_multi${REMARKDIR}.gnu plotTS_${LIN2}_${PIX2}_multi${REMARKDIR}.gnu ${GNUNAME} ; fi

rm -f ${RUNDIR}/fit_${RNDM}1.log  ${RUNDIR}/fit_${RNDM}2.log ${RUNDIR}/fit_${RNDM}3.log

# Make optional png files
#########################
if [ ${PNGPLOT} == "YES" ]
	then 
		EPSLIST=`echo "timeLines_${LIN1}_${PIX1}${REMARKDIR}.eps timeLines_${LIN2}_${PIX2}${REMARKDIR}.eps timeLines_${LIN1}_${PIX1}_${LIN2}_${PIX2}${REMARKDIR}.eps"`
		for EPSFILE in ${EPSLIST}
		do 
			if [ -f "${EPSFILE}" ] && [ -s "${EPSFILE}" ] ; then 
					#convert -density 150 -rotate 90 -background white -alpha remove ${EPSFILE} ${EPSFILE}.png
					convert -density 150 -rotate 90 -trim -background white ${EPSFILE} ${EPSFILE}.png
			fi
		done
fi

# Add tag with direction of deformation and location of pixels 
##############################################################
#------------   Add by Maxime Jaspard 20200114 --------------#
# if double diff and if last param contains a t, it means that you want a double difference and a tag to explain direction of displacments 
if  [ ${TWOPIXELS} == "YES" ] && [ ${TAG} == "YES" ] ; then
	EPSFILE=$(find . -maxdepth 1 -type f -name "*${LIN1}_${PIX1}_${LIN2}_${PIX2}${REMARKDIR}.eps")
	${PATH_SCRIPTS}/SCRIPTS_MT/TS_AddLegend_EW_UD.sh ${REMARKDIR} ${EPSFILE}
fi
#-------------                 end              --------------#


