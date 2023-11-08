# https://gis.stackexchange.com/questions/261504/getting-row-col-on-click-of-a-pixel-on-a-qgis-map?noredirect=1&lq=1
# Slightly modified by AD from Detlev for QT5 and QGIS 3
# Works with python3.10
# New in Distro V 	20231030:	- Rename MasTer Toolbox as AMSTer Software
#
# AMSTer: SAR & InSAR Automated Mass processing Software for Multidimensional Time series
# NdO (c) 2016/03/07 - could make better with more functions... when time.
# -----------------------------------------------------------------------------------------

import qgis

# added by NdO - Aug 8 2019
import os
import subprocess

# change dir where your mesbas is processed (one mode at a time) eg /Volumes/hp-D3602-Data_RAID5/MSBAS/LUX_partial/zz_UD_test
os.chdir("/Volumes/hp-D3602-Data_RAID5/MSBAS/_Guadeloupe_S1_Auto_50m_150days/zz_LOS_IWDesc_Auto_2_0.04_Guadeloupe")
print("")
print("Current Working Directory " , os.getcwd())
print("")

from qgis.utils import iface
from qgis.gui import (QgsMapTool, QgsRubberBand, QgsLayerTreeMapCanvasBridge, QgsLayerTreeView,
                  QgsMapCanvas, QgsMapToolPan,
                  QgsVertexMarker, QgsMessageBar, QgsMapCanvas)
from PyQt5.QtCore import Qt, QPoint
from math import floor

# references to QGIS objects 

canvas = iface.mapCanvas()
layer = iface.activeLayer()
data_provider = layer.dataProvider()

# properties to map mouse position to row/col index of the raster in memory 
extent = data_provider.extent() 
width = data_provider.xSize() if data_provider.capabilities() & data_provider.Size else 1000 
height = data_provider.ySize() if data_provider.capabilities() & data_provider.Size else 1000 
xres = extent.width() / width 
yres = extent.height() / height

class ClickTool(QgsMapTool): 
    def __init__(self, canvas):
        QgsMapTool.__init__(self, canvas)
        self.canvas = canvas 

    def canvasPressEvent(self, event):
        if event.button() == Qt.LeftButton: 
            x = event.pos().x()
            y = event.pos().y()

            # clicked position on screen to map coordinates
            point = self.canvas.getCoordinateTransform().toMapCoordinates(x, y)

            if extent.xMinimum() <= point.x() <= extent.xMaximum() and \
                extent.yMinimum() <= point.y() <= extent.yMaximum():
                col = int(floor((point.x() - extent.xMinimum()) / xres))
                row = int(floor((extent.yMaximum() - point.y()) / yres))

                # Modified by NdO for consistency with MSBAS
                # print (row, col)
                print (col, row)
                # added by NdO - Aug 8 2019
                os.system("/Users/doris/SAR/AMSTer/SCRIPTS_MT/PlotTS.sh %s %s -f -r -g -D" % (col,row))

tool = ClickTool(iface.mapCanvas())
iface.mapCanvas().setMapTool(tool)

