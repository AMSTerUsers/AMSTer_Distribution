#!/opt/local/amster_python_env/bin/python
######################################################################################
# CheckIncidenceRef.py  V1.0
# 
# Determine whether an incidence map holds
#   - GEOID incidence  : angle between the LOS and the local vertical
#                        (e.g. from AMSTerEngine < V20260531 ; what you  
#                        need for ZTD -> slant delay, and for any
#                         LOS projection / EW-UD decomposition)
#   - LOCAL incidence  : angle between the LOS and the terrain normal
#                        (e.g. from AMSTerEngine >= V20260531 ; correct 
#                         for radiometry, wrong for atmospheric-delay 
#                         projection)
# 
# and, if the map is a local incidence, rebuild the geoid incidence from it.
# 
# The detection needs nothing but the map itself: geoid incidence is a smooth,
# almost-quadratic ramp in ground range, so its scatter about a low-order
# polynomial is a few hundredths of a degree, whereas local incidence inherits
# the full high-frequency roughness of the terrain (degrees to tens of degrees).
# The two regimes are separated by more than two orders of magnitude.
# 
# The recovery fits a low-order polynomial through the NEAR-FLAT pixels only,
# where local and geoid incidence coincide by construction. It needs a DEM on
# the same grid (for the slope mask) but not the slope aspect, not the look
# azimuth, and it has no root ambiguity.
# 
# Usage
#   CheckIncidenceRef.py --check INCIDENCE
#   CheckIncidenceRef.py --to-geoid INCIDENCE --dem DEM [--out FILE]
#                        [--max-slope DEG] [--order N]
# 
# Parameters: 	
#		INCIDENCE: 	incidence angles map (e.g. from AMSTer Engine processing)
#					in Envi format
#		DEM (optional): dem map at the same grid as the incidence 
#		DEG (optional, for use with --to-geoid): slope ceiling that defines a 
#			"near-flat" pixel. Default is 5. You can set 3 whenever the terrain  
#    		provides enough flat ground
#		N (optional, for use with --to-geoid): Polynomial order of the ramp. 
#			Default is 2 and should be fine. Going past 2 is not recommended. 
# 
# Both ENVI file naming styles are handled, including the AMSTer quirk where the
# binary ends in '...Head260.1deg' but the header is '...Head260_1deg.hdr'.
#
# Dependencies:	- python3.10 and modules below (numpy, see import)
#
# New in Distro V 1.0:	- built with an AI assistance 
#
# AMSTer: SAR & InSAR Automated Mass processing Software for Multidimensional Time series
# Nicolas d'Oreye, (c)2016-2026
######################################################################################

import argparse
import os
import re
import sys

import numpy as np

PLAUSIBLE = (5.0, 85.0)      # deg; anything outside is a flag or a nodata code
GEOID_MAX_MAD = 0.30         # deg; below this the map is a geoid incidence
LOCAL_MIN_MAD = 1.00         # deg; above this the map is a local incidence

ENVI_DTYPE = {1: 'u1', 2: '<i2', 3: '<i4', 4: '<f4', 5: '<f8',
              12: '<u2', 13: '<u4', 14: '<i8', 15: '<u8'}


# ----------------------------------------------------------------- ENVI I/O

def HeaderPath(path):
    """Locate the .hdr belonging to an ENVI binary, covering both conventions."""
    candidates = [path + '.hdr', os.path.splitext(path)[0] + '.hdr']
    d, b = os.path.dirname(path) or '.', os.path.basename(path)
    # AMSTer style: last '.' of the basename becomes '_' in the header name
    candidates.append(os.path.join(d, re.sub(r'\.([^.]*)$', r'_\1', b) + '.hdr'))
    for c in candidates:
        if os.path.isfile(c):
            return c
    sys.exit('ERROR: no .hdr found for %s (tried: %s)' % (path, ', '.join(candidates)))


