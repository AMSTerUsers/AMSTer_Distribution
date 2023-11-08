#!/opt/local/bin/python
# 
# This scripts computes an unweighted Delaunay triangulation based on the file  allPairsListing.txt in the pwd. 
#
# It takes 1 option:
#	-Ratio=integer: ratio between X and Y axis for Delaunay triangulation to avoid elongated or shortened triangles
#                   Without ratio, 1m Bp is orthogonal to 1 day.
#					A ratio of 30 will make the 1m orthogonal to 1 day/30 , i.e. favor "longer" triangles
#					A ratio of 0.5 will make the 1m orthogonal to 2 days, i.e. favor "higher" triangles
#
# It creates :
#		- a file named table_0_0_DelaunayRatioMaxBtMaxBp_0.txt 
#			that contains all the list of pairs for the mass processing (naming depends on parameters),
#		- a file named Delaunay_Triangulation_MaxBtdays_MaxBpm_xyRatio_PairsforPlot.txt 
#			that contains all the list of pairs for plotting with baselinePlot (naming depends on parameters),
#		- a figure named Delaunay_Triangulation_Plot_xyRatio.png 
#			with the baseline plot (naming depends on parameters)
#
# WARNING: 	the filtering of the Delaunay connections with the Python script below seems to 
#			be wrong in rarer cases. Consider to use this filtering step from the bash script 
#			of the same name, that is DelaunayTable.py
#
# V 1.0 (2023/09/19)
# New in Distro V 2.0 20231030:	- Rename MasTer Toolbox as AMSTer Software
#								- rename Master and Slave as Primary and Secondary (though not possible in some variables and files)
#
# AMSTer: SAR & InSAR Automated Mass processing Software for Multidimensional Time series
# NdO (c) 2016/03/07 - could make better with more functions... when time.
# -----------------------------------------------------------------------------------------

import numpy as np
from scipy.spatial import Delaunay
import matplotlib.pyplot as plt
from datetime import datetime
import re
import argparse
import subprocess

# Create an argument parser
parser = argparse.ArgumentParser(description="Optional max Bp and Bt parameters")

# Define optional parameters 
#parser.add_argument('-BpMax', type=int, help="Optional max Bp")
#parser.add_argument('-BtMax', type=int, help="Optional max Bt")
parser.add_argument('-Ratio', type=float, help="Optional ratio between x (Bt) and y (Bp) graph for Delaunay triangulation")

# Parse the command-line arguments
args = parser.parse_args()

# Check if MaxBp and/or MaxBt were provided and do pass values to variables
# if args.BpMax:
# 	max_y_length = args.BpMax
# 	print(f"Max Bp is provided with value: {max_y_length}")
# 
# if args.BtMax:
# 	max_x_length = args.BtMax 
# 	print(f"Max Bt is provided with value: {max_x_length}")

if args.Ratio:
	# Define a ratio between X and Y axis for Delaunay triangulation to avoid elongated triangles
	ratio_x_y = args.Ratio 	# i.e. 1m Bp is orthogonal to 1 years/ratio_x_y Bt (eg 1m ortho to 1 day if ratio_x_y = 365) 
	print(f"Ratio between x (Bt) and y (Bp) graph for Delaunay triangulation is provided with value: {ratio_x_y}")
else: 
	ratio_x_y = 1

# Initialize variables to store data
lines = []

# Read the data from the file, skipping the first 7 header lines
with open('allPairsListing.txt', 'r') as file:
    lines = file.readlines()[7:]

# Define a regular expression pattern to split lines by variable whitespace
pattern = re.compile(r'\s+')

# Extract relevant columns (column 2 for date and column 8 for Bp values) ; stop reading when date of master in col 1 changes
dates = []
perpendicular_baseline = []

# Read the first date and Bp from line 8 (cols[0]) and store it in the dates list
with open('allPairsListing.txt', 'r') as file:
	first_line = file.readlines()[7]
	cols_first_line = pattern.split(first_line.strip())
	first_date_yyyymmdd = cols_first_line[0]
	dates.append(first_date_yyyymmdd)  # Assuming the date is in column 0 of the first line
	perpendicular_baseline.append(0)

# reads all lines from allpairsListing.txt (headerless) until value in col 1 changes
for line in lines:
	cols = pattern.split(line.strip())
	if cols[0] == first_date_yyyymmdd:
		dates.append(cols[1])
		perpendicular_baseline.append(float(cols[7]))
	else:
		break

