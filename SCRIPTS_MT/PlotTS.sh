#!/bin/bash
#
# In a dir that contains MSBAS results (EW, or UD or LOS defo maps), the script will 
# extract the displacement of a given pixel and generate a 3 col txt file : DATE TIME DISPL. 
# A graph is then generated with gnuplot with all the components. It can be plotted on the time series:
#	a line fit, a linear rate and/or a tag with direction of deformation and position of pixels, and 
#   plot several types of events as lines and/or rectangles on the plots (see param below for explanation). 
# If two pixels are provided, it computes also a plot with the double difference. 
# Note: Events are plotted only for double differences)
#
# ATTENTION: if plotting time series of LOS only and use option -t:
#			- the direction of the orbit (Asc or Desc) MUST (!!) be in the name of dir where msbas results are to properly tag the direction of displacement 
#			- a satview.jpg file MUST be created and stored in the /_Combi dir/ that must be in the dir where msbas is processed 
#			  See Web_tool_V1.2.docx for explanations on how to create that satview.jpg imgage. Without that satview.jpg file, 
#			  the script won't be able to display the pixel positions on the Google Earth image as tag in the double difference time series. 
#            
#
# Script must be launched in dir where msbas data are 
#
# Parameters :	- coordinates of the desired pixel in lines and pixels (as given for instance with Preview)
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
#
#
# Dependencies : - function getLineThroughStack (AMSTer Engine utilities)
#                - gnuplot
#                - gnu plot template plotTS_template.gnu or plotTS_template_fit.gnu 
#				And for adding Legend with direction of deformation
#				 - TS_AddLegend_LOS.sh, TimeSeriesInfo_HP.sh, AmpDefo_map.sh
#				 - Python + Numpy + script: CreateColorFrame.py, Mask_Builder.py
#				 - figures and paramerters file in ${PATH_SCRIPTS}/SCRIPTS_MT/TSCombiFiles/
#				 - gnu stat (gstat) e.g. from coreutils
#			 	 - __HardCodedLines.sh
#
# Hard coded (only if you run it from QGIS python console; 
#     otherwise, these info are taken from the state variables):	
#				- path to template plotTS_template.gnu (One may want to change some plot style in there ?.)
#				- PATH TO AMSTer Toolbox and Engine in order to be run from python console in QGIS which does not understand state variables
#	Note that some info about plot style (title, range, font, color...) are also set up in the script. 
#
# New in Distro V 1.0:	- Based on developpement version and Beta V3.0
#		 Distro V 1.1:	- Adapted to be run in Python Console
# New in Distro V 1.2:	- perform linear fit if option -f added at the end
#		 Distro V 1.3:	- bug in path template gnu for Linux
#		 Distro V 1.4:	- search in double diff for a third syntax when searcing for u 1:3
#		 Distro V 1.5:	- remove transparency option "-alpha remove" from convert (because may crash on linux; maybe must be "-alapha off" on recent convert versions)
#		 Distro V 2.0:	- Add tag with direction of displacement for double difference (by M. Jaspard)
#		 Distro V 2.1:	- Display Linear trend on plot (cm/yr) if option -t (attention year is rounded to 31.536.000 sec, i.e. neglect leap year) 
#						- Set optional tag for doubble difference  
#						- LINFIT was $5 instead of $6 and clean fit.log
#		 Distro V 3.0:	- options -r instead of -e and more options 
#						- Set optional tag for doubble difference  
#						- clean fit.log
#		 Distro V 4.0:	- allows adding tags with events
#						- change option -e in -r to avoid possible confusion
#						- change way to detect options -f -r -t 
#		 Distro V 4.1:	- less gnu template; small bugs in option testing
#						- secure fit.log to avoid overwritng or mixing if several run at the same time 
#		 Distro V 4.2:	- allows limiting time span of displayed time series using -start= and -stop= otpions 
#						- improve vertical bar for events
#		 Distro V 5.0:	- path to GNUTEMPLATENOFIT and GNUTEMPLATEFIT the same way now for Mac and Linux
#		 Distro V 5.0.1:- add comment in header to reming that LOS dir must be named with orbit direction 
#		 Distro V 5.0.2:- use gdate instead of date. Just in case. 
# New in Distro V 6.0:	- Use hard coded lines definition from __HardCodedLines.sh
#						- rename PATHTOMT with PATHTOME
# New in Distro V 6.1:	- sourcing __HardCodedLines.sh was missing...
# New in Distro V 6.2: - replace if -s as -f -s && -f to be compatible with mac os if 
# New in Distro V 7.0 20230830:	- Rename SCRIPTS_OK directory as SCRIPTS_MT 
#								- Replace CIS by MT in names 
#								- Renamed FUNCTIONS_FOR_MT.sh
# New in Distro V 8.0 20231030:	- Rename MasTer Toolbox as AMSTer Software
#								- rename Master and Slave as Primary and Secondary (though not possible in some variables and files)
#
# AMSTer: SAR & InSAR Automated Mass processing Software for Multidimensional Time series
# NdO (c) 2016/03/07 - could make better with more functions... when time.
# -----------------------------------------------------------------------------------------
PRG=`basename "$0"`
VER="Distro V8.0 AMSTer script utilities"
AUT="Nicolas d'Oreye, (c)2016-2019, Last modified on Oct 30, 2023"
echo " "
echo "${PRG} ${VER}, ${AUT}"
echo " "