def ReadEnvi(path):
    """Return (array, header dict, header path). Single band only."""
    hdr = HeaderPath(path)
    h = {}
    with open(hdr) as f:
        txt = f.read()
    for key in ('samples', 'lines', 'bands', 'data type', 'byte order',
                'header offset', 'interleave', 'map info', 'data ignore value'):
        m = re.search(r'^\s*%s\s*=\s*(.+?)\s*$' % key.replace(' ', r'[ _]'),
                      txt, re.I | re.M)
        if m:
            h[key] = m.group(1).strip()
    need = ('samples', 'lines', 'data type')
    if any(k not in h for k in need):
        sys.exit('ERROR: %s lacks one of %s' % (hdr, need))
    ns, nl = int(h['samples']), int(h['lines'])
    dt = int(h['data type'])
    if dt not in ENVI_DTYPE:
        sys.exit('ERROR: unsupported ENVI data type %d' % dt)
    dtype = ENVI_DTYPE[dt]
    if h.get('byte order', '0').strip() == '1' and dtype[0] == '<':
        dtype = '>' + dtype[1:]
    if int(h.get('bands', 1)) != 1:
        sys.exit('ERROR: %s has %s bands; single band expected' % (hdr, h['bands']))
    off = int(h.get('header offset', 0))
    a = np.fromfile(path, dtype=dtype, offset=off)
    if a.size != ns * nl:
        sys.exit('ERROR: %s holds %d values, header says %d x %d = %d'
                 % (path, a.size, ns, nl, ns * nl))
    return a.reshape(nl, ns).astype(np.float64), h, hdr


def WriteEnvi(path, arr, template_hdr, description):
    """Write float32 ENVI, cloning the geometry of an existing header."""
    arr.astype('<f4').tofile(path)
    with open(template_hdr) as f:
        txt = f.read()
    txt = re.sub(r'^\s*[Dd]escription\s*=\s*\{[^}]*\}',
                 'Description = {%s}' % description, txt, count=1, flags=re.M | re.S)
    txt = re.sub(r'^\s*[Dd]ata type\s*=.*$', 'Data type = 4', txt, count=1, flags=re.M)
    txt = re.sub(r'^\s*byte order\s*=.*$', 'byte order = 0', txt, count=1, flags=re.M | re.I)
    if 'Data ignore value' not in txt:
        txt = txt.rstrip('\n') + '\nData ignore value = NAN\n'
    out_hdr = re.sub(r'\.([^.]*)$', r'_\1', os.path.basename(path)) + '.hdr'
    out_hdr = os.path.join(os.path.dirname(path) or '.', out_hdr)
    with open(out_hdr, 'w') as f:
        f.write(txt)
    return out_hdr


def GridKey(h):
    mi = h.get('map info', '')
    parts = [p.strip() for p in mi.strip('{} ').split(',')]
    return (h['samples'], h['lines'], tuple(parts[3:8]) if len(parts) >= 8 else ())


# ------------------------------------------------------------- diagnostics

def ValidMask(th):
    """Finite, non-zero, and physically plausible. Zero is finite and cos(0)=1,
    so an unmasked zero silently turns the slant conversion into a no-op."""
    return np.isfinite(th) & (th > PLAUSIBLE[0]) & (th < PLAUSIBLE[1])


def PolyBasis(shape, order, mask=None):
    nl, ns = shape
    y, x = np.mgrid[0:nl, 0:ns].astype(np.float64)
    x = (x - 0.5 * ns) / ns
    y = (y - 0.5 * nl) / nl
    cols = [x ** i * y ** j for d in range(order + 1)
            for i in range(d + 1) for j in [d - i]]
    if mask is None:
        return np.column_stack([c.ravel() for c in cols])
    return np.column_stack([c[mask] for c in cols])


def SmoothFit(th, mask, order):
    B = PolyBasis(th.shape, order, mask)
    c, *_ = np.linalg.lstsq(B, th[mask], rcond=None)
    full = PolyBasis(th.shape, order) @ c
    return full.reshape(th.shape), c


