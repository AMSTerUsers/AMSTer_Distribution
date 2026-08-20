#!/opt/local/bin/python
#
# The scripts searches for the presence of “burst-remnant” artifacts in Sentinel-1 TOPS 
# interferograms.
# The script outputs a message saying wether or not it detected the bursts 
#
# Parameters: - Interferogram to check
#			  - nr of lines and columns 
#			  - threshold for detection (depends on ML, noise etc) 
#			  - method for detection: fast or robust (difference is small though)
# Depending on the method, the detection threshold is typically 4–5 (fast), or 5-7 (robust)
#
# Hard coded:	- 
#
# Dependencies:	 
#		- see modules 
#
#
# New in Distro V 1.0 20260108:	
#
# AMSTer: SAR & InSAR Automated Mass processing Software for Multidimensional Time series
# NdO (c) 2016/03/07 - could make better with more functions... when time.
# -----------------------------------------------------------------------------------------

import sys
import os
import numpy as np


def read_ci2(path, nlines, ncols):
    """
    Memory-map a complex int16 .ci2 file.
    """
    raw = np.memmap(
        path,
        dtype=np.int16,
        mode="r",
        shape=(nlines, ncols * 2)
    )
    return raw[:, 0::2] + 1j * raw[:, 1::2]


def burst_score(data, robust):
    """
    Compute burst artifact score using azimuth FFT.
    """
    if robust:
        # More robust: wrapped phase
        x = np.angle(data)
    else:
        # Fastest: imaginary part only
        x = np.imag(data)

    # Remove range mean
    x -= x.mean(axis=1, keepdims=True)

    naz = x.shape[0]
    nfft = 1 << (naz - 1).bit_length()

    # FFT along azimuth
    fft = np.fft.rfft(x, n=nfft, axis=0)
    psd = np.abs(fft)**2

    # Average over range
    psd = psd.mean(axis=1)

    # Normalize
    psd /= np.median(psd)

    freq = np.fft.rfftfreq(nfft)

    # Sentinel-1 TOPS burst frequency band
    band = (freq > 0.08) & (freq < 0.25)

    return psd[band].max()


def main():
    if len(sys.argv) != 6:
        print("Usage: detect_burst_ci2.py <ci2> <lines> <cols> <threshold> <fast|robust>")
        sys.exit(1)

    path = sys.argv[1]
    nlines = int(sys.argv[2])
    ncols = int(sys.argv[3])
    threshold = float(sys.argv[4])
    mode = sys.argv[5].lower()

    if mode not in ("fast", "robust"):
        print("Mode must be 'fast' or 'robust'")
        sys.exit(1)

    robust = (mode == "robust")

    # Resolve full path
    full_path = os.path.abspath(path)

    ci = read_ci2(path, nlines, ncols)
    score = burst_score(ci, robust)

    # Modified output message
    if score >= threshold:
        print(f"burst presence in {full_path} : yes")
    else:
        print(f"burst presence in {full_path} : no")


if __name__ == "__main__":
    main()
