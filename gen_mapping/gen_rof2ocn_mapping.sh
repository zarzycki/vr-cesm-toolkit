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
ocnName="tx0.1v2"
ocnGridName="/glade/p/cesmdata/cseg/mapping/grids/tx0.1v2_090127.nc"
rofName="r8th"
rofGridName="/glade/p/cesmdata/cseg/inputdata/lnd/clm2/mappingdata/grids/SCRIPgrid_0.125x0.125_cwvrts_nomask_c170206.nc"
wgtFileDir="/glade/scratch/zarzycki/"
#####################################################################################

# do ROF2OCN_FMAPNAME (aave)
interp_method="conserve"   # bilinear, patch, conserve
ncl gen_X_to_Y_wgts.ncl 'srcName="'${rofName}'"' 'srcGridName="'${rofGridName}'"' 'dstName="'${ocnName}'"' 'dstGridName="'${ocnGridName}'"' 'wgtFileDir="'${wgtFileDir}'"' 'InterpMethod="'${interp_method}'"'