def Diagnose(th, order=2):
    m = ValidMask(th)
    if m.sum() < 500:
        sys.exit('ERROR: only %d plausible pixels; cannot diagnose' % m.sum())
    fit, _ = SmoothFit(th, m, order)
    r = (th - fit)[m]
    mad = float(np.median(np.abs(r - np.median(r))) * 1.4826)
    nan = int((~np.isfinite(th)).sum())
    zero = int((th == 0).sum())
    out = int((np.isfinite(th) & (th != 0) & ~m).sum())
    verdict = ('GEOID' if mad < GEOID_MAX_MAD else
               'LOCAL' if mad > LOCAL_MIN_MAD else 'AMBIGUOUS')
    return dict(mad=mad, rms=float(r.std()), span=float(th[m].max() - th[m].min()),
                mean=float(th[m].mean()), nvalid=int(m.sum()), nan=nan,
                zero=zero, outband=out, verdict=verdict)


# ---------------------------------------------------------------- recovery

def SlopeFromDem(dem, px, py):
    gy, gx = np.gradient(dem, py, px)
    return np.degrees(np.arctan(np.hypot(gx, gy)))


def PixelSize(h):
    parts = [p.strip() for p in h.get('map info', '').strip('{} ').split(',')]
    try:
        return float(parts[5]), float(parts[6])
    except (IndexError, ValueError):
        sys.exit('ERROR: cannot read pixel size from "Map info"; grid unknown')


def ToGeoid(th_loc, dem, px, py, max_slope, order):
    slope = SlopeFromDem(dem, px, py)
    m = ValidMask(th_loc) & np.isfinite(slope) & (slope < max_slope)
    npar = (order + 1) * (order + 2) // 2
    if m.sum() < 20 * npar:
        sys.exit('ERROR: only %d pixels below %g deg slope for %d parameters.\n'
                 '       Raise --max-slope or lower --order.' % (m.sum(), max_slope, npar))
    B = PolyBasis(th_loc.shape, order, m)
    fit, _ = SmoothFit(th_loc, m, order)
    resid = (th_loc - fit)[m]
    mad = float(np.median(np.abs(resid - np.median(resid))) * 1.4826)
    # The scatter of near-flat pixels about the ramp is of order the slope
    # ceiling and is NOT an accuracy figure. What matters is how well the ramp
    # itself is pinned down, i.e. the predictive standard error of the fit.
    cov = np.linalg.pinv(B.T @ B) * mad ** 2
    Bf = PolyBasis(th_loc.shape, order)
    se = np.sqrt(np.maximum(np.einsum('ij,jk,ik->i', Bf, cov, Bf), 0.0))
    fit[~np.isfinite(dem)] = np.nan
    return fit, m, mad, slope, float(np.median(se)), float(se.max())


# -------------------------------------------------------------------- main