# Create a dictionary to store Bp and Bt values from column 8 and 9 of allPairsListing.txt
column_8_values = {}	# Bp
column_9_values = {}	# Bt

with open('allPairsListing.txt', 'r') as file:
    for line_num, line in enumerate(file, start=1):
        if line_num <= 7:
            continue  # Skip the first 7 lines
        cols = pattern.split(line.strip())
        key1 = f"{cols[0]}\t{cols[1]}"  # Create the date pair key
        key2 = f"{cols[1]}\t{cols[0]}"  # Create the reversed date pair key
        valueBp = float(cols[7])  # Get the value from column 8
        column_8_values[key1] = valueBp
        column_8_values[key2] = valueBp  # Store the reversed key with the same value
        valueBt = int(cols[8])  # Get the value from column 9
        column_9_values[key1] = valueBt
        column_9_values[key2] = valueBt  # Store the reversed key with the same value

# Convert date strings to decimal years as Linux seconds
date_in_days = []

for date_str in dates:
	dateymd = datetime.strptime(date_str, "%Y%m%d")
	unix_timestamp = dateymd.timestamp()  # Convert to Unix timestamp (seconds since epoch)
	#days_in_year = 365 if not date.year % 4 else 366
	days_year = round(( unix_timestamp )/ ( 60 * 60 * 24 * ratio_x_y ))  # Calculate date in days since Linux sec * ratio_x_y because Bp and Bt are in different units 
	date_in_days.append(days_year)

# Convert the list of decimal years and values to NumPy arrays
x = np.array(date_in_days)
y = np.array(perpendicular_baseline)

# Combine X and Y arrays into a single array of (x, y) points
points = np.column_stack((x, y))

# Perform Delaunay triangulation
triangulation = Delaunay(points)

# Access the triangles and their vertices
triangles = triangulation.simplices

# Create a list to store pairs of dates for each triangle and corresponding perpendicular_baseline values for each triangle
date_pairs = []

# Calculate the x-length and y-length of each edge in the triangles
edges = []
for triangle in triangles:
    edges.extend([(triangle[0], triangle[1]), (triangle[1], triangle[2]), (triangle[2], triangle[0])])

# Update triangles based on the filtered edges
updated_triangles = []