# Check OS
OS=`uname -a | cut -d " " -f 1 `
echo "Running on ${OS}"
echo


# ^^^ ----- Hard coded lines to check -- ^^^ 
# This is only needed if run from QGIS console; 
# if not, info are taken from state variables

# Test if STATE VARIABLES are known. If not, use these that are hard coded,
#       which is mandatory for being run from Python console from QGIS
TESTVAR=`echo ${PATHGNU} | wc -w`
if [ ${TESTVAR} == "0" ]
	then 
		case "${OS}" in
			"Darwin")
					PATHGNU=/opt/local/bin 	;;
			"Linux")
					PATHGNU=/usr/bin 		;;
		esac
fi
PATH_SCRIPTS=/$HOME/SAR/AMSTer/
PATHTOME=/$HOME/SAR/AMSTer/AMSTerEngine 

source ${PATH_SCRIPTS}/SCRIPTS_MT/__HardCodedLines.sh

#source ${PATH_SCRIPTS}/SCRIPTS_MT/__HardCodedLines.sh
	# Get name of the institue $INSTITUTE where computation is performed (defined as a function in __HardCodedLines.sh)
	Institue
	# Get the templates for plotting with or without fit
	TemplatesGnuForPlotWOfit
# ^^^ ----- Hard coded lines to check --- ^^^ 




RNDM=`echo $(( $RANDOM % 10000 ))`

