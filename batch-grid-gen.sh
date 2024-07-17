#!/bin/bash -l

#PBS -A P93300642
#PBS -N batch-gen-vr
#PBS -q main
#PBS -j oe
#PBS -l job_priority=premium
#PBS -l walltime=7:59:00
#PBS -l select=1:ncpus=128:mpiprocs=128:ompthreads=1

### This echos the line of the script we are on for debugging
#set -x
MACHINE="NCAR" # NERSC or NCAR <-- allows for machine-specific settings

## Special logic for E3SM
#INDEX=$1
#EXODUSFILE="TClandfall-${INDEX}_ne48x4.g"
#atmName="TClandfall-${INDEX}_ne48x4_pg2"
#atmGridName="/global/homes/c/czarzyck/m2637/E3SM_SCREAM_files/grids/scrip/TClandfall-${INDEX}_ne48x4_pg2_scrip.nc"
#echo $EXODUSFILE

###### GRIDS
#EXODUSFILE="nhemi_30_x4.g"
INDEX="014"
atmName="mpasa3-60-tclf${INDEX}"
atmGridName="/glade/work/zarzycki/grids/scrip/mpasa3-60-tclf${INDEX}_scrip.nc"
atmRefineLevel=20
#lndName="ne128pg2"
#lndGridName="/global/homes/c/czarzyck/m2637/E3SM_SCREAM_files/grids/scrip/ne128pg2_scrip.nc"
rofName="r8th"
rofGridName="/glade/campaign/cesm/cesmdata/inputdata/lnd/clm2/mappingdata/grids/SCRIPgrid_0.125x0.125_nomask_c170126.nc"

##### MASKS
# E3SM
#maskName="oRRS15to5"
#maskGridName="/global/cfs/cdirs/e3sm/inputdata/ocn/mpas-o/oRRS15to5/ocean.RRS.15-5km_scrip_151209.nc"
#maskName="ICOS10"
#maskGridName="/global/cfs/cdirs/e3sm/inputdata/ocn/mpas-o/ICOS10/ocean.ICOS10.scrip.211015.nc"
# CESM
maskName="tx0.1v2"
maskGridName="/glade/p/cesmdata/cseg/inputdata/share/scripgrids/tx0.1v2_090127.nc"

do_e3sm_topo=false
do_cesm_topo=true
generate_maps=false
generate_domain=true
generate_atmsrf=true
cdate=`date +%y%m%d`

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

echo "Exodus File: ${EXODUSFILE}"
echo "Index: ${INDEX}"
echo "Atmosphere Name: ${atmName}"
echo "Atmosphere Grid Name: ${atmGridName}"
echo "Atmosphere Refine Level: ${atmRefineLevel}"
echo "River Name: ${rofName}"
echo "River Grid Name: ${rofGridName}"
echo "Mask Name: ${maskName}"
echo "Mask Grid Name: ${maskGridName}"
echo "Do E3SM Topo: ${do_e3sm_topo}"
echo "Do CESM Topo: ${do_cesm_topo}"
echo "Generate Maps: ${generate_maps}"
echo "Generate Domain: ${generate_domain}"
echo "Generate Atmosphere Surface: ${generate_atmsrf}"

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
