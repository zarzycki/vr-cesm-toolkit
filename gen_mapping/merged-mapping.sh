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

# Init to empty strings
atmName="" atmGridName="" lndName="" lndGridName="" ocnName="" ocnGridName="" rofName="" rofGridName="" glcName="" glcGridName="" wavName="" wavGridName="" wgtFileDir=""
cdate=`date +%y%m%d`
wgtFileDir="/pscratch/sd/c/$LOGNAME/tmp.maps.${cdate}/"
#wgtFileDir="/glade/scratch/$LOGNAME/tmp.maps.${cdate}/"

# Process arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    --atmName)
      atmName="$2"
      shift # past argument
      shift # past value
      ;;
    --atmGridName)
      atmGridName="$2"
      shift # past argument
      shift # past value
      ;;
    --lndName)
      lndName="$2"
      shift # past argument
      shift # past value
      ;;
    --lndGridName)
      lndGridName="$2"
      shift # past argument
      shift # past value
      ;;
    --ocnName)
      ocnName="$2"
      shift # past argument
      shift # past value
      ;;
    --ocnGridName)
      ocnGridName="$2"
      shift # past argument
      shift # past value
      ;;
    --rofName)
      rofName="$2"
      shift # past argument
      shift # past value
      ;;
    --rofGridName)
      rofGridName="$2"
      shift # past argument
      shift # past value
      ;;
    --glcName)
      glcName="$2"
      shift # past argument
      shift # past value
      ;;
    --glcGridName)
      glcGridName="$2"
      shift # past argument
      shift # past value
      ;;
    --wavName)
      wavName="$2"
      shift # past argument
      shift # past value
      ;;
    --wavGridName)
      wavGridName="$2"
      shift # past argument
      shift # past value
      ;;
    --wgtFileDir)
      wgtFileDir="$2"
      shift # past argument
      shift # past value
      ;;
    *)
      shift # past argument
      ;;
  esac
done

mkdir -p $wgtFileDir

echo "Atmosphere Model Name: $atmName"
echo "Atmosphere Grid Name: $atmGridName"
echo "Land Model Name: $lndName"
echo "Land Grid Name: $lndGridName"
echo "Ocean Model Name: $ocnName"
echo "Ocean Grid Name: $ocnGridName"
echo "River Model Name: $rofName"
echo "River Grid Name: $rofGridName"
echo "Glacier Model Name: $glcName"
echo "Glacier Grid Name: $glcGridName"
echo "Wave Model Name: $wavName"
echo "Wave Grid Name: $wavGridName"
echo "wgtFileDir: $wgtFileDir"

############################# ATM <-> LND ########################################

if [ "$atmName" != "$lndName" ] && [ ! -z "$atmName" ] && [ ! -z "$lndName" ]; then
  echo "Generating ATM <-> LND maps..... "

  # do ATM2LND_FMAPNAME (aave)
  interp_method="conserve"   # bilinear, patch, conserve
  ncl gen_X_to_Y_wgts.ncl 'srcName="'${atmName}'"' 'srcGridName="'${atmGridName}'"' 'dstName="'${lndName}'"' 'dstGridName="'${lndGridName}'"' 'wgtFileDir="'${wgtFileDir}'"' 'InterpMethod="'${interp_method}'"'

  # do LND2ATM_FMAPNAME (aave)
  interp_method="conserve"   # bilinear, patch, conserve
  ncl gen_X_to_Y_wgts.ncl 'srcName="'${lndName}'"' 'srcGridName="'${lndGridName}'"' 'dstName="'${atmName}'"' 'dstGridName="'${atmGridName}'"' 'wgtFileDir="'${wgtFileDir}'"' 'InterpMethod="'${interp_method}'"'

  # do ATM2LND_FMAPNAME (patc)
  interp_method="patch"   # bilinear, patch, conserve
  ncl gen_X_to_Y_wgts.ncl 'srcName="'${atmName}'"' 'srcGridName="'${atmGridName}'"' 'dstName="'${lndName}'"' 'dstGridName="'${lndGridName}'"' 'wgtFileDir="'${wgtFileDir}'"' 'InterpMethod="'${interp_method}'"'

  # do LND2ATM_FMAPNAME (patc)
  interp_method="patch"   # bilinear, patch, conserve
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

############################# ROF <-> ATM ########################################

if [ "$atmName" != "$rofName" ] && [ ! -z "$atmName" ] && [ ! -z "$rofName" ]; then
  echo "Generating ATM <-> ROF maps..... "

  # do ATM2ROF_FMAPNAME (aave)
  interp_method="conserve"   # bilinear, patch, conserve
  ncl gen_X_to_Y_wgts.ncl 'srcName="'${atmName}'"' 'srcGridName="'${atmGridName}'"' 'dstName="'${rofName}'"' 'dstGridName="'${rofGridName}'"' 'wgtFileDir="'${wgtFileDir}'"' 'InterpMethod="'${interp_method}'"'

  # do ROF2ATM_FMAPNAME (aave)
  interp_method="conserve"   # bilinear, patch, conserve
  ncl gen_X_to_Y_wgts.ncl 'srcName="'${rofName}'"' 'srcGridName="'${rofGridName}'"' 'dstName="'${atmName}'"' 'dstGridName="'${atmGridName}'"' 'wgtFileDir="'${wgtFileDir}'"' 'InterpMethod="'${interp_method}'"'
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

