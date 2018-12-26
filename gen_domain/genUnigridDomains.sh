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

#atmName will be used in the domain filenames.
#atmGridName is the path to the scrip file of the VR mesh
atmName="ne0np4tcfplane.ne15x8"
atmGridName="/glade/u/home/zarzycki/work/grids/scrip/${atmName}.g_scrip.nc"

# Top level path to CIME mapping tools
# Note: need to have write access to this directory, so either copy the exec
# or checkout and build in your own dir
PATH_TO_MAPPING="/glade/work/zarzycki/cesm2_0_beta08/cime/tools/mapping/"

# =====================================================================
# May need to change these settings, but safe to use t12 for mask for anything >ne30
ocnName="tx0.1v2"
ocnGridName="/glade/p/cesmdata/cseg/mapping/grids/tx0.1v2_090127.nc"
wgtFileDir="."

cdate=`date +%y%m%d`

aaveMap=map_${ocnName}_TO_${atmName}_aave.${cdate}.nc

#----------------------------------------------------------------------
# CREATE MAPPING FILE
#----------------------------------------------------------------------
cd $PATH_TO_MAPPING/gen_domain_files

# do ATM2OCN_FMAPNAME (aave)
interp_method="conserve"   # bilinear, patch, conserve
ESMF_RegridWeightGen --ignore_unmapped -m ${interp_method} -w ${aaveMap} -s ${ocnGridName} -d ${atmGridName}

#----------------------------------------------------------------------
# CREATE DOMAIN FILES
#----------------------------------------------------------------------

set +e
./gen_domain -m ${aaveMap} -o tx01 -l ${atmName}

#----------------------------------------------------------------------
# MOVING FILES + CLEANUP 
#----------------------------------------------------------------------
# Move domain files to OUTBASE dir
mkdir -p ${OUTBASE}/${atmName}/domains
mv domain*${atmName}*${cdate}*nc ${OUTBASE}/${atmName}/domains

# Remove mapping files since they are large and we really only needed aave for domains anyway
rm map_*.nc


