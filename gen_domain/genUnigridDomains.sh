#!/bin/bash
#
# Colin Zarzycki
# Created: 9/15/2015
# Last updated: 12/25/2018
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
# If you are getting errors with gen_domain binary, make sure you follow the README
# instructions for building, as the tool now configures mach specific
#

##=======================================================================
#PBS -N gen_domain
#PBS -A P93300642 
#PBS -l walltime=00:29:00
#PBS -q premium
#PBS -j oe
#PBS -M zarzycki@ucar.edu
#PBS -l select=1:ncpus=36
################################################################

# This is the top-level directory where the domain files will be written
OUTBASE="/glade/work/zarzycki/unigridFiles/"
#PATHTONCL="/glade/u/home/zarzycki/shellScripts/vrGridGen/"

atmName="ne0np4tcfplane.ne15x8"
atmGridName="/glade/u/home/zarzycki/work/grids/scrip/${atmName}.g_scrip.nc"

# Need to have write access to this directory, so either copy the exec
# or rebuild 
PATH_TO_MAPPING="/glade/work/zarzycki/cesm2_0_beta08/cime/tools/mapping/"

#----------------------------------------------------------------------
# Set user-defined parameters here
#----------------------------------------------------------------------
cd $PATH_TO_MAPPING/gen_domain_files

ocnName="tx0.1v2"
ocnGridName="/glade/p/cesmdata/cseg/mapping/grids/tx0.1v2_090127.nc"
wgtFileDir="."

cdate=`date +%y%m%d`

aaveMap=map_${ocnName}_TO_${atmName}_aave.${cdate}.nc

# do ATM2OCN_FMAPNAME (aave)
interp_method="conserve"   # bilinear, patch, conserve
#ncl ${PATHTONCL}/gen_X_to_Y_wgts.ncl 'srcName="'${ocnName}'"' 'srcGridName="'${ocnGridName}'"' 'dstName="'${atmName}'"' 'dstGridName="'${atmGridName}'"' 'wgtFileDir="'${wgtFileDir}'"' 'InterpMethod="'${interp_method}'"'
ESMF_RegridWeightGen --ignore_unmapped -m ${interp_method} -w ${aaveMap} -s ${ocnGridName} -d ${atmGridName}

#----------------------------------------------------------------------
# MOVING FILES
#----------------------------------------------------------------------


set +e

#----------------------------------------------------------------------
# MOVING ON TO DOMAIN
#----------------------------------------------------------------------

./gen_domain -m ${aaveMap} -o tx01 -l ${atmName}

# Move domain files to OUTBASE dir
mkdir -p ${OUTBASE}/${atmName}/domains
mv domain*${atmName}*${cdate}*nc ${OUTBASE}/${atmName}/domains

# Remove mapping files since they are large and we really only needed aave for domains anyway
rm map_*.nc


