#!/bin/bash -l

#SBATCH --qos=regular
#SBATCH --time=06:00:00
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=128
#SBATCH --constraint=cpu

#### Settings

export NCARG_ROOT=/global/homes/c/czarzyck/.conda/pkgs/ncl-6.6.2-h3fdc804_41/
PATHTONCL=/global/homes/c/czarzyck/.conda/envs/e3sm_unified_1.8.1_nompi/bin/

set -e

EXODUSFILE=Philadelphia_TC_grid_v2_ne128x16.g
SET_NP=4
SET_PG=2

GRIDSDIR=/global/homes/c/czarzyck/m2637/E3SM_SCREAM_files/grids/
TOPODIR=/global/homes/c/czarzyck/m2637/E3SM_SCREAM_files/topo/
e3sm_root=/global/homes/c/czarzyck/E3SM-20230714/
machine=perlmutter-nocuda-gnu
INPUTTOPO=/global/cfs/cdirs/e3sm/inputdata/atm/cam/hrtopo/USGS-topo-cube3000.nc
nsmooth=6

#### Namechanging logic

EXODUS_NO_EXT="${EXODUSFILE%.*}"
EXODUSFILE_PG="$EXODUS_NO_EXT"_pg"$SET_PG".g
SCRIPFILE_PG="$EXODUS_NO_EXT"_pg"$SET_PG"_SCRIP.nc
SCRIPFILE_NP="$EXODUS_NO_EXT"_np"$SET_NP"_SCRIP.nc

####

homme_tool_root=${e3sm_root}/components/homme/test/tool
EXODUSDIR=$GRIDSDIR/exodus
SCRIPDIR=$GRIDSDIR/scrip
TEMPLATEDIR=$GRIDSDIR/template
mkdir -p $EXODUSDIR
mkdir -p $SCRIPDIR
mkdir -p $TEMPLATEDIR
mkdir -p $TOPODIR

#####

module purge
module load PrgEnv-gnu/8.3.3
module load gcc/11.2.0
module load craype-accel-host
module load cray-libsci
module load craype
module load cray-mpich/8.1.22
module load cray-hdf5-parallel/1.12.2.1
module load cray-netcdf-hdf5parallel/4.9.0.1
module load cray-parallel-netcdf/1.12.3.1
module load cmake/3.22.0
source /global/common/software/e3sm/anaconda_envs/load_latest_e3sm_unified_pm-cpu.sh

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

eval $( ${e3sm_root}/cime/CIME/Tools/get_case_env )
cd ${homme_tool_root}

#########################################################################################
## Smooth the topography
#########################################################################################

GenerateVolumetricMesh --in $EXODUSDIR/$EXODUSFILE --out $EXODUSDIR/$EXODUSFILE_PG --np $SET_PG --uniform
ConvertMeshToSCRIP --in $EXODUSDIR/$EXODUSFILE_PG --out $SCRIPDIR/$SCRIPFILE_PG

#########################################################################################
## Set env, navigate to env, build if needed
#########################################################################################

# cmake \
#     -C ${homme_tool_root}/../../cmake/machineFiles/${machine}.cmake \
#     -DBUILD_HOMME_WITHOUT_PIOLIBRARY=OFF \
#     -DHOMME_PROJID=m2637 \
#     -DUSE_QUEUING:BOOL=OFF \
#     -DPREQX_PLEV=26 ${homme_tool_root}/../../
#
# make -j4 homme_tool

#########################################################################################
## Create consistent SCRIP for GLL
#########################################################################################

rm -fv input.nl
cat > input.nl <<EOF
&ctl_nl
ne = 0
mesh_file = '${EXODUSDIR}/${EXODUSFILE}'
/
&vert_nl
/

&analysis_nl
tool = 'grid_template_tool'
output_dir = "./"
output_timeunits=1
output_frequency=1
output_varnames1='area','corners','cv_lat','cv_lon'
output_type='netcdf'
!output_type='netcdf4p'  ! needed for ne1024
io_stride = 16
/
EOF

srun -n 8 ./src/tool/homme_tool < input.nl

#~~ Creates ne0np4_tmp1.nc
#~~ Now we convert to SCRIP

mv ne0np4_tmp1.nc ne0np4_tmp.nc
set +e ; ${PATHTONCL}/ncl ncl/HOMME2SCRIP.ncl name=\"ne0np4\" ne=0 np=4 ; set -e
mv -v ne0np4_scrip.nc $SCRIPDIR/$SCRIPFILE_NP
rm -v ne0np4_tmp.nc

#########################################################################################
## Generate topography on GLL grid
#########################################################################################

${e3sm_root}/components/eam/tools/topo_tool/cube_to_target/cube_to_target \
  --target-grid $SCRIPDIR/$SCRIPFILE_NP \
  --input-topography ${INPUTTOPO} \
  --output-topography out.nc

#########################################################################################
## Smooth the GLL topography on PG
#########################################################################################

rm -fv input.nl
cat > input.nl <<EOF
&ctl_nl
ne = 0
mesh_file = '${EXODUSDIR}/${EXODUSFILE}'
smooth_phis_p2filt = 0
smooth_phis_numcycle = $nsmooth
smooth_phis_nudt = 4e-16
hypervis_scaling = 2
se_ftype = 2 ! actually output NPHYS; overloaded use of ftype
/
&vert_nl
/
&analysis_nl
tool = 'topo_pgn_to_smoothed'
infilenames = 'out.nc', '${EXODUS_NO_EXT}np${SET_NP}pg${SET_PG}_smoothed_phis'
/
EOF

srun -n 8 ./src/tool/homme_tool < input.nl

#########################################################################################
## Recompute SGH, etc.
#########################################################################################

${e3sm_root}/components/eam/tools/topo_tool/cube_to_target/cube_to_target \
  --target-grid $SCRIPDIR/$SCRIPFILE_PG \
  --input-topography ${INPUTTOPO} \
  --smoothed-topography ${EXODUS_NO_EXT}np${SET_NP}pg${SET_PG}_smoothed_phis1.nc \
  --output-topography final.nc

#########################################################################################
## Append output
#########################################################################################

ncks -A ${EXODUS_NO_EXT}np${SET_NP}pg${SET_PG}_smoothed_phis1.nc final.nc
mv final.nc $TOPODIR/USGS-gtopo30_${EXODUS_NO_EXT}np${SET_NP}pg${SET_PG}_x${nsmooth}t.nc

#########################################################################################
## Cleanup
#########################################################################################

rm -fv out.nc
rm -fv final.nc
rm -fv ${EXODUS_NO_EXT}np${SET_NP}pg${SET_PG}_smoothed_phis1.nc
rm -fv io_perf_summary_*
rm -rf mass.out