def main():
    p = argparse.ArgumentParser(description=__doc__,
                                formatter_class=argparse.RawDescriptionHelpFormatter)
    g = p.add_mutually_exclusive_group(required=True)
    g.add_argument('--check', metavar='INCIDENCE')
    g.add_argument('--to-geoid', metavar='INCIDENCE')
    p.add_argument('--dem', metavar='DEM', help='DEM on the same grid (--to-geoid)')
    p.add_argument('--out', metavar='FILE', help='output map (--to-geoid)')
    p.add_argument('--max-slope', type=float, default=5.0,
                   help='slope ceiling defining near-flat pixels, deg (default 5)')
    p.add_argument('--order', type=int, default=2,
                   help='polynomial order of the geoid ramp (default 2)')
    a = p.parse_args()

    src = a.check or a.to_geoid
    th, h, hdr = ReadEnvi(src)
    d = Diagnose(th, a.order)

    print('map            : %s' % os.path.basename(src))
    print('header         : %s' % os.path.basename(hdr))
    print('grid           : %s x %s' % (h['samples'], h['lines']))
    print('valid pixels   : %d   NaN %d   exact zero %d   out of %g-%g deg %d'
          % (d['nvalid'], d['nan'], d['zero'], PLAUSIBLE[0], PLAUSIBLE[1], d['outband']))
    print('mean incidence : %.4f deg   span %.3f deg' % (d['mean'], d['span']))
    print('residual about an order-%d polynomial : MAD %.4f deg (rms %.4f)'
          % (a.order, d['mad'], d['rms']))
    print('verdict        : %s incidence' % d['verdict'])
    if d['verdict'] == 'GEOID':
        print('                 -> referenced to the local vertical, use as is')
    elif d['verdict'] == 'LOCAL':
        print('                 -> terrain-normal (AMSTerEngine >= V20260531)')
        print('                    do NOT use for ZTD/cos, LOS projection or EW-UD')
    else:
        print('                 -> between the two regimes; inspect before use')
    if d['zero']:
        print('WARNING        : %d exact zeros. cos(0)=1, so they would silently'
              % d['zero'])
        print('                 leave the delay unscaled rather than raise a NaN.')

    if a.check:
        return 0 if d['verdict'] == 'GEOID' else 2

    if not a.dem:
        sys.exit('ERROR: --to-geoid needs --dem')
    if d['verdict'] == 'GEOID':
        print('\nNothing to do: this map is already a geoid incidence.')
        return 0

    dem, dh, _ = ReadEnvi(a.dem)
    if GridKey(dh) != GridKey(h):
        sys.exit('ERROR: DEM grid differs from the incidence grid.\n'
                 '       incidence %s\n       dem       %s'
                 % (GridKey(h), GridKey(dh)))
    px, py = PixelSize(h)
    geoid, flat, mad, slope, se_med, se_max = ToGeoid(th, dem, px, py,
                                                     a.max_slope, a.order)

    print('\nrecovery')
    print('  pixel size            : %g x %g m' % (px, py))
    print('  near-flat pixels used : %d (%.2f%% of the grid, slope < %g deg)'
          % (flat.sum(), 100.0 * flat.mean(), a.max_slope))
    print('  scatter of those about the ramp : %.3f deg (expected: order %g deg,'
          ' the slope ceiling)' % (mad, a.max_slope))
    print('  standard error of the fitted ramp : %.4f deg median, %.4f deg worst'
          % (se_med, se_max))
    print('  -> error on the 1/cos factor      : %.3f %% median, %.3f %% worst'
          % (100 * se_med * np.pi / 180 * np.tan(np.radians(np.nanmean(geoid))),
             100 * se_max * np.pi / 180 * np.tan(np.radians(np.nanmean(geoid)))))
    if mad > 3.0 * a.max_slope:
        print('  WARNING: scatter far exceeds the slope ceiling. Suspect a DEM/map'
              ' misregistration.')
    if se_max > 0.3:
        print('  WARNING: the ramp is poorly constrained. Lower --order, or raise'
              ' --max-slope to admit more pixels.')
    gm = np.isfinite(geoid)
    print('  recovered geoid incidence : %.4f to %.4f deg (mean %.4f)'
          % (geoid[gm].min(), geoid[gm].max(), geoid[gm].mean()))

    out = a.out or re.sub(r'^incidence', 'incidenceGeoid', os.path.basename(src))
    if out == os.path.basename(src):
        out = 'geoid_' + os.path.basename(src)
    out = os.path.join(os.path.dirname(a.out or src) or '.', os.path.basename(out))
    oh = WriteEnvi(out, geoid, hdr,
                   'incidence referenced to the local vertical, rebuilt by '
                   'CheckIncidenceRef.py from a local incidence map')
    print('  written : %s\n            %s' % (out, oh))
    return 0


if __name__ == '__main__':
    sys.exit(main())