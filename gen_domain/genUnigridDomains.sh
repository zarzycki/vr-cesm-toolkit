#!/bin/bash -l

# The SLURM header is what matters when this is submitted with sbatch on
# pm-cpu. A real allocation is required for the MOAB/mbtempest weight
# generation below, which launches via srun.
#SBATCH -C cpu
#SBATCH -A m2637
#SBATCH --qos=premium
#SBATCH --time=02:00:00
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=128

###=======================================================================
##PBS -N sub_gendomain
##PBS -A P93300642
##PBS -l walltime=00:19:00
##PBS -q premium
##PBS -j oe
##PBS -M zarzycki@ucar.edu
##PBS -l select=1:ncpus=36
#################################################################

echo "Command used: $0 \"$@\""
echo "PID       : $$"
echo "Host      : $(hostname)"
echo "User      : $(whoami)"
echo "Start time: $(date -u +"%Y-%m-%d %H:%M:%S UTC")"
echo "Shell     : $SHELL"

# Stopwatches. The two expensive stages (weight generation and the python
# domain generator) are timed separately so the log says where the wallclock
# actually went. SECONDS is a bash builtin counting since shell startup.
SCRIPT_T0=${SECONDS}
hms () { printf "%02d:%02d:%02d (%d s)" $(($1/3600)) $((($1%3600)/60)) $(($1%60)) "$1" ; }

# If on pm-cpu
#source /global/common/software/e3sm/anaconda_envs/load_latest_e3sm_unified_pm-cpu.sh

# Path to this script, needed to find generate_domain_files_E3SM.py after we cd
SCRIPTPATH="$( cd -- "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 ; pwd -P )"
# Under sbatch the batch script runs from a SLURM spool copy, so BASH_SOURCE
# points at /var/spool/... instead of the repo. Fall back to the submit dir.
if [ ! -f "${SCRIPTPATH}/generate_domain_files_E3SM.py" ] && [ -n "${SLURM_SUBMIT_DIR}" ]; then
  SCRIPTPATH="${SLURM_SUBMIT_DIR}"
fi
echo "Using SCRIPTPATH: $SCRIPTPATH"

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
  # NOTE: no longer used, we now use the E3SM python gen_domain in this repo,
  # but retained so the calling interface is unchanged
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
  source /global/common/software/e3sm/anaconda_envs/load_latest_e3sm_unified_pm-cpu.sh
fi
if [ "$MACHINE" == "NCAR" ]; then
  module load esmf
fi
which ncremap
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

echo "Making tmp dir"
mkdir -p $SCRATCH/gen_domain_files/
cd $SCRATCH/gen_domain_files/
echo "Done!"

# do ATM2OCN_FMAPNAME (aave)
# generate_domain_files_E3SM.py recommends a conservative, monotone (traave)
# map, so build it with ncremap. Set map_alg to esmfaave to get ESMF's
# conservative remap (what the legacy gen_domain workflow used) via ncremap.
map_alg="traave"           # traave, esmfaave, tempest
interp_method="conserve"   # bilinear, patch, conserve (ESMF fallback only)
# needs to be gx1v7 or tx01 instead of ocnGridName??

#----------------------------------------------------------------------
# PARALLEL WEIGHT GENERATION
#----------------------------------------------------------------------
# Serial TempestRemap is the bottleneck of this script: the overlap-mesh
# computation scales non-linearly with grid size, so a high-res ocean (e.g.
# oRRS15to5) crossed with a high-res atm (e.g. ne128pg2) takes hours.
# Handing ncremap --mpi_nbr makes it dispatch the *same* TempestRemap
# algorithm to the MPI-parallel MOAB toolchain (mbconvert/mbpart/mbtempest)
# instead, which turns that into minutes. traave (== fv2fv_flx) is the one
# algorithm MOAB is considered trustworthy for, which is what we want here.
#
# Two requirements: mbtempest has to be in PATH (e3sm-unified has it, a
# bare NCO conda env does not), and we have to be inside a batch allocation,
# because ncremap prefixes mbtempest with `srun -n ${MPI_NBR}` on Perlmutter
# and `mpirun -n ${MPI_NBR}` on derecho. Set MPI_NBR=0 to force serial.
if [ -z "${MPI_NBR}" ]; then
  if [ -n "${SLURM_JOB_ID}" ]; then
    MPI_NBR=${SLURM_NTASKS:-${SLURM_CPUS_ON_NODE:-64}}
  elif [ -n "${PBS_NODEFILE}" ]; then
    MPI_NBR=$(wc -l < "${PBS_NODEFILE}")
  else
    MPI_NBR=0   # login node / interactive shell, no MPI launcher available
  fi
  # More than ~64 partitions buys little and costs mbpart time
  [ "${MPI_NBR}" -gt 64 ] && MPI_NBR=64
fi

