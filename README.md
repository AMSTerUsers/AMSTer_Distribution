# MasTer Toolbox

"If you need InSAR, MasTer it"

This repo contains the shell scripts, codes, binaries and doc required for installing and 
running MasTer. 
(MasTer: InSAR automated Mass processing Toolbox for Multidimensional time series).

MasTer is mostly based on 3 elements:
- an InSAR processor (MasTer Engine)
- a time series processor (MSBAS)
- a set of mostly shell (bash) and some python scripts 

MasTer is aiming at processing automatically a large number of interferometric pairs and 
feeding and running the MSBAS processor [Samsonov and d’Oreye, 2012, 2017; Samsonov et 
al., 2017, 2020] in order to obtain the desired 2D or 3D deformation maps and time series. 

Of course, MasTer can also perform individual differential interferograms (for deformation 
measurement or DEM creation purposes). 
MasTer can also create time series of coherence or amplitude maps coregistered on a Global 
Primary (both in radar geometry or in geographic coordinates). 

MasTer is able to process any type of SAR data (ERS1 & 2, EnviSAT, ALOS, ALOS2, RadarSAT,
CosmoSkyMed, TerraSAR-X, TanDEM-X (incl. bistatic mode), Sentinel1 A & B (incl. SM mode), 
Kompsat5, PAZ, SAOCOM, ICEYE...).  
MasTer Engine is optimised to fit the needs of the MasTer tool, which benefitted from some
of its unique specificities.   

Geocoded amplitude, coherence, interferometric phase and deformation maps are computed 
using MasTer Engine, a command line InSAR processor derived from the Centre Spatial de 
Liege (CSL) InSAR Suite (CIS)[Derauw, 1999; Derauw et al, 2019]. 

The MasTer Engine stays in continuous developments to catch up with new sensors and add 
new capabilities. It has interesting features such as : 
- the ability to perform absolute phase unwrapping or ionospheric mapping using the 
  SplitBand interferometry [Bovenga et al., 2013; Libert & al. 2017],
- several tools for unwrapping such as the largely used SNAPHU [Chen and Zebker 2002], 
  a homemade branch cut algorithm [Goldstein et al. 1988; Derauw 1995], and a 
  pre-unwrapping tool named DetPhun (exploratory tool), 
- specific tools for selecting and stitching swaths and bursts of interest from TOPSAR 
  Sentinel 1 data,
- tools for TOPSAR coherence tracking, or spectral coherence estimation 
- adaptive filtering and masking procedure, automatic layover masking …  

In the MasTer Toolbox repository, you will find more scripts in SCRIPTS_OK than what is 
required for a "normal" use of MasTer because this is the copy of my developpment scripts 
directory. Hence it also contains several scripts and tools that you may never need. 

Nevertheless, if you need a specific tool that wouldn't be documented in the manual, feel 
free to let me know (ndo@ecgs.lu). There are high chances that some of these several 
scripts may be able to do what you need. And if not, with a little bit of luck, it might 
be easy for me to adapt some of these existing scripts to satisfy your needs. 
At least I can try on the best effort basis... 


References: Please cite 

Derauw D., d’Oreye N., Jaspard M., Caselli A. and Samsonov S. (2020)
Ongoing automated Ground Deformation monitoring of Domuyo – Laguna del Maule area 
(Argentina) using Sentinel-1 MSBAS time series: Methodology description and first 
observations for the period 2015 – 2020. J. South Am. Earth Sc., Vol. 104, 102850. 
https://doi.org/10.1016/j.jsames.2020.102850
Freely available here: https://www.sciencedirect.com/science/article/pii/S089598112030393X?via%3Dihub 

d’Oreye N., D. Derauw, S. Samsonov, M. Jaspard, D. Smittarello
MASTER: A FULL AUTOMATIC MULTI-SATELLITE INSAR MASS PROCESSING TOOL FOR RAPID INCREMENTAL 
2D GROUND DEFORMATION TIME SERIES. Proceedings of the IEEE International Geoscience and 
Remote Sensing Symposium (IGARSS) 2021, Brussels

Develloppers of MasTer:
    Dominique Derauw (MasTer Engine)
    Nicolas d'Oreye (MasTer toolbox scripts)
    Sergey Samsonov (MSBAS)
    Delphine Smittarello (modules for pair selection optimisation or recursive unwrapping)
    Maxime Jaspard (web interface)
    
Updates:
- New in V 20230421:
  1. Scripts:
    + Read_All_Img.sh: add CSK 2nd generation and correct/improve reading of several formats 
    + Prepa_MSBAS.sh: now can build basline plot and pair selection table based on a second sets of temporal and spatial baseline criteria from a given table. This is unseful e.g. since the lost of S1B, which may require to increase the orbital tube
    + installer: use g++ to compile msbas 
    + Linux: replace Helvetica font now unavailable for convert function used in some scripts to build time series grpahs 
    + several cosmetic and minor imporvements in various scripts
    + several corrections and improvements in cron job scripts 
    + addition of small utilities 
  2. msbas: compilation with g++ in Linux
  3. MasTer Engine:
    + some add/corrections in DataReaders (ERS, RS1, RS2 CSK 2nd generation)
    + some parallelistaion are now possible (S1 Coregistration) 
  4. DOC: 
    + revised and updated according to recent changes
