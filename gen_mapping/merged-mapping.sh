#!/bin/bash

################################################################
#PBS -N ncl-maps
#PBS -A P54048000
#PBS -l walltime=01:00:00
#PBS -q regular
#PBS -k oe
#PBS -m a
#PBS -M zarzycki@ucar.edu
#PBS -l select=1:ncpus=36
################################################################

#export NCARG_ROOT=/global/homes/c/czarzyck/.conda/pkgs/ncl-6.6.2-h3fdc804_41/
#PATHTONCL=/global/homes/c/czarzyck/.conda/envs/e3sm_unified_1.8.1_nompi/bin/

atmName="TClandfall-001_ne32x4_pg2"
atmGridName="~/m2637/E3SM_SCREAM_files/grids/scrip/TClandfall-001_ne32x4_pg2_SCRIP.nc"
#lndName=${atmName}
#lndGridName=${atmGridName}
lndName="ne128pg2"
lndGridName="/global/homes/c/czarzyck/m2637/E3SM_SCREAM_files/grids/scrip/ne128pg2_scrip.nc"
#ocnName="oRRS15to5"
#ocnGridName="/global/cfs/cdirs/e3sm/inputdata/ocn/mpas-o/oRRS15to5/ocean.RRS.15-5km_scrip_151209.nc"
rofName="r0125"
rofGridName="/global/cfs/cdirs/e3sm/inputdata/lnd/clm2/mappingdata/grids/SCRIPgrid_0.125x0.125_nomask_c170126.nc"
#glcName="gland4km"
#glcGridName="/glade/p/cesmdata/inputdata/share/scripgrids/SCRIPgrid_greenland_4km_epsg3413_c170414.nc"
#wavName="ww3a"
#wavGridName="/glade/p/cesmdata/inputdata/share/scripgrids/ww3a_120222.nc"

cdate=`date +%y%m%d`
wgtFileDir="/pscratch/sd/c/$LOGNAME/tmp.maps.${cdate}/"
#wgtFileDir="/glade/scratch/$LOGNAME/tmp.maps.${cdate}/"
mkdir -p $wgtFileDir

############################# ATM <-> LND ########################################

if [ "$atmName" != "$lndName" ] && [ ! -z "$atmName" ] && [ ! -z "$lndName" ]; then
  echo "Generating ATM <-> LND maps..... "

  # do ATM2LND_FMAPNAME (aave)
  interp_method="conserve"   # bilinear, patch, conserve
  ncl gen_X_to_Y_wgts.ncl 'srcName="'${atmName}'"' 'srcGridName="'${atmGridName}'"' 'dstName="'${lndName}'"' 'dstGridName="'${lndGridName}'"' 'wgtFileDir="'${wgtFileDir}'"' 'InterpMethod="'${interp_method}'"'

  # do LND2ATM_FMAPNAME(aave)
  interp_method="conserve"   # bilinear, patch, conserve
  ncl gen_X_to_Y_wgts.ncl 'srcName="'${lndName}'"' 'srcGridName="'${lndGridName}'"' 'dstName="'${atmName}'"' 'dstGridName="'${atmGridName}'"' 'wgtFileDir="'${wgtFileDir}'"' 'InterpMethod="'${interp_method}'"'
fi

############################# ATM <-> OCN ########################################

if [ "$atmName" != "$ocnName" ] && [ ! -z "$atmName" ] && [ ! -z "$ocnName" ]; then
  echo "Generating ATM <-> OCN maps..... "

  # do ATM2OCN_FMAPNAME (aave)
  interp_method="conserve"   # bilinear, patch, conserve
  ncl gen_X_to_Y_wgts.ncl 'srcName="'${atmName}'"' 'srcGridName="'${atmGridName}'"' 'dstName="'${ocnName}'"' 'dstGridName="'${ocnGridName}'"' 'wgtFileDir="'${wgtFileDir}'"' 'InterpMethod="'${interp_method}'"'

  # do ATM2OCN_SMAPNAME and ATM2OCN_VMAPNAME (blin)
  interp_method="bilinear"   # bilinear, patch, conserve
  ncl gen_X_to_Y_wgts.ncl 'srcName="'${atmName}'"' 'srcGridName="'${atmGridName}'"' 'dstName="'${ocnName}'"' 'dstGridName="'${ocnGridName}'"' 'wgtFileDir="'${wgtFileDir}'"' 'InterpMethod="'${interp_method}'"'

  # do OCN2ATM_FMAPNAME and OCN2ATM_SMAPNAME (aave)
  interp_method="conserve"   # bilinear, patch, conserve
  ncl gen_X_to_Y_wgts.ncl 'srcName="'${ocnName}'"' 'srcGridName="'${ocnGridName}'"' 'dstName="'${atmName}'"' 'dstGridName="'${atmGridName}'"' 'wgtFileDir="'${wgtFileDir}'"' 'InterpMethod="'${interp_method}'"'