# Check the conditions and perform actions accordingly
# if args.BpMax and args.BtMax:
# 	# filter edges based on max Bt and Bp lengths
# 	filtered_edges = [edge for edge in edges if ((np.abs(x[edge[0]] - x[edge[1]]) * ratio_x_y ) <= max_x_length) and (np.abs(y[edge[0]] - y[edge[1]]) <= max_y_length)]
# 	#filtered_edges = [edge for edge in edges if (np.abs(np.abs(x[edge[0]]) - np.abs(x[edge[1]])) <= max_x_length) and (np.abs(np.abs(y[edge[0]]) - np.abs(y[edge[1]])) <= max_y_length)]
# 
# 	# Remove duplicate edges (convert to a set and back to a list)
# 	unique_filtered_edges = list(set(filtered_edges))
# 	filter_flag = "yes"
# 	if args.Ratio:
# 		title = f'Delaunay Triangulation [1m is orthogonal to 1day/{ratio_x_y}] ; maximum {max_x_length} days baseline and maximum {max_y_length} m baseline'
# 		plotname = f'Delaunay_Triangulation_Plot_MaxBt{max_x_length}days_MaxBp{max_y_length}m_xyRatio{ratio_x_y}.png'
# 		pairsfilename = f'Delaunay_Triangulation_MaxBt{max_x_length}days_MaxBp{max_y_length}m_xyRatio{ratio_x_y}_PairsforPlot.txt'
# 		tablename = f'table_0_0_DelaunayRatio{ratio_x_y}MaxBt{max_x_length}MaxBp{max_y_length}_0.txt'
# 	else:
# 		title = f'Delaunay Triangulation [1m is orthogonal to 1day] ; maximum {max_x_length} days baseline and maximum {max_y_length} m baseline'
# 		plotname = f'Delaunay_Triangulation_Plot_MaxBt{max_x_length}days_MaxBp{max_y_length}m_NoRatio.png'
# 		pairsfilename = f'Delaunay_Triangulation_MaxBt{max_x_length}days_MaxBp{max_y_length}m_NoRatio_PairsforPlot.txt'
# 		tablename = f'table_0_0_DelaunayNoRatioMaxBt{max_x_length}MaxBp{max_y_length}_0.txt'
# 
# 	# Iterate over filtered triangles and calculate pairs of dates and perpendicular_baseline values
# 	for triangle in triangles:
# 		if all(edge in unique_filtered_edges for edge in [(triangle[0], triangle[1]), (triangle[1], triangle[2]), (triangle[2], triangle[0])]):
# 			date_pairs.append([(dates[triangle[0]], dates[triangle[1]]), 
# 			                    (dates[triangle[1]], dates[triangle[2]]), 
# 			                    (dates[triangle[2]], dates[triangle[0]])])
# 			updated_triangles.append(triangle)
# 
# 
# elif args.BtMax:
#     # Filter edges based on max Bt-length
# 	#filtered_edges = [edge for edge in edges if np.abs(np.abs(x[edge[0]]) - np.abs(x[edge[1]])) <= max_x_length]
# 	filtered_edges = [edge for edge in edges if ((np.abs(x[edge[0]] - x[edge[1]]) * ratio_x_y) <= max_x_length)]
# 
# 	# Remove duplicate edges (convert to a set and back to a list)
# 	unique_filtered_edges = list(set(filtered_edges))
# 	filter_flag = "yes"
# 	if args.Ratio:
# 		title = f'Delaunay Triangulation [1m is orthogonal to 1day/{ratio_x_y}] ; maximum {max_x_length} days baseline'
# 		plotname = f'Delaunay_Triangulation_Plot_MaxBt{max_x_length}days_xyRatio{ratio_x_y}.png'
# 		pairsfilename = f'Delaunay_Triangulation_MaxBt{max_x_length}days_xyRatio{ratio_x_y}_PairsforPlot.txt'
# 		tablename = f'table_0_0_DelaunayRatio{ratio_x_y}MaxBt{max_x_length}_0.txt'
# 	else:
# 		title = f'Delaunay Triangulation [1m is orthogonal to 1day] ; maximum {max_x_length} days baseline'
# 		plotname = f'Delaunay_Triangulation_Plot_MaxBt{max_x_length}days_NoRatio.png'
# 		pairsfilename = f'Delaunay_Triangulation_MaxBt{max_x_length}days_NoRatio_PairsforPlot.txt'
# 		tablename = f'table_0_0_DelaunayNoRatioMaxBt{max_x_length}_0.txt'
# 
# 	# Iterate over filtered triangles and calculate pairs of dates
# 	for triangle in triangles:
# 		if all(edge in unique_filtered_edges for edge in [(triangle[0], triangle[1]), (triangle[1], triangle[2]), (triangle[2], triangle[0])]):
# 			date_pairs.append([(dates[triangle[0]], dates[triangle[1]]), 
# 			                    (dates[triangle[1]], dates[triangle[2]]), 
# 			                    (dates[triangle[2]], dates[triangle[0]])])
# 			updated_triangles.append(triangle)
# 
# elif args.BpMax:
#     # Filter edges based on max Bp-length
# 	#filtered_edges = [edge for edge in edges if np.abs(np.abs(y[edge[0]]) - np.abs(y[edge[1]])) <= max_y_length]
# 	filtered_edges = [edge for edge in edges if (np.abs(y[edge[0]] - y[edge[1]]) <= max_y_length)]
# 	
# 	# Remove duplicate edges (convert to a set and back to a list)
# 	unique_filtered_edges = list(set(filtered_edges))
# 	filter_flag = "yes"
# 	if args.Ratio:
# 		title = f'Delaunay Triangulation [1m is orthogonal to 1day/{ratio_x_y}] ; maximum {max_y_length} m baseline'
# 		plotname = f'Delaunay_Triangulation_Plot_MaxBp{max_y_length}m_xyRatio{ratio_x_y}.png'
# 		pairsfilename = f'Delaunay_Triangulation_MaxBp{max_y_length}m_xyRatio{ratio_x_y}_PairsforPlot.txt'
# 		tablename = f'table_0_0_DelaunayRatio{ratio_x_y}MaxBp{max_y_length}_0.txt'
# 	else:
# 		title = f'Delaunay Triangulation [1m is orthogonal to 1day] ; maximum {max_y_length} m baseline'
# 		plotname = f'Delaunay_Triangulation_Plot_MaxBp{max_y_length}m_NoRatio.png'
# 		pairsfilename = f'Delaunay_Triangulation_MaxBp{max_y_length}m_NoRatio_PairsforPlot.txt'
# 		tablename = f'table_0_0_DelaunayNoRatioMaxBp{max_y_length}_0.txt'
# 
# 	# Iterate over filtered triangles and calculate pairs of dates
# 	for triangle in triangles:
# 		if all(edge in unique_filtered_edges for edge in [(triangle[0], triangle[1]), (triangle[1], triangle[2]), (triangle[2], triangle[0])]):
# 			date_pairs.append([(dates[triangle[0]], dates[triangle[1]]), 
# 			                    (dates[triangle[1]], dates[triangle[2]]), 
# 			                    (dates[triangle[2]], dates[triangle[0]])])
# 			updated_triangles.append(triangle)
# 
# else:
# 	print("No filtering of triangles.")
# 	# Do something when neither p1 nor p2 are provided
# 	filter_flag = "no"
# 	if args.Ratio:
# 		title = f'Delaunay Triangulation [1m is orthogonal to 1day/{ratio_x_y}] ; no maximum baselines'
# 		plotname = f'Delaunay_Triangulation_NoMaxBaselines_xyRatio{ratio_x_y}.png'
# 		pairsfilename = f'Delaunay_Triangulation_NoMaxBaselines_xyRatio{ratio_x_y}_PairsforPlot.txt'
# 		tablename = f'table_0_0_DelaunayRatio{ratio_x_y}NoMaxBaselines_0.txt'
# 	else:
# 		title = f'Delaunay Triangulation [1m is orthogonal to 1day] ; no maximum baselines'
# 		plotname = f'Delaunay_Triangulation_NoMaxBaselines_NoRatio.png'
# 		pairsfilename = f'Delaunay_Triangulation_NoMaxBaselines_NoRatio_PairsforPlot.txt'
# 		tablename = f'table_0_0_DelaunayNoRatioNoMaxBaselines_0.txt'
# 
# 	for triangle in triangles:
# 		# Extract the pairs of dates for this triangle
# 		date_pairs.append([(dates[triangle[0]], dates[triangle[1]]), 
# 		                        (dates[triangle[1]], dates[triangle[2]]), 
# 		                        (dates[triangle[2]], dates[triangle[0]])])
#Replace commented above
# Do something when neither p1 nor p2 are provided
filter_flag = "no"
if args.Ratio:
	title = f'Delaunay Triangulation [1m is orthogonal to 1day/{ratio_x_y}]'
	plotname = f'Delaunay_Triangulation_xyRatio{ratio_x_y}.png'
	pairsfilename = f'Delaunay_Triangulation_xyRatio{ratio_x_y}_PairsforPlot.txt'
	tablename = f'table_0_0_DelaunayRatio{ratio_x_y}_0.txt'
