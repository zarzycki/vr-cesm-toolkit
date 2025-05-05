#!/bin/bash
#
# Colin Zarzycki 9/17/2015
#
# This script will generate the CLM fsurdat and transient land use files for 1850/2000 runs
#
# NOTES:
# User needs to have write access to $CESMROOT (files are generated within this substructure
# User needs to have write access to $OUTBASE
# Output files are written to ${OUTBASE}/${VRname}/clm_surfdata_${CLMVERSION}

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
STARTYEAR=1999
ENDYEAR=2001

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

cd $MKSURFDATADIR
echo "Currently working in: $pwd"

# Get NX
NX=$(ncdmnsz elementCount "$VRESMF")
echo "Used NCO to find NX: $NX"

./gen_mksurfdata_namelist --res $VRname --model-mesh $VRESMF --start-year $STARTYEAR --end-year $ENDYEAR --model-mesh-nx $NX --model-mesh-ny 1 --namelist $NAMELIST_FNAME

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

pwd
echo $NAMELIST_FNAME

# Run env_mach_specific.sh to control the machine dependent environment including the paths to compilers and libraries external to cime such as netcdf
. $MKSURFDATADIR/tool_bld/.env_mach_specific.sh
if [ $? != 0 ]; then echo "Error running env_mach_specific script"; exit -4; fi
# Edit the mpirun command to use the MPI executable on your system and the arguments it requires
time mpibind $MKSURFDATADIR/tool_bld/mksurfdata < $NAMELIST_FNAME
if [ $? != 0 ]; then echo "Error running for namelist $NAMELIST_FNAME"; exit -4; fi
echo "Successfully ran resolution!"
