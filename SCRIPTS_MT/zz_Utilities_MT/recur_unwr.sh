#!/bin/bash
# -----------------------------------------------------------------------------------------
# This script is aiming at launching snaphu for recursive unwrapping. If snaphu config file 
# does not exist, it creates it. 
#
# Parameters :  - Input file (complex interf as Re and Img in float32)
# 				- N of columns
#
# Hard coded: none
#
# Dependencies:
#	 - snaphu
#
# New in Distro V 1.0 (Oct 07, 2022):		- Based on developpement version 15.1 and Beta V5.1.1
# New in Distro V 2.0 20231030:	- Rename MasTer Toolbox as AMSTer Software
#								- rename Master and Slave as Primary and Secondary (though not possible in some variables and files)
#
# AMSTer: SAR & InSAR Automated Mass processing Software for Multidimensional Time series
# Delphine Smittarello (c) - could make better with more functions... when time.
# -----------------------------------------------------------------------------------------
PRG=`basename "$0"`
VER="Distro V2.0 AMSTer script utilities"
AUT="Delphine Smittarello, (c)2016-2019, Last modified on Oct 30, 2023"
echo " "
echo "${PRG} ${VER}, ${AUT}"
echo "Processing launched on $(date) " 
echo " " 

INFILE=$1
NBCOL=$2