ncremap_opts=(--no_stdin -5 -a ${map_alg} --grd_src=${ocnGridName} --grd_dst=${atmGridName} --map_fl=${aaveMap})
use_moab=false
if [ "${MPI_NBR}" -gt 1 ] && [[ "${map_alg}" != esmf* ]] && command -v mbtempest > /dev/null 2>&1 ; then
  use_moab=true
  ncremap_opts+=(--mpi_nbr=${MPI_NBR})
  # mbconvert cannot read a netCDF4/HDF5 grid file in parallel. --mbt_grd_nc4
  # tells ncremap to read the grids serially instead of erroring out.
  for grd in "${ocnGridName}" "${atmGridName}" ; do
    if ncdump -k "${grd}" 2> /dev/null | grep -q "netCDF-4" ; then
      ncremap_opts+=(--mbt_grd_nc4)
      break
    fi
  done
  echo "GEN_DOMAIN: using MOAB/mbtempest with ${MPI_NBR} MPI tasks"
else
  echo "GEN_DOMAIN: using serial TempestRemap (MPI_NBR=${MPI_NBR})"
fi

map_t0=${SECONDS}
map_gen="none"
echo "GEN_DOMAIN TIMING: weight generation started $(date -u +"%Y-%m-%d %H:%M:%S UTC")"

if command -v ncremap > /dev/null 2>&1 ; then
  [ "${use_moab}" == true ] && map_gen="ncremap/MOAB(${MPI_NBR} tasks)" || map_gen="ncremap/TempestRemap(serial)"
  ncremap "${ncremap_opts[@]}"
  # MOAB support varies by NCO/MOAB version, so retry in serial rather than
  # dropping all the way through to the ESMF fallback below
  if [ ! -f "${aaveMap}" ] && [ "${use_moab}" == true ]; then
    echo "GEN_DOMAIN: MOAB did not produce ${aaveMap}, retrying with serial TempestRemap"
    echo "GEN_DOMAIN TIMING: MOAB attempt burned $(hms $((SECONDS - map_t0))) before falling back"
    map_gen="ncremap/TempestRemap(serial, after MOAB retry)"
    ncremap --no_stdin -5 -a ${map_alg} --grd_src=${ocnGridName} --grd_dst=${atmGridName} --map_fl=${aaveMap}
  fi
else
  echo "GEN_DOMAIN: ncremap not found in PATH"
fi

# Fall back to ESMF_RegridWeightGen if ncremap is missing or did not make a map
if [ ! -f "${aaveMap}" ]; then
  echo "GEN_DOMAIN: falling back to ESMF_RegridWeightGen for ${aaveMap}"
  map_gen="ESMF_RegridWeightGen(${interp_method})"
  ESMF_RegridWeightGen --ignore_unmapped -m ${interp_method} -w ${aaveMap} -s ${ocnGridName} -d ${atmGridName}
fi

t_map=$((SECONDS - map_t0))

if [ ! -f "${aaveMap}" ]; then
  echo "GEN_DOMAIN: could not create ${aaveMap}"
  echo "GEN_DOMAIN TIMING: weight generation failed after $(hms ${t_map})"
  echo "GEN_DOMAIN: Exiting."
  exit 1
fi

echo "GEN_DOMAIN TIMING: mapping file (${map_gen}) took $(hms ${t_map})"
echo "GEN_DOMAIN TIMING: mapping file size $(du -h ${aaveMap} | cut -f1)"

#----------------------------------------------------------------------
# CREATE DOMAIN FILES
#----------------------------------------------------------------------
# Python replacement for the legacy CIME gen_domain binary. --date-stamp is
# passed so filenames keep the YYMMDD stamp gen_domain used (python defaults
# to YYYYMMDD), which the mv below relies on.

dom_t0=${SECONDS}
echo "GEN_DOMAIN TIMING: generate_domain_files_E3SM.py started $(date -u +"%Y-%m-%d %H:%M:%S UTC")"

python ${SCRIPTPATH}/generate_domain_files_E3SM.py -m ${aaveMap} -o ${ocnName} -l ${atmName} --date-stamp ${cdate}
dom_rc=$?

t_dom=$((SECONDS - dom_t0))
echo "GEN_DOMAIN TIMING: generate_domain_files_E3SM.py took $(hms ${t_dom}) (exit ${dom_rc})"

#----------------------------------------------------------------------
# MOVING FILES + CLEANUP
#----------------------------------------------------------------------
# Move domain files to OUTBASE dir
mkdir -p ${OUTBASE}
mv -v domain*${atmName}*${cdate}*nc ${OUTBASE}

# Remove mapping files since they are large and we really only needed aave for domains anyway
rm -fv map_*.nc
rm -fv domain*.nc

#----------------------------------------------------------------------
# TIMING SUMMARY
#----------------------------------------------------------------------
t_tot=$((SECONDS - SCRIPT_T0))
echo "===================================================================="
echo "GEN_DOMAIN TIMING SUMMARY for ${atmName} <-> ${ocnName}"
printf "  %-34s %s\n" "mapping file (${map_gen})" "$(hms ${t_map})"
printf "  %-34s %s\n" "generate_domain_files_E3SM.py" "$(hms ${t_dom})"
printf "  %-34s %s\n" "other (setup, env, moves, cleanup)" "$(hms $((t_tot - t_map - t_dom)))"
printf "  %-34s %s\n" "TOTAL" "$(hms ${t_tot})"
echo "End time: $(date -u +"%Y-%m-%d %H:%M:%S UTC")"
echo "===================================================================="
