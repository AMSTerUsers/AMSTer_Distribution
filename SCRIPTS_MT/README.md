SCRIPTS_MT (formerly SCRIPTS_OK)

This repo contains the shell scripts required for AMSTer software 
(AMSTer: SAR & InSAR Automated Mass processing Software for Multidimensional Time series).

AMSTer = AMSTer Engine + AMSTer toolbox + MSBAS
 
AMSTer toolbox is a set of mostly shell scripts aiming at processing automatically a large number of interferometric pairs and feeding and 
running the MSBAS processor [Samsonov and d’Oreye, 2012, 2017; Samsonov et al., 2017, 2020] in order to obtain the desired 2D or 3D 
deformation maps and time series. Geocoded amplitude, coherence, interferometric phase and  deformation maps are computed using the 
AMSTer Engine, a command line InSAR processor derived from the Centre Spatial de Liege (CSL) InSAR Suite (CIS)
[Derauw, 1999; Derauw et al, 2019] which is able to process any type of SAR data (ERS1 & 2, EnviSAT, ALOS, ALOS2, RadarSAT 1& 2, 
CosmoSkyMed, TerraSAR-X, TanDEM-X (incl. bistatic mode), Sentinel1 A & B, Kompsat5, PAZ...).  
AMSTer was formerly named MasTer.

There is more than the scripts required for a "normal" use of AMSTer because this is the copy of my developpment scripts directory. 
Hence it also contains several scripts and tools that you may never need. 

If you need a specific tool that wouldn't be documented in the manual, feel free to let me know (ndo@ecgs.lu). There are high chances 
that some of these several scripts may be able to do what you need. And if not, with a little bit of luck, it might be easy for me to adapt 
some of these existing scripts to satisfy your needs. At least I can try on the best effort basis... 

The InSAR suite was modified and optimized to fit the needs of the AMSTer software, which benefitted from some of its unique specificities.   

We call the AMSTer Engine, the command line InSAR processor used in the AMSTer software in addition to some preprocessing tools allowing to 
perform per mode image pairs selection based on input criterion of limit baseline and limit time base. The command line InSAR processor 
is derived from the Centre Spatial de Liege (CSL) InSAR Suite (CIS) developed internally mainly on public Belgian Science Policy (BelSPo) 
funding since the early nineteen’s. CIS constitutes also the core of the SAOCOM InSAR Suite (SIS) internally used at CONAE. 

The AMSTer Engine stays in continuous developments to catch up with new sensors and add new capabilities. It has interesting features 
such as : 
-	the ability to perform absolute phase unwrapping or ionospheric mapping using the SplitBand interferometry [Bovenga et al., 2013; Libert & al. 2017],
-	several tools for unwrapping such as the largely used SNAPHU [Chen and Zebker 2002], a homemade branch cut algorithm [Goldstein et al. 1988; Derauw 1995], and a pre-unwrapping tool named DetPhun able to reduce up to a factor of 2 the unwrapping time [Derauw and d’Oreye, submitted],
-	specific tools for selecting and stitching swaths and bursts of interest from TOPSAR Sentinel 1 data,
-	tools for TOPSAR coherence tracking, or spectral coherence estimation 
-	adaptive filtering and masking procedure, automatic layover masking …     

Reference: Please cite 

Derauw D., d’Oreye N., Jaspard M., Caselli A. and Samsonov S. (2020)
Ongoing automated Ground Deformation monitoring of Domuyo – Laguna del Maule area (Argentina) using Sentinel-1 MSBAS time series: Methodology description and first observations for the period 2015 – 2020.
J. South Am. Earth Sc., Vol. 104, 102850. 
https://doi.org/10.1016/j.jsames.2020.102850
Freely available here: https://www.sciencedirect.com/science/article/pii/S089598112030393X?via%3Dihub 


Develloppers of AMSTer:
    Dominique Derauw (AMSTer Engine)
    Nicolas d'Oreye, Delphine Smittarello, Maxime Jaspard (AMSTer toolbox)
    Sergey Samsonov (MSBAS)
    ...