# create snaphu conf file: 
if [ ! -f recur_unwr.brief ] ; then 

	echo "# snaphu configuration file " 												> recur_unwr.brief
	echo "# "																			>> recur_unwr.brief
	echo "# Lines with fewer than two fields and lines whose first non-whitespace  " 	>> recur_unwr.brief
	echo "# characters are not alphnumeric are ignored.  For the remaining lines,   " 	>> recur_unwr.brief
	echo "# anything after the first two fields (delimited by whitespace) is   " 		>> recur_unwr.brief
	echo "# also ignored.  Inputs are converted in the order they appear in the file;   " >> recur_unwr.brief
	echo "# if multiple assignments are made to the same parameter, the last one   " 	>> recur_unwr.brief
	echo "# given is the one used.  Parameters in this file will be superseded by   " 	>> recur_unwr.brief
	echo "# parameters given on the command line after the -f flag specifying this  "	>> recur_unwr.brief
	echo "# file.  Multiple configuration files may be given on the command line.  " 	>> recur_unwr.brief
	echo "  " 																			>> recur_unwr.brief
	echo "  " 																			>> recur_unwr.brief
	echo "  " 																			>> recur_unwr.brief
	echo "  " 																			>> recur_unwr.brief
	echo "#############################################  " 								>> recur_unwr.brief
	echo "# File input and output and runtime options #  " 								>> recur_unwr.brief
	echo "#############################################  " 								>> recur_unwr.brief
	echo "  " 																			>> recur_unwr.brief
	echo "  " 																			>> recur_unwr.brief
	echo "# See section below for file format configuration options.  "					>> recur_unwr.brief
	echo "  " 																			>> recur_unwr.brief
	echo "  " 																			>> recur_unwr.brief
	echo "# Input file name  "															>> recur_unwr.brief
	echo "# INFILE        snaphu.in  " 													>> recur_unwr.brief
	echo "  " 																			>> recur_unwr.brief
	echo "  " 																			>> recur_unwr.brief
	echo "# Input file line length   " 													>> recur_unwr.brief
	echo "# LINELENGTH    1000  " 														>> recur_unwr.brief
	echo "  " 																			>> recur_unwr.brief
	echo "  " 																			>> recur_unwr.brief
	echo "# Output file name  " 														>> recur_unwr.brief
	echo "# OUTFILE       snaphu.out  " 												>> recur_unwr.brief
	echo "  "																			>> recur_unwr.brief
	echo "  "																			>> recur_unwr.brief
	echo "# Amplitude file name(s)  " 													>> recur_unwr.brief
	echo "# AMPFILE       snaphu.amp.in   # Single file containing amplitude images  " 	>> recur_unwr.brief
	echo "  " 																			>> recur_unwr.brief
	echo "  " 																			>> recur_unwr.brief
	echo "# Correlation file name  " 													>> recur_unwr.brief
	echo "# CORRFILE      snaphu.corr.in  " 											>> recur_unwr.brief
	echo "  " 																			>> recur_unwr.brief
	echo "  " 																			>> recur_unwr.brief
	echo "# Statistical-cost mode (TOPO, DEFO, SMOOTH, or NOSTATCOSTS)  " 				>> recur_unwr.brief
	echo "# STATCOSTMODE  TOPO  " 														>> recur_unwr.brief
	echo "  " 																			>> recur_unwr.brief
	echo "  " 																			>> recur_unwr.brief
	echo "# Initialize-only mode (TRUE or FALSE)  " 									>> recur_unwr.brief
	echo "# INITONLY      FALSE  " 														>> recur_unwr.brief
	echo "  " 																			>> recur_unwr.brief
	echo "  " 																			>> recur_unwr.brief
	echo "# Algorithm used for initialization of wrapped phase values.  Possible  " 	>> recur_unwr.brief
	echo "# values are MST and MCF.    " 												>> recur_unwr.brief
	echo "# INITMETHOD    MST  " 														>> recur_unwr.brief
	echo "  " 																			>> recur_unwr.brief
	echo "  " 																			>> recur_unwr.brief
	echo "# Verbose-output mode (TRUE or FALSE)  " 										>> recur_unwr.brief
	echo "# VERBOSE       FALSE  " 														>> recur_unwr.brief
	echo "  " 																			>> recur_unwr.brief
	echo "  " 																			>> recur_unwr.brief
	echo "  " 																			>> recur_unwr.brief
	echo "################  " 															>> recur_unwr.brief
	echo "# File formats #  " 															>> recur_unwr.brief
	echo "################  " 															>> recur_unwr.brief
	echo "  " 																			>> recur_unwr.brief
	echo "  " 																			>> recur_unwr.brief
	echo "# Valid data formats:  " 														>> recur_unwr.brief
	echo "#  " 																			>> recur_unwr.brief
	echo "# COMPLEX_DATA:      complex values: real, imag, real, imag  "				>> recur_unwr.brief
	echo "# ALT_LINE_DATA:     real values from different arrays, alternating by line  " >> recur_unwr.brief
	echo "# ALT_SAMPLE_DATA:   real values from different arrays, alternating by sample  " >> recur_unwr.brief
	echo "# FLOAT_DATA:        single array of floating-point data  " 					>> recur_unwr.brief
	echo "#   " 																		>> recur_unwr.brief
	echo "  " 																			>> recur_unwr.brief
	echo "  " 																			>> recur_unwr.brief
	echo "# The ALT_SAMPLE_DATA format is sometimes known as .amp or sample-  " 		>> recur_unwr.brief
	echo "# interleaved format; the ALT_LINE_DATA format is sometimes known as  " 		>> recur_unwr.brief
	echo "# .hgt or line-interleaved format.  For the ALT_LINE_DATA format, the  " 		>> recur_unwr.brief
	echo "# first array is always assumed to be the interferogram magnitude.  All  " 	>> recur_unwr.brief
	echo "# formats assume single-precision (32-bit) floating-point data (real*4  " 	>> recur_unwr.brief
	echo "# and complex*8 in Fortran) in the native byte order (big vs. little  " 		>> recur_unwr.brief
	echo "# endian) of the system.  " 													>> recur_unwr.brief
	echo "  " 																			>> recur_unwr.brief
	echo "  " 																			>> recur_unwr.brief
	echo "  " 																			>> recur_unwr.brief
	echo "# Input file format  " 														>> recur_unwr.brief
	echo "# Allowable formats:  " 														>> recur_unwr.brief
	echo "#   COMPLEX_DATA        (default)  " 											>> recur_unwr.brief
	echo "#   ALT_LINE_DATA       (magnitude in channel 1, phase in radians in channel 2)  " >> recur_unwr.brief
	echo "#   ALT_SAMPLE_DATA     (magnitude in channel 1, phase in radians in channel 2)  " >> recur_unwr.brief
	echo "#   FLOAT_DATA          (phase in radians)  " 								>> recur_unwr.brief
	echo "#  " 																			>> recur_unwr.brief
	echo "INFILEFORMAT            COMPLEX_DATA  " 										>> recur_unwr.brief
	echo "  " 																			>> recur_unwr.brief
	echo "  " 																			>> recur_unwr.brief
	echo "# Output file format  " 														>> recur_unwr.brief
	echo "# Allowable formats:  " 														>> recur_unwr.brief
	echo "#   ALT_LINE_DATA       (interferogram magnitude in channel 1,   " 			>> recur_unwr.brief
	echo "#                        unwrapped phase in radians in channel 2; default)  " >> recur_unwr.brief
	echo "#   ALT_SAMPLE_DATA     (interferogram magnitude in channel 1,   " 			>> recur_unwr.brief
	echo "#                        unwrapped phase in radians in channel 2)  " 			>> recur_unwr.brief
	echo "#   FLOAT_DATA          (unwrapped phase in radians)  " 						>> recur_unwr.brief
	echo "#  " 																			>> recur_unwr.brief
	echo "OUTFILEFORMAT           FLOAT_DATA  " 										>> recur_unwr.brief
	echo "  " 																			>> recur_unwr.brief
	echo "  " 																			>> recur_unwr.brief
	echo "# Amplitude or power file format  " 											>> recur_unwr.brief
	echo "# Units should be consistent with interferogram.  Allowable formats:  " 		>> recur_unwr.brief
	echo "#   ALT_LINE_DATA       (first image amplitude in channel 1,   " 				>> recur_unwr.brief
	echo "#                        second image amplitude in channel 2)  " 				>> recur_unwr.brief
	echo "#   ALT_SAMPLE_DATA     (first image amplitude in channel 1,   " 				>> recur_unwr.brief
	echo "#                        second image amplitude in channel 2; default)  " 	>> recur_unwr.brief
	echo "#   FLOAT_DATA          (square root of average power of two images)  " 		>> recur_unwr.brief
	echo "  " 																			>> recur_unwr.brief
	echo "#AMPFILEFORMAT          FLOAT_DATA  " 										>> recur_unwr.brief
	echo "  " 																			>> recur_unwr.brief
	echo "  " 																			>> recur_unwr.brief
	echo "# Correlation file format  " 													>> recur_unwr.brief
	echo "# Allowable formats:  " 														>> recur_unwr.brief
	echo "#   ALT_LINE_DATA       (channel 1 ignored; correlation values   " 			>> recur_unwr.brief
	echo "#                        between 0 and 1 in channel 2; default)  " 			>> recur_unwr.brief
	echo "#   ALT_SAMPLE_DATA     (channel 1 ignored; correlation values   " 			>> recur_unwr.brief
	echo "#                        between 0 and 1 in channel 2)  " 					>> recur_unwr.brief
	echo "#   FLOAT_DATA          (correlation values between 0 and 1)  " 				>> recur_unwr.brief
	echo "  " 																			>> recur_unwr.brief
	echo "CORRFILEFORMAT         FLOAT_DATA  " 											>> recur_unwr.brief
	echo "  " 																			>> recur_unwr.brief
	echo "  " 																			>> recur_unwr.brief
	echo "  " 																			>> recur_unwr.brief
	echo "###############################  " 											>> recur_unwr.brief
	echo "# SAR and geometry parameters #  " 											>> recur_unwr.brief
	echo "###############################  " 											>> recur_unwr.brief
	echo "  " 																			>> recur_unwr.brief
	echo "  " 																			>> recur_unwr.brief
	echo "# Orbital radius (double, meters) or altitude (double, meters).  The  " 		>> recur_unwr.brief
	echo "# radius should be the local radius if the orbit is not circular.  The  " 	>> recur_unwr.brief
	echo "# altitude is just defined as the orbit radius minus the earth radius.  " 	>> recur_unwr.brief
	echo "# Only one of these two parameters should be given.    " 						>> recur_unwr.brief
	echo "#ORBITRADIUS            7153000.0  " 											>> recur_unwr.brief
	echo "#ALTITUDE               775000.0  " 											>> recur_unwr.brief
	echo "ALTITUDE                798000.0  " 											>> recur_unwr.brief
	echo "  " 																			>> recur_unwr.brief
	echo "  " 																			>> recur_unwr.brief
	echo "# Local earth radius (double, meters).  A spherical-earth model is  " 		>> recur_unwr.brief
	echo "# used.  "																	>> recur_unwr.brief
	echo "EARTHRADIUS             6378000.0  " 											>> recur_unwr.brief
	echo "  " 																			>> recur_unwr.brief
	echo "  " 																			>> recur_unwr.brief
	echo "# The baseline parameters are not used in deformation mode, but they  " 		>> recur_unwr.brief
	echo "# are very important in topography mode.  The parameter BASELINE  " 			>> recur_unwr.brief
	echo "# (double, meters) is the physical distance (always positive) between  " 		>> recur_unwr.brief
	echo "# the antenna phase centers.  The along-track componenet of the  " 			>> recur_unwr.brief
	echo "# baseline is assumed to be zero.  The parameter BASELINEANGLE_DEG  " 		>> recur_unwr.brief
	echo "# (double, degrees) is the angle between the antenna phase centers  " 		>> recur_unwr.brief
	echo "# with respect to the local horizontal.  Suppose the interferogram is  " 		>> recur_unwr.brief
	echo "# s1*conj(s2).  The baseline angle is defined as the angle of antenna2  " 	>> recur_unwr.brief
	echo "# above the horizontal line extending from antenna1 towards the side  " 		>> recur_unwr.brief
	echo "# of the SAR look direction.  Thus, if the baseline angle minus the  " 		>> recur_unwr.brief
	echo "# look angle is less than -pi/2 or greater than pi/2, the topographic  " 		>> recur_unwr.brief
	echo "# height increases with increasing elevation.  The units of  " 				>> recur_unwr.brief
	echo "# BASELINEANGLE_RAD are radians.  " 											>> recur_unwr.brief
	echo "BASELINE                150.0  " 												>> recur_unwr.brief
	echo "BASELINEANGLE_DEG       225.0  " 												>> recur_unwr.brief
	echo "#BASELINEANGLE_RAD      3.92699  " 											>> recur_unwr.brief
	echo "  " 																			>> recur_unwr.brief
	echo "  " 																			>> recur_unwr.brief
	echo "# If the BPERP parameter is given, the baseline angle is taken to be  " 		>> recur_unwr.brief
	echo "# equal to the look angle (mod pi) at midswath, and the length of the  " 		>> recur_unwr.brief
	echo "# baseline is set accordingly.  Particular attention must be paid to  " 		>> recur_unwr.brief
	echo "# the sign of this parameter--it should be negative if increasing  " 			>> recur_unwr.brief
	echo "# phase implies increasing topographic height.    " 							>> recur_unwr.brief
	echo "#BPERP          -150.0  " 													>> recur_unwr.brief
	echo "  " 																			>> recur_unwr.brief
	echo "  " 																			>> recur_unwr.brief
	echo "# The transmit mode should be either REPEATPASS or PINGPONG if both  " 		>> recur_unwr.brief
	echo "# antennas transmitted and both received (REPEATPASS and PINGPONG have  " 	>> recur_unwr.brief
	echo "# the same effect); the transmit mode should be SINGLEANTENNATRANSMIT  " 		>> recur_unwr.brief
	echo "# if only one antenna was used to transmit while both antennas  " 			>> recur_unwr.brief
	echo "# received.  In single-antenna-transmit mode, the baseline is  " 				>> recur_unwr.brief
	echo "# effectively halved.  This parameter is ignored for cost modes other  " 		>> recur_unwr.brief
	echo "# than topography.  " 														>> recur_unwr.brief
	echo "TRANSMITMODE    REPEATPASS  " 												>> recur_unwr.brief
	echo "  " 																			>> recur_unwr.brief
	echo "  " 																			>> recur_unwr.brief
	echo "# Slant range from platform to first range bin in input data file  " 			>> recur_unwr.brief
	echo "# (double, meters).  Be sure to modify this parameter if the input   " 		>> recur_unwr.brief
	echo "# file is extracted from a larger scene.  The parameter does not need   " 	>> recur_unwr.brief
	echo "# to be modified is snaphu is unwrapping only a subset of the input file.  "	>> recur_unwr.brief
	echo "NEARRANGE       831000.0  " 													>> recur_unwr.brief
	echo "  " 																			>> recur_unwr.brief
	echo "  " 																			>> recur_unwr.brief
	echo "# Slant range and azimuth pixel spacings of input interferogram after  " 		>> recur_unwr.brief
	echo "# any multilook averaging.  This is not the same as the resolution.  " 		>> recur_unwr.brief
	echo "# (double, meters).  " 														>> recur_unwr.brief
	echo "DR              45  "  														>> recur_unwr.brief
	echo "DA              45  "  														>> recur_unwr.brief
	echo "  " 																			>> recur_unwr.brief
	echo "  " 																			>> recur_unwr.brief
	echo "# Single-look slant range and azimuth resolutions.  This is not the  "		>> recur_unwr.brief
	echo "# same as the pixel spacing.  (double, meters).  " 							>> recur_unwr.brief
	echo "RANGERES        8.0  " 														>> recur_unwr.brief
	echo "AZRES           4.5  " 														>> recur_unwr.brief
	echo "  " 																			>> recur_unwr.brief
	echo "  " 																			>> recur_unwr.brief
	echo "# Wavelength (double, meters).  "												>> recur_unwr.brief
	echo "LAMBDA          0.0565647  " 													>> recur_unwr.brief
	echo "  " 																			>> recur_unwr.brief
	echo "  " 																			>> recur_unwr.brief
	echo "# Number of real (not necessarily independent) looks taken in range and  " 	>> recur_unwr.brief
	echo "# azimuth to form the input interferogram (long).    " 						>> recur_unwr.brief
	echo "NLOOKSRANGE     1  " 															>> recur_unwr.brief
	echo "NLOOKSAZ        4  " 															>> recur_unwr.brief
	echo "  " 																			>> recur_unwr.brief
	echo "  " 																			>> recur_unwr.brief
	echo "# Number of looks (assumed independent) from nonspatial averaging (long).  "	>> recur_unwr.brief
	echo "NLOOKSOTHER     1  " 															>> recur_unwr.brief
	echo "  " 																			>> recur_unwr.brief
	echo "  " 																			>> recur_unwr.brief
	echo "# Equivalent number of independent looks (double, dimensionless) that were  " >> recur_unwr.brief
	echo "# used to generate correlation file if one is specified.  This parameter  " 	>> recur_unwr.brief
	echo "# is ignored if the correlation data are generated by the interferogram  " 	>> recur_unwr.brief
	echo "# and amplitude data.  " 														>> recur_unwr.brief
	echo "  " 																			>> recur_unwr.brief
	echo "# The equivalent number of independent looks is approximately equal to the   " >> recur_unwr.brief
	echo "# real number of looks divided by the product of range and azimuth   " 		>> recur_unwr.brief
	echo "# resolutions, and multiplied by the product of the single-look range and   " >> recur_unwr.brief
	echo "# azimuth pixel spacings.  It is about 0.53 times the number of real looks   " >> recur_unwr.brief
	echo "# for ERS data processed without windowing.  " 								>> recur_unwr.brief
	echo "NCORRLOOKS      23.8  " 														>> recur_unwr.brief
	echo "  " 																			>> recur_unwr.brief
	echo "  " 																			>> recur_unwr.brief
	echo "# Number of looks that should be taken in range and azimuth for estimating  " >> recur_unwr.brief
	echo "# the correlation coefficient from the interferogram and the amplitude   " 	>> recur_unwr.brief
	echo "# data.  These numbers must be larger than NLOOKSRANGE and NLOOKSAZ.  " 		>> recur_unwr.brief
	echo "# The actual numbers used may be different since we prefer odd integer  " 	>> recur_unwr.brief
	echo "# multiples of NLOOKSRANGE and NLOOKSAZ (long).  These numbers are ignored  " >> recur_unwr.brief
	echo "# if a separate correlation file is given as input.  " 						>> recur_unwr.brief
	echo "NCORRLOOKSRANGE 3  "															>> recur_unwr.brief
	echo "NCORRLOOKSAZ    15  " 														>> recur_unwr.brief
	echo "  " 																			>> recur_unwr.brief
	echo "  " 																			>> recur_unwr.brief
	echo "  " 																			>> recur_unwr.brief
	echo "###############################  " 											>> recur_unwr.brief
	echo "# Scattering model parameters #  " 											>> recur_unwr.brief
	echo "###############################  " 											>> recur_unwr.brief
	echo "  " 																			>> recur_unwr.brief
	echo "  " 																			>> recur_unwr.brief
	echo "# Threshold brightness (normalized) for layover height integration   " 		>> recur_unwr.brief
	echo "# (double, dimensionless)  "													>> recur_unwr.brief
	echo "LAYMINEI        1.25  " 														>> recur_unwr.brief
	echo "  " 																			>> recur_unwr.brief
	echo "  " 																			>> recur_unwr.brief
	echo "  " 																			>> recur_unwr.brief
	echo "##################################  " 										>> recur_unwr.brief
	echo "# Decorrelation model parameters #  " 										>> recur_unwr.brief
	echo "##################################  " 										>> recur_unwr.brief
	echo "  " 																			>> recur_unwr.brief
	echo "  " 																			>> recur_unwr.brief
	echo "# Here, rho is the magnitude of the complex correlation coefficient  " 		>> recur_unwr.brief
	echo "# between the two observations forming the interferogram (0<=rho<=1)  " 		>> recur_unwr.brief
	echo "# See Zebker & Villasenor, 1992  " 											>> recur_unwr.brief
	echo "  " 																			>> recur_unwr.brief
	echo "  " 																			>> recur_unwr.brief
	echo "# Default value to use uniformly for true, unbiased correlation if no   " 	>> recur_unwr.brief
	echo "# correlation file is specified and correlation cannot be generated   " 		>> recur_unwr.brief
	echo "# from the available data (double).   " 										>> recur_unwr.brief
	echo "DEFAULTCORR     0.01  " 														>> recur_unwr.brief
	echo "  " 																			>> recur_unwr.brief
	echo "  " 																			>> recur_unwr.brief
	echo "# Factor applied to expected minimum measured (biased) correlation.  " 		>> recur_unwr.brief
	echo "# Values smaller than the threshold rhominfactor*rho0 are assumed to  " 		>> recur_unwr.brief
	echo "# come from zero statistical correlation because of estimator bias (double).  " >> recur_unwr.brief
	echo "# This is used only in topo mode; for defo mode, use DEFOTHRESHFACTOR.  " 	>> recur_unwr.brief
	echo "RHOMINFACTOR    1.3  " 														>> recur_unwr.brief
	echo "  " 																			>> recur_unwr.brief
	echo "  " 																			>> recur_unwr.brief
	echo "  " 																			>> recur_unwr.brief
	echo "########################  " 													>> recur_unwr.brief
	echo "# PDF model parameters #  " 													>> recur_unwr.brief
	echo "########################  " 													>> recur_unwr.brief
	echo "  " 																			>> recur_unwr.brief
	echo "  " 																			>> recur_unwr.brief
	echo "# Algorithm costs are based on the negative log pdf:  "						>> recur_unwr.brief
	echo "  " 																			>> recur_unwr.brief
	echo "#   cost = -log(f(phi | EI, rho))  " 											>> recur_unwr.brief
	echo "  " 																			>> recur_unwr.brief
	echo "  " 																			>> recur_unwr.brief
	echo "# Factor applied to range layover probability density to get azimuth  " 		>> recur_unwr.brief
	echo "# layover probability density (double).    " 									>> recur_unwr.brief
	echo "AZDZFACTOR      0.99   " 														>> recur_unwr.brief
	echo "  " 																			>> recur_unwr.brief
	echo "  " 																			>> recur_unwr.brief
	echo "# Ratio of layover probability density to peak probability density  " 		>> recur_unwr.brief
	echo "# for non-layover slopes expected (double).  " 								>> recur_unwr.brief
	echo "LAYCONST        0.9  " 														>> recur_unwr.brief
	echo "  " 																			>> recur_unwr.brief
	echo "  " 																			>> recur_unwr.brief
	echo "  " 																			>> recur_unwr.brief
	echo "###############################  " 											>> recur_unwr.brief
	echo "# Deformation mode parameters #  " 											>> recur_unwr.brief
	echo "###############################  " 											>> recur_unwr.brief
	echo "  " 																			>> recur_unwr.brief
	echo "  " 																			>> recur_unwr.brief
	echo "# Factor applied to range discontinuity probability density to get   " 		>> recur_unwr.brief
	echo "# corresponding value for azimuth (double).  " 								>> recur_unwr.brief
	echo "DEFOAZDZFACTOR  1.0  " 														>> recur_unwr.brief
	echo "  " 																			>> recur_unwr.brief
	echo "  " 																			>> recur_unwr.brief
	echo "# Factor applied to rho0 to get threshold for whether or not phase  " 		>> recur_unwr.brief
	echo "# discontinuity is possible (double).  rho0 is the expected, biased   " 		>> recur_unwr.brief
	echo "# correlation measure if true correlation is 0.  " 							>> recur_unwr.brief
	echo "DEFOTHRESHFACTOR 1.2  " 														>> recur_unwr.brief
	echo "  " 																			>> recur_unwr.brief
	echo "  " 																			>> recur_unwr.brief
	echo "# Maximum phase discontinuity likely (double).  Units are radians or cycles.  " >> recur_unwr.brief
	echo "# If abrupt phase discontinuities are not expected, this paramter can be   " 	>> recur_unwr.brief
	echo "# set to zero.  " 															>> recur_unwr.brief
	echo "DEFOMAX_CYCLE   15.0  " 														>> recur_unwr.brief
	echo "#DEFOMAX_CYCLE   1.0  "														>> recur_unwr.brief
	echo "#DEFOMAX_RAD    7.5398  " 													>> recur_unwr.brief
	echo "  " 																			>> recur_unwr.brief
	echo "  " 																			>> recur_unwr.brief
	echo "# Ratio of phase discontinuity probability density to peak probability  " 	>> recur_unwr.brief
	echo "# density expected for discontinuity-possible pixel differences (double).  " 	>> recur_unwr.brief
	echo "# Value of 1 means zero cost for discontinuity, 0 means infinite cost.  " 	>> recur_unwr.brief
	echo "DEFOCONST       0.9  " 														>> recur_unwr.brief
	echo "  " 																			>> recur_unwr.brief
	echo "  " 																			>> recur_unwr.brief
	echo "########################  " 													>> recur_unwr.brief
	echo "# Algorithm parameters #  " 													>> recur_unwr.brief
	echo "########################  " 													>> recur_unwr.brief
	echo "  " 																			>> recur_unwr.brief
	echo "  " 																			>> recur_unwr.brief
	echo "# Maximum flow increment (long) for solver.  Not the same as maximum   " 		>> recur_unwr.brief
	echo "# flow possible.  " 															>> recur_unwr.brief
	echo "MAXFLOW         4  " 															>> recur_unwr.brief
	echo "  " 																			>> recur_unwr.brief
	echo "  " 																			>> recur_unwr.brief
	echo "# Scaling constant factor applied to double precision costs to get   " 		>> recur_unwr.brief
	echo "# integer costs (double).  " 													>> recur_unwr.brief
	echo "COSTSCALE       100.0  " 														>> recur_unwr.brief
	echo "  " 																			>> recur_unwr.brief
	echo "  " 																			>> recur_unwr.brief
	echo "# End of snaphu configuration file  " 										>> recur_unwr.brief
	echo "  " 																			>> recur_unwr.brief
fi

snaphu ${INFILE} ${NBCOL} -d -o res_unwr.tmp -f ./recur_unwr.brief
