#!/opt/local/amster_python_env/bin/python
######################################################################################
# This script makes a vecor plot from EW and NS displacements maps wrapped on DEM.	
# All files are provided in UTM Envi Harris format. 
#
# Parameters: -	UTM ENvi Harris DEM
#			  - UTM ENvi Harris NS displ  e.g. "MSBAS_LINEAR_RATE_NS.bin"
#			  - UTM ENvi Harris EW displ  e.g. "MSBAS_LINEAR_RATE_EW.bin"
#			  - optional :  - number of lines and col to crop from original image 
#							  as follow: --x_min 50 --x_max 115 --y_min 100 --y_max 240 
#								(to crop and keep from 50 to 115 col and from 100 to 240 lines)
#						or: - number of first Lines that where removed from DEM at processing 
#							  as follow: --x_min 100 (to remove the 100 first lines to the north)
# 			  - a threshold (in mm/yr) for small absolute values of displacement. 
# 				Pixels where magnitude of displ is below that threshold will be masked in vector plot.
# 				  	e.g.:	--threshold 0.003  	(default is 0.002)
#			  - the scale of the vector in the definition of plt.quiver; larger makes vector smaller 
#					e.g.:   --scalevalue 0.3	(default is 0.2)
#			  - the downsampling rate (e.g. dwsple=3 will display one vector every 3 pixel)
#					e.g.:   --dwsple 5			(default is 3)
#			  - contour DEM instead of shaded relief if add --contour 
# 
# Dependencies:	- python3.10 and modules below (see import)
#
# launch command : python thisscript.py param1 param2 ..
#
# New in Distro V 1.1 20240625:	- comment show plot to allow continuing in cron script
# 								- allows downsampling the plot (hardcoded)
#								- correctly adjust the length of vector scale with fig
# New in Distro V 1.2 20250103:	- set threshold, scale and downsampling as parameters 
# New in Distro V 2.0 20250813:	- launched from python3 venv
# New in Distro V 2.1 20250904:	- add option to plot results on contoured DEM instead of shaded relief 
#
#
# AMSTer: SAR & InSAR Automated Mass processing Software for Multidimensional Time series
# NdO (c) 2024/01/16 - could make better with more functions... when time.
######################################################################################

# Now as parameters
## vvvvvvvvv hard coded vvvvvvvvvvvvvv
#
## Set a threshold for small absolute values of displacement. 
##    Pixels where magnitude of displ is below that threshold will be masked in vector plot. 
#threshold = 0.002	# in m/yr
#
## larger scale values make vectors smaller
#scalevalue=0.2
#
## downsampling rate to plot vector plot with a vector for every 1/dwsple pixel (e.g. EW_NS_Vector_Displ_Downsampled_3.jpg)
## Note that a full vector plot is also displayed (EW_NS_Vector_Displ.jpg)
#dwsple=3
#
## ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

import numpy as np
import sys
import os
import subprocess
import argparse

import matplotlib.pyplot as plt
from mpl_toolkits.axes_grid1 import make_axes_locatable
from matplotlib.colors import LightSource

