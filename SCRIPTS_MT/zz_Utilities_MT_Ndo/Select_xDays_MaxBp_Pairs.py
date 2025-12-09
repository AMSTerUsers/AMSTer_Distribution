#!/opt/local/amster_python_env/bin/python
######################################################################################
# This script aims at creating a table of interferometric pairs based on the file 
# allPairsListing.txt that is like: 
#   # List of all potential InSAR pairs in directory:
#   #	/mnt/1650/SAR_SM/MSBAS/ARGENTINE/set1
#   #
#   #
#   #Identified Super Master: 20180512
#   #
#   # Master date   .   Slave date  .       xm     .       ym     .       xs     .       ys     .       Bp0      .       Bp      .       Dt      .       Ha
#       20141030        20141123          122.65           28.72         -116.72          -20.59          119.95         -228.72              24           61.60
#       20141030        20141217          122.65           28.72           -6.00          -37.71          119.95         -144.62              48           97.42
#
# The output pair list (named Min{MinDays}daysAfterImg_Max{MaxDays}daysAfterImg_Max{BpThreshold}Bp_pairs.txt) 
# contains for each individual Primary image (master) date, the date of the Secondary (slave) image 
# that is >= MinDays days after the Primary date but not after MaxDays. If no MaxDays is provided, it set it to 9999 days
# If not Max Bp parameter, it will take the first date available. If a Max Bp parameter is provided, 
# it will take the first Secondary image at least x days after the Primary date, though with 
# a Bp below the given threshold. 
#
# Parameters: - path to the allPairsListing.txt table (must be provided as 1st parameter)
#			  - min number of days to select the Secondary image in the form of +MinDays= 
#			  - optional: max number of days to select the Secondary image in the form of +MaxDays=  (will set it to 9999 if not provided)
#			  - optional: max Bp in the form of +Bp= 	(will set it to 9999 if not provided)
#
# Usage:
#   Select_xDays_MaxBp_Pairs.py <path/To/My/>allPairsListing.txt +MinDays=<N> [+MaxDays=<N>] [+MaxBp=<N>]
#
# Meaning:
#   For each Primary image, find the Secondary image acquired between +MinDays and +MaxDays days
#   after the Primary, with |Bp| ≤ MaxBp. If no such Secondary exists, that Primary is skipped.
#
# Dependencies : - python3.10 and modules below (see import) 
#
# New in Distro V 1.0 20251024:	- created
# New in Distro V 1.1 20251028:	- new parameter to restrict search to x + MinDays up to x + MaxDays  
#
#
# AMSTer: SAR & InSAR Automated Mass processing Software for Multidimensional Time series
# Nicolas d'Oreye, (c)2025
######################################################################################

import sys
import os
import pandas as pd
from datetime import datetime, timedelta

# === 1. Handle command-line arguments ===
if len(sys.argv) < 2:
    print("Usage: My_script.py <file_path> +MinDays=<N> [+MaxDays=<N>] [+MaxBp=<N>]")
    print("Example: My_script.py /path/to/allPairsListing.txt +MinDays=90 +MaxDays=105 +MaxBp=30")
    sys.exit(1)

file_path = sys.argv[1]
min_days = None
max_days = 9999  # default if not provided
bp_threshold = 9999  # default if not provided

# === 2. Parse optional arguments ===
for arg in sys.argv[2:]:
    if arg.startswith("+MinDays="):
        min_days = int(arg.split("=")[1])
    elif arg.startswith("+MaxDays="):
        max_days = int(arg.split("=")[1])
    elif arg.startswith("+MaxBp="):
        bp_threshold = float(arg.split("=")[1])
    else:
        print(f" Ignoring unknown argument: {arg}")

# === 3. Validate required parameters ===
if min_days is None:
    print(" Error: +MinDays= parameter is required.")
    sys.exit(1)

print(f"\n Reading: {file_path}")
print(f" MinDays: {min_days}")
print(f" MaxDays: {max_days if max_days != 9999 else 'No upper limit'}")
print(f" Max |Bp|: {bp_threshold if bp_threshold != 9999 else 'No threshold'}\n")

# === 4. Load the InSAR pairs file ===
df = pd.read_csv(
    file_path,
    comment="#",
    sep=r"\s+",  # modern syntax replacing delim_whitespace=True
    names=[
        "Master", "Slave", "xm", "ym", "xs", "ys",
        "Bp0", "Bp", "Dt", "Ha"
    ]
)

# === 5. Convert date strings to datetime objects ===
df["Master"] = pd.to_datetime(df["Master"], format="%Y%m%d")
df["Slave"] = pd.to_datetime(df["Slave"], format="%Y%m%d")

# === 6. Apply Bp threshold (unless set to 9999) ===
if bp_threshold < 9999:
    before_count = len(df)
    df = df[df["Bp"].abs() <= bp_threshold]
    print(f" Filtered by |Bp| ≤ {bp_threshold}: kept {len(df)} of {before_count} pairs\n")

# === 7. For each master, select one slave within the given window ===
selected_rows = []

for master, group in df.groupby("Master"):
    target_min = master + timedelta(days=min_days)
    target_max = master + timedelta(days=max_days)

    # Keep only slaves within [MinDays, MaxDays]
    valid = group[(group["Slave"] >= target_min) & (group["Slave"] <= target_max)]

    if not valid.empty:
        # Choose the slave closest to the MinDays target
        chosen = valid.loc[(valid["Slave"] - target_min).abs().idxmin()]
        selected_rows.append(chosen)
    # else: silently skip this master if no valid slave found

# === 8. Build result DataFrame ===
if len(selected_rows) == 0:
    print("⚠️  No valid pairs found matching criteria.")
    sys.exit(0)

result = pd.DataFrame(selected_rows)

# === 9. Format output table ===
result["Master"] = result["Master"].dt.strftime("%Y%m%d")
result["Slave"] = result["Slave"].dt.strftime("%Y%m%d")
result["Bperp"] = result["Bp"].round(0).astype(int)
result["Delay"] = result["Dt"].astype(int)
final_table = result[["Master", "Slave", "Bperp", "Delay"]]

# === 10. Build output file path ===
input_dir = os.path.dirname(os.path.abspath(file_path))
out_file = os.path.join(
    input_dir,
    f"Min{min_days}_Max{max_days}daysAfterImg_Max{int(bp_threshold)}Bp_pairs.txt"
)

# === 11. Save with blank line after header ===
with open(out_file, "w") as f:
    f.write("Master\tSlave\tBperp\tDelay\n\n")
    final_table.to_csv(f, sep="\t", index=False, header=False)

# === 12. Display summary ===
print(" Selection complete! Saved output as:")
print(f"   {out_file}\n")
print(final_table.to_string(index=False))

