#Option: -R[unit]xmin/xmax/ymin/ymax[r]
#Hawaii data set
#gmt xyz2grd  $1 -Gdata.bin -R-155.5/-155.1/19.17/19.54 -I2001+/1851+ -N0  -ZTLfw -V

#9    		# FORCEGEOPIXSIZE, Pix size wanted eg as you want for your final MSBAS database
#748000		# XMIN, minimum X UTM coord of final geocoded product
#752500		# XMAX, maximum X UTM coord of final geocoded product
#9829000		# YMIN, minimum Y UTM coord of final geocoded product
#9833500		# YMAX, maximum Y coord of final geocoded product

gmt xyz2grd  $1 -Gdata.bin -R29.22895339316599/29.269334381785153/-1.545291/-1.504584 -I502+/502+ -di0  -ZTLf -V 
#gmt xyz2grd  $1 -Gdata.bin -R703000/712800/9716000/9727000 -I1226+/1376+ -di0  -ZTLf -V


#Hawaii data set
#bash plot_gmt5.sh $1 -155.40 -155.15 19.20 19.5

#Funu data set
bash plot_gmt5.sh $1 29.22895339316599 29.269334381785153 -1.545291 -1.504584
#bash plot_gmt5.sh $1 703000 712800 9716000 9727000

gmt psconvert $1.eps -Tj -A -E600
#mv data.bin $1.grd
mv data.bin $1.grd

rm $1.eps 
