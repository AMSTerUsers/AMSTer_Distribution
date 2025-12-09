#!/bin/bash
# Script aims at merging several pair files and remove duplicated lines. 
# Pair files are provided as parameters. They are all of the following type:
#
#    Master	   Slave	 Bperp	 Delay
# 
# 20141030	20150311	    -6	   132
# 20141217	20150110	     0	    24 ...
#
# All input files must be provided with full path. 
# Output file is stored in path of first input file.   
# Output file is named by the addition of the input file names
#
# Parameters:	- Pair files (e.g. Merge_PairFiles.sh file1.txt file2.txt [file3.txt ...])
#
#
# Dependencies:	- 
#
# New in Distro V 1.0 20251024:	- 
#
# AMSTer: SAR & InSAR Automated Mass processing Software for Multidimensional Time series
# NdO (c) 2016/03/07 - could make better with more functions... when time.
# -----------------------------------------------------------------------------------------
PRG=`basename "$0"`
VER="Distro V1.0 AMSTer script utilities"
AUT="Nicolas d'Oreye, (c)2016-2019, Last modified on Oct 24, 2025"

echo "${PRG} ${VER}, ${AUT}"
echo " "

# === 1. Check arguments ===
if [ "$#" -lt 2 ]; then
  echo "Usage: $0 /full/path/to/file1.txt /full/path/to/file2.txt [more files...]"
  exit 1
fi

# === 2. Validate all input files exist ===
for file in "$@"; do
  if [ ! -f "$file" ]; then
    echo "❌ Error: File not found -> $file"
    exit 1
  fi
done

# === 3. Determine output directory (same as first input file) ===
first_file="$1"
output_dir=$(dirname "$first_file")

# === 4. Build output filename (combine basenames without extensions) ===
output_name=""
for file in "$@"; do
  base=$(basename "$file" .txt)
  if [ -z "$output_name" ]; then
    output_name="$base"
  else
    output_name="${output_name}_${base}"
  fi
done
output_path="${output_dir}/${output_name}.txt"

# === 5. Temporary files ===
tmpfile=$(mktemp)
sorted_unique=$(mktemp)

# === 6. Merge all data lines (skip 2-line header in each input) ===
for file in "$@"; do
  tail -n +3 "$file" >> "$tmpfile"
done

# === 7. Remove duplicate lines and sort numerically by Master + Slave ===
sort -u -k1,1n -k2,2n "$tmpfile" > "$sorted_unique"

# === 8. Write output with proper 2-line header ===
{
  echo -e "Master\tSlave\tBperp\tDelay"
  echo ""
  cat "$sorted_unique"
} > "$output_path"

# === 9. Cleanup ===
rm -f "$tmpfile" "$sorted_unique"

# === 10. Done ===
echo " Merge complete!"
echo " Output saved to: $output_path"
echo