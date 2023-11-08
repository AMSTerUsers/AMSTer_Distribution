#! Gnuplot mastershell for plotting stuff
# DO NOT CHANGE BELOW AS IT IS CALLED AND EDITED BY PlotTS.sh

set terminal png font "Helvetica,8"
set output "timeLines_808_605_830_605_Auto_2_0.04_VVP.png" 

set multiplot

#set size square
set grid
set xdata time 
set timefmt "%Y%m%d"
set format x "%Y\n%b"
#set xtics 0.5 font "Helvetica,20" rotate by 45 right 
#set xtics font "Helvetica,20" rotate by 45 right
#set yrange [*:*] 
#set yrange [*:*] reverse


#set yrange [*:*] reverse
#set yrange [-0.12:0.04]
#set terminal postscript eps enhanced color font 'Helvetica,10'
#set term post landscape "Helvetica" 9


# some styles
set style line 1 lc rgb "blue" lt 1 lw 2 pt 7 ps 1.2   # --- blue
set style line 2 lc rgb "red" lt 1 lw 2 pt 5 ps 1.2   # --- red
set style line 3 lc rgb "green" lt 1 lw 2 pt 4 ps 0.8   # --- green
set style line 4 lc rgb "blue" lt 1 lw 1   # --- blue
set style line 5 lc rgb "red" lt 1 lw 2   # --- red
set style line 6 lc rgb "green" lt 1 lw 1   # --- green

### Plot Time series 


set title "Ground displacement EW+UD and linear fit; pixel 808 605 - pixel 830 605 as in _Auto_2_0.04_VVP \n Last date is 20200206" 
set key left bottom
#set key right top
#set key off
set title noenhanced

# UNCOMMENT BELOW IF WANTS ERUPTION BARS
# See convertion tool date to linux here : 
# https://www.epochconverter.com
#######################
# eruption04_start=1084017600    #20040508
# eruption04_stop=1085745600    #20040528
# 
# eruption06_start=1164628800    #20061127
# eruption06_stop=1165320000    #20061205
# 
# eruption10_start=1262433600    #20100102
# eruption10_stop=1264593600    #20100127
# 
# eruption11_start=1320537600    #20111106
# eruption11_stop=1333238400    #20120401 - exact date unknown

# Asymetric geometries 
#######################
# beginning_zone1=1022936400  		# 2002 06 01
# end_zone1=1109336400  		# 2005 02 025
#
# beginning_zone2=1285851600  		# 2010 09 30
# end_zone2=1302699600  			# 2011 04 13


# ASYMETRIC GEOMETRIES
######################
# set style rect fc lt -0.2 fs solid 0.15 noborder
# set obj rect from 1022936400, graph 0 to 1109336400, graph 1 fc rgbcolor "grey" behind
# set obj rect from 1285851600, graph 0 to 1302699600, graph 1 fc rgbcolor "grey" behind 

# ERUPTIONS
############
set style rect fc lt -1 fs solid 0.15 noborder
set obj rect from 1084017600, graph 0 to 1085745600, graph 1 fc rgbcolor "red" fs solid 0.15 behind
set obj rect from 1164628800, graph 0 to 1165320000, graph 1 fc rgbcolor "red" fs solid 0.45 behind
set obj rect from 1262433600, graph 0 to 1264593600, graph 1 fc rgbcolor "red" fs solid 0.15 behind
set obj rect from 1320537600, graph 0 to 1333238400, graph 1 fc rgbcolor "red" fs solid 0.15 behind

