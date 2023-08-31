#Option: -R[unit]xmin/xmax/ymin/ymax[r]
#Hawaii data set
#gmt xyz2grd  $1 -Gdata.bin -R-155.5/-155.1/19.17/19.54 -I2001+/1851+ -N0  -ZTLfw -V

#Funu data set : see LaunchMTparam file : 
#8    		# FORCEGEOPIXSIZE, Pix size wanted eg as you want for your final MSBAS database
#703000		# XMIN, minimum X UTM coord of final geocoded product
#712800		# XMAX, maximum X UTM coord of final geocoded product
#9716000		# YMIN, minimum Y UTM coord of final geocoded product
#9727000		# YMAX, maximum Y coord of final geocoded product

gmt xyz2grd  $1 -Gdata.bin -R28.825820154107955/28.91378580613603/-2.567082/-2.467529 -I246+/276+ -di0  -ZTLf -V
#gmt xyz2grd  $1 -Gdata.bin -R703000/712800/9716000/9727000 -I1226+/1376+ -di0  -ZTLf -V


#Hawaii data set
#bash plot_gmt5.sh $1 -155.40 -155.15 19.20 19.5

#Funu data set
bash plot_gmt5.sh $1 28.825820154107955 28.91378580613603 -2.567082 -2.467529
#bash plot_gmt5.sh $1 703000 712800 9716000 9727000

gmt psconvert $1.eps -Tj -A -E600
#mv data.bin $1.grd
mv data.bin $1.grd

rm $1.eps 
