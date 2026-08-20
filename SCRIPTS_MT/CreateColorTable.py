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
# New in Distro V 2.1 20060121:	- rename rgba_color as rgba
#								- update for val in values loop
#								- auto format legend 
#								- ensure no division by 0
#
# This script is part of the AMSTer Toolbox 
# AMSTer: SAR & InSAR Automated Mass processing Software for Multidimensional Time series
# -----------------------------------------------------------------------------------------
import sys
import numpy as np


#def generate_colortable(outfile, vmin, vmax, nsteps=256):
#
#    with open(outfile, "w") as f:
#
#        values = np.linspace(vmin, vmax, nsteps)
#
#        ZERO_EPS = 1e-12  # only exact zero transparent
#        for val in values:
#            if val < 0:
#                t = (val - vmin) / (0 - vmin) if vmin != 0 else 0
#                r = int((1 - t) * 255)
#                g = int(t * 255)
#                b = 0
#            else:
#                t = val / vmax if vmax != 0 else 0
#                r = 0
#                g = int((1 - t) * 255)
#                b = int(t * 255)
#        
#            # Only exact zero is transparent
#            a = 0 if abs(val) < ZERO_EPS else 1
#            f.write(f"{val} {r} {g} {b} {a}\n")  # include alpha

def generate_colortable(outfile, vmin, vmax, nsteps=256):
    with open(outfile, "w") as f:

        values = np.linspace(vmin, vmax, nsteps)
        ZERO_EPS = 1e-12  # only exact zero transparent

        for val in values:
            if val < 0:
                t = (val - vmin) / (0 - vmin) if vmin != 0 else 0
                r = int((1 - t) * 255)
                g = int(t * 255)
                b = 0
            else:
                t = val / vmax if vmax != 0 else 0
                r = 0
                g = int((1 - t) * 255)
                b = int(t * 255)

            # write 3 columns (RGB) for all real values
            f.write(f"{val} {r} {g} {b}\n")

        # Only NV (or exact zero) is transparent
        f.write("nv 0 0 0 0\n")          
# --------------------------
# Legend (auto-format)
# --------------------------
def generate_legend(outfile, vmin, vmax, width, height):
    import matplotlib.pyplot as plt
    from matplotlib.colors import LinearSegmentedColormap

    # Fine-scale gradient
    nsteps = 1024
    values = np.linspace(vmin, vmax, nsteps)
    rgba = []

    for val in values:
         if val < 0:
             t = (val - vmin) / (0 - vmin)
             r, g, b = (1 - t), t, 0
         elif val > 0:
             t = val / vmax
             r, g, b = 0, (1 - t), t
         else:
             r = g = b = 0
         ZERO_EPS = 1e-12
         a = 0 if abs(val) < ZERO_EPS else 1
         rgba.append((r, g, b, a))

    cmap = LinearSegmentedColormap.from_list("diverging", rgba, N=nsteps)

    # Vertical gradient for legend
    gradient = np.linspace(0, 1, height).reshape(height, 1)

    fig, ax = plt.subplots(figsize=(width/100, height/100), dpi=100)
    fig.patch.set_alpha(0)  # transparent background

    ax.imshow(gradient, aspect='auto', cmap=cmap, origin='lower', extent=[0, width, vmin, vmax])
    ax.set_axis_off()

    # Add min, 0, max labels
    fmt = lambda v: f"{v:.2f}"

    ax.text(width/2, vmin, f">{fmt(vmin)}", ha='center', va='bottom')
    ax.text(width/2, 0, fmt(0), ha='center', va='center')
    ax.text(width/2, vmax, f"{fmt(vmax)}<", ha='center', va='top')

    plt.subplots_adjust(0, 0, 1, 1)
    plt.savefig(outfile, transparent=True, bbox_inches='tight', pad_inches=0)
    plt.close()


# --------------------------
# Main
# --------------------------
if len(sys.argv) < 4:
    print(__doc__)
    sys.exit(1)

if sys.argv[1] == '--legend':
    generate_legend(
        sys.argv[2],
        float(sys.argv[3]),
        float(sys.argv[4]),
        int(sys.argv[5]),
        int(sys.argv[6])
    )
else:
    generate_colortable(
        sys.argv[1],
        float(sys.argv[2]),
        float(sys.argv[3]),
        int(sys.argv[4]) if len(sys.argv) > 4 else 256
    )
