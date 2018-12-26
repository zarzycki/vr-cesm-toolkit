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
lndName="mp120a"
lndGridName="/glade/work/zarzycki/grids/scrip/mp120a_grid_140708.nc"
glcName="gland4km"
glcGridName="/glade/p_old/cesm/cseg/inputdata/glc/cism/griddata/SCRIPgrid_greenland_4km_epsg3413_c170414.nc"
wgtFileDir="/glade/scratch/zarzycki/"
#####################################################################################

# do LND2GLC_FMAPNAME (aave)
interp_method="conserve"   # bilinear, patch, conserve
ncl gen_X_to_Y_wgts.ncl 'srcName="'${lndName}'"' 'srcGridName="'${lndGridName}'"' 'dstName="'${glcName}'"' 'dstGridName="'${glcGridName}'"' 'wgtFileDir="'${wgtFileDir}'"' 'InterpMethod="'${interp_method}'"'

# do LND2GLC_SMAPNAME (blin)
interp_method="bilinear"   # bilinear, patch, conserve
ncl gen_X_to_Y_wgts.ncl 'srcName="'${lndName}'"' 'srcGridName="'${lndGridName}'"' 'dstName="'${glcName}'"' 'dstGridName="'${glcGridName}'"' 'wgtFileDir="'${wgtFileDir}'"' 'InterpMethod="'${interp_method}'"'

# do GLC2LND_FMAPNAME, GLC2LND_SMAPNAME (aave)
interp_method="conserve"   # bilinear, patch, conserve
ncl gen_X_to_Y_wgts.ncl 'srcName="'${glcName}'"' 'srcGridName="'${glcGridName}'"' 'dstName="'${lndName}'"' 'dstGridName="'${lndGridName}'"' 'wgtFileDir="'${wgtFileDir}'"' 'InterpMethod="'${interp_method}'"'
