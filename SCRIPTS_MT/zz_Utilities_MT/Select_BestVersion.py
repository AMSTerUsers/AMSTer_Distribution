#!/opt/local/amster_python_env/bin/python

############################################################################
#
# Select_BestVersion.py
#
# Among several versions of a same deformation map (GACOS, MANGO/GAMIT,
# MANGO/GIPSY, uncorrected, ...) sitting SIDE BY SIDE in one directory,
# tell which one is the best, and print its full path on stdout so that a
# bash script can grab it:
#
#   BESTMAP=$(Select_BestVersion.py "${PRIORITY}_TMP_${RUNDATE}_${RNDM1}")
#
# Nothing is moved, copied or deleted unless -move is given (see below).
#
# Scoring follows Select_bestatmocor.py (D. Smittarello): for each pair, the
# spatial std and mad of the displacement are computed over the valid pixels
# (finite, and inside an optional 0/1 mask). Lowest std wins; if the mad
# points at another candidate the disagreement is logged, but std decides.
# Lower score = less residual atmospheric noise.
#
# stdout holds ONLY the result: one full path per pair, nothing else, so that
# a command substitution returns a directly usable value. Everything else
# (progress, scores, warnings, errors) goes to stderr.
#
# ENVI is read natively (header parsing + numpy), hence no rasterio/GDAL
# dependency and no .aux.xml sidecar dropped in the data directories.
#
############################################################################
# Author: N. d'Oreye + assistant, 2026
# Scoring logic after Select_bestatmocor.py, D. Smittarello, 2026
############################################################################
# New in V1.1 : - 
#
# AMSTer: SAR & InSAR Automated Mass processing Software for Multidimensional Time series
# Nicolas d'Oreye, (c)2017-18
######################################################################################

"""
Select_BestVersion.py
---------------------
Usage:
  Select_BestVersion.py <dir> [-print best|others|all] [-mask FILE]
                        [-pair YYYYMMDD_YYYYMMDD] [-csv FILE]
                        [-move [-best DIR] [-others DIR] [-dryrun]] [-v N]

Argument:
  <dir>        Directory holding every candidate version of the maps
               (ENVI binary + '<binary>.hdr'), all pairs mixed together,
               typically <MODE>_TMP_<rnd1>_<rnd2>.

Prints:        one absolute path per line. With -print all, the winner of a pair
               comes first, followed by the candidates discarded for that pair.
Exit status:   0 if every pair got a winner, 1 otherwise (and the failing pair
               prints nothing, so the caller's variable stays empty).

Options:
  -print       'best' (default) the winner, 'others' the discarded candidates,
               'all' both, winner first.
  -mask        ENVI 0/1 mask on the same grid as the maps; 1 = use the pixel.
  -pair        Restrict to that single pair. Default: every pair found.
  -csv         Also write the scores of every candidate to that table.
               Default: none (avoids a race when several runs go in parallel).
  -move        Additionally dispatch the maps: the winner to -best, the others
               to -others. Off by default, the script only reports.
  -best        With -move, destination of the winners. Default: <dir> truncated
               at its 'TMP' token, i.e. <MODE>.
  -others      With -move, destination of the others. Default: <MODE>_UnselectedVersion.
  -dryrun      With -move, report the moves without doing them.
  -v           0 critical, 1 error, 2 warning, 3 info (default), 4 debug.

Examples:
  # just tell me which one is best
  BESTMAP=$(Select_BestVersion.py "${PRIORITY}_TMP_${RUNDATE}_${RNDM1}")
  [ -z "${BESTMAP}" ] && echo "no usable map" && exit 1

  # best AND discarded in one single run, one pair with two candidates:
  # the winner is printed first, so two successive reads fill the two variables
  { read -r BESTMAP ; read -r OTHERMAP ; } < <(Select_BestVersion.py \
      "${PRIORITY}_TMP_${RUNDATE}_${RNDM1}" -print all)

  # more than two candidates, or more than one pair: loop over the discarded ones
  Select_BestVersion.py "${PRIORITY}_TMP_${RUNDATE}_${RNDM1}" -print others |
      while IFS= read -r OTHERMAP ; do mv "${OTHERMAP}" "${OTHERMAP}.hdr" "${UNSEL}" ; done

  # and dispatch them at the same time
  Select_BestVersion.py "${PRIORITY}_TMP_${RUNDATE}_${RNDM1}" -move \\
      -best "${PRIORITY}" -others "${PRIORITY}_UnselectedVersion"
"""

