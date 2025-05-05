#!/bin/bash
#
# Colin Zarzycki 5/2025
#
# This script will generate the CLM fsurdat and transient land use files
# for versions of CESM that use CTSM 5.3.0 and later.
#
#

##=======================================================================
#PBS -A P93300042
#PBS -N sub_genfsurdat
#PBS -q main
#PBS -j oe
#PBS -l job_priority=premium
#PBS -l walltime=7:59:00
#PBS -l select=1:ncpus=128:mpiprocs=128:mem=218GB
################################################################



# Load modules + conda envs
module load peak-memusage
module load conda
conda activate npl
# Load NCO and define functions
module load nco
function ncdmnsz { ncks --trd -m -M ${2} | grep -E -i ": ${1}, size =" | cut -f 7 -d ' ' | uniq ; }

VRESMF="/glade/u/home/zarzycki/work/grids/esmf/ne0np4nhemitc.ne30x4_np4_ESMF.nc"
VRname="ne0np4nhemi30x4"
STARTYEAR=2000
ENDYEAR=2000
DO_SP_ONLY=true   # true (only create SP surdats) or false (create full crop surdats)

CTSMROOT="/glade/work/zarzycki/CTSM-5.3.0/"

#CSMDATA=/glade/campaign/cesm/cesmdata/inputdata
CSMDATA=/glade/derecho/scratch/zarzycki/ELM-data/inputdata

TMPDIRBASE="/glade/derecho/scratch/zarzycki/"

# Derived things or internal controls
VRshort=${VRname}
# This is where the tools are located...
MKSURFDATADIR=${CTSMROOT}/tools/mksurfdata_esmf/
cdate=`date +%y%m%d` # Get data in YYMMDD format
NAMELIST_FNAME="cmz.$VRname.$STARTYEAR.$ENDYEAR.$cdate.nl"

if ($DO_SP_ONLY); then
  CROPSTRING="--nocrop"
else
  CROPSTRING=""
fi

# #NOTE: Everything has to be built first. Here is an example block
#
# git clone https://github.com/ESCOMP/CTSM.git CTSM-5.3.0 && \
# cd CTSM-5.3.0 && \
# git checkout ctsm5.3.0 && \
# ./bin/git-fleximod update && \
# cd tools/mksurfdata_esmf/ && \
# ./gen_mksurfdata_build && \
# echo "Successful build!"

cd $MKSURFDATADIR
echo "Currently working in: $pwd"

# Get NX
NX=$(ncdmnsz elementCount "$VRESMF")
echo "Used NCO to find NX: $NX"

#   -h, --help                  show this help message and exit
#   -v, --verbose               Output extra logging info
#   --silent                    Only output errors
#   --debug                     Output even more logging info for debugging
#   --start-year START_YEAR     Simulation start year. [Required]
#   --end-year END_YEAR         Simulation end year. [Required]
#   --res RES                   Model resolution (required) To see available supported resolutions, simply invoke this command with a --res unknown option. For custom resolutions, provide a grid name of your choosing to be used in the name of the fsurdat file.
#   --model-mesh FORCE_MODEL_MESH_FILE     model mesh [default: None] Ignore --res and use --model-mesh to be this file
#   --namelist NAMELIST_FNAME              name of output namelist filename if NOT given the name will be the same as the surface dataset name with a *.namelist extension rather than *.nc
#   --model-mesh-nx FORCE_MODEL_MESH_NX    model mesh [default: None] Required when using --model-mesh: set nx to the grid's number of columns; expect nx x ny = elementCount for consistency with the model mesh
#   --model-mesh-ny FORCE_MODEL_MESH_NY    model mesh [default: None] Required when using --model-mesh: set ny to the grid's number of rows; expect nx x ny = elementCount for consistency with the model mesh
#   --glc-nec GLC_NEC         Number of glacier elevation classes to use. [default: 10]
#   --ssp-rcp {SSP1-2.6,SSP3-7.0,SSP5-3.4,SSP2-4.5,SSP1-1.9,SSP4-3.4,SSP4-6.0,SSP5-8.5,none}       Shared Socioeconomic Pathway and Representative Concentration Pathway Scenario name(s). [default: none]
#   --rawdata-dir INPUT_PATH    /path/of/root/of/input/data on izumi use /fs/cgd/csm/inputdata [default: /glade/campaign/cesm/cesmdata/inputdata/]
#   --inlandwet                 Flag for including inland wetlands. [default: False]
#   --glc                       Flag for adding the optional 3D glacier fields for verification of the glacier model. [default: False]
#   --hires_soitex              If you want to use the high-resolution soil texture dataset rather than the default lower resolution dataset. (Low resolution is 5x5min, high resolution 30-second) [default: False]
#   --nosurfdata                Do not output a surface datase This is useful if you only want a landuse_timeseries file [default: False]
#   --nocrop                    Do not create datasets with the extensive list of prognostic crop types. [default: False]
#   --potveg_flag               Use Potential Vegetation for pft_years [default: False]

./gen_mksurfdata_namelist --res $VRname --model-mesh $VRESMF --start-year $STARTYEAR --end-year $ENDYEAR --model-mesh-nx $NX --model-mesh-ny 1 --namelist $NAMELIST_FNAME $CROPSTRING

echo "Finished with namelist stuff, moving on to actually generating files!"

### Here is stuff to handle temporary directory stuff
TMPDIR=${TMPDIRBASE}/tmp.clmsurfdata.${VRname}.${cdate}/
mkdir -p "$TMPDIR"

# Update fsurdat, fsurlog, and fdyndat paths in the namelist by appending TMPDIR
# Need to escape slashes for sed first
ESCAPED_TMPDIR=$(printf '%s\n' "$TMPDIR" | sed 's:/:\\/:g')
sed -i -E "s|(fsurdat *= *)'(.*)'|\1'${ESCAPED_TMPDIR}/\2'|" "$NAMELIST_FNAME"
sed -i -E "s|(fsurlog *= *)'(.*)'|\1'${ESCAPED_TMPDIR}/\2'|" "$NAMELIST_FNAME"
sed -i -E "s|(fdyndat *= *)'(.*)'|\1'${ESCAPED_TMPDIR}/\2'|" "$NAMELIST_FNAME"

echo "We are in: $PWD"
echo "The namelist is: $NAMELIST_FNAME"

# Run env_mach_specific.sh to control the machine dependent environment including the paths to compilers and libraries external to cime such as netcdf
. $MKSURFDATADIR/tool_bld/.env_mach_specific.sh
if [ $? != 0 ]; then echo "Error running env_mach_specific script"; exit -4; fi
# Edit the mpirun command to use the MPI executable on your system and the arguments it requires
time mpibind $MKSURFDATADIR/tool_bld/mksurfdata < $NAMELIST_FNAME
if [ $? != 0 ]; then echo "Error running for namelist $NAMELIST_FNAME"; exit -4; fi
echo "Successfully ran script!"