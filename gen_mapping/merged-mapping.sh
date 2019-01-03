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

atmName="ne0np4colorado.ne30x16"
atmGridName="/glade/u/home/zarzycki/work/grids/scrip/ne0np4colorado.ne30x16.g_scrip.nc"
lndName="ne0np4colorado.ne30x16"
lndGridName="/glade/u/home/zarzycki/work/grids/scrip/ne0np4colorado.ne30x16.g_scrip.nc"
ocnName="ne0np4colorado.ne30x16"
ocnGridName="/glade/u/home/zarzycki/work/grids/scrip/ne0np4colorado.ne30x16.g_scrip.nc"
rofName="r05"
rofGridName="/glade/p/cesmdata/inputdata/lnd/clm2/mappingdata/grids/SCRIPgrid_0.5x0.5_nomask_c110308.nc"
glcName="gland4km"
glcGridName="/glade/p/cesm/cseg/inputdata/glc/cism/griddata/SCRIPgrid_greenland_4km_epsg3413_c170414.nc"
wavName="ww3a"
wavGridName="/glade/p/cesm/cseg/mapping/grids/ww3a_120222.nc"

cdate=`date +%y%m%d`
wgtFileDir="/glade/scratch/zarzycki/tmp.maps.${cdate}/"
mkdir -p $wgtFileDir

############################# ATM <-> LND ########################################

if [ "$atmName" != "$lndName" ]; then
  echo "Generating ATM <-> LND maps..... "
  
  # do ATM2LND_FMAPNAME (aave)
  interp_method="conserve"   # bilinear, patch, conserve
  ncl gen_X_to_Y_wgts.ncl 'srcName="'${atmName}'"' 'srcGridName="'${atmGridName}'"' 'dstName="'${lndName}'"' 'dstGridName="'${lndGridName}'"' 'wgtFileDir="'${wgtFileDir}'"' 'InterpMethod="'${interp_method}'"'
  
  # do LND2ATM_FMAPNAME(aave)
  interp_method="conserve"   # bilinear, patch, conserve
  ncl gen_X_to_Y_wgts.ncl 'srcName="'${lndName}'"' 'srcGridName="'${lndGridName}'"' 'dstName="'${atmName}'"' 'dstGridName="'${atmGridName}'"' 'wgtFileDir="'${wgtFileDir}'"' 'InterpMethod="'${interp_method}'"'
fi

############################# ATM <-> OCN ########################################

if [ "$atmName" != "$ocnName" ]; then
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

if [ "$ocnName" != "$rofName" ]; then
  echo "Generating ROF <-> OCN maps..... "
  
  # do ROF2OCN_FMAPNAME (aave)
  interp_method="conserve"   # bilinear, patch, conserve
  ncl gen_X_to_Y_wgts.ncl 'srcName="'${rofName}'"' 'srcGridName="'${rofGridName}'"' 'dstName="'${ocnName}'"' 'dstGridName="'${ocnGridName}'"' 'wgtFileDir="'${wgtFileDir}'"' 'InterpMethod="'${interp_method}'"'
fi

############################# ROF <-> LND ########################################

if [ "$lndName" != "$rofName" ]; then
  echo "Generating ROF <-> LND maps..... "
  
  # do LND2ROF_FMAPNAME (aave)
  interp_method="conserve"   # bilinear, patch, conserve
  ncl gen_X_to_Y_wgts.ncl 'srcName="'${atmName}'"' 'srcGridName="'${atmGridName}'"' 'dstName="'${rofName}'"' 'dstGridName="'${rofGridName}'"' 'wgtFileDir="'${wgtFileDir}'"' 'InterpMethod="'${interp_method}'"'
  
  # do ROF2LND_FMAPNAME (aave)
  interp_method="conserve"   # bilinear, patch, conserve
  ncl gen_X_to_Y_wgts.ncl 'srcName="'${rofName}'"' 'srcGridName="'${rofGridName}'"' 'dstName="'${atmName}'"' 'dstGridName="'${atmGridName}'"' 'wgtFileDir="'${wgtFileDir}'"' 'InterpMethod="'${interp_method}'"'
fi

############################# GLC <-> LND ########################################

if [ "$lndName" != "$glcName" ]; then
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

if [ "$wavName" != "$atmName" ]; then
  echo "Generating WAV <-> ATM maps..... "
  
  # do ATM2WAV_SMAPNAME (blin)
  interp_method="bilinear"   # bilinear, patch, conserve
  ncl gen_X_to_Y_wgts.ncl 'srcName="'${atmName}'"' 'srcGridName="'${atmGridName}'"' 'dstName="'${wavName}'"' 'dstGridName="'${wavGridName}'"' 'wgtFileDir="'${wgtFileDir}'"' 'InterpMethod="'${interp_method}'"'

  # do WAV2ATM_SMAPNAME (blin)
  interp_method="bilinear"   # bilinear, patch, conserve
  ncl gen_X_to_Y_wgts.ncl 'srcName="'${wavName}'"' 'srcGridName="'${wavGridName}'"' 'dstName="'${atmName}'"' 'dstGridName="'${atmGridName}'"' 'wgtFileDir="'${wgtFileDir}'"' 'InterpMethod="'${interp_method}'"'
fi