import argparse
import csv
import logging
import os
import re
import shutil
import sys
from datetime import datetime, timezone
from pathlib import Path

import numpy as np

PAIR_RE = re.compile(r"(\d{8}_\d{8})")

CSV_FIELDS = ["pair", "filename", "n_valid", "std", "mad",
              "is_best", "best_metric", "std_mad_agree", "moved_to", "scored_at"]

# ENVI 'data type' code -> numpy dtype
ENVI_DTYPES = {1: "u1", 2: "i2", 3: "i4", 4: "f4", 5: "f8",
               12: "u2", 13: "u4", 14: "i8", 15: "u8"}


# --------------------------------------------------------------------- ENVI reader
def read_envi_header(hdr_path):
    """Parse an ENVI .hdr into a dict of lowercase keys -> string values.
    Handles the multi-line '{ ... }' blocks (band names, map info, ...)."""
    text = Path(hdr_path).read_text(errors="replace")
    fields = {}
    key = None
    buf = ""
    depth = 0
    for line in text.splitlines():
        if depth == 0:
            if "=" not in line:
                continue
            key, _, val = line.partition("=")
            key = key.strip().lower()
            buf = val.strip()
            depth = buf.count("{") - buf.count("}")
            if depth <= 0:
                fields[key] = buf.strip("{} \t")
                depth = 0
        else:
            buf += " " + line.strip()
            depth += line.count("{") - line.count("}")
            if depth <= 0:
                fields[key] = buf.strip("{} \t")
                depth = 0
    return fields


def read_envi_band(path):
    """Read band 1 of an ENVI file as float64, with the nodata value NaN-filled.

    AMSTer convention: the header is '<binary>.hdr', i.e. '.hdr' appended to the
    full binary name (which itself contains many dots)."""
    path = Path(path)
    hdr_path = Path(str(path) + ".hdr")
    if not hdr_path.is_file():
        raise FileNotFoundError(f"no ENVI header next to {path.name} ({hdr_path.name})")

    hdr = read_envi_header(hdr_path)
    try:
        samples = int(hdr["samples"])
        lines = int(hdr["lines"])
        dtype_code = int(hdr["data type"])
    except KeyError as e:
        raise ValueError(f"{hdr_path.name}: missing mandatory field {e}")

    bands = int(hdr.get("bands", 1))
    offset = int(hdr.get("header offset", 0))
    interleave = hdr.get("interleave", "bsq").lower()
    byte_order = int(hdr.get("byte order", 0))

    if dtype_code not in ENVI_DTYPES:
        raise ValueError(f"{hdr_path.name}: unsupported ENVI data type {dtype_code} "
                         f"(complex data cannot be scored by std/mad)")
    dtype = np.dtype((">" if byte_order == 1 else "<") + ENVI_DTYPES[dtype_code])

    expected = samples * lines * bands * dtype.itemsize
    actual = path.stat().st_size - offset
    if actual < expected:
        raise ValueError(f"{path.name}: file holds {actual} bytes, header announces "
                         f"{expected} ({samples}x{lines}x{bands} of {dtype.str})")

    with open(path, "rb") as f:
        f.seek(offset)
        raw = np.fromfile(f, dtype=dtype, count=samples * lines * bands)

    # keep band 1 only, whatever the interleave (identical when bands == 1)
    if bands == 1:
        band = raw.reshape(lines, samples)
    elif interleave == "bsq":
        band = raw.reshape(bands, lines, samples)[0]
    elif interleave == "bil":
        band = raw.reshape(lines, bands, samples)[:, 0, :]
    elif interleave == "bip":
        band = raw.reshape(lines, samples, bands)[:, :, 0]
    else:
        raise ValueError(f"{hdr_path.name}: unknown interleave '{interleave}'")

    band = band.astype(np.float64)

    # 'data ignore value' is the ENVI nodata; absent in most AMSTer headers,
    # in which case only the NaNs are discarded.
    if "data ignore value" in hdr:
        try:
            nodata = float(hdr["data ignore value"])
            band[band == nodata] = np.nan
        except ValueError:
            logging.warning(f"{hdr_path.name}: unreadable 'data ignore value', ignored.")
    return band


