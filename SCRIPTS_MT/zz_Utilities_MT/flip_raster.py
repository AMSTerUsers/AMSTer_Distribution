#!/opt/local/bin/python
###############################################################################
# $Id: flip_raster.py
#
# Purpose:  Module to flip a raster dataset on the y axis.
#           Useful for netcdf and surfer grd files with upper y values
#           that are south of the lower y values.
# Original Author:   Frank Warmerdam, warmerdam@pobox.com
# Modified By:       Matthew Perry, perrygeo@gmail.com
# Based on the gdal_merge.py script distributed with GDAL 
#
###############################################################################
# Copyright (c) 2000, Atlantis Scientific Inc. (www.atlsci.com)
# 
# This library is free software; you can redistribute it and/or
# modify it under the terms of the GNU Library General Public
# License as published by the Free Software Foundation; either
# version 2 of the License, or (at your option) any later version.
# 
# This library is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# Library General Public License for more details.
# 
# You should have received a copy of the GNU Library General Public
# License along with this library; if not, write to the
# Free Software Foundation, Inc., 59 Temple Place - Suite 330,
# Boston, MA 02111-1307, USA.
#
# Adapted to python 3.10 by N. d'Oreye on July 7 2022. 
#        Some doubts about lines 48-51 and 281-284. It seems to be OK though.   
#
###############################################################################

from osgeo import gdal
import sys

#  depreciated since 2,7: 
#import Numeric
from numpy import oldnumeric as Numeric

verbose = 0

# =============================================================================
def raster_flip( s_fh, s_xoff, s_yoff, s_xsize, s_ysize, s_band_n,
                 t_fh, t_xoff, t_yoff, t_xsize, t_ysize, t_band_n, nodata ):

#     if verbose != 0:
#          print('Copy %d,%d,%d,%d to %d,%d,%d,%d.' \
#                % (s_xoff, s_yoff, s_xsize, s_ysize, t_xoff, \
#                   t_yoff, t_xsize, t_ysize ))
 
    s_band = s_fh.GetRasterBand( s_band_n )
    t_band = t_fh.GetRasterBand( t_band_n )
 
    # write out the first line from source file as the last line in the dest
    for line in range(s_ysize):
        data_src = s_band.ReadAsArray( s_xoff, line, s_xsize, 1, t_xsize, 1 )
        t_band.WriteArray( data_src, t_xoff, abs(line - t_ysize) -1  )                             
    return 0


