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
  source /global/common/software/e3sm/anaconda_envs/load_latest_e3sm_unified_pm-cpu.sh
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
echo "Generate np/pg SCRIP: ${generate_np_pg_scrip}"
echo "Do E3SM Topo: ${do_e3sm_topo}"
echo "Do CESM Topo: ${do_cesm_topo}"
echo "Generate Maps: ${generate_maps}"
echo "Generate Domain: ${generate_domain}"
echo "Generate Atmosphere Surface: ${generate_atmsrf}"

# Check for necessary binaries, but only for the stages we are actually running.
# Every stage is now pure python + NCO/ESMF, nothing needs NCL.
if [ "$generate_maps" == true ]; then
  if ! command -v ncremap >/dev/null 2>&1; then
    echo "ncremap is not in the PATH (needed by gen_mapping). Please install/activate NCO." ; exit 1
  fi
  if ! command -v python >/dev/null 2>&1; then
    echo "python is not in the PATH (needed by gen_mapping). Please install/activate it." ; exit 1
  fi
fi
if [ "$generate_domain" == true ] && ! command -v ESMF_RegridWeightGen >/dev/null 2>&1; then
  echo "ESMF_RegridWeightGen is not in the PATH (needed by gen_domain). Please install/activate it." ; exit 1
fi
if [ "$generate_atmsrf" == true ]; then
  if ! command -v ncremap >/dev/null 2>&1; then
    echo "ncremap is not in the PATH (needed by gen_atmsrf). Please install/activate NCO." ; exit 1
  fi
  if ! command -v python >/dev/null 2>&1; then
    echo "python is not in the PATH (needed by gen_atmsrf). Please install/activate it." ; exit 1
  fi
fi
if [ "$generate_np_pg_scrip" == true ]; then
  for binary in GenerateVolumetricMesh ConvertMeshToSCRIP; do
    if ! command -v $binary >/dev/null 2>&1; then
      echo "$binary is not in the PATH (needed by generate_np_pg_scrip). Please install/activate TempestRemap." ; exit 1
    fi
  done
fi
set -e

mkdir -p $OUTBASE

# Spectral element / physics grid resolution. Set here and passed down to e3sm-topo.sh so
# the SCRIP file names generated below and the ones the topo script looks for agree.
SET_NP=4
SET_PG=2

#---------------------------------------------------------------------------------------------

# Only the pg SCRIP grid is built here. The matching np SCRIP still comes out of
# homme_tool inside e3sm/e3sm-topo.sh, since it needs the HOMME build and srun.
if [ "$generate_np_pg_scrip" == true ]; then
  EXODUS_NO_EXT="${EXODUSFILE%.*}"
  EXODUSFILE_PG="$EXODUS_NO_EXT"_pg"$SET_PG".g
  SCRIPFILE_PG="$EXODUS_NO_EXT"_pg"$SET_PG"_scrip.nc
  EXODUSDIR=$OUTBASE/grids/exodus
  SCRIPDIR=$OUTBASE/grids/scrip
  mkdir -p $EXODUSDIR
  mkdir -p $SCRIPDIR
  if [[ ! -f "$SCRIPDIR/$SCRIPFILE_PG" ]]; then
    if [ ! -f "$EXODUSDIR/$EXODUSFILE" ]; then
      echo "Error: exodus file does not exist: $EXODUSDIR/$EXODUSFILE" ; exit 1
    fi
    GenerateVolumetricMesh --in $EXODUSDIR/$EXODUSFILE --out $EXODUSDIR/$EXODUSFILE_PG --np $SET_PG --uniform
    ConvertMeshToSCRIP --in $EXODUSDIR/$EXODUSFILE_PG --out $SCRIPDIR/$SCRIPFILE_PG
  else
    echo "$SCRIPDIR/$SCRIPFILE_PG already exists, skipping SCRIP generation"
  fi
fi

#---------------------------------------------------------------------------------------------

# The atm SCRIP grid is consumed by the mapping, domain, and atmsrf stages, so it has to
# exist by this point (it may have just been created by the block above).
if [ "$generate_maps" == true ] || [ "$generate_domain" == true ] || [ "$generate_atmsrf" == true ]; then
  if [ ! -f "$atmGridName" ]; then
    echo "Error: File does not exist: $atmGridName" ; exit 1
  fi
fi

#---------------------------------------------------------------------------------------------

if [ "$do_e3sm_topo" == true ]; then
  cd e3sm/
  date
  sbatch --wait e3sm-topo.sh \
   $EXODUSFILE \
   $OUTBASE/grids/ \
   $OUTBASE/topo/ \
   $SET_NP \
   $SET_PG
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

  # On NERSC the domain script needs a real allocation, since its weight
  # generation dispatches mbtempest through srun, so submit it with
  # sbatch --wait (same pattern as e3sm-topo.sh above) rather than running it
  # inline on whatever node we happen to be on. Elsewhere (derecho) run it
  # directly, as before.
  run_gen_domain () {
    if [ "$MACHINE" == "NERSC" ]; then
      sbatch --wait genUnigridDomains.sh "$@"
    else
      ./genUnigridDomains.sh "$@"
    fi
  }

  date
  (run_gen_domain \
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
    run_gen_domain \
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
  python gen_se_mkatmsrf_from_se.py \
    --dstName "${atmName}" \
    --dstGridDir "${atmGridName%/*}/" \
    --dstGridFile "${atmGridName##*/}" \
    --atmsrfDir "${ATMSRFOUTLOC}" \
    --wgtFileDir "${SCRATCHDIR}" \
    --MACHINE "${MACHINE}"
  echo $? ; date
  set -e

  cd ..

fi

echo "Done with grid_gen script!"
