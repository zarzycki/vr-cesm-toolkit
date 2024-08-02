#!/bin/bash

#PBS -A P93300642
#PBS -N batch-gen-vr
#PBS -q main
#PBS -j oe
#PBS -l job_priority=premium
#PBS -l walltime=7:59:00
#PBS -l select=1:ncpus=128:mpiprocs=128:ompthreads=1

### This echos the line of the script we are on for debugging
#set -x

if [ -z "$1" ]; then
  echo "Error: No configuration file provided."
  echo "Usage: $0 config_file"
  exit 1
fi

CONFIG_FILE=$1

if [ ! -f "$CONFIG_FILE" ]; then
  echo "Error: Configuration file '$CONFIG_FILE' does not exist."
  exit 1
fi

# Source the specified configuration file
source $CONFIG_FILE

# Get a date string in YYMMDD format
cdate=`date +%y%m%d`

# Check the MACHINE variable and re-execute the script if necessary
# This allows us to run different shebang configurations on the machines
# The SHELL_TYPE check is done to prevent infinite re-execution
if [ "$MACHINE" == "NERSC" ] && [ "$SHELL_TYPE" != "bash" ]; then
  echo "Updating NERSC shell"
  export SHELL_TYPE="bash"
  exec /bin/bash "$0" "$@"
elif [ "$MACHINE" == "NCAR" ] && [ "$SHELL_TYPE" != "bash -l" ]; then
  echo "Updating NCAR shell"
  export SHELL_TYPE="bash -l"
  exec /bin/bash -l "$0" "$@"
fi

# Conditional assignment based on MACHINE
if [ "$MACHINE" = "NERSC" ]; then
  OUTBASE="/global/cfs/cdirs/m2637/E3SM_SCREAM_files/"
  PATH_TO_MAPPING="/global/homes/c/czarzyck/E3SM-20230714/cime/tools/mapping/"
  SCRATCHDIR="/pscratch/sd/c/czarzyck/"
elif [ "$MACHINE" = "NCAR" ]; then
  OUTBASE="/glade/work/zarzycki/CESM_files/"
  PATH_TO_MAPPING="/glade/work/zarzycki/cesm2_2_1/cime/tools/mapping/"
  SCRATCHDIR="/glade/derecho/scratch/zarzycki/"
else
  echo "Unknown machine type: $MACHINE"
  exit 1
fi

if [ "$MACHINE" == "NERSC" ]; then
  conda activate e3sm_unified_1.8.1_nompi
fi
if [ "$MACHINE" == "NCAR" ]; then
  module load esmf
fi

# # Extract the path without the filename
# atmGridPath="${atmGridName%/*}/"
# # Extract the filename
# atmGridFilename="${atmGridName##*/}"

echo "Exodus File: ${EXODUSFILE}"
echo "Atmosphere Name: ${atmName}"
echo "Atmosphere Grid Name: ${atmGridName}"
echo "Atmosphere Refine Level: ${atmRefineLevel}"
echo "Land Name: ${lndName}"
echo "Land Grid Name: ${lndGridName}"
echo "Ocean Name: ${ocnName}"
echo "Ocean Grid Name: ${ocnGridName}"
echo "River Name: ${rofName}"
echo "River Grid Name: ${rofGridName}"
echo "Mask Name: ${maskName}"
echo "Mask Grid Name: ${maskGridName}"
echo "Do E3SM Topo: ${do_e3sm_topo}"
echo "Do CESM Topo: ${do_cesm_topo}"
echo "Generate Maps: ${generate_maps}"
echo "Generate Domain: ${generate_domain}"
echo "Generate Atmosphere Surface: ${generate_atmsrf}"

# Check for necessary binaries
if ! command -v ncl >/dev/null 2>&1; then
  echo "ncl is not in the PATH. Please install/activate it." ; exit 1
fi
if ! command -v ESMF_RegridWeightGen >/dev/null 2>&1; then
  echo "ESMF_RegridWeightGen is not in the PATH. Please install/activate it." ; exit 1
fi
# File checks
if [ ! -f "$atmGridName" ]; then
  echo "Error: File does not exist: $atmGridName" ; exit 1
fi

set -e

mkdir -p $OUTBASE

#---------------------------------------------------------------------------------------------

if [ "$do_e3sm_topo" == true ]; then
  cd e3sm/
  date
  sbatch --wait e3sm-topo.sh \
   $EXODUSFILE \
   $OUTBASE/grids/ \
   $OUTBASE/topo/
  echo $? ; date
  cd ..
elif [ "$do_cesm_topo" == true ]; then
  cd cesm-topo/
  #-W block=true \   # add this to qsub line to cause the script to wait until qsub is done
  qsub \
    -v SCRIPGRIDFILE="$atmGridName",OUTPUTGRIDNAME="$atmName",REFINELEV="$atmRefineLevel",TOPODIR="${OUTBASE}/topo/" \
    cam-topo.sh
  echo $? ; date
  cd ..
fi

#---------------------------------------------------------------------------------------------

if [ "$generate_maps" == true ]; then
  cd gen_mapping/

  date
  (./merged-mapping.sh \
    --atmName "$atmName" \
    --atmGridName "$atmGridName" \
    --lndName "$lndName" \
    --lndGridName "$lndGridName" \
    --ocnName "$ocnName" \
    --ocnGridName "$ocnGridName" \
    --rofName "$rofName" \
    --rofGridName "$rofGridName" \
    --wgtFileDir "${OUTBASE}/grids/maps/" \
  )
  echo $? ; date

#   echo "Cleaning up gen_mapping"
#   mkdir -p ${OUTBASE}/grids/maps/
#   mv -v ${SCRATCHDIR}/tmp.maps.$cdate/map_*.nc ${OUTBASE}/grids/maps/
#   rm -rfv ${SCRATCHDIR}/tmp.maps.$cdate/

  cd ..
fi

#---------------------------------------------------------------------------------------------

if [ "$generate_domain" == true ]; then

  cd gen_domain/

  date
  (./genUnigridDomains.sh \
    $atmName \
    $atmGridName \
    $maskName \
    $maskGridName \
    $OUTBASE/grids/domains \
    $PATH_TO_MAPPING \
    $MACHINE \
  )
  echo $? ; date

  # If the land and atm are different grids, and lndGridName exists do this again
  if [ "$atmGridName" != "$lndGridName" ] && [ -n "$lndGridName" ]; then
    (date
    ./genUnigridDomains.sh \
      $lndName \
      $lndGridName \
      $maskName \
      $maskGridName \
      $OUTBASE/grids/domains \
      $PATH_TO_MAPPING \
      $MACHINE
    echo $? ; date)
  else
    echo "Not doing atm<->land domain"
  fi

  cd ..

fi

#---------------------------------------------------------------------------------------------

if [ "$generate_atmsrf" == true ]; then

  cd gen_atmsrf/

  ATMSRFOUTLOC="${OUTBASE}/atmsrf/"
  mkdir -p "$ATMSRFOUTLOC"
  set +e
  date
  ncl gen_se_mkatmsrf_from_se.ncl \
    'dstName="'${atmName}'"' \
    'dstGridDir="'${atmGridName%/*}/'"' \
    'dstGridFile="'${atmGridName##*/}'"' \
    'atmsrfDir="'${ATMSRFOUTLOC}'"' \
    'wgtFileDir="'${SCRATCHDIR}'"' \
    'MACHINE="'${MACHINE}'"'
  date
  set -e

  cd ..

fi

echo "Done with grid_gen script!"