# *****************************************************************************
class file_info:
    """A class holding information about a GDAL file."""

    def init_from_name(self, filename):
        """
        Initialize file_info from filename
        filename -- Name of file to read.
        Returns 1 on success or 0 if the file can't be opened.
        """
        fh = gdal.Open( filename )
        if fh is None:
            return 0

        self.filename = filename
        self.bands = fh.RasterCount
        self.xsize = fh.RasterXSize
        self.ysize = fh.RasterYSize
        self.band_type = fh.GetRasterBand(1).DataType
        self.projection = fh.GetProjection()
        self.geotransform = fh.GetGeoTransform()
        self.ulx = self.geotransform[0]
        self.uly = self.geotransform[3]
        self.lrx = self.ulx + self.geotransform[1] * self.xsize
        self.lry = self.uly + self.geotransform[5] * self.ysize

        ct = fh.GetRasterBand(1).GetRasterColorTable()
        if ct is not None:
            self.ct = ct.Clone()
        else:
            self.ct = None

        return 1

    def report( self ):
        print ('Filename: '+ self.filename)
        print ('File Size: %dx%dx%d' \
              % (self.xsize, self.ysize, self.bands))
        print ('Pixel Size: %f x %f' \
              % (self.geotransform[1],self.geotransform[5]))
        print ('UL:(%f,%f)   LR:(%f,%f)' \
              % (self.ulx,self.uly,self.lrx,self.lry))

    def copy_into( self, t_fh, s_band = 1, t_band = 1, nodata_arg=None ):
        """
        Copy this files image into target file.
        This method will compute the overlap area of the file_info objects
        file, and the target gdal.Dataset object, and copy the image data
        for the common window area.  It is assumed that the files are in
        a compatible projection ... no checking or warping is done.  However,
        if the destination file is a different resolution, or different
        image pixel type, the appropriate resampling and conversions will
        be done (using normal GDAL promotion/demotion rules).
        t_fh -- gdal.Dataset object for the file into which some or all
        of this file may be copied.
        Returns 1 on success (or if nothing needs to be copied), and zero one
        failure.
        """
        t_geotransform = t_fh.GetGeoTransform()
        t_ulx = t_geotransform[0]
        t_uly = t_geotransform[3]
        t_lrx = t_geotransform[0] + t_fh.RasterXSize * t_geotransform[1]
        t_lry = t_geotransform[3] + t_fh.RasterYSize * t_geotransform[5]

        # figure out intersection region
        tgw_ulx = max(t_ulx,self.ulx)
        tgw_lrx = min(t_lrx,self.lrx)
        if t_geotransform[5] < 0:
            tgw_uly = min(t_uly,self.uly)
            tgw_lry = max(t_lry,self.lry)
        else:
            tgw_uly = max(t_uly,self.uly)
            tgw_lry = min(t_lry,self.lry)
        
        # do they even intersect?
        if tgw_ulx >= tgw_lrx:
            return 1
        if t_geotransform[5] < 0 and tgw_uly <= tgw_lry:
            return 1
        if t_geotransform[5] > 0 and tgw_uly >= tgw_lry:
            return 1
            
        # compute target window in pixel coordinates.
        tw_xoff = int((tgw_ulx - t_geotransform[0]) / t_geotransform[1] + 0.1)
        tw_yoff = int((tgw_uly - t_geotransform[3]) / t_geotransform[5] + 0.1)
        tw_xsize = int((tgw_lrx - t_geotransform[0])/t_geotransform[1] + 0.5) \
                   - tw_xoff
        tw_ysize = int((tgw_lry - t_geotransform[3])/t_geotransform[5] + 0.5) \
                   - tw_yoff

        if tw_xsize < 1 or tw_ysize < 1:
            return 1

        # Compute source window in pixel coordinates.
        sw_xoff = int((tgw_ulx - self.geotransform[0]) / self.geotransform[1])
        sw_yoff = int((tgw_uly - self.geotransform[3]) / self.geotransform[5])
        sw_xsize = int((tgw_lrx - self.geotransform[0]) \
                       / self.geotransform[1] + 0.5) - sw_xoff
        sw_ysize = int((tgw_lry - self.geotransform[3]) \
                       / self.geotransform[5] + 0.5) - sw_yoff

        if sw_xsize < 1 or sw_ysize < 1:
            return 1

        # Open the source file, and copy the selected region.
        s_fh = gdal.Open( self.filename )

        return \
            raster_flip( s_fh, sw_xoff, sw_yoff, sw_xsize, sw_ysize, s_band,
                         t_fh, tw_xoff, tw_yoff, tw_xsize, tw_ysize, t_band,
                         nodata_arg )


# =============================================================================
def Usage():
    print ('Usage: flip_raster.py [-o out_filename] [-of out_format] [-co NAME=VALUE]*')
    print ('                      [-v] [-pct] [-n nodata_value] [-init value]')
    print ('                      [-ot datatype] [-createonly] input_files')
    print ('                      [--help-general]')
    print ()

# =============================================================================
#
# Program mainline.
#