def main():
	parser = argparse.ArgumentParser(description='DEM NS_displ EW_displ [Lines or x_min to cut] [x_max to cut] [y_min to cut] [y_max to cut]')

	# Mandatory parameters
	parser.add_argument('input_dem', type=str, help='Mandatory DEM')
	parser.add_argument('input_ns_displ', type=str, help='Mandatory NS_displ')
	parser.add_argument('input_ew_displ', type=str, help='Mandatory EW_displ')

	# Optional parameters
	parser.add_argument('--x_min', type=int, nargs=1, help='Optional parameter 1: nr of first lines (i.e. to the North) to cut or x_min to crop ')
	parser.add_argument('--x_max', type=int, nargs=1, help='Optional parameter 2:  x_max to crop ')
	parser.add_argument('--y_min', type=int, nargs=1, help='Optional parameter 3: y_min to crop ')
	parser.add_argument('--y_max', type=int, nargs=1, help='Optional parameter 4: y_max to crop ')

	# New optional parameters
	parser.add_argument('--threshold', type=float, default=0.002, help='Threshold for displacement magnitude (default: 0.002):  Pixels where magnitude of displ is below that threshold will be masked in vector plot. ')
	parser.add_argument('--scalevalue', type=float, default=0.2, help='Scale value for the quiver plot (default: 0.2): larger scale values make vectors smaller')
	parser.add_argument('--dwsple', type=int, default=3, help='Downsampling factor to plot vector plot with a vector for every 1/dwsple pixel (e.g. EW_NS_Vector_Displ_Downsampled_3.jpg) (default: 3)')
	parser.add_argument('--contour', action='store_true', help='If provided, plot DEM as terrain contours instead of hillshade')
	
	args = parser.parse_args()
	print(' ')
	print('Mandatory Parameters:')
	print(f'input_dem: {args.input_dem}')
	print(f'input_ns_displ: {args.input_ns_displ}')
	print(f'input_ew_displ: {args.input_ew_displ} \n')

	print('Optional Parameters:')
	print(f'x_min: {args.x_min}')
	print(f'x_max: {args.x_max}')
	print(f'y_min: {args.y_min}')
	print(f'y_max: {args.y_max}')
	print(f'threshold: {args.threshold}')
	print(f'scalevalue: {args.scalevalue}')
	print(f'dwsple: {args.dwsple}')
	print(f'contour: {args.contour}\n')


	# Initialize first_lines_to_discard and x_max to 0 by default
	first_lines_to_discard = 0
	x_max = 0

	if args.x_min is not None:
		print(f'Optional parameter x_min or Nr of first lines to remove: {args.x_min[0]}')
		x_min = args.x_min[0]
		if args.x_max is not None:
			print(f'Optional parameter x_max: {args.x_max[0]}')
			x_max = args.x_max[0]
			if args.y_min is not None:
				print(f'Optional parameter y_min: {args.y_min[0]}')
				y_min = args.y_min[0]
			if args.y_max is not None:
				print(f'Optional parameter y_max: {args.y_max[0]} \n')
				y_max = args.y_max[0]
		else:
			first_lines_to_discard = args.x_min[0]

	# Read the input UTM Envi Harris dem as regular binary file
	###########################################################
	with open(args.input_dem, 'rb') as file:
		# Assuming 32-bit floating-point data, adjust the dtype accordingly
		dem = np.fromfile(file, dtype=np.float32)

	# Reads its header to get the nr of rows and columns 
	# Get the base filename without extension
	base_filename, _ = os.path.splitext(args.input_dem)
	# Create the filename for the corresponding .hdr file
	header_dem = base_filename + '.hdr'
	
	def read_envi_header(header_dem):
		# Use grep to extract Lines and Samples lines
		grep_command = f"grep -E '(ines|amples|info)' {header_dem}"
		grep_output = subprocess.check_output(grep_command, shell=True, text=True)
	
		# Process the output to create a dictionary
		header_info = {}
		for line in grep_output.splitlines():
			key, value = map(str.strip, line.split('=', 1))
			header_info[key] = value
		
		return header_info
	
	def get_lines_and_columns(header_info):
		lines = int(header_info['Lines'])
		samples = int(header_info['Samples'])
		
		return lines, samples

	def get_pixel_size(header_info):
		map_info = header_info.get('Map info', '').replace('{', '').replace('}', '').split(',')
		pixel_size_x = float(map_info[5])
		pixel_size_y = float(map_info[6])
		return pixel_size_x, pixel_size_y

	
	header_info = read_envi_header(header_dem)
	lines, columns = get_lines_and_columns(header_info)
	pixel_size_x, pixel_size_y = get_pixel_size(header_info)

	full_lines = lines		# Keep just in case
	full_columns = columns	# Keep just in case
	
	print(f'Number of full lines: {full_lines}')
	print(f'Number of full columns: {full_columns} \n')
	print(f'pixel size: {pixel_size_x} x {pixel_size_y} m \n')

	# Read the input UTM Envi Harris ns displacement as regular binary file
	########################################################################
	# UTM Envi Harris ns displacement
	with open(args.input_ns_displ, 'rb') as file:
		nsdispl = np.fromfile(file, dtype=np.float32)

	# Read the input UTM Envi Harris ew displacement as regular binary file
	########################################################################
	with open(args.input_ew_displ, 'rb') as file:
		# Assuming 32-bit floating-point data, adjust the dtype accordingly
		ewdispl = np.fromfile(file, dtype=np.float32)


	# Read the data as matrix
	#########################
	dem = dem.reshape((lines ,columns))
	dem_original = dem		# Keep just in case
	
	nsdispl = nsdispl.reshape((lines ,columns))
	ewdispl = ewdispl.reshape((lines ,columns))

	nsdispl_original = nsdispl 	# Keep just in case
	ewdispl_original = ewdispl 	# Keep just in case

	
	## Clip the data if 4 optional parameters 
	#########################################
	if x_max > 0:
		print(f'Clip the files:')
		# clip dem
		dem = dem[y_min:y_max, x_min:x_max]

		# clip nsdispl
		nsdispl = nsdispl[y_min:y_max, x_min:x_max]

		# clip ewdispl
		ewdispl = ewdispl[y_min:y_max, x_min:x_max]

		# Now that all files are read with full lines and columns
		# then clipped, re-evaluate the number of lines and columns
		lines = y_max - y_min
		columns = x_max - x_min
		
		print(f'Number of clipped lines: {lines}')
		print(f'Number of clipped columns: {columns} \n')
	else:
		print(f'Do not clip the files: {x_max}')
		

	# Remove the first_lines_to_discard = x_min first lines (specific purpose) 
	# if only one additional parameter is used
	##########################################################################
	if first_lines_to_discard > 0:
		# remove 100 first lines
		dem = dem[first_lines_to_discard:, :]
	
		# remove 100 first lines
		nsdispl = nsdispl[first_lines_to_discard:, :]
		ewdispl = ewdispl[first_lines_to_discard:, :]

		# Now that all files are read with full lines and columns
		# then first lines removed, re-evaluate the number of lines 
		lines = lines - first_lines_to_discard
		
		print(f'Number of lines after removing the {first_lines_to_discard} first lines: {lines} \n')

	
	# Detrend ns comp
	#################
	#
	## Create a grid of coordinates
	#x, y = np.meshgrid(np.arange(columns), np.arange(lines))
	#
	## Reshape the displacement map and coordinates to 1D arrays
	#nsdispl_flat = nsdispl.flatten()
	#x_flat = x.flatten()
	#y_flat = y.flatten()
	#
	## Prepare the input data for linear regression
	#A = np.column_stack((x_flat, y_flat, np.ones_like(nsdispl_flat)))
	#
	## Solve the linear system to find the coefficients of the plane
	#coefficients, _, _, _ = np.linalg.lstsq(A, nsdispl_flat, rcond=None)
	#
	## Extract coefficients for the plane
	#slope_x, slope_y, intercept = coefficients
	#
	## Compute the plane trend
	#plane_trend = slope_x * x + slope_y * y + intercept
	#
	## Remove the plane trend from the displacement map
	#nsdispl_detrended = nsdispl - plane_trend
	#
	#nsdispl = nsdispl_detrended
	#


	# Plot the DEM
	##############
	#plt.imshow(dem, cmap='terrain', origin='upper')
	# Plot the DEM with a light grey color scale
	#plt.imshow(dem, cmap='gray', origin='upper')
	
	#### Calculate hillshade using a LightSource
	###ls = LightSource(azdeg=315, altdeg=65)
	###hillshade = ls.hillshade(dem, vert_exag=1.0, dx=1.0, dy=1.0)
	
	# Plot the shaded relief
	plt.figure(figsize=(12, 12))
	#plt.imshow(hillshade, cmap='gray', origin='upper', extent=(0, dem.shape[1], dem.shape[0], 0))
	
	#extent = (0, dem.shape[1], dem.shape[0], 0)
	extent = (0, columns, 0, lines) 

	if args.contour:
		# Contour plotting without flipping the array
		contourf = plt.contourf(dem, levels=30, cmap="terrain", extent=extent, alpha=0.7)
		contours = plt.contour(dem, levels=30, colors="black", linewidths=0.3, extent=extent)
		plt.clabel(contours, inline=True, fontsize=6, fmt="%d")
		cbar = plt.colorbar(contourf)
		cbar.set_label("Elevation (m)")
		
		# Flip the y-axis to match the NS orientation of imshow
		plt.gca().invert_yaxis()
	else:
	 	# Hillshade plotting
	 	ls = LightSource(azdeg=315, altdeg=65)
	 	hillshade = ls.hillshade(dem, vert_exag=1.0, dx=1.0, dy=1.0)
	 	plt.imshow(hillshade, cmap='gray', origin='upper', extent=extent)
	
	# Create a vector plot for displacement
	#######################################forget anoy
	
	# Create a mask for small absolute values in ewdispl
	#mask = np.abs(ewdispl) < threshold
	
	#mask based on magnitude of displ (i.e. in ew and ns)
	# Calculate the magnitude of the displacement vectors
	magnitude = np.sqrt(ewdispl**2 + nsdispl**2)
	mask = magnitude < args.threshold
	
	# Set vectors to NaN where ewdispl is smaller than the threshold
	ewdispl[mask] = np.nan
	nsdispl[mask] = np.nan
	
	# Clip the figure instead of file :
	# comment section "Clip the data if 4 optional parameters" 
	# and uncomment below
	# Beware : you can see vectors crossing fig from pix outside of plots
	########################################################################
