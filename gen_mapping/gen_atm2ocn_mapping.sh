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

#BSUB -P P54048000        # project number
#BSUB -n 32                # number of processors
#BSUB -R "span[ptile=16]" 
#BSUB -W 2:00             # wall-clock limit
#BSUB -q premium            # queue
#BSUB -o regrid.%J.out    # ouput filename
#BSUB -e regrid.%J.err    # error filename
#BSUB -J gen_cesm_maps    # job name
#BSUB -N                  # send email upon job completion


#####################################################################################
#atmName="ne0np4conus30x8"
#atmGridName="/glade/p/work/zarzycki/grids/scrip/conus_30_x8.g_scrip.nc"
atmName="mp15a-120a-US"
atmGridName="/glade/p/work/zarzycki/ASD2017_files/grids/scrip/mp15a-120a-US.grid.170306.nc"
#ocnName="gx1v6"
#ocnGridName="/glade/p/cesmdata/cseg/mapping/grids/gx1v6_090205.nc"
ocnName="tx0.1v2"
ocnGridName="/glade/p/cesmdata/cseg/mapping/grids/tx0.1v2_090127.nc"
wgtFileDir="/glade/scratch/zarzycki/"
#####################################################################################

# do ATM2OCN_FMAPNAME (aave)
interp_method="conserve"   # bilinear, patch, conserve
ncl gen_X_to_Y_wgts.ncl 'srcName="'${atmName}'"' 'srcGridName="'${atmGridName}'"' 'dstName="'${ocnName}'"' 'dstGridName="'${ocnGridName}'"' 'wgtFileDir="'${wgtFileDir}'"' 'InterpMethod="'${interp_method}'"'

# do ATM2OCN_SMAPNAME and ATM2OCN_VMAPNAME (blin)
interp_method="bilinear"   # bilinear, patch, conserve
ncl gen_X_to_Y_wgts.ncl 'srcName="'${atmName}'"' 'srcGridName="'${atmGridName}'"' 'dstName="'${ocnName}'"' 'dstGridName="'${ocnGridName}'"' 'wgtFileDir="'${wgtFileDir}'"' 'InterpMethod="'${interp_method}'"'

# do OCN2ATM_FMAPNAME and OCN2ATM_SMAPNAME (aave)
interp_method="conserve"   # bilinear, patch, conserve
ncl gen_X_to_Y_wgts.ncl 'srcName="'${ocnName}'"' 'srcGridName="'${ocnGridName}'"' 'dstName="'${atmName}'"' 'dstGridName="'${atmGridName}'"' 'wgtFileDir="'${wgtFileDir}'"' 'InterpMethod="'${interp_method}'"'



# 
#       <map name="ATM2OCN_FMAPNAME">cpl/gridmaps/ne120np4/map_ne120np4_to_gx1v6_aave_110428.nc</map>
#       <map name="ATM2OCN_SMAPNAME">cpl/gridmaps/ne120np4/map_ne120np4_to_gx1v6_bilin_110428.nc</map>
#       <map name="ATM2OCN_VMAPNAME">cpl/gridmaps/ne120np4/map_ne120np4_to_gx1v6_bilin_110428.nc</map>
#       <map name="OCN2ATM_FMAPNAME">cpl/gridmaps/gx1v6/map_gx1v6_to_ne120np4_aave_110428.nc</map>
#       <map name="OCN2ATM_SMAPNAME">cpl/gridmaps/gx1v6/map_gx1v6_to_ne120np4_aave_110428.nc</map>
