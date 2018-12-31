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
#PBS -N sub_genfsurdat 
#PBS -A P93300642 
#PBS -l walltime=3:59:00
#PBS -q regular
#PBS -j oe
#PBS -l select=4:ncpus=2:mpiprocs=2:mem=109GB
################################################################

set +e

module load mpt

VRname="ne0np4colorado.ne30x16"
VRshort=${VRname}
CESMROOT="/glade/u/home/zarzycki/scratch/cesm20rel/"
VRSCRIP="/glade/work/zarzycki/grids/scrip/ne0np4colorado.ne30x16.g_scrip.nc"
OUTBASE="/glade/work/zarzycki/unigridFiles/"
TMPDIRBASE="/glade/scratch/zarzycki/"
ESMFBIN_PATH="/glade/u/apps/ch/opt/esmf/7.0.0-ncdfio-mpi/intel/17.0.1/bin/binO/Linux.intel.64.mpi.default"
CLMVERSION="5_0" # options are 4_0 or 5_0
DO_SP_ONLY=true   # true (only create SP surdats) or false (create full crop surdats)

#----------------------------------------------------------------------
# First, we need to generate the mapping files
# This may next up to 12 hours to finish with very refined grids
# NOTE: May need to change {mpitype} in ESMF binary path to mpiuni (mkmapdata.sh)
# probably since we are spawning in serial.
#----------------------------------------------------------------------
cdate=`date +%y%m%d` # Get data in YYMMDD format

# Create TMPDIR
TMPDIR=${TMPDIRBASE}/tmp.clmsurfdata.${cdate}/
mkdir -p ${TMPDIR}

# Use for CESM2.0xx
MKMAPDATADIR=${CESMROOT}/components/clm/tools/mkmapdata/

cd ${TMPDIR}
regrid_num_proc=8
time env ESMFBIN_PATH=${ESMFBIN_PATH} REGRID_PROC=$regrid_num_proc ${MKMAPDATADIR}/mkmapdata.sh -b -v --gridfile ${VRSCRIP} --res ${VRname} --gridtype global

cd ${CESMROOT}/components/clm/tools/mksurfdata_map/

if ($DO_SP_ONLY); then
  CROPSTRING="-no-crop"
else
  CROPSTRING=""
fi
./mksurfdata.pl -years 1850-2000,1850,2000 ${CROPSTRING} -res usrspec -usr_gname ${VRname} -usr_gdate ${cdate} -usr_mapdir ${TMPDIR}

## Move the surface datasets
mkdir -p ${OUTBASE}/${VRname}/clm_surfdata_${CLMVERSION}
mv landuse*${VRname}*nc surfdata_${VRname}_*.nc ${OUTBASE}/${VRname}/clm_surfdata_${CLMVERSION}

# Delete mapping files
rm -rf ${TMPDIR}

