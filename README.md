# MasTer Toolbox

"If you need InSAR, MasTer it"

This repo contains the shell scripts, codes and doc required for installing and 
running MasTer. 
(MasTer: InSAR automated Mass processing Toolbox for Multidimensional time series).

MasTer is mostly based on 3 elements:
- an InSAR processor (MasTer Engine)
- a time series processor (MSBAS; https://doi.org/10.4095/313749)
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

In the MasTer Toolbox repository, you will find more scripts in SCRIPTS_MT than what is 
required for a "normal" use of MasTer because this is the copy of my development scripts 
directory. Hence it also contains several scripts and tools that you may never need. 

Nevertheless, if you need a specific tool that wouldn't be documented in the manual, feel 
free to let me know (ndo@ecgs.lu). There are high chances that some of these several 
scripts may be able to do what you need. And if not, with a little bit of luck, it might 
be easy for me to adapt some of these existing scripts to satisfy your needs. 
At least I can try on the best effort basis... 

**License:**

**________**

"MasTer toolbox: an InSAR automated Mass processing Toolbox for Multidimensional time series" © 2023 
by Nicolas d'Oreye, Dominique Derauw, Sergey Samsonov, Delphine Smittarello, Maxime Jaspard and Gilles Celli 
is licensed under CC BY-NC-SA 4.0 (Attribution-NonCommercial-ShareAlike 4.0 International).
http://creativecommons.org/licenses/by-nc-sa/4.0/


You are free to:
    Share — copy and redistribute the material in any medium or format
    Adapt — remix, transform, and build upon the material
    The licensor cannot revoke these freedoms as long as you follow the license terms.

Under the following terms:
    Attribution - You must give appropriate credit , provide a link to the license, and indicate if changes were made . You may do so in any reasonable manner, but not in any way that suggests the licensor endorses you or your use.
    NonCommercial - You may not use the material for commercial purposes .
    ShareAlike - If you remix, transform, or build upon the material, you must distribute your contributions under the same license as the original.
    No additional restrictions - You may not apply legal terms or technological measures that legally restrict others from doing anything the license permits.

Notices:
  You do not have to comply with the license for elements of the material in the public domain or where your use is permitted by an applicable exception or limitation .
  No warranties are given. The license may not give you all of the permissions necessary for your intended use. For example, other rights such as publicity, privacy, or moral rights may limit how you use the material.

Moreover, MSBAS is licensed to the https://open.canada.ca/en/open-government-licence-canada

Because MasTer Toolbox program is licensed free of charge, there is no warranty for the program.  

**References:** 

**___________**

Please cite at least the following references. More can be found in 
/MasTerToolbox_Distribution/DOC/How_To_Cite_MasTer.txt

Derauw D., d’Oreye N., Jaspard M., Caselli A. and Samsonov S. (2020)
Ongoing automated Ground Deformation monitoring of Domuyo – Laguna del Maule area 
(Argentina) using Sentinel-1 MSBAS time series: Methodology description and first 
observations for the period 2015 – 2020. J. South Am. Earth Sc., Vol. 104, 102850. 
https://doi.org/10.1016/j.jsames.2020.102850
Freely available here: https://www.sciencedirect.com/science/article/pii/S089598112030393X?via%3Dihub 

d’Oreye N., D. Derauw, S. Samsonov, M. Jaspard, D. Smittarello (2021)
MASTER: A FULL AUTOMATIC MULTI-SATELLITE INSAR MASS PROCESSING TOOL FOR RAPID INCREMENTAL 
2D GROUND DEFORMATION TIME SERIES. Proceedings of the IEEE International Geoscience and 
Remote Sensing Symposium (IGARSS) 2021, Brussels

Samsonov S. (2019) 
User manual, source code, and test set for MSBASv3 (Multidimensional Small Baseline Subset version 3) for one- and two-dimensional deformation analysis
https://doi.org/10.4095/313749

**Develloppers of MasTer:**

**_______________________**

    Nicolas d'Oreye [1,2] (MasTer Toolbox scripts)
    Dominique Derauw [3,4] (MasTer Engine)
    Sergey Samsonov [5] (MSBAS)
    Delphine Smittarello [1] (modules for pair selection optimisation, recursive unwrapping...)
    Maxime Jaspard [1] (web interface)
    Gilles Celli [1,2] (downloaders, compilation issues...)

    [1] European Center for Geodynamics and Seismology, Luxembourg
    [2] National Museum of Natural History, Luxembourg
    [3] Centre Spatial de Liège, Université de Liège, Belgium
    [4] Universidad Nacional de Rio Negro, General Roca, Argentina
    [5] Canada Centre for Mapping and Earth Observation, Natural Resources Canada, Ottawa, Canada

The development of the MasTer Toolbox commenced in the early 2010s and leveraged the capabilities of various pre-existing tools, including the CSL InSAR suite, which was fully remastered to be the MasTerEngine. Over time, the MasTer Toolbox underwent incremental enhancements, both independently and within the context of numerous projects, notably (unsorted) RESIST, MUZUBI, GEORISCA, SMMIP, TIGRES, ECTIC, MODUS, VERSUS, advInSAR, Vi-X... These projects were primarily funded by the Belgian Scientific Policy (BelSPo) and the Luxembourgish Fond National de la Recherche (FNR).
    
**Updates:**

**________**
- New in V 20231003:
  Because this new version includes major changes (also in the structure), it is hardly recommended to perform a new installation with the installer (MasTer_Install.sh): 
  1. Some important files were renamed (e.g. FUNCTIONS_FOR_MT.sh), some files were moved in more appropriate directories and some directories were renamed for more clarity (like where to store some scripts or parameters files). 
  2. The MasTer Toolbox is now distributed on a public GitHub repository and covered by a CC BY-NC-SA 4.0 license. A discussions group was also implemented on Github. Do not hesitate to visit and ask or contribute.  
  3. A new section entiteled "trouble shooting" was started in the manual... To be continued...
  4. New tools to select the pairs for the mass processing (now possible with Delaunay triangulation or x-shortests connections in addition to the existing baselines lengths criteria) 
  5. Major change in the mask handling: now mask pixels 0 = always keep ; 1 = always mask and 2 = mask if coherence is lower than COHCLNTHRESH parameter at unwrapping
  6. New way to manage hard coded lines in scripts: now they are all listed in a file named __HardCodedLines.sh (see manual)
  7. Bug fixed in geocoding (half a pixel offset was introduced in a former version of MasTer Engine several months ago...) 
  8. Several new scripts and small tools (see e.g. chapter 8 and 9 in manual)
  9. New way for MasTer Engine to read Sentinel-1 Wide Swath images. The former and the new methods can be used together though. 
  10. The manuals were updated accordingly
  11. The __LaunchMTparam.txt was updated accordingly
       
  
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
    
- New in V 20230828 (non exhaustive list...):
  1. Scripts:
    + Important changes in directories and file naming
    + Add optimisation module 
    + Manage hard coded lines in scripts by sourcing a single file containing the hard coded lines
    + Several modifictions to cope with recent upgrades in MasTer Engine
    + Some new tools 
  2. msbas: source code for msbas 3D and 4D inversions. These are however not
  	 (yet) integrated within the MasTer Toolbox scripts
  3. MasTer Engine:
    + new way to read S1 images in IW
    + half pixel offset bug in geoprojection removed 
    + more parallelistaion are now possible 
    + takes into account new CSK format
    + can force UTM zone at geoprojection 
  4. DOC: 
    + revised and updated according to recent changes
