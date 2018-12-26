#!/bin/bash
#
# Colin Zarzycki 9/15/2015
#
# Batch script to generate domain files for VR grids.
# OUTBASE: the low-level directory where files will be stored
# VRscripfile: Absolute path to SCRIP descriptor for VR grid
# VRname: Long VR name
# VRshort: Short VR name
#
# NOTES
# Folder will be generated at $OUTBASE/$VRname for storage
# Resultant output will be (1 each) *.lnd.* and *.ocn.* domain files
# Use tx0.1v2 mask unless using an exceptionally low-res grid (per Mariana)
#
##=======================================================================
#PBS -N ncl-maps
#PBS -A P54048000 
#PBS -l walltime=01:00:00
#PBS -q regular
#PBS -k oe
#PBS -m a 
#PBS -M zarzycki@ucar.edu
#PBS -l select=1:ncpus=36
################################################################

#####################################################################################
#atmName="ne0np4conus30x8"
#atmGridName="/glade/p/work/zarzycki/grids/scrip/conus_30_x8.g_scrip.nc"
atmName="mp3a-15a-US"
atmGridName="/glade/p/work/jjang/cesm/inputdata/mp3a-15a-US/mp3a-15a-US.grid.170919.nc"
#ocnName="gx1v6"
#ocnGridName="/glade/p/cesmdata/cseg/mapping/grids/gx1v6_090205.nc"
ocnName="f19"
ocnGridName="/glade/p/cesmdata/cseg/mapping/grids/fv1.9x2.5_141008.nc"
wgtFileDir="/glade/scratch/zarzycki/"
#####################################################################################

# do ATM2LND_FMAPNAME (aave)
interp_method="conserve"   # bilinear, patch, conserve
ncl gen_X_to_Y_wgts.ncl 'srcName="'${atmName}'"' 'srcGridName="'${atmGridName}'"' 'dstName="'${ocnName}'"' 'dstGridName="'${ocnGridName}'"' 'wgtFileDir="'${wgtFileDir}'"' 'InterpMethod="'${interp_method}'"'

# do LND2ATM_FMAPNAME(aave)
interp_method="conserve"   # bilinear, patch, conserve
ncl gen_X_to_Y_wgts.ncl 'srcName="'${ocnName}'"' 'srcGridName="'${ocnGridName}'"' 'dstName="'${atmName}'"' 'dstGridName="'${atmGridName}'"' 'wgtFileDir="'${wgtFileDir}'"' 'InterpMethod="'${interp_method}'"'

# 
#       <map name="ATM2OCN_FMAPNAME">cpl/gridmaps/ne120np4/map_ne120np4_to_gx1v6_aave_110428.nc</map>
#       <map name="ATM2OCN_SMAPNAME">cpl/gridmaps/ne120np4/map_ne120np4_to_gx1v6_bilin_110428.nc</map>
#       <map name="ATM2OCN_VMAPNAME">cpl/gridmaps/ne120np4/map_ne120np4_to_gx1v6_bilin_110428.nc</map>
#       <map name="OCN2ATM_FMAPNAME">cpl/gridmaps/gx1v6/map_gx1v6_to_ne120np4_aave_110428.nc</map>
#       <map name="OCN2ATM_SMAPNAME">cpl/gridmaps/gx1v6/map_gx1v6_to_ne120np4_aave_110428.nc</map>
