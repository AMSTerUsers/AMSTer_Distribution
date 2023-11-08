#! /bin/bash
# -----------------------------------------------------------------------------------------
# This script was written by Sergey Samsonov for the MSBAS software
# -----------------------------------------------------------------------------------------


[[ $# != 1  || ! -f ${1} ]] && {
    echo "provide file to plot, exitinig..."
    exit 1
}

nc=$(awk 'NR == 1 { print NF; exit; }' ${1})
outname=$(echo ${1} | awk '{gsub(/.txt/,"")}; 1')

[[ ${nc} -eq 4 ]] && {

gnuplot << EOF
set title '${1}' offset 0,0
set xlabel "Time, year"
set ylabel "Displacement, m"
set autoscale
set size 1, 1
set key bottom left 
set output "${outname}.pdf" 
set terminal pdf noenhanced crop font "Helvetica,10"
plot "${1}" using 2:3:4 with yerrorbars title "LOS" lw 2 lt 1 lc rgb '#5DA5DA', "${1}" using 2:3 with lines notitle lw 2 lt 1 lc rgb '#5DA5DA'
EOF
}


[[ ${nc} -eq 6 ]] && {

gnuplot << EOF
set title '${1}' offset 0,0
set xlabel "Time, year"
set ylabel "Displacement, m"
set autoscale
set size 1, 1
set key bottom left 
set output "${outname}.pdf" 
set terminal pdf noenhanced crop font "Helvetica,10"
plot "${1}" using 2:3:4 with yerrorbars title "East-West" lw 2 lt 1 lc rgb '#5DA5DA', "${1}" using 2:5:6 with yerrorbars title "Vertical" lw 2 lt 1 lc rgb '#B276B2', "${1}" using 2:3 with lines notitle lw 2 lt 1 lc rgb '#5DA5DA', "${1}" using 2:5 with lines notitle "Vertical" lw 2 lt 1 lc rgb '#B276B2'
EOF
}


#    4D4D4D (gray)
#    5DA5DA (blue)
#    FAA43A (orange)
#    60BD68 (green)
#    F17CB0 (pink)
#    B2912F (brown)
#    B276B2 (purple)
#    DECF3F (yellow)
#    F15854 (red)
