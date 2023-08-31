#!/bin/bash

#useful scripts
#mapproject tmp -C -I -F -R14/15/35/38 -JU33/1

############################################################################## 
# sets GMT defaults
############################################################################## 

rm .gmtdefaults*
gmt gmtdefaults -D > .gmtdefaults5
gmt gmtset PROJ_LENGTH_UNIT inch FORMAT_GEO_MAP ddd:mm MAP_FRAME_TYPE plain MAP_FRAME_AXES WeSn FONT_ANNOT_PRIMARY 10 FONT_ANNOT_PRIMARY 10		

imgtoplot=$1
# the window
longmin=$2
longmax=$3
latmin=$4
latmax=$5

min=`gmt grdinfo data.bin  | grep x_min: | awk '{print $3}'`
max=`gmt grdinfo data.bin  | grep x_min: | awk '{print $5}'`
scale=`echo $min $max | awk '{print int(60*($2-$1)/4);}'`

range=$longmin/$longmax/$latmin/$latmax
projection=M$longmin/$latmin/6.5
ticks="$scale"mg10d:.:

psfile=$imgtoplot".eps"
############################################################################## 
# starts plotting
############################################################################## 


#  draws basemap
gmt psbasemap -B$ticks -J$projection -R$range -X0.75 -Y0.5 -P -V -K > $psfile
#gmt psbasemap -B$ticks -J$projection -R$range -P -V -K > $psfile

gmt grdclip data.bin -Sa3.99/3.99 -Sb-3.99/-3.99 -G1.b
mv 1.b data.bin

# sets color scale
min=`gmt grdinfo data.bin  | grep z_min: | awk '{print $3}'`
max=`gmt grdinfo data.bin  | grep z_min: | awk '{print $5}'`
scale=`echo $min $max | awk '{if ($1*$1>$2*$2) print int(10*sqrt($1*$1)+1)/10; else print int(10*sqrt($2*$2)+1)/10;}'`
gmt makecpt -T-$scale/$scale/0.2 -Z -V -Crainbow > color.cpt

gmt grdimage data.bin -J$projection  -R$range -Ccolor.cpt -O -V -K -P -Ei -Q >> $psfile

#gmt grdgradient data.bin -A10/270 -Gdata_grad.bin -Ne0.6 -V
#gmt grdimage data.bin -J$projection  -R$range -Ccolor.cpt -Idata_grad.bin -O -V -K -P >> $psfile

#  draws coast line
gmt pscoast -J$projection -Ba0.2f0.1 -BWSne -A1 -N1 -Lf28.9/-1.15/0/10+l -R$range -Df -O -V -W1 -S235/235/255 -K -P -X0.75 -Y0.5 >> $psfile
#from Halldor for GPS
#gmt pscoast -JM16 -R28.8/29.5/-1.9/-1.1  -Ba0.2f0.1 -BWSne -A1 -N1 -Df -S90/200/255 -W1 -Lf28.9/-1.15/0/10+l -P -K -X2.0 -Y3.0 > $PS

latmean=`echo $latmin $latmax | awk '{print ($1+$2)/2}'`
#gmt pscoast -J$projection  -R$range -Df -O -V -W2 -S235/235/255 -K -P -Lfx5.5/0.5/$latmean/20+lkm  >> $psfile

#gmt psxy points2.txt  -R$region  -J$projection -W1,black -Gblack -Sd0.05c -O -V -K -: >>$psfile
#gmt pstext points2.txt -R$region -J$projection -O -K -P -D0.05c/0.05c -V -: -F+f16p,Helvetica,black+j+a>>$psfile

gmt pslegend  -J$projection  -R$range -F+gwhite -Dx0i/0.75i/2.5i/0.75i/TL -C0.1i/0.1i -L1.2 -F -B5f1 -K -V -O << EOF >> $psfile
EOF

gmt psscale -D1.1i/0.55i/1.5i/0.5ch -Ccolor.cpt -B$scale::/:cm: -P -O >> $psfile
rm color.cpt data.bin

