#!/opt/local/bin/python
#
# The script re-wrap a deformation image (provided as input param 1, float)
# and save the rewrapped image as jpg if the width of the image 
# is provided as a 2nd parameter. 
# Re-wrapped image is named after the input file with an additional string 
# before the extension, that is _rewrapped_{mod_value}
#
# Image is re-wrapped at 10 cm (0.1 m in script below). 
# Change hardcoded line in script if needed 
#
# Parameters :  - path to image to re-wrap
#				- optional: width of image to create jpg plot
#
# Dependencies:	- numpy
#
# Hardcoded: 	- re-wrapping value (in m): e.g. mod_value = 0.1 means 10cm
#
#
# AMSTer: SAR & InSAR Automated Mass processing Software for Multidimensional Time series
# N.d'Oreye, v 1.0 2025/06/03 -                         
######################################################################################

import numpy as np
import sys
import os
import matplotlib.pyplot as plt

def main():
    if len(sys.argv) < 2:
        print("Usage: python rewrap_floats.py <input_file> [width]")
        sys.exit(1)

    input_file = sys.argv[1]
    width = int(sys.argv[2]) if len(sys.argv) >= 3 else None
    mod_value = 0.1  # You can change this

    # Derive output filename
    base, ext = os.path.splitext(input_file)
    output_file = f"{base}_rewrapped_{mod_value}{ext}"

    # Read binary float32 data
    floats = np.fromfile(input_file, dtype=np.float32)

    # Apply modulo
    mod_floats = np.mod(floats, mod_value)

    # Save the output
    mod_floats.astype(np.float32).tofile(output_file)
    print(f"Rewrapped file written to: {output_file}")

    # Optional plotting
    if width:
        if len(mod_floats) % width != 0:
            print(f"Warning: Data size {len(mod_floats)} is not divisible by width {width}, trimming excess.")
            mod_floats = mod_floats[:len(mod_floats) - (len(mod_floats) % width)]

        height = len(mod_floats) // width
        image = mod_floats.reshape((height, width))

        plt.imshow(image, cmap='viridis', interpolation='nearest')
        plt.title("Modulo Rewrapped Image")
        plt.colorbar(label='Value (mod {:.2f})'.format(mod_value))

        # Save as JPG
        plt.savefig(f"{base}_rewrapped_{mod_value}.jpg", format='jpg', dpi=300)
        
        #plt.show()

if __name__ == "__main__":
    main()