# SATELLITES
############
# set obj rect from 1302872400, graph 0.98 to 1496754000, graph 1 fc rgb "#0000FF" fs solid 0.15  behind  # CSK A
# set label "CSK Asc" at  1399813200, graph 0.99 
# set obj rect from 1302699600, graph 0.96 to 1496581200, graph 0.98 fc rgb "#8B2252" fs solid 0.15 behind   # CSK D
# set label "CSK Desc" at  1399813200, graph 0.97 
# 
# set obj rect from 1040821200, graph 0.98 to 1285851600, graph 1 fc rgb "#0000FF" fs solid 0.15 behind   # ENV A
# set label "ENV Asc" at  1163336400, graph 0.99 
# set obj rect from 1109336400, graph 0.96 to 1285851600, graph 0.98 fc rgb "#8B2252" fs solid 0.15 behind   # ENV D
# set label "ENV Desc" at  1197594000, graph 0.97 
# 
# set obj rect from 1330779600, graph 0.94 to 1540213200, graph 0.96 fc rgb "#0000FF" fs solid 0.15 behind   # RS A
# set label "RS Asc" at  1435496400, graph 0.95 
# set obj rect from 1269777600, graph 0.92 to 1539345600, graph 0.94 fc rgb "#8B2252" fs solid 0.15 behind   # RS D F2F
# set label "RS D F2F Desc" at  1404561600, graph 0.93 
# set obj rect from 1260878400, graph 0.90 to 1397736000, graph 0.92 fc rgb "#8B2252" fs solid 0.15 behind   # RS D F21N
# set label "RS D F21N" at  1329307200, graph 0.91 
# 
# 
# set obj rect from 1413550800, graph 0.90 to 1550667600, graph 0.92 fc rgb "#0000FF" fs solid 0.15 behind   # S1 A
# set label "S1 Asc" at  1482109200, graph 0.91 
# set obj rect from 1412686800, graph 0.88 to 1550667600, graph 0.90 fc rgb "#8B2252" fs solid 0.15 behind   # S1 D
# set label "S1 Desc" at  1481677200, graph 0.89 

# FIT
#####
f(x) = a+ b*x 
a = 1
b = 1e-8
fit f(x) 'timeLine_EW_808_605_830_605_Auto_2_0.04_VVP.txt' using 1: ($3 - $6) via a,b

g(x) = c+ d*x 
c = 1
d = 1e-8
fit g(x) 'timeLine_UD_808_605_830_605_Auto_2_0.04_VVP.txt' using 1: ($3 - $6) via c,d

set timestamp "Created by AMSTer at ECGS on: %d/%m/%y %H:%M " font "Helvetica,8" textcolor rgbcolor "#2a2a2a" 

plot 'timeLine_EW_808_605_830_605_Auto_2_0.04_VVP.txt' u 1: ($3 - $6) with linespoints title 'EW' ls 1, \
	f(x) ls 4 title 'Lin Fit EW', \
	'timeLine_UD_808_605_830_605_Auto_2_0.04_VVP.txt' u 1: ($3 - $6) with linespoints title 'UD' ls 3, \
	g(x) ls 6 title 'Lin Fit UD'
	
	
#plot 'timeLine_EW_808_605_830_605_Auto_2_0.04_VVP.txt' u 1: ($3 - $6) with linespoints title 'EW' ls 1, f(x) ls 4 title 'Lin Fit EW','PATH_TO_UD_EPS.txt' u 1: ($3 - $6) with linespoints title 'UD' ls 3, g(x) ls 6 title 'Lin Fit UD', eruption04_start,t, eruption04_stop,t, eruption06_start,t, eruption06_stop,t, eruption10_start,t, eruption10_stop,t, eruption11_start,t, eruption11_stop,t


# Background picture
unset tics
unset border
unset title 



set lmargin at screen 0.10
set rmargin at screen 0.40
set bmargin at screen 0.87
set tmargin at screen 0.57

set timestamp "Created by AMSTer at ECGS on: %d/%m/%y %H:%M " font "Helvetica,8" textcolor rgbcolor "#2a2a2a" 

#Plot the background image
plot '/Volumes/hp-D3602-Data_RAID5/MSBAS/_VVP_S1_Auto_20m_400days/zz_UD_EW_TS_Auto_2_0.04_VVP/_Accross_91_94_Flow_left_timeLines_Loca_808_605_830_605_S.png' binary filetype=png w rgbimage



unset multiplot
