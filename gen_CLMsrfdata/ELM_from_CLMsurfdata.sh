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
#PBS -q premium
#PBS -j oe
#PBS -l select=4:ncpus=2:mpiprocs=2:mem=109GB
################################################################

set +e

module load ncl

VRSCRIP="/glade/u/home/zarzycki/work/grids/scrip/Guam_ne128x8_lon145W_lat15N_pg2_SCRIP.nc"
VRname="Guam_ne128x8_lon145W_lat15N"
VRshort=${VRname}
CESMROOT="/glade/u/home/zarzycki/work/ELM-filegen/"
OUTBASE="/glade/work/zarzycki/unigridFiles/"
TMPDIRBASE="/glade/scratch/zarzycki/"
ESMFBIN_PATH="/glade/u/apps/ch/opt/esmf/7.0.0-ncdfio-mpi/intel/17.0.1/bin/binO/Linux.intel.64.mpi.default"
CLMVERSION="4_5" # options are 4_0 or 5_0
DO_SP_ONLY=true   # true (only create SP surdats) or false (create full crop surdats)
DO_MAPS=true  # true if we need to gen (or re-gen) maps -- false if we already made them and just want surdat

# For ELM, this may need to be a different spot
CSMDATA=/glade/u/home/zarzycki/scratch/ELM-data/inputdata

# This is where the tools are located...
MKSURFDATADIR=${CESMROOT}/components/clm/tools/mksurfdata_map/
MKMAPDATADIR=${CESMROOT}/components/clm/tools/mkmapdata/

#----------------------------------------------------------------------
# First, we need to generate the mapping files
# This may next up to 12 hours to finish with very refined grids
# NOTE: May need to change {mpitype} in ESMF binary path to mpiuni (mkmapdata.sh)
# probably since we are spawning in serial.
#----------------------------------------------------------------------
cdate=`date +%y%m%d` # Get data in YYMMDD format

# Create TMPDIR
TMPDIR=${TMPDIRBASE}/tmp.elmsurfdata.${VRname}.${cdate}/
mkdir -p ${TMPDIR}

cd ${TMPDIR}

if ($DO_MAPS); then
  regrid_num_proc=8
  time env CSMDATA=${CSMDATA} ESMFBIN_PATH=${ESMFBIN_PATH} REGRID_PROC=$regrid_num_proc ${MKMAPDATADIR}/mkmapdata.sh -b -v --gridfile ${VRSCRIP} --res ${VRname} --gridtype global
fi

# Now make the surface data
if ($DO_SP_ONLY); then
  CROPSTRING=""
else
  CROPSTRING="-crop"
fi
${MKSURFDATADIR}/mksurfdata.pl -years 1850,2000,2010 ${CROPSTRING}                -res usrspec -usr_gname ${VRname} -usr_gdate ${cdate} -usr_mapdir ${TMPDIR} -exedir ${MKSURFDATADIR}
#${MKSURFDATADIR}/mksurfdata.pl -years 1850-2100 ${CROPSTRING} -rcp "2-4.5,5-8.5" -res usrspec -usr_gname ${VRname} -usr_gdate ${cdate} -usr_mapdir ${TMPDIR} -exedir ${MKSURFDATADIR}

# Move the surface datasets
#mkdir -p ${OUTBASE}/${VRname}/clm_surfdata_${CLMVERSION}
#mv landuse*${VRname}*nc surfdata_${VRname}_*.nc ${OUTBASE}/${VRname}/clm_surfdata_${CLMVERSION}

# Delete mapping files
#rm -rf ${TMPDIR}