def load_mask(mask_path, ref_shape):
    """Load a 0/1 ENVI mask as a boolean array (True = keep the pixel)."""
    mask = read_envi_band(mask_path)
    if mask.shape != ref_shape:
        raise ValueError(f"mask shape {mask.shape} != map shape {ref_shape} "
                         f"for {mask_path}")
    return np.nan_to_num(mask, nan=0.0) > 0.5


# --------------------------------------------------------------------- scoring
def compute_scores(data, mask=None):
    """(std, mad, n_valid) over the finite pixels, restricted to the mask if given."""
    valid = np.isfinite(data)
    if mask is not None:
        valid &= mask
    vals = data[valid]
    n_valid = int(vals.size)
    if n_valid == 0:
        return np.nan, np.nan, 0
    std = float(np.std(vals))
    mad = float(np.median(np.abs(vals - np.median(vals))))
    return std, mad, n_valid


# --------------------------------------------------------------------- discovery
def discover_candidates(srcdir, only_pair=None):
    """Return {pair: [binary paths]} for every ENVI map found in srcdir.
    A map is a '<binary>.hdr' header whose binary exists beside it."""
    bypair = {}
    for hdr in sorted(Path(srcdir).glob("*.hdr")):
        m = PAIR_RE.search(hdr.name)
        if not m:
            logging.debug(f"{hdr.name}: no YYYYMMDD_YYYYMMDD in the name, ignored.")
            continue
        if only_pair and m.group(1) != only_pair:
            continue
        binary = hdr.parent / hdr.name[:-4]      # strip exactly '.hdr'
        if not binary.is_file():
            logging.warning(f"{hdr.name}: no binary beside the header, ignored.")
            continue
        bypair.setdefault(m.group(1), []).append(binary)
    return bypair


# --------------------------------------------------------------------- destinations
TMP_TOKEN = "TMP"
UNSEL_TOKEN = "UnselectedVersion"


def derive_destinations(srcdir):
    """Only used by -move. The source is a temporary directory
    '<MODE>_TMP_<rnd1>_<rnd2>' whose trailing parts are a random tag, so
    everything from the 'TMP' token onwards is dropped to get back to <MODE>:

        <MODE>_TMP_<rnd1>_<rnd2>  -> best   in  <MODE>
                                  -> others in  <MODE>_UnselectedVersion

    A bare '<MODE>_TMP' gives the same result. Returns (None, None) if the name
    holds no 'TMP' token, in which case -best and -others must be given. Only the
    exact token 'TMP' counts: 'TMPO', 'aTMP' or 'tmp' are ordinary name parts."""
    parts = srcdir.name.split("_")
    if TMP_TOKEN not in parts:
        return None, None
    mode = "_".join(parts[:parts.index(TMP_TOKEN)])     # first 'TMP' splits the name
    if not mode:                                        # the name started with 'TMP'
        return None, None
    return srcdir.parent / mode, srcdir.parent / (mode + "_" + UNSEL_TOKEN)


# --------------------------------------------------------------------- moving
SIDECARS = (".hdr", ".aux.xml", ".sta")


def move_map(binary, target, dryrun=False):
    """Move a map (binary + its sidecars) to target. Never overwrite: since this
    is a move, an existing destination file would mean losing the source."""
    files = [binary] + [Path(str(binary) + s) for s in SIDECARS
                        if Path(str(binary) + s).is_file()]
    for f in files:
        if (target / f.name).exists():
            logging.error(f"{f.name} already exists in {target}: {binary.name} "
                          f"left in {binary.parent.name}.")
            return False
    if dryrun:
        logging.info(f"[dryrun] {binary.name} -> {target}")
        return True
    target.mkdir(parents=True, exist_ok=True)
    for f in files:
        shutil.move(str(f), str(target / f.name))
    logging.info(f"{binary.name} -> {target}")
    return True