else:
	title = f'Delaunay Triangulation [1m is orthogonal to 1day]'
	plotname = f'Delaunay_Triangulation_NoRatio.png'
	pairsfilename = f'Delaunay_Triangulation_NoRatio_PairsforPlot.txt'
	tablename = f'table_0_0_DelaunayNoRatio_0.txt'

for triangle in triangles:
	# Extract the pairs of dates for this triangle
	date_pairs.append([(dates[triangle[0]], dates[triangle[1]]), 
	                        (dates[triangle[1]], dates[triangle[2]]), 
	                        (dates[triangle[2]], dates[triangle[0]])])


# Save the list of date pairs and  Bp to a text file for plotting with baselinePlot
with open(pairsfilename, 'w') as date_pairs_file:
	for pairs in date_pairs:
		for pair in pairs:
			date_pair_key = f"{pair[0]}\t{pair[1]}"  # Create the date pair key
			value_from_column_8 = column_8_values.get(date_pair_key, "N/A")  # Get the corresponding value from column 8
			date_pairs_file.write(f"Dummy\t{value_from_column_8}\t{pair[0]}\t{pair[1]}\n")
# Sort the file based on columns 3 and 4
subprocess.run(['sort', '-o', pairsfilename, '-k3,3', '-k4,4', pairsfilename])

# Save the list of date pairs and  Bp to a text file for plotting with baselinePlot
with open(tablename, 'w') as date_pairs_file:
	for pairs in date_pairs:
		for pair in pairs:
			date_pair_key = f"{pair[0]}\t{pair[1]}"  # Create the date pair key
			value_from_column_8 = column_8_values.get(date_pair_key, "N/A")  # Get the corresponding value from column 8
			value_from_column_9 = column_9_values.get(date_pair_key, "N/A")  # Get the corresponding value from column 9
			date_pairs_file.write(f"{pair[0]}\t{pair[1]}\t{value_from_column_8}\t{value_from_column_9}\n")
