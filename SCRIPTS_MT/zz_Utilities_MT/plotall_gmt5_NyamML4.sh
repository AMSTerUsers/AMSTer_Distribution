#Option: -R[unit]xmin/xmax/ymin/ymax[r]
#Hawaii data set
#gmt xyz2grd  $1 -Gdata.bin -R-155.5/-155.1/19.17/19.54 -I2001+/1851+ -N0  -ZTLfw -V

#743200		# XMIN, minimum X UTM coord of final geocoded product
#747700		# XMAX, maximum X UTM coord of final geocoded product
#9840000		# YMIN, minimum Y UTM coord of final geocoded product
#9846000		# YMAX, maximum Y coord of final geocoded product

gmt xyz2grd  $1 -Gdata.bin -R29.185735251572982/29.226106374578833/-1.445929/-1.391669 -I502+/668+ -di0  -ZTLf -V 
#gmt xyz2grd  $1 -Gdata.bin -R703000/712800/9716000/9727000 -I1226+/1376+ -di0  -ZTLf -V


#Hawaii data set
#bash plot_gmt5.sh $1 -155.40 -155.15 19.20 19.5

#Funu data set
bash plot_gmt5.sh $1 29.185735251572982 29.226106374578833 -1.445929 -1.391669
#bash plot_gmt5.sh $1 703000 712800 9716000 9727000

gmt psconvert $1.eps -Tj -A -E600
#mv data.bin $1.grd
mv data.bin $1.grd

rm $1.eps 