fi

############################# ROF <-> OCN ########################################

if [ "$ocnName" != "$rofName" ] && [ ! -z "$ocnName" ] && [ ! -z "$rofName" ]; then
  echo "Generating ROF <-> OCN maps..... "

  # do ROF2OCN_FMAPNAME (aave)
  interp_method="conserve"   # bilinear, patch, conserve
  ncl gen_X_to_Y_wgts.ncl 'srcName="'${rofName}'"' 'srcGridName="'${rofGridName}'"' 'dstName="'${ocnName}'"' 'dstGridName="'${ocnGridName}'"' 'wgtFileDir="'${wgtFileDir}'"' 'InterpMethod="'${interp_method}'"'
fi

############################# ROF <-> LND ########################################

if [ "$lndName" != "$rofName" ] && [ ! -z "$lndName" ] && [ ! -z "$rofName" ]; then
  echo "Generating ROF <-> LND maps..... "

  # do LND2ROF_FMAPNAME (aave)
  interp_method="conserve"   # bilinear, patch, conserve
  ncl gen_X_to_Y_wgts.ncl 'srcName="'${lndName}'"' 'srcGridName="'${lndGridName}'"' 'dstName="'${rofName}'"' 'dstGridName="'${rofGridName}'"' 'wgtFileDir="'${wgtFileDir}'"' 'InterpMethod="'${interp_method}'"'

  # do ROF2LND_FMAPNAME (aave)
  interp_method="conserve"   # bilinear, patch, conserve
  ncl gen_X_to_Y_wgts.ncl 'srcName="'${rofName}'"' 'srcGridName="'${rofGridName}'"' 'dstName="'${lndName}'"' 'dstGridName="'${lndGridName}'"' 'wgtFileDir="'${wgtFileDir}'"' 'InterpMethod="'${interp_method}'"'
fi

############################# GLC <-> LND ########################################

if [ "$lndName" != "$glcName" ] && [ ! -z "$lndName" ] && [ ! -z "$glcName" ]; then
  echo "Generating GLC <-> LND maps..... "

  # do LND2GLC_FMAPNAME (aave)
  interp_method="conserve"   # bilinear, patch, conserve
  ncl gen_X_to_Y_wgts.ncl 'srcName="'${lndName}'"' 'srcGridName="'${lndGridName}'"' 'dstName="'${glcName}'"' 'dstGridName="'${glcGridName}'"' 'wgtFileDir="'${wgtFileDir}'"' 'InterpMethod="'${interp_method}'"'

  # do LND2GLC_SMAPNAME (blin)
  interp_method="bilinear"   # bilinear, patch, conserve
  ncl gen_X_to_Y_wgts.ncl 'srcName="'${lndName}'"' 'srcGridName="'${lndGridName}'"' 'dstName="'${glcName}'"' 'dstGridName="'${glcGridName}'"' 'wgtFileDir="'${wgtFileDir}'"' 'InterpMethod="'${interp_method}'"'

  # do GLC2LND_FMAPNAME, GLC2LND_SMAPNAME (aave)
  interp_method="conserve"   # bilinear, patch, conserve
  ncl gen_X_to_Y_wgts.ncl 'srcName="'${glcName}'"' 'srcGridName="'${glcGridName}'"' 'dstName="'${lndName}'"' 'dstGridName="'${lndGridName}'"' 'wgtFileDir="'${wgtFileDir}'"' 'InterpMethod="'${interp_method}'"'
fi

############################# WAV <-> ATM ########################################

if [ "$wavName" != "$atmName" ] && [ ! -z "$wavName" ] && [ ! -z "$atmName" ]; then
  echo "Generating WAV <-> ATM maps..... "

  # do ATM2WAV_SMAPNAME (blin)
  interp_method="bilinear"   # bilinear, patch, conserve
  ncl gen_X_to_Y_wgts.ncl 'srcName="'${atmName}'"' 'srcGridName="'${atmGridName}'"' 'dstName="'${wavName}'"' 'dstGridName="'${wavGridName}'"' 'wgtFileDir="'${wgtFileDir}'"' 'InterpMethod="'${interp_method}'"'

  # do WAV2ATM_SMAPNAME (blin)
  interp_method="bilinear"   # bilinear, patch, conserve
  ncl gen_X_to_Y_wgts.ncl 'srcName="'${wavName}'"' 'srcGridName="'${wavGridName}'"' 'dstName="'${atmName}'"' 'dstGridName="'${atmGridName}'"' 'wgtFileDir="'${wgtFileDir}'"' 'InterpMethod="'${interp_method}'"'
fi

