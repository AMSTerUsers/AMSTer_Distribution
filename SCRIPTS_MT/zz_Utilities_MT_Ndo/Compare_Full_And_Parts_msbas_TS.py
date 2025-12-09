#!/opt/local/amster_python_env/bin/python
#
# The script aims at displaying the (double difference) time series of a msbas inversion performed in 2 parts. 
#
# If provided with a 3rd parameter, it will plot that time series as well. It can be either the
# result of the processing performed in one block instead of two parts, or the results from the 
# combination of block 1 and 2 as done for instance in Domuyo_S1_Step3_MSBAS_DEMGeoid_Split.sh
#
# The date provided as the first parameter will allow to draw a vertical line at the date of the middle 
# overlap, where block 1 and 2 were adjusted by Add_DefoMap_ToAllMapsInDir.py. 
# The figure is saved in the current directory as Part1_2.png (or Part1_2_Full.png if provided 
# with 3 files)
#
# This script allows to check that the 2 parts are correctly aligned. 
#
# Each file is a txt file resulting from PlotTS_all_comp.sh, hence made of 6 columns: 
# YYYYMMDD HHMMSS TS_pix1  YYYYMMDD HHMMSS TS_pix2
# Hence files must be pre-processed with fct process_file to get [date , col 6-3]
#
# Parameters:	- date of the middle overlap, where the offset is computed by 
#				- Path to the file with data from part 1 (e.g. timeLine_EW_1456_1947_1573_1976_Auto_2_0.04_LUX_PART1_OVERLAP_20200816.txt)
# 				- Path to the file with data from part 2 (e.g. timeLine_EW_1456_1947_1573_1976_Auto_2_0.04_LUX_PART2_OVERLAP_20200816.txt
#				  Note here that the data of part 2 were offset during the split msbas by the difference between defo map 
#				  in the middle of the overlap period. See Add_DefoMap_ToAllMapsInDir.py for more info.
#				- [Path to the file with data from the whole porcessing (e.g. timeLine_EW_1456_1947_1573_1976_Auto_2_0.04_LUX.txt)]
#  
# Remember: Part 1 and 2 are expected to overlap during 3 times the max Temporal baseline used
# for computing the interferograms (BT). Note that if max BT is short (i.e. equivalent of 
# only a small number of orbit cycles), then it is advised to take 1 year instead of BT 
# in the following reasoning. 
# This overlap is mandatory because the beginning and the end of msbas 
# time series are expected to be affected by the fact that there is not enough pairs linked  
# to each images comprised in that first and last period of BT (see x in fig below).
#
# begin   BT    BT    BT                            BT    BT    BT    end
#   |xxxxx|-----|-----|------- ...Part1... ---------|-----|ooooo|xxxxx|
#                                                            ^
#                                                         Mid Overlap
#                                                            v
# 												  begin   BT    BT    BT                            BT    BT    BT    end
# 												    |xxxxx|ooooo|-----|------- ...Part2... ---------|-----|-----|xxxxx|
# begin   	    																									  end
#   |xxxxx---------------------------------------- ...Full... --------------------------------------------------|xxxxx|

# where - = good results in each TS
#		x = less accurate msbas results
#		o = overlapping good results in each TS 
#  

# New in Distro V 1.0  20240808: - set up 
# New in Distro V 2.0 20250813:	- launched from python3 venv
#
#
# AMSTer: SAR & InSAR Automated Mass processing Software for Multidimensional Time series
# NdO (c) 2024 - could make better with more functions... when time.
# -----------------------------------------------------------------------------------------
import csv
import argparse
import matplotlib.pyplot as plt
from datetime import datetime
import os

# Function to read and process double difference (col6 - col3) from the data from a file
def process_file(file_path):
    dates = []
    differences = []

    with open(file_path, 'r') as file:
        reader = csv.reader(file, delimiter='\t')
        for row in reader:
            date = row[0] + row[1]
            value3 = float(row[2])
            value6 = float(row[5])
            difference = value6 - value3

            # Convert date string to datetime object
            datetime_obj = datetime.strptime(date, '%Y%m%d%H%M%S')

            dates.append(datetime_obj)
            differences.append(difference)

    return dates, differences

# Main function
def main(vertical_date, file1, file2, file3=None):
    # Get base names of the files
    base_name_file1 = os.path.basename(file1)
    base_name_file2 = os.path.basename(file2)
    
    # Read and process the double diff of each file (to end with date and col 6-3)
    dates_file1, diff_file1 = process_file(file1)
    dates_file2, diff_file2 = process_file(file2)
    
    plt.figure(figsize=(12, 6))
    
    title = f'Plot of Double Differences TS {base_name_file1}: part1, part2'
    
    # Plot the vertical line at the specified date
    plt.axvline(x=vertical_date, color='blue', linestyle=':', label=f'MidOverlap: {vertical_date.strftime("%Y-%m-%d")}')
    
    # Check if the third file is provided and process it
    if file3:
        base_name_file3 = os.path.basename(file3)
        dates_file3, diff_file3 = process_file(file3)
        plt.plot(dates_file3, diff_file3, color='red', label='Full - (Column 6 - Column 3)')
        title += f', and Full'

    # Plot differences for file1 and file2
    plt.plot(dates_file2, diff_file2, color='cyan', linestyle='--', dashes=(10, 2), linewidth=1.0, label='Part2')
    plt.plot(dates_file1, diff_file1, color='green', linestyle='--', dashes=(10, 2), linewidth=1.0, label='Part1')
   
    # Add labels and legend
    plt.xlabel('Date')
    plt.ylabel('Double Difference [m]')
    plt.title(title)
    plt.legend()
    plt.grid(True)
    
    # Show the plot
    #plt.show()
    
    if file3:
        plt.savefig('Part1_2_Full.png')  # Save plot to a file
    else:
        plt.savefig('Part1_2.png')  # Save plot to a file
  
# Entry point of the script
if __name__ == "__main__":
    parser = argparse.ArgumentParser(description='Process and plot data from two or three files.')
    parser.add_argument('date', type=str, help='Date for the vertical bar (format: yyyymmdd)')
    parser.add_argument('file1', type=str, help='Path to the first part')
    parser.add_argument('file2', type=str, help='Path to the second part')
    parser.add_argument('file3', type=str, nargs='?', help='Optional: Path to the full time series')  # The "?" makes file3 optional
    
    args = parser.parse_args()
    
    # Convert the date argument to a datetime object
    vertical_date = datetime.strptime(args.date, '%Y%m%d')
    
    main(vertical_date, args.file1, args.file2, args.file3)