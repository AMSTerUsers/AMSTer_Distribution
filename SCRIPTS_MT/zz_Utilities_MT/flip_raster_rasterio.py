#!/opt/local/amster_python_env/bin/python
###############################################################################
# This script aims at flipping a geotif or an Envi Harris file and output it as 
# an Envi Harris file named _flip.bil 
#
# Parameters : - 
#
# For an up to date and detailed list of dependencies (and sub-dependencies), 
#    run the following command (add option -v to also list the commands and calls):
#  		Search_Dependencies /Path/to/This/script 
# 	 (Results are displayed at the Terminal; redirect them to a file with > file.txt if wished)
#
# Dependencies:	- 
#

# New in Distro V 1.0 202603125:- setup
# New in Distro V 1.1 20261013:	- Recommend using Search_Dependencies.sh for 
#								  an updated list of dependencies
#
# AMSTer: SAR & InSAR Automated Mass processing Software for Multidimensional Time series
# N.d'Oreye, v Beta 1.0 2022/08/31 -       
###############################################################################

import sys
from pathlib import Path
import numpy as np
import rasterio


def flip_to_envi_bil(infile):

    inpath = Path(infile)
    outbase = inpath.stem + "_flip"
    outfile = outbase + ".bil"

    with rasterio.open(infile) as src:

        if src.count != 1:
            raise RuntimeError("Input raster must contain exactly one band")

        data = src.read(1)

        # flip vertically
        flipped = np.flipud(data)

        profile = src.profile.copy()

        profile.update(
            driver="ENVI",
            interleave="bil",
            count=1
        )

        with rasterio.open(outfile, "w", **profile) as dst:
            dst.write(flipped, 1)

    print("Created files:")
    print(outfile)
    print(outbase + ".hdr")


if __name__ == "__main__":

    if len(sys.argv) != 2:
        print("Usage: flip_to_envi_bil.py input_raster")
        sys.exit(1)

    flip_to_envi_bil(sys.argv[1])