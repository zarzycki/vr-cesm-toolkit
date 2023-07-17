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
#PBS -N sub_gendomain
#PBS -A P93300642
#PBS -l walltime=00:19:00
#PBS -q premium
#PBS -j oe
#PBS -M zarzycki@ucar.edu
#PBS -l select=1:ncpus=36
################################################################

# If on Cori
source /global/common/software/e3sm/anaconda_envs/load_latest_e3sm_unified_pm-cpu.sh

# This is the top-level directory where the domain files will be written
OUTBASE="/global/homes/c/czarzyck/grids/domains/"

#atmName will be used in the domain filenames.
#atmGridName is the path to the scrip file of the VR mesh
atmName="Guam_ne128x8_lon145W_lat15N"
atmGridName="/global/homes/c/czarzyck/grids/scrip/Guam_ne128x8_lon145W_lat15N_pg2_SCRIP.nc"

# Top level path to CIME mapping tools
# Note: need to have write access to this directory, so either copy the exec
# or checkout and build in your own dir
#PATH_TO_MAPPING="/glade/u/home/zarzycki/work/cesm2_2_0/cime/tools/mapping/"
PATH_TO_MAPPING="/global/homes/c/czarzyck/E3SM-20230714/cime/tools/mapping/"

# =====================================================================
# May need to change these settings, but safe to use t12 for mask for anything >ne30
#ocnName="tx0.1v2"
#ocnGridName="/glade/p/cesmdata/cseg/inputdata/share/scripgrids/tx0.1v2_090127.nc"
#ocnName="gx1v7"
#ocnGridName="/glade/p/cesmdata/cseg/inputdata/share/scripgrids/gx1v7_151008.nc"
# This was added for E3SM
ocnName="oRRS15to5"
ocnGridName="/global/cfs/cdirs/e3sm/inputdata/ocn/mpas-o/oRRS15to5/ocean.RRS.15-5km_scrip_151209.nc"

wgtFileDir="."

cdate=`date +%y%m%d`

aaveMap=map_${ocnName}_TO_${atmName}_aave.${cdate}.nc

#----------------------------------------------------------------------
# CREATE MAPPING FILE
#----------------------------------------------------------------------
cd $PATH_TO_MAPPING/gen_domain_files

# do ATM2OCN_FMAPNAME (aave)
interp_method="conserve"   # bilinear, patch, conserve
# needs to be gx1v7 or tx01 instead of ocnGridName??
ESMF_RegridWeightGen --ignore_unmapped -m ${interp_method} -w ${aaveMap} -s ${ocnGridName} -d ${atmGridName}

#----------------------------------------------------------------------
# CREATE DOMAIN FILES
#----------------------------------------------------------------------

./gen_domain -m ${aaveMap} -o ${ocnName} -l ${atmName}

#----------------------------------------------------------------------
# MOVING FILES + CLEANUP
#----------------------------------------------------------------------
# Move domain files to OUTBASE dir
mkdir -p ${OUTBASE}
mv domain*${atmName}*${cdate}*nc ${OUTBASE}

# Remove mapping files since they are large and we really only needed aave for domains anyway
rm map_*.nc


