#!/opt/local/amster_python_env/bin/python
######################################################################################
# This script computes radar look vector (unit vector Earth-to_sat) 
#
# Parameters:	- incidence (looking angle) in decimal degree
#				- azimuth heading of the SAR satellite in decimal degree
#				- [modulo pi. The default is 0.; uncomment input line if needed]
# 
# Dependencies:	- python 3.10
#               - see https://pypi.org/project/utm/#files
#
# New in V1.0 : - based on python code from Nelly-Wangue Moussissa
# New in Distro V 2.0 20250813:	- launched from python3 venv
#
#
# AMSTer: SAR & InSAR Automated Mass processing Software for Multidimensional Time series
# Nicolas d'Oreye, (c)2024
######################################################################################

import numpy as np
import sys


iVal = float(sys.argv[1])  # Incidence angle in degrees (float).
hVal = float(sys.argv[2])  # Orbit heading in degrees (float).

#kVal = int(sys.argv[3])  # modulo pi. The default is 0.
kVal=0


# fct 
def compute_RDL(i, h_CSL, k):
    """

    Parameters
    ----------
    i : float
        Incidence angle in degrees.
    h_CSL : float
        Angle in degrees.
    k : int, optional
        modulo pi. The default is 0.

    Returns
    -------
    RDL : ndarray of floats
        Angles defining the radar look normed (origin-centered base) vector.

    """
    i = np.copy( np.radians(i) )# Angles déterministes : localisation dans le ciel du satellite
    z = np.cos(i) ; #print( 'z = ', np.round(z, 2) )
    
    #h_CSL = phi + (180+90)[360], par conséquent,
    phi = h_CSL - 270. + 2*k*180.
# 	print( 'phi =', phi)
    phi = np.copy( np.radians(phi) )
    # sachant que phi = arctan2(y,x), on sait aussi que
    y = np.sin(i)*np.sin( phi ); #print( 'y =', np.round(y, 2) )
    x = np.sin(i)*np.cos( phi ) ;#print( 'x =', np.round(x, 2) )
    # Par définition : RDL[x, y, z]
    RDL = np.array( np.round([x, y, z], 2) ) # Attention, préciser unités
#	print('Hence, the radar look vector is :', RDL)
    # Hypothèse sur l'origine = (0,0,0)
    # x0, y0, z0 = 0, 0, 0
    # print('And its normed version is :',
    #       RDL/np.sqrt( (x-x0)**2 + (y-y0)**2 + (z-z0)**2))
    print(f"[ {x} , {y} , {z} ]")
    return RDL # Vecteur unitaire orienté Terre-satellite

RDL = compute_RDL(iVal, hVal, kVal); print(RDL)


##### manual launch  (comment lines reading parameters and computing RDL above for manual launch below)
##### example for ALOS2
##########################################################


#RDL01 = compute_RDL( 68.3490, 352, kVal); #print(RDL01)
#RDL02 = compute_RDL( 63.5898, 352, kVal); #print(RDL02)
#RDL03 = compute_RDL( 57.6726, 351, kVal); #print(RDL03)
#RDL04 = compute_RDL( 50.1304, 351, kVal); #print(RDL04)
#RDL05 = compute_RDL( 40.3468, 350, kVal); #print(RDL05)
#RDL06 = compute_RDL( 27.7091, 349, kVal); #print(RDL06)
##RDL07 = compute_RDL( 12.1677, 349, kVal); print(RDL07)
#RDL08 = compute_RDL( 21.6106, 348, kVal); #print(RDL08)
#RDL09 = compute_RDL( 35.3997, 347, kVal); #print(RDL09)
#RDL10 = compute_RDL( 46.0105, 346, kVal); #print(RDL10)
#RDL11 = compute_RDL( 54.4967, 346, kVal); #print(RDL11)
#RDL12 = compute_RDL( 60.9509, 345, kVal); #print(RDL12)
#RDL13 = compute_RDL( 65.9607, 344, kVal); #print(RDL13)
##RDL14 = compute_RDL(, -168, 16.8269, kVal); print(RDL14)
#RDL15 = compute_RDL( 31.6098, -169, kVal); #print(RDL15)
#RDL16 = compute_RDL( 43.1942, -169, kVal); #print(RDL16)
#RDL17 = compute_RDL( 52.4765, -170, kVal); #print(RDL17)
##RDL18 = compute_RDL( , kVal); print(RDL18)
#RDL19 = compute_RDL( 65.049, -171, kVal); #print(RDL19)
##RDL20 = compute_RDL(69.5447, -172, kVal); print(RDL20)
#RDL21 = compute_RDL( 69.1682, -163, kVal); #print(RDL21)
#RDL22 = compute_RDL( 64.7445, -164, kVal); #print(RDL22)
#RDL23 = compute_RDL( 59.2810, -164, kVal); #print(RDL23)
#RDL24 = compute_RDL( 52.3633, -165, kVal); #print(RDL24)
#RDL25 = compute_RDL( 43.4214, -166, kVal); #print(RDL25)
#RDL26 = compute_RDL( 31.8008, -166, kVal); #print(RDL26)
##RDL27 = compute_RDL( 17.1694, -167, kVal); print(RDL27)
