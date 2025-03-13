#!/bin/bash -l

##=======================================================================
#PBS -N sub_gendomain
#PBS -A P93300642
#PBS -l walltime=00:19:00
#PBS -q premium
#PBS -j oe
#PBS -M zarzycki@ucar.edu
#PBS -l select=1:ncpus=36
################################################################

# If on pm-cpu
#source /global/common/software/e3sm/anaconda_envs/load_latest_e3sm_unified_pm-cpu.sh

echo "$# args passed in!"

if [ "$#" -eq 7 ]; then
  atmName="$1"
  atmGridName="$2"
  ocnName="$3"
  ocnGridName="$4"
  OUTBASE="$5"
  PATH_TO_MAPPING="$6"
  MACHINE="$7"
else
  echo "Using internal values."
  #atmName will be used in the domain filenames.
  atmName="ne128pg2"
  atmGridName="/global/homes/c/czarzyck/m2637/E3SM_SCREAM_files/grids/scrip/ne128pg2_scrip.nc"

  # May need to change these settings, but safe to use t12 for mask for anything >ne30
  #ocnName="tx0.1v2"
  #ocnGridName="/glade/p/cesmdata/cseg/inputdata/share/scripgrids/tx0.1v2_090127.nc"
  #ocnName="gx1v7"
  #ocnGridName="/glade/p/cesmdata/cseg/inputdata/share/scripgrids/gx1v7_151008.nc"
  # This was added for E3SM
  ocnName="oRRS15to5"
  ocnGridName="/global/cfs/cdirs/e3sm/inputdata/ocn/mpas-o/oRRS15to5/ocean.RRS.15-5km_scrip_151209.nc"
  #ocnName="ICOS10"
  #ocnGridName="/global/cfs/cdirs/e3sm/inputdata/ocn/mpas-o/ICOS10/ocean.ICOS10.scrip.211015.nc"

  # This is the top-level directory where the domain files will be written
  OUTBASE="/global/cfs/cdirs/m2637/E3SM_SCREAM_files/grids/domains/"

  #atmGridName is the path to the scrip file of the VR mesh
  # Top level path to CIME mapping tools
  # Note: need to have write access to this directory, so either copy the exec
  # or checkout and build in your own dir
  #PATH_TO_MAPPING="/glade/u/home/zarzycki/work/cesm2_2_0/cime/tools/mapping/"
  PATH_TO_MAPPING="/global/homes/c/czarzyck/E3SM-20230714/cime/tools/mapping/"
  MACHINE=""
fi

# Echoing variables to see what goes into the script
echo "Using atmName: $atmName"
echo "Using atmGridName: $atmGridName"
echo "Using ocnName: $ocnName"
echo "Using ocnGridName: $ocnGridName"
echo "Using OUTBASE: $OUTBASE"
echo "Using PATH_TO_MAPPING: $PATH_TO_MAPPING"
echo "Using MACHINE: $MACHINE"

if [ "$MACHINE" == "NERSC" ]; then
  conda activate e3sm_unified_1.8.1_nompi
fi
if [ "$MACHINE" == "NCAR" ]; then
  module load esmf
fi
which ESMF_RegridWeightGen

wgtFileDir="."

cdate=`date +%y%m%d`

aaveMap=map_${ocnName}_TO_${atmName}_aave.${cdate}.nc

ocnFiles=$(ls "${OUTBASE}/domain.ocn.${atmName}_${ocnName}."*.nc 2> /dev/null)
lndFiles=$(ls "${OUTBASE}/domain.lnd.${atmName}_${ocnName}."*.nc 2> /dev/null)

if [[ -n "$ocnFiles" && -n "$lndFiles" ]]; then
  echo "GEN_DOMAIN: At least one file matching each pattern exists in ${OUTBASE}!"
  echo "GEN_DOMAIN: Exiting."
  exit 0
fi

echo "Making tmp dir and linking"
mkdir -p $SCRATCH/gen_domain_files/
cd $SCRATCH/gen_domain_files/
ls -l $PATH_TO_MAPPING/gen_domain_files/gen_domain
ln -s $PATH_TO_MAPPING/gen_domain_files/gen_domain .
echo "Done!"

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
mv -v domain*${atmName}*${cdate}*nc ${OUTBASE}

# Remove mapping files since they are large and we really only needed aave for domains anyway
rm -fv map_*.nc
rm -fv domain*.nc
rm -fv gen_domain
