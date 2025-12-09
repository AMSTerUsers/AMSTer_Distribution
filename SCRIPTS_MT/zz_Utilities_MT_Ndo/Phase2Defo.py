#!/opt/local/amster_python_env/bin/python
# The script aims at transforming a phase file into a deformation file. The input phase file is supposed to be float 32
# and provided with or without its path. 
# The input file is expected to be like ETADxxxPhaseCorrection, where xxx is either Geodetic, Ionospheric or Tropospheric.
# The output file is deformationETADxxxCorrection where xxx is either Geodetic, Ionospheric or Tropospheric.
# It takes as input parameters the nr of lines, columns, name of file and wavelength of the SAR sensor (e.g. 0.056 for C-band)
#
#
# Parameters:	- nr of lines in the input file 
# 				- nr of columns in the input file 
#				- the name of the input file (float 32), with or without its path. It must however be named like TADxxxPhaseCorrection, where xxx is either Geodetic, Ionospheric or Tropospheric.
#				- the wavelength of the SAR sensor 
#  
#
# New in Distro V 1.0  20280909: - set up 
#
# AMSTer: SAR & InSAR Automated Mass processing Software for Multidimensional Time series
# NdO (c) 2025 - could make better with more functions... when time.
# -----------------------------------------------------------------------------------------

import numpy as np
import argparse
import os
import math
import re

def process_file(input_file, lines, cols, factor):
    # Load binary float32 data
    data = np.fromfile(input_file, dtype=np.float32)

    # Check if file size matches expected matrix
    expected_size = lines * cols
    if data.size != expected_size:
        raise ValueError(
            f"File size does not match given dimensions. "
            f"Expected {expected_size}, got {data.size}"
        )

    # Reshape into 2D
    data = data.reshape((lines, cols))

    # Apply math operation
    data = (data * factor) / (4 * math.pi)

    # Extract xxx part from input filename (ETADxxxPhaseCorrection)
    basename = os.path.basename(input_file)
    match = re.match(r"ETAD(.*)PhaseCorrection", basename)
    if not match:
        raise ValueError("Input filename does not match expected format: ETADxxxPhaseCorrection")

    xxx = match.group(1)
    output_file = os.path.join(os.path.dirname(input_file), f"deformationETAD{xxx}Correction")

    # Save as float32 binary file
    data.astype(np.float32).tofile(output_file)
    print(f"Processed file saved as: {output_file}")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        description="Apply correction to ETADxxxPhaseCorrection float32 file."
    )
    parser.add_argument("input_file", help="Path to input ETADxxxPhaseCorrection file")
    parser.add_argument("lines", type=int, help="Number of lines (rows)")
    parser.add_argument("cols", type=int, help="Number of columns")
    parser.add_argument("factor", type=float, help="Multiplier factor (e.g. 0.056)")

    args = parser.parse_args()

    process_file(args.input_file, args.lines, args.cols, args.factor)