if __name__ == '__main__':

    names = []
    format = 'GTiff'
    out_file = 'out.tif'

    ulx = None
    psize_x = None
    separate = 0
    copy_pct = 0
    nodata = None
    create_options = []
    pre_init = None
    band_type = None
    createonly = 0

    gdal.AllRegister()
    argv = gdal.GeneralCmdLineProcessor( sys.argv )
    if argv is None:
        sys.exit( 0 )

    # Parse command line arguments.
    i = 1
    while i < len(argv):
        arg = argv[i]

        if arg == '-o':
            i = i + 1
            out_file = argv[i]

        elif arg == '-v':
            verbose = 1

        elif arg == '-createonly':
            createonly = 1

        elif arg == '-pct':
            copy_pct = 1

        elif arg == '-ot':
            i = i + 1
            band_type = gdal.GetDataTypeByName( argv[i] )
            if band_type == gdal.GDT_Unknown:
                print ('Unknown GDAL data type: ', argv[i])
                sys.exit( 1 )

        elif arg == '-init':
            i = i + 1
            pre_init = float(argv[i])

        elif arg == '-n':
            i = i + 1
            nodata = float(argv[i])

        elif arg == '-f':
            # for backward compatibility.
            i = i + 1
            format = argv[i]

        elif arg == '-of':
            i = i + 1
            format = argv[i]

        elif arg == '-co':
            i = i + 1
            create_options.append( argv[i] )

        elif arg[:1] == '-':
            print ('Unrecognised command option: ', arg)
            Usage()
            sys.exit( 1 )

        else:
            names.append( arg )
            
        i = i + 1

    if len(names) == 0:
        print ('No input files selected.')
        Usage()
        sys.exit( 1 )

    if len(names) > 1:
        print ('You can only select one file to flip at a time')
        sys.exit(1)
        
    Driver = gdal.GetDriverByName(format)
    if Driver is None:
        print ('Format driver %s not found, pick a supported driver.' % format)
        sys.exit( 1 )

    DriverMD = Driver.GetMetadata()
# .has_key removed from python 3 - not sure how to handle... NDO june 2022
#     if not DriverMD.has_key('DCAP_CREATE'):
#         print ('Format driver %s does not support creation and piecewise writing.\nPlease select a format that does, such as GTiff (the default) or HFA (Erdas Imagine).' % format)
#         sys.exit( 1 )

    # Collect information on all the source file.
    fi = file_info()
    if fi.init_from_name( names[0] ) != 1:
        print ("can't get file info")
        sys.exit(1)
    
    ulx = fi.ulx
    uly = fi.uly
    lrx = fi.lrx
    lry = fi.lry
    psize_x = fi.geotransform[1]
    psize_y = fi.geotransform[5]

    if band_type is None:
        band_type = fi.band_type

    # Try opening as an existing file.
    gdal.PushErrorHandler( 'CPLQuietErrorHandler' )
    t_fh = gdal.Open( out_file, gdal.GA_ReadOnly )
    gdal.PopErrorHandler()
    
    # Create output file if it does not already exist.
    if t_fh is None:
        geotransform = [ulx, psize_x, 0, uly, 0, psize_y]

        xsize = int((lrx - ulx) / geotransform[1] + 0.5)
        ysize = int((lry - uly) / geotransform[5] + 0.5)

        bands = fi.bands

        t_fh = Driver.Create( out_file, xsize, ysize, bands,
                              band_type, create_options )
        if t_fh is None:
            print ('Creation failed, terminating gdal_merge.')
            sys.exit( 1 )
            
        t_fh.SetGeoTransform( geotransform )
        t_fh.SetProjection( fi.projection )

        if copy_pct:
            t_fh.GetRasterBand(1).SetRasterColorTable(fi.ct)
    else:
         bands = min(fi.bands,t_fh.RasterCount)

    # Do we need to pre-initialize the whole mosaic file to some value?
    if pre_init is not None:
        for i in range(t_fh.RasterCount):
            t_fh.GetRasterBand(i+1).Fill( pre_init )

    if verbose != 0:
        print()
        fi.report()

    for band in range(1, bands+1):
        fi.copy_into( t_fh, band, band, nodata )
            
    # Force file to be closed.
    t_fh = None