# --------------------------------------------------------------------- CSV
def write_csv(csv_path, rows):
    csv_path = Path(csv_path)
    csv_path.parent.mkdir(parents=True, exist_ok=True)
    with open(csv_path, "w", newline="") as f:
        writer = csv.DictWriter(f, fieldnames=CSV_FIELDS)
        writer.writeheader()
        for r in rows:
            writer.writerow({k: r.get(k, "") for k in CSV_FIELDS})


def fmt(x):
    return f"{x:.6g}" if np.isfinite(x) else ""


# --------------------------------------------------------------------- main logic
def select_best(srcdir, mask_path=None, only_pair=None,
                bestdir=None, othersdir=None, dryrun=False):
    """Score every candidate of every pair and designate a winner.

    If bestdir/othersdir are given, the maps are also moved there. Returns
    (selection, rows, n_failed) where selection is, in pair order, a list of
    {"pair", "best", "others"} holding the final absolute-able paths, and rows is
    the material for the CSV."""
    srcdir = Path(srcdir)
    bypair = discover_candidates(srcdir, only_pair)
    if not bypair:
        raise SystemExit(f"ERROR: no ENVI map (binary + .hdr) found in {srcdir}"
                         + (f" for pair {only_pair}." if only_pair else "."))
    logging.info(f"{sum(len(v) for v in bypair.values())} map(s) in {len(bypair)} pair(s).")

    scored_at = datetime.now(timezone.utc).isoformat(timespec="seconds")
    mask = None
    selection, rows, n_failed = [], [], 0

    for pair in sorted(bypair):
        results = []
        for path in bypair[pair]:
            data = read_envi_band(path)
            if mask_path and mask is None:
                mask = load_mask(mask_path, data.shape)
            elif mask is not None and mask.shape != data.shape:
                raise SystemExit(f"ERROR: {path.name}: map shape {data.shape} != "
                                 f"mask shape {mask.shape}.")
            std, mad, n_valid = compute_scores(data, mask)
            logging.info(f"{pair} {path.name}: std={std:.6g} mad={mad:.6g} n={n_valid}")
            results.append({"path": path, "std": std, "mad": mad, "n_valid": n_valid})

        scorable = [r for r in results if r["n_valid"] > 0 and np.isfinite(r["std"])]
        if not scorable:
            logging.error(f"{pair}: no scorable candidate (all empty/NaN), no winner.")
            n_failed += 1
            for r in results:
                rows.append({"pair": pair, "filename": r["path"].name,
                             "n_valid": r["n_valid"], "std": fmt(r["std"]),
                             "mad": fmt(r["mad"]), "is_best": "", "best_metric": "std",
                             "std_mad_agree": "", "moved_to": "", "scored_at": scored_at})
            continue

        # std decides; the mad is only used to flag a disagreement
        best = min(scorable, key=lambda r: r["std"])
        best_mad = min(scorable, key=lambda r: r["mad"])
        agree = best is best_mad
        if not agree:
            logging.warning(
                f"{pair}: std and mad disagree: std-best={best['path'].name} "
                f"(std={best['std']:.6g}) vs mad-best={best_mad['path'].name} "
                f"(mad={best_mad['mad']:.6g}). std decides.")
        logging.info(f"{pair}: best is {best['path'].name}")

        for r in results:
            is_best = r is best
            moved_to = ""
            if bestdir is not None:
                target = bestdir if is_best else othersdir
                if move_map(r["path"], target, dryrun):
                    moved_to = str(target)
                else:
                    n_failed += 1
            rows.append({
                "pair": pair,
                "filename": r["path"].name,
                "n_valid": r["n_valid"],
                "std": fmt(r["std"]),
                "mad": fmt(r["mad"]),
                "is_best": "1" if is_best else "0",
                "best_metric": "std",
                "std_mad_agree": "1" if agree else "0",
                "moved_to": moved_to,
                "scored_at": scored_at,
            })

        # report the paths AFTER a possible move, so that they always exist
        def final(path, target):
            if target is not None and not dryrun:
                moved = target / path.name
                if moved.is_file():
                    return moved
            return path

        selection.append({
            "pair": pair,
            "best": final(best["path"], bestdir),
            "others": [final(r["path"], othersdir) for r in results if r is not best],
        })

    return selection, rows, n_failed


