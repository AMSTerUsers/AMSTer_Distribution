#!/opt/local/amster_python_env/bin/python
# The scripts aims at generating a smooth, diverging color table identical to 
# what ImageMagick -clut would do for an Envi velocity map for instance, where 
# min=red, 0=green, max=blue (diverging)
# It is needed for GraphicsMagick, which does not have -clut.  
#
# This will be fed into the script Envi2ColorKmz.sh 
#
# Parameters:	- name of the color table to create
#				- Min value of Envi file to be used as min value in table 
#				- Max value of Envi file to be used as max value in table 
#				- optional: number of steps in table. If not provided, it will use 256 
#				- optional: --legend to generate a PNG legend from the same colortable 
#
# New in Distro V 1.0 20050917:	- 
# New in Distro V 2.0 20051202:	- debug scale > 0 
#								- make true zero transparent
#
# This script is part of the AMSTer Toolbox 
# AMSTer: SAR & InSAR Automated Mass processing Software for Multidimensional Time series
# -----------------------------------------------------------------------------------------
import sys
import numpy as np


def generate_colortable(outfile, vmin, vmax, nsteps=256):
    import numpy as np

    with open(outfile, "w") as f:

        values = np.linspace(vmin, vmax, nsteps)

        for val in values:
            if val < 0:
                t = (val - vmin) / (0 - vmin)
                r = int((1 - t) * 255)
                g = int(t * 255)
                b = 0
            else:
                t = val / vmax
                r = 0
                g = int((1 - t) * 255)
                b = int(t * 255)

            # ALWAYS OPAQUE — zero transparency handled by GDAL alpha
            f.write(f"{val} {r} {g} {b}\n")

        # Only NaN is transparent
        f.write("nv 0 0 0 0\n")

def generate_legend(outfile, vmin, vmax, width, height):
    import matplotlib.pyplot as plt
    from matplotlib.colors import LinearSegmentedColormap
    import numpy as np

    # Fine-scale gradient
    nsteps = 1024
    values = np.linspace(vmin, vmax, nsteps)
    rgba_colors = []

    EPS = 1e-6
    for val in values:
        if val < 0:
            t = (val - vmin) / (0 - vmin)
            r = (1-t)
            g = t
            b = 0
        elif val > 0:
            t = (val - 0) / (vmax - 0)
            r = 0
            g = (1-t)
            b = t
        else:
            r = g = b = 0
        a = 0 if val == 0 else 1  # only exact zero transparent
        rgba_colors.append((r, g, b, a))

    cmap = LinearSegmentedColormap.from_list("diverging", rgba_colors, N=nsteps)

    # Vertical gradient for legend
    gradient = np.linspace(0, 1, height).reshape(height, 1)

    fig, ax = plt.subplots(figsize=(width/100, height/100), dpi=100)
    fig.patch.set_alpha(0)  # transparent background

    ax.imshow(gradient, aspect='auto', cmap=cmap, origin='lower', extent=[0, width, vmin, vmax])
    ax.set_axis_off()

    # Add min, 0, max labels
    def format_label(val, digits=2):
        return f"{val:.{digits}f}"
    
    ax.text(width/2, vmin, f">{format_label(vmin)}", color='black', fontsize=12, ha='center', va='bottom')
    ax.text(width/2, 0, format_label(0), color='black', fontsize=12, ha='center', va='center')
    ax.text(width/2, vmax, f"{format_label(vmax)}<", color='black', fontsize=12, ha='center', va='top')
    
    plt.subplots_adjust(left=0, right=1, top=1, bottom=0)
    plt.savefig(outfile, bbox_inches='tight', pad_inches=0, transparent=True)
    plt.close()


# --------------------------
# Main
# --------------------------
if len(sys.argv) < 4:
    print(__doc__)
    sys.exit(1)

if sys.argv[1] == '--legend':
    # Legend mode
    if len(sys.argv) != 7:
        print("Usage: python3 CreateColorTable.py --legend legend.png MIN MAX WIDTH HEIGHT")
        sys.exit(1)
    outfile = sys.argv[2]
    vmin = float(sys.argv[3])
    vmax = float(sys.argv[4])
    width = int(sys.argv[5])
    height = int(sys.argv[6])
    generate_legend(outfile, vmin, vmax, width, height)
else:
    # Colortable mode
    outfile = sys.argv[1]
    vmin = float(sys.argv[2])
    vmax = float(sys.argv[3])
    nsteps = int(sys.argv[4]) if len(sys.argv) > 4 else 256
    generate_colortable(outfile, vmin, vmax, nsteps)
