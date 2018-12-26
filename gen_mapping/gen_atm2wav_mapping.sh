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
atmName="ne0conus30x8"
atmGridName="/glade/p/work/zarzycki/ASD2017_files/grids/scrip/SCRIPgrid_conus_30_x8_nomask_c170111.nc"
wavName="ww3a"
wavGridName="/glade/p/cesm/cseg/mapping/grids/ww3a_120222.nc"
wgtFileDir="/glade/scratch/zarzycki/"
#####################################################################################

# do ATM2WAV_SMAPNAME (blin)
interp_method="bilinear"   # bilinear, patch, conserve
ncl gen_X_to_Y_wgts.ncl 'srcName="'${atmName}'"' 'srcGridName="'${atmGridName}'"' 'dstName="'${wavName}'"' 'dstGridName="'${wavGridName}'"' 'wgtFileDir="'${wgtFileDir}'"' 'InterpMethod="'${interp_method}'"'