if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        description="Print the full path of the best version of each map found in a "
                    "directory holding several corrected versions of the same maps.")
    parser.add_argument("srcdir", help="Directory holding the candidate maps.")
    parser.add_argument("-print", dest="what", default="best",
                        choices=["best", "others", "all"],
                        help="What to print: the winner (default), the discarded "
                             "candidates, or both (winner first, then the others).")
    parser.add_argument("-mask", default=None, help="ENVI 0/1 mask on the same grid.")
    parser.add_argument("-pair", default=None, help="Restrict to that YYYYMMDD_YYYYMMDD pair.")
    parser.add_argument("-csv", default=None, help="Also write the scores to that table.")
    parser.add_argument("-move", action="store_true",
                        help="Also dispatch the maps to -best / -others (off by default).")
    parser.add_argument("-best", default=None,
                        help="With -move: destination of the winners (default <MODE>).")
    parser.add_argument("-others", default=None,
                        help="With -move: destination of the others "
                             "(default <MODE>_UnselectedVersion).")
    parser.add_argument("-dryrun", action="store_true", help="With -move: move nothing.")
    parser.add_argument("-v", type=int, default=3,
                        help="0 critical, 1 error, 2 warning, 3 info, 4 debug")
    args = parser.parse_args()

    # stderr, so that stdout carries the result and nothing else
    logging.basicConfig(stream=sys.stderr,
                        level={0: logging.CRITICAL, 1: logging.ERROR, 2: logging.WARNING,
                               3: logging.INFO, 4: logging.DEBUG}.get(args.v, logging.INFO),
                        format="%(asctime)s [%(levelname)s] %(message)s")

    srcdir = Path(args.srcdir.rstrip("/"))       # tolerate the tab-completion slash
    if not srcdir.is_dir():
        sys.exit(f"ERROR: no such directory: {srcdir}")

    if args.pair and not re.fullmatch(r"\d{8}_\d{8}", args.pair):
        sys.exit(f"ERROR: -pair must be YYYYMMDD_YYYYMMDD, got '{args.pair}'.")

    # -best / -others are only meaningful when the maps are dispatched
    bestdir = othersdir = None
    if args.move:
        bestdir = Path(args.best) if args.best else None
        othersdir = Path(args.others) if args.others else None
        if bestdir is None or othersdir is None:
            auto_best, auto_others = derive_destinations(srcdir)
            if auto_best is None:
                sys.exit(f"ERROR: '{srcdir.name}' holds no '{TMP_TOKEN}' token, so <MODE> "
                         f"cannot be derived. Give both -best and -others.")
            bestdir = bestdir or auto_best
            othersdir = othersdir or auto_others
        if bestdir.resolve() == othersdir.resolve() or \
                srcdir.resolve() in (bestdir.resolve(), othersdir.resolve()):
            sys.exit("ERROR: the source and the two destinations must be three distinct dirs.")
        logging.info(f"best -> {bestdir} / others -> {othersdir}")
    elif args.best or args.others or args.dryrun:
        logging.warning("-best/-others/-dryrun are ignored without -move: "
                        "the script only reports, it moves nothing.")

    selection, rows, n_failed = select_best(
        srcdir=srcdir, mask_path=args.mask, only_pair=args.pair,
        bestdir=bestdir, othersdir=othersdir, dryrun=args.dryrun)

    # THE result on stdout, nothing else: one full path per line, and for -print all
    # the winner of a pair always comes first, its discarded candidates right after.
    for sel in selection:
        if args.what in ("best", "all"):
            print(os.path.abspath(sel["best"]))
        if args.what in ("others", "all"):
            for other in sel["others"]:
                print(os.path.abspath(other))

    if args.csv:
        write_csv(args.csv, rows)
        logging.info(f"Scores written to {args.csv}")

    # the source is a temporary directory: get rid of it once it is empty. rmdir
    # (not rmtree) so that anything left behind is always preserved.
    if args.move and not args.dryrun and not any(srcdir.iterdir()):
        srcdir.rmdir()
        logging.info(f"Removed the emptied temporary directory {srcdir}.")

    sys.exit(1 if n_failed else 0)