# Sort the file based on columns 1 and 2 
subprocess.run(['sort', '-o', tablename, '-k1,1', '-k2,2', tablename])

# Create the header lines
header_line1 = "   Master	   Slave	 Bperp	 Delay"
header_line2 = " "

# Reopen the file in write mode and write the header lines to the beginning, overwriting the file
with open(tablename, 'r+') as sorted_file:
    # Read the sorted content
    sorted_content = sorted_file.read()
    # Seek to the beginning of the file
    sorted_file.seek(0)
    # Write the header lines
    sorted_file.write(header_line1 + '\n')
    sorted_file.write(header_line2 + '\n')
    # Write the sorted content after the header
    sorted_file.write(sorted_content)
    # Truncate any remaining content (in case the new content is shorter than the old)
    sorted_file.truncate()

# title of the plot
if args.Ratio:
	xlabeltitle = f'Years [in Linux days] * {ratio_x_y} '
else:
	xlabeltitle = f'Years [in Linux days] '

# Plot the Delaunay triangulation
plt.figure(figsize=(8, 6))
if filter_flag == "yes":
	plt.triplot(x, y, updated_triangles, 'go--', linewidth=0.5)
else: 
	plt.triplot(x, y, triangles, 'go--', linewidth=0.5)
plt.plot(x, y, 'ro')  # Mark the points
plt.xlabel(xlabeltitle)
plt.ylabel('Bp')
plt.title(title)
plt.savefig(plotname)  # Save the plot as an image

# Show the plot if needed
#plt.show()

#####################################
# for debugging: 
#####################################

# Save the edges list to a text file
# edges_filename = "DEBUG_edges.txt"
# filtered_edges_filename = "DEBUG_filtered_edges.txt"
# with open(edges_filename, 'w') as edges_file:
#     edges_file.write(f"edge_0 edge_1 DateDays_0 DateDays_1 BP_0 	BP_1 	Delta_Bt  	Delta_Bp\n")
#     edges_file.write(f"\n")
#     for edge in edges:
#         # edge_0 edge_1 DateDays_0 DateDays_1 BP_0 BP_1 Delta_Bt  Delta_Bp
#         edges_file.write(f"{edge[0]}\t\t{edge[1]}\t\t{x[edge[0]]}\t{x[edge[1]]}\t\t{y[edge[0]]}\t{y[edge[1]]}\t{(np.abs(x[edge[0]] - x[edge[1]]) * ratio_x_y)}\t\t{np.abs(y[edge[0]] - y[edge[1]])}\n")
# if filter_flag == "yes":        
# 	with open(filtered_edges_filename, 'w') as filtered_edges_file:
# 		filtered_edges_file.write(f"edge_0 edge_1 DateDays_0 DateDays_1 BP_0 	BP_1 	Delta_Bt  	Delta_Bp\n")
# 		filtered_edges_file.write(f"\n")
# 		for edge in filtered_edges:
# 			filtered_edges_file.write(f"{edge[0]}\t\t{edge[1]}\t\t{x[edge[0]]}\t{x[edge[1]]}\t\t{y[edge[0]]}\t{y[edge[1]]}\t{(np.abs(x[edge[0]] - x[edge[1]]) * ratio_x_y)}\t\t{np.abs(y[edge[0]] - y[edge[1]])}\n")
# 
# # Save the dates in days to a text file
# dates_days_filename = "DEBUG_Dates_In_days_Bp.txt"
# # stack date and date_in_days
# img_numbers = np.arange(0, len(dates) )
# compare_dates = np.column_stack((img_numbers, dates, x, perpendicular_baseline))
# #compare_dates = np.column_stack((dates, x))
# with open(dates_days_filename, 'w') as dates_days_filename:
#     dates_days_filename.write(f"Pt_Nr\tDate \t Date_in_days\tBp\n")
#     dates_days_filename.write(f"\n")
#     for datedays in compare_dates:
#         dates_days_filename.write(f"{datedays[0]}\t\t{datedays[1]}\t{datedays[2]}\t\t{datedays[3]}\n")

# save X Y points of Delaunay triangulation
#txt_filename = "DEBUG_X_Y_points.txt"
#format_string = '%.2f'  # precision (e.g., 6 decimal places)
#np.savetxt(txt_filename, points, delimiter='\t', header='Date_in_Days\tBp_From_1st_Img\n', comments='', fmt=format_string)