if [ $# -lt 2 ] ; then 
	echo "Usage $0 LIN PIX [LIN PIX] [-f -r -t -events=PATH -d -D -g -png] " 
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
	echo ""
	exit
fi


RUNDIR=`pwd`

# Filst pixel
if [[ $1 =~ ^[0-9]+$ ]] ; then LIN1=$1 ; else echo "Must provide a Line coord in Parameter 1" ; exit 0 ; fi
if [[ $2 =~ ^[0-9]+$ ]] ; then PIX1=$2 ; else echo "Must provide a Pixel coord in Parameter 2" ; exit 0 ; fi

# second pixel (optional)
if [ $# -eq 2 ] ; then TWOPIXELS="NO" ; fi
if [[ $3 =~ ^[0-9]+$ ]] ; then LIN2=$3 ; else TWOPIXELS="NO" ; fi
if [[ $4 =~ ^[0-9]+$ ]] ; then PIX2=$4 ; TWOPIXELS="YES" ; else TWOPIXELS="NO" ; fi

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
				${PATHGNU}/gawk '/'\#${KEY}'/{system("cat TMPTABLE_'${RNDM}'.txt");next}1' plotTS_${LIN1}_${PIX1}_${LIN2}_${PIX2}_events.gnu > plotTS_${LIN1}_${PIX1}_${LIN2}_${PIX2}_events.gnu.tmp
				mv plotTS_${LIN1}_${PIX1}_${LIN2}_${PIX2}_events.gnu.tmp plotTS_${LIN1}_${PIX1}_${LIN2}_${PIX2}_events.gnu
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
				${PATHGNU}/gawk '/'\#${KEY}'/{system("cat TMPTABLE_'${RNDM}'.txt");next}1' plotTS_${LIN1}_${PIX1}_${LIN2}_${PIX2}_events.gnu > plotTS_${LIN1}_${PIX1}_${LIN2}_${PIX2}_events.gnu.tmp
				mv plotTS_${LIN1}_${PIX1}_${LIN2}_${PIX2}_events.gnu.tmp plotTS_${LIN1}_${PIX1}_${LIN2}_${PIX2}_events.gnu
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
						#echo "set arrow from ${STARTDATESEC},${MIN} to ${STARTDATESEC},${MAX} nohead lc rgb \"${COLOR}\" lt 1 lw 2 dt 2  " >> TMPTABLE_${RNDM}.txt
						echo "set arrow from ${STARTDATESEC}, graph 0 to ${STARTDATESEC}, graph 1 nohead lc rgb \"${COLOR}\" lt 1 lw 2 dt 2  " >> TMPTABLE_${RNDM}.txt

						# remove underscores which would be interpreted by gnoplot
						EVENTNAME=`echo ${EVENTNAME} | ${PATHGNU}/gsed 's/_/ /g' `
						echo "set label \"${EVENTNAME}\" at  ${STARTDATESEC}, graph 0.15 ${ROTATE}" >> TMPTABLE_${RNDM}.txt
				done < ${DATEFILES}

				# inserted TMPTABLE_${RNDM}.txt in gnu template where ERUPTION_TABLE string is located
				${PATHGNU}/gawk '/'\#${KEY}'/{system("cat TMPTABLE_'${RNDM}'.txt");next}1' plotTS_${LIN1}_${PIX1}_${LIN2}_${PIX2}_events.gnu > plotTS_${LIN1}_${PIX1}_${LIN2}_${PIX2}_events.gnu.tmp
				mv plotTS_${LIN1}_${PIX1}_${LIN2}_${PIX2}_events.gnu.tmp plotTS_${LIN1}_${PIX1}_${LIN2}_${PIX2}_events.gnu
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
cd ${RUNDIR}
HDR=`ls *.hdr | head -1` 
if [ ! -s ${HDR} ] ; then echo "No hdr file - please check your dir."; exit; fi

# Get first time series 
${PATHTOME}/getLineThroughStack ${RUNDIR} ${LIN1} ${PIX1}

sort timeLine${LIN1}_${PIX1}.txt > timeLine${LIN1}_${PIX1}.tmp.txt
rm timeLine${LIN1}_${PIX1}.txt
mv timeLine${LIN1}_${PIX1}.tmp.txt timeLine${LIN1}_${PIX1}.txt

# Get first and last date 
FIRSTDATE=`head -1 timeLine${LIN1}_${PIX1}.txt | cut -c 1-8`
LASTDATE=`tail -1 timeLine${LIN1}_${PIX1}.txt | cut -c 1-8`
echo "Full time series runs from ${FIRSTDATE} to ${LASTDATE}"

#Get min max of values in col3
MINPIX1=`${PATHGNU}/gawk '{print $3}' timeLine${LIN1}_${PIX1}.txt | tail -1`
MAXPIX1=`${PATHGNU}/gawk '{print $3}' timeLine${LIN1}_${PIX1}.txt | head -1`
if [ "${MINPIX1}" == "${MAXPIX1}" ] ; then echo "Empty time series 1" ; exit 0 ; fi
if [ `echo "${MINPIX1} > ${MAXPIX1}" | bc` -eq 1 ]
	then 
		TMP=${MINPIX1}
		MINPIX1=${MAXPIX1}
		MAXPIX1=${TMP} 
fi
echo "Time series 1 goes from ${MINPIX1} to ${MAXPIX1}"

# PLOT (without tags for events)

# Set size in template 
#IMGSAMPLES=`cat ${HDR} | ${PATHGNU}/grep "Samples" | ${PATHGNU}/grep -oP '\D+\K\d+' ` 
#IMGLINES=`cat ${HDR} | ${PATHGNU}/grep "Lines" | ${PATHGNU}/grep -oP '\D+\K\d+' `
SENSOR=`cat ${HDR} | ${PATHGNU}/grep "sensor" | cut -d = -f 3 `
HEADING=`cat ${HDR} | ${PATHGNU}/grep "Heading" | cut -d = -f 2 | cut -d " " -f 2 `
#MODE=`basename ${RUNDIR} | cut -d _ -f 2`
MODE=`basename ${RUNDIR} | cut -d _ -f 2-3`

cp ${GNUTEMPLATE} plotTS_${LIN1}_${PIX1}.gnu

# Change title
if [ "${LINFIT}" == "YES" ]
	then
		${PATHGNU}/gsed -i '1i set fit logfile "'${RUNDIR}'/fit_'${RNDM}'1.log"' plotTS_${LIN1}_${PIX1}.gnu
		TITLE="Ground displacement ${SENSOR} ${HEADING} ${MODE} and linear fit; pixel ${LIN1} ${PIX1} - Last date is ${LASTDATE} "
		CMD_LINE=`echo "plot 'PATH_TO_EPS.txt' u 1: 3 with linespoints ls 1 title 'Comp', f(x) ls 4 title 'Lin Fit' "`
					
		if [ ${LINRATE} == "YES" ] ; then
			${PATHGNU}/gsed -i "s/# ANNUALRATE/set label sprintf('Linear rate = %.2f cm\/yr', annualrate(b) ) at  graph 0.84,0.02 front /" plotTS_${LIN1}_${PIX1}.gnu
		fi

	else 
		TITLE="Ground displacement ${SENSOR} ${HEADING} ${MODE}; pixel ${LIN1} ${PIX1} - Last date is ${LASTDATE} "
		CMD_LINE=`echo "plot 'PATH_TO_EPS.txt' u 1: 3 with linespoints ls 1 "`
fi	
${PATHGNU}/gsed -i "s%CMD_LINE%${CMD_LINE}%" plotTS_${LIN1}_${PIX1}.gnu

# Change input time series txt name
${PATHGNU}/gsed -i "s%PATH_TO_EPS%timeLine${LIN1}_${PIX1}%" plotTS_${LIN1}_${PIX1}.gnu

# Change title
${PATHGNU}/gsed -i "s%TITLE%${TITLE}%" plotTS_${LIN1}_${PIX1}.gnu

# Change INSTITUTE name 
${PATHGNU}/gsed -i "s%INSTITUTE%${INSTITUTE}%" plotTS_${LIN1}_${PIX1}.gnu

# Change time span
if [ ${SPAN} == "YES" ]
	then 
		${PATHGNU}/gsed -i "s%# XRANGE%set xrange [${STARTSPANSEC}:${STOPSPANSEC}]%" plotTS_${LIN1}_${PIX1}.gnu
fi

${PATHGNU}/gnuplot plotTS_${LIN1}_${PIX1}.gnu


# SECOND TIME SERIES IF NEEDED
##############################
if [ ${TWOPIXELS} == "YES" ] ; then 

	getLineThroughStack ${RUNDIR} ${LIN2} ${PIX2}

	sort timeLine${LIN2}_${PIX2}.txt > timeLine${LIN2}_${PIX2}.tmp.txt
	rm timeLine${LIN2}_${PIX2}.txt
	mv timeLine${LIN2}_${PIX2}.tmp.txt timeLine${LIN2}_${PIX2}.txt

	#Get min max of values in col3
	MINPIX2=`${PATHGNU}/gawk '{print $3}' timeLine${LIN2}_${PIX2}.txt | tail -1`
	MAXPIX2=`${PATHGNU}/gawk '{print $3}' timeLine${LIN2}_${PIX2}.txt | head -1`
	if [ "${MINPIX2}" == "${MAXPIX2}" ] ; then echo "Empty time series 2" ; exit 0 ; fi
	if [ `echo "${MINPIX2} > ${MAXPIX2}" | bc` -eq 1 ]
		then 
			TMP=${MINPIX2}
			MINPIX2=${MAXPIX2}
			MAXPIX2=${TMP} 
	fi
	echo "Time series 2 goes from ${MINPIX2} to ${MAXPIX2}"


	# PLOT SERIE 2 (without tags for events)

	cp ${GNUTEMPLATE} plotTS_${LIN2}_${PIX2}.gnu

		# Change title
		if [ "${LINFIT}" == "YES" ]
			then
				${PATHGNU}/gsed -i '1i set fit logfile "'${RUNDIR}'/fit_'${RNDM}'2.log"' plotTS_${LIN2}_${PIX2}.gnu
				TITLE="Ground displacement ${SENSOR} ${HEADING} ${MODE} and linear fit; pixel ${LIN2} ${PIX2} - Last date is ${LASTDATE} "
				CMD_LINE=`echo "plot 'PATH_TO_EPS.txt' u 1: 3 with linespoints ls 1 title 'Comp', f(x) ls 4 title 'Lin Fit ' "`
							
				if [ ${LINRATE} == "YES" ] ; then
					${PATHGNU}/gsed -i "s/# ANNUALRATE/set label sprintf('Linear rate = %.2f cm\/yr', annualrate(b) ) at  graph 0.84,0.02 front /" plotTS_${LIN2}_${PIX2}.gnu
				fi

			else 
				TITLE="Ground displacement ${SENSOR} ${HEADING} ${MODE} ; pixel ${LIN2} ${PIX2} - Last date is ${LASTDATE} "
				CMD_LINE=`echo "plot 'PATH_TO_EPS.txt' u 1: 3 with linespoints ls 1 "`
		fi	
		${PATHGNU}/gsed -i "s%CMD_LINE%${CMD_LINE}%" plotTS_${LIN2}_${PIX2}.gnu


	# Change input time series txt name
	${PATHGNU}/gsed -i "s%PATH_TO_EPS%timeLine${LIN2}_${PIX2}%" plotTS_${LIN2}_${PIX2}.gnu

	# Change title
	${PATHGNU}/gsed -i "s%TITLE%${TITLE}%" plotTS_${LIN2}_${PIX2}.gnu

	# Change INSTITUTE name 
	${PATHGNU}/gsed -i "s%INSTITUTE%${INSTITUTE}%" plotTS_${LIN2}_${PIX2}.gnu


	# Change time span
	if [ ${SPAN} == "YES" ]
		then 
			${PATHGNU}/gsed -i "s%# XRANGE%set xrange [${STARTSPANSEC}:${STOPSPANSEC}]%" plotTS_${LIN2}_${PIX2}.gnu
	fi

	${PATHGNU}/gnuplot plotTS_${LIN2}_${PIX2}.gnu


	# find min max for whole plot
	#############################
	if [ `echo "${MINPIX1} > ${MINPIX2}" | bc` -eq 1 ] ; then MIN=${MINPIX2} ; else MIN=${MINPIX1} ; fi
	#MIN=`echo "${MIN} -0.1" | bc -l`

	if [ `echo "${MAXPIX1} > ${MAXPIX2}" | bc` -eq 1 ] ; then MAX=${MAXPIX1} ; else MAX=${MAXPIX2} ; fi
	#MAX=`echo "${MAX} +0.1" | bc -l`
	echo "min max are ${MIN} and ${MAX}"

	# and get the double difference
	###############################

	if [ ${ADDEVENTS} == "YES" ] ; then GNUNAME=plotTS_${LIN1}_${PIX1}_${LIN2}_${PIX2}_events.gnu ; else GNUNAME=plotTS_${LIN1}_${PIX1}_${LIN2}_${PIX2}.gnu ; fi 

	cp ${GNUTEMPLATE} ${GNUNAME}

	#merge line by lines the two txt files
	paste timeLine${LIN1}_${PIX1}.txt timeLine${LIN2}_${PIX2}.txt > timeLine${LIN1}_${PIX1}_${LIN2}_${PIX2}.txt

	if [ "${LINFIT}" == "YES" ] 
		then
			${PATHGNU}/gsed -i '1i set fit logfile "'${RUNDIR}'/fit_'${RNDM}'3.log"' ${GNUNAME}			
			TITLE="Ground displacement and linear fit ${SENSOR} ${HEADING} ${MODE} ; pixel ${LIN1} ${PIX1} - pixel ${LIN2} ${PIX2} - Last date is ${LASTDATE}"
			# Add events
			PlotEvents

			CMD_LINE=`echo "plot 'PATH_TO_EPS.txt' u 1:3 with linespoints ls 1 title 'Comp', f(x) ls 4 title 'Lin Fit '"`

			if [ ${LINRATE} == "YES" ] ; then
				${PATHGNU}/gsed -i "s/# ANNUALRATE/set label sprintf('Linear rate = %.2f cm\/yr', annualrate(b) ) at  graph 0.82,0.02 front /" ${GNUNAME}
			fi

		else 
			TITLE="Ground displacement ${SENSOR} ${HEADING} ${MODE} ; pixel ${LIN1} ${PIX1} - pixel ${LIN2} ${PIX2} - Last date is ${LASTDATE}"
			# Add events
			PlotEvents
						
			CMD_LINE=`echo "plot 'PATH_TO_EPS.txt' u 1:3 with linespoints ls 1"`
	fi	
	${PATHGNU}/gsed -i "s%CMD_LINE%${CMD_LINE}%" ${GNUNAME}

	${PATHGNU}/gsed -i "s%u 1:3%u 1: (\$3 - \$6)%g" ${GNUNAME}  # several syntax may be possible
	${PATHGNU}/gsed -i "s%u 1: 3%u 1: (\$3 - \$6)%g" ${GNUNAME}
	${PATHGNU}/gsed -i "s%using 1:3%using 1: (\$3 - \$6)%g" ${GNUNAME} # several syntax may be possible
	${PATHGNU}/gsed -i "s%using 1: 3%using 1: (\$3 - \$6)%g"  ${GNUNAME}
	
	${PATHGNU}/gsed -i "s%TITLE%${TITLE}%" ${GNUNAME}

	# Change INSTITUTE name 
	${PATHGNU}/gsed -i "s%INSTITUTE%${INSTITUTE}%" ${GNUNAME}

	# Change output name
	${PATHGNU}/gsed -i "s%PATH_TO_EPS%timeLine${LIN1}_${PIX1}_${LIN2}_${PIX2}%" ${GNUNAME}

	# Change time span
	if [ ${SPAN} == "YES" ]
		then 
			${PATHGNU}/gsed -i "s%# XRANGE%set xrange [${STARTSPANSEC}:${STOPSPANSEC}]%" ${GNUNAME}
	fi

	gnuplot ${GNUNAME}

fi   # end of if for 2 pixels

# Some optional cleaning 
########################
# Cleaning text files with individual TS values
if [ ${DELPIXVAL} == "YES" ] || [ ${DELDDVAL} == "YES" ] ; then rm -f timeLine${LIN1}_${PIX1}.txt timeLine${LIN2}_${PIX2}.txt ; fi
# Cleaning text files with Double Difference TS values
if [ ${DELDDVAL} == "YES" ] ; then rm -f timeLine${LIN1}_${PIX1}_${LIN2}_${PIX2}.txt ; fi
# Cleaning gnuplot scripts 
if [ ${DELGNU} == "YES" ] ; then rm -f plotTS_${LIN1}_${PIX1}.gnu plotTS_${LIN2}_${PIX2}.gnu ${GNUNAME} ; fi

rm -f ${RUNDIR}/fit_${RNDM}1.log  ${RUNDIR}/fit_${RNDM}2.log ${RUNDIR}/fit_${RNDM}3.log

# Make optional png files
#########################
if [ ${PNGPLOT} == "YES" ]
	then 
		EPSLIST=`echo "timeLine${LIN1}_${PIX1}.eps timeLine${LIN2}_${PIX2}.eps timeLine${LIN1}_${PIX1}_${LIN2}_${PIX2}.eps"`
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
	EPSFILE=$(find . -type f -name "*${LIN1}_${PIX1}_${LIN2}_${PIX2}.eps")
	${PATH_SCRIPTS}/SCRIPTS_MT/TS_AddLegend_LOS.sh ${EPSFILE}
fi
#-------------                 end              --------------#