#	if x_max > 0:
#		plt.xlim(x_min, x_max)
#		plt.ylim(y_max, y_min)  # Note that y-axis limits are set from 125 to 100 to reverse the direction
	
	
	# Create a vector plot
	#plt.quiver(range(columns_clip), range(lines_clip), ewdispl, nsdispl, color='red', scale=2)
	scalevalue = args.scalevalue
	q = plt.quiver(range(columns), range(lines), ewdispl, nsdispl, color='red', scale=scalevalue)
	plt.quiverkey(q,0.3,0.9,0.01 / scalevalue,"0.01 m/yr",coordinates='figure',color='red')

	# Set labels and title
	#plt.xlabel('Columns')
	#plt.ylabel('Rows')
	if first_lines_to_discard > 0:
		plt.xlabel(f'Columns\n 1 pixel = {pixel_size_y}m')
		plt.ylabel(f'Rows ({full_lines} minus {first_lines_to_discard} first lines)\n 1 pixel = {pixel_size_x}m')
		pltname="EW_NS_Vector_Displ_MinusLines"
	else:
		if x_max > 0:
			plt.xlabel(f'Columns (from {x_min} to {x_max} among {full_columns} original)\n 1 pixel = {pixel_size_y}m')
			plt.ylabel(f'Rows (from {y_min} to {y_max} among {full_lines} original)\n 1 pixel = {pixel_size_x}m')
			pltname="EW_NS_Vector_Displ_Zoom"
		else: 
			plt.xlabel(f'Columns\n 1 pixel = {pixel_size_y}m')
			plt.ylabel(f'Rows\n 1 pixel = {pixel_size_x}m')
			pltname="EW_NS_Vector_Displ"

	# Append "_contour" if the --contour flag is used
	if args.contour:
		pltname += "_contour"

	# Add the extension
	pltname += ".jpg"

	plt.title(f'Vector plot of displacement wrapped on DEM')
	
	# Save the plot as a JPEG image
	plt.savefig(f'{pltname}', dpi=1300)
	
	# Show the plot
	#plt.show()

	
	# create the same plot, though downsampled plot every dwsple pixel
	##################################################################
	#clean fig
	plt.clf()
	# get background again
	plt.figure(figsize=(12, 12))
	##plt.imshow(hillshade, cmap='gray', origin='upper', extent=(0, dem.shape[1], dem.shape[0], 0))
	if args.contour:
		# Contour plotting without flipping the array
		contourf = plt.contourf(dem, levels=30, cmap="terrain", extent=extent, alpha=0.7)
		contours = plt.contour(dem, levels=30, colors="black", linewidths=0.3, extent=extent)
		plt.clabel(contours, inline=True, fontsize=6, fmt="%d")
		cbar = plt.colorbar(contourf)
		cbar.set_label("Elevation (m)")
		
		# Flip the y-axis to match the NS orientation of imshow
		plt.gca().invert_yaxis()
	else:
		ls = LightSource(azdeg=315, altdeg=65)
		hillshade = ls.hillshade(dem, vert_exag=1.0, dx=1.0, dy=1.0)
		plt.imshow(hillshade, cmap='gray', origin='upper', extent=extent)

	# Create a grid of coordinates
	x = np.arange(0, columns)
	y = np.arange(0, lines)

	# Use slicing to select every dwspleth element
	dwsple = args.dwsple
	
	x_subsampled = x[::dwsple]
	y_subsampled = y[::dwsple]
	
	ewdispl_subsampled = ewdispl[::dwsple, ::dwsple]
	nsdispl_subsampled = nsdispl[::dwsple, ::dwsple]
	
	# Plot the quiver plot with subsampled data
	qsub = plt.quiver(x_subsampled, y_subsampled, ewdispl_subsampled, nsdispl_subsampled, color='red', scale=scalevalue)
	plt.quiverkey(qsub, 0.3, 0.9, 0.01 / scalevalue , "0.01 m/yr", coordinates='figure', color='red')

	if first_lines_to_discard > 0:
		plt.xlabel(f'Columns\n 1 pixel = {pixel_size_y}m')
		plt.ylabel(f'Rows ({full_lines} minus {first_lines_to_discard} first lines)\n 1 pixel = {pixel_size_x}m')
		pltname = f"EW_NS_Vector_Displ_MinusLines_Downsampled_{dwsple}"
	else:
		if x_max > 0:
			plt.xlabel(f'Columns (from {x_min} to {x_max} among {full_columns} original)\n 1 pixel = {pixel_size_y}m')
			plt.ylabel(f'Rows (from {y_min} to {y_max} among {full_lines} original)\n 1 pixel = {pixel_size_x}m')
			pltname = f"EW_NS_Vector_Displ_Zoom_Downsampled_{dwsple}"
		else: 
			plt.xlabel(f'Columns\n 1 pixel = {pixel_size_y}m')
			plt.ylabel(f'Rows\n 1 pixel = {pixel_size_x}m')
			pltname = f"EW_NS_Vector_Displ_Downsampled_{dwsple}"

	# Append "_contour" if the --contour flag is used
	if args.contour:
		pltname += "_contour"

	# Add the extension
	pltname += ".jpg"


	plt.title(f'Subsampled vector plot of displacement wrapped on DEM (1 vector every {dwsple} pixel)')
	
	# Save the plot as a JPEG image
	plt.savefig(pltname, dpi=1300)

	
	#plt.show()


		
if __name__ == "__main__":
	main()
