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
#PBS -N CLM.gensurdat
#PBS -N mpi_job
#PBS -A P93300642 
#PBS -l walltime=3:59:00
#PBS -q regular
#PBS -j oe
#PBS -l select=4:ncpus=2:mpiprocs=2:mem=109GB
################################################################

set +e

module load mpt

VRname="ne0np4conus30x8"
VRshort=${VRname}
CESMROOT="/glade/scratch/zarzycki/clm-build/cesm-rel/"
#CESMROOT="/glade/u/home/zarzycki/scratch/cesm2_0_beta08/"
#CESMROOT="/glade/scratch/zarzycki/clm-build/mksrfunreplu_n04_clm4_5_14_r215/"
#VRSCRIP="/glade/cesmdata/cseg/mapping/grids/ne16np4_110512_pentagons.nc"
#VRSCRIP="/glade/work/zarzycki/grids/scrip/${VRname}.g_scrip.nc"
VRSCRIP="/glade/work/zarzycki/grids/scrip/conus_30_x8.g_scrip.nc"
#VRSCRIP="/glade/u/home/zarzycki/work/ASD2017_files/grids/scrip/mp120a_grid_140708.nc"
#VRSCRIP="/glade/u/home/zarzycki/work/ASD2017_files/grids/scrip/mp15a-120a-US.grid.170118.nc"
OUTBASE="/glade/work/zarzycki/unigridFiles/"

CLMVERSION="5_0" # options are 4_0 or 4_5

#----------------------------------------------------------------------
# First, we need to generate the mapping files
# This may next up to 12 hours to finish with very refined grids
# NOTE: May need to change {mpitype} in ESMF binary path to mpiuni (mkmapdata.sh)
# probably since we are spawning in serial.
#----------------------------------------------------------------------
cdate=`date +%y%m%d` # Get data in YYMMDD format

# Use for CESM1.2.2
#MKMAPDATADIR=${CESMROOT}/models/lnd/clm/tools/shared/mkmapdata
# Use for CESM1.5.XX
#MKMAPDATADIR=${CESMROOT}/components/clm/tools/shared/mkmapdata
# Use for CESM2.0xx
MKMAPDATADIR=${CESMROOT}/components/clm/tools/mkmapdata/

cd ${MKMAPDATADIR}

ESMFBIN_PATH="/glade/u/apps/ch/opt/esmf/7.0.0-ncdfio-mpi/intel/17.0.1/bin/binO/Linux.intel.64.mpi.default"
regrid_num_proc=8
#./mkmapdata.sh -b -v --phys clm${CLMVERSION} --gridfile ${VRSCRIP} --res ${VRname} --gridtype global
time env ESMFBIN_PATH=${ESMFBIN_PATH} REGRID_PROC=$regrid_num_proc ./mkmapdata.sh -b -v --gridfile ${VRSCRIP} --res ${VRname} --gridtype global

#cd ../../clm${CLMVERSION}/mksurfdata_map
cd ${CESMROOT}/components/clm/tools/mksurfdata_map/

#./mksurfdata.pl -y 1850-2100,1850,2000 -rcp 8.5 -res usrspec -usr_gname ${VRname} -usr_gdate ${cdate}
#./mksurfdata.pl -y 1850-2000,1850,2000 -res usrspec -usr_gname ${VRname} -usr_gdate ${cdate}
#./mksurfdata.pl           -y 1850,2000 -res usrspec -usr_gname ${VRname} -usr_gdate ${cdate}
##./mksurfdata.pl -y 1850-2000,1850,2000 -no-crop -res usrspec -usr_gname ${VRname} -usr_gdate ${cdate} #-usr_mapdir $CSMDATA/lnd/clm2/mappingdata/maps/mp120a/

#### CLM5, SP
./mksurfdata.pl -y 1850-2000,1850,2000 -no-crop -res usrspec -usr_gname ${VRname} -usr_gdate ${cdate} #-usr_mapdir $CSMDATA/lnd/clm2/mappingdata/maps/mp120a/
#### CLM5, BGC
#./mksurfdata.pl -years 1850-2000,1850,2000 -res usrspec -usr_gname ${VRname} -usr_gdate ${cdate} #-usr_mapdir $CSMDATA/lnd/clm2/mappingdata/maps/mp120a/

## Move the surface datasets

mkdir -p ${OUTBASE}/${VRname}/clm_surfdata_${CLMVERSION}
mv landuse*${VRname}*nc surfdata_${VRname}_*.nc ${OUTBASE}/${VRname}/clm_surfdata_${CLMVERSION}

# Delete mapping files
#cd ${MKMAPDATADIR}
#rm *.nc

