#!/bin/bash

################################################################
#PBS -N gen-maps
#PBS -A P54048000
#PBS -l walltime=01:00:00
#PBS -q regular
#PBS -k oe
#PBS -m a
#PBS -M zarzycki@ucar.edu
#PBS -l select=1:ncpus=36
################################################################


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

# Running log, appended as each map finishes, so a job that dies partway
# through (PBS walltime, node failure) still leaves a record on disk
statusLog="${wgtFileDir}/map-gen-status.${cdate}.log"
echo "# map generation started `date`" >> "$statusLog"

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

# Every map we attempt gets recorded here so we can print a summary at the end
mapFiles=()
mapStatus=()

run_map() {
  local srcName="$1" srcGrid="$2" dstName="$3" dstGrid="$4" method="$5"
  local pattern="${wgtFileDir}/map_${srcName}_TO_${dstName}_${method}*.nc"
  local pre post rc mapFile status

  # gen_X_to_Y_wgts.py is a no-op if a matching map is already sitting there,
  # so look before as well as after to tell "made it" from "found it"
  pre=$(ls -1 $pattern 2>/dev/null | head -n 1)

  (set -x; python gen_X_to_Y_wgts.py 'srcName="'${srcName}'"' 'srcGridName="'${srcGrid}'"' 'dstName="'${dstName}'"' 'dstGridName="'${dstGrid}'"' 'wgtFileDir="'${wgtFileDir}'"' 'InterpMethod="'${method}'"' )
  rc=$?

  post=$(ls -1 $pattern 2>/dev/null | head -n 1)

  if [ ! -z "$pre" ]; then
    mapFile="$pre"
    status="EXISTED"
  elif [ $rc -ne 0 ]; then
    mapFile="${post:-${wgtFileDir}/map_${srcName}_TO_${dstName}_${method}.${cdate}.nc}"
    status="FAILED (rc=$rc)"
  elif [ -z "$post" ]; then
    mapFile="${wgtFileDir}/map_${srcName}_TO_${dstName}_${method}.${cdate}.nc"
    status="FAILED (no file)"
  else
    mapFile="$post"
    status="SUCCESS"
  fi

  mapFiles+=("$mapFile")
  mapStatus+=("$status")

  printf "%-18s %s\n" "$status" "$mapFile" >> "$statusLog"
}

# -a alg_typ  Algorithm for weight generation (default ncoaave) [alg_typ, algorithm, regrid_algorithm]
#             CDO algorithms: cdo_bilinear|cdo_conservative (same as ESMF)
#             ESMF algorithms: esmfbilin,bilinear|esmfaave,aave,conserve|conserve2nd|nearestdtos|neareststod|patch
#             NCO algorithms: ncoaave,nco,nco_con|ncoidw,nco_dwe (inverse-distance-weighted interpolation/extrapolation)
#             Tempest (and MOAB-Tempest) algorithms: traave,fv2fv_flx|trbilin|trfv2|trintbilin|tempest|fv2fv|fv2fv_stt|fv2se_flx|fv2se_stt|fv2se_alt|se2fv_flx|se2fv_stt|se2fv_alt|se2se

############################# ATM <-> LND ########################################

if [ "$atmName" != "$lndName" ] && [ ! -z "$atmName" ] && [ ! -z "$lndName" ]; then
  echo "Generating ATM <-> LND maps..... "

  # do ATM2LND_FMAPNAME (aave)
  interp_method="traave"   # bilinear, patch, conserve
  run_map "${atmName}" "${atmGridName}" "${lndName}" "${lndGridName}" "${interp_method}"

  # do LND2ATM_FMAPNAME (aave)
  interp_method="traave"   # bilinear, patch, conserve
  run_map "${lndName}" "${lndGridName}" "${atmName}" "${atmGridName}" "${interp_method}"

  # do ATM2LND_FMAPNAME (patc)
  interp_method="trintbilin"   # bilinear, patch, conserve
  run_map "${atmName}" "${atmGridName}" "${lndName}" "${lndGridName}" "${interp_method}"

  # do LND2ATM_FMAPNAME (patc)
  interp_method="trintbilin"   # bilinear, patch, conserve
  run_map "${lndName}" "${lndGridName}" "${atmName}" "${atmGridName}" "${interp_method}"
fi

############################# ATM <-> OCN ########################################

if [ "$atmName" != "$ocnName" ] && [ ! -z "$atmName" ] && [ ! -z "$ocnName" ]; then
  echo "Generating ATM <-> OCN maps..... "

  # do ATM2OCN_FMAPNAME (aave)
  interp_method="traave"   # bilinear, patch, conserve
  run_map "${atmName}" "${atmGridName}" "${ocnName}" "${ocnGridName}" "${interp_method}"

  # do ATM2OCN_SMAPNAME and ATM2OCN_VMAPNAME (blin)
  interp_method="trintbilin"   # bilinear, patch, conserve
  run_map "${atmName}" "${atmGridName}" "${ocnName}" "${ocnGridName}" "${interp_method}"

  # do OCN2ATM_FMAPNAME and OCN2ATM_SMAPNAME (aave)
  interp_method="traave"   # bilinear, patch, conserve
  run_map "${ocnName}" "${ocnGridName}" "${atmName}" "${atmGridName}" "${interp_method}"
fi

############################# ROF <-> OCN ########################################

if [ "$ocnName" != "$rofName" ] && [ ! -z "$ocnName" ] && [ ! -z "$rofName" ]; then
  echo "Generating ROF <-> OCN maps..... "

  # do ROF2OCN_FMAPNAME (aave)
  interp_method="traave"   # bilinear, patch, conserve
  run_map "${rofName}" "${rofGridName}" "${ocnName}" "${ocnGridName}" "${interp_method}"
fi

############################# ROF <-> ATM ########################################

if [ "$atmName" != "$rofName" ] && [ ! -z "$atmName" ] && [ ! -z "$rofName" ]; then
  echo "Generating ATM <-> ROF maps..... "

  # do ATM2ROF_FMAPNAME (aave)
  interp_method="traave"   # bilinear, patch, conserve
  run_map "${atmName}" "${atmGridName}" "${rofName}" "${rofGridName}" "${interp_method}"

  # do ROF2ATM_FMAPNAME (aave)
  interp_method="traave"   # bilinear, patch, conserve
  run_map "${rofName}" "${rofGridName}" "${atmName}" "${atmGridName}" "${interp_method}"
fi

############################# ROF <-> LND ########################################

if [ "$lndName" != "$rofName" ] && [ ! -z "$lndName" ] && [ ! -z "$rofName" ]; then
  echo "Generating ROF <-> LND maps..... "

  # do LND2ROF_FMAPNAME (aave)
  interp_method="traave"   # bilinear, patch, conserve
  run_map "${lndName}" "${lndGridName}" "${rofName}" "${rofGridName}" "${interp_method}"

  # do ROF2LND_FMAPNAME (aave)
  interp_method="traave"   # bilinear, patch, conserve
  run_map "${rofName}" "${rofGridName}" "${lndName}" "${lndGridName}" "${interp_method}"
fi

############################# GLC <-> LND ########################################

if [ "$lndName" != "$glcName" ] && [ ! -z "$lndName" ] && [ ! -z "$glcName" ]; then
  echo "Generating GLC <-> LND maps..... "

  # do LND2GLC_FMAPNAME (aave)
  interp_method="traave"   # bilinear, patch, conserve
  run_map "${lndName}" "${lndGridName}" "${glcName}" "${glcGridName}" "${interp_method}"

  # do LND2GLC_SMAPNAME (blin)
  interp_method="trintbilin"   # bilinear, patch, conserve
  run_map "${lndName}" "${lndGridName}" "${glcName}" "${glcGridName}" "${interp_method}"

  # do GLC2LND_FMAPNAME, GLC2LND_SMAPNAME (aave)
  interp_method="traave"   # bilinear, patch, conserve
  run_map "${glcName}" "${glcGridName}" "${lndName}" "${lndGridName}" "${interp_method}"
fi

############################# WAV <-> ATM ########################################

if [ "$wavName" != "$atmName" ] && [ ! -z "$wavName" ] && [ ! -z "$atmName" ]; then
  echo "Generating WAV <-> ATM maps..... "

  # do ATM2WAV_SMAPNAME (blin)
  interp_method="trintbilin"   # bilinear, patch, conserve
  run_map "${atmName}" "${atmGridName}" "${wavName}" "${wavGridName}" "${interp_method}"

  # do WAV2ATM_SMAPNAME (blin)
  interp_method="trintbilin"   # bilinear, patch, conserve
  run_map "${wavName}" "${wavGridName}" "${atmName}" "${atmGridName}" "${interp_method}"
fi


############################# SUMMARY ###########################################

echo ""
echo "################################################################"
echo "Map generation summary  (wgtFileDir: $wgtFileDir)"
echo "################################################################"

nFail=0
for ii in "${!mapStatus[@]}"; do
  case "${mapStatus[$ii]}" in
    FAILED*) nFail=$((nFail+1)) ;;
  esac
done

if [ ${#mapFiles[@]} -eq 0 ]; then
  echo "No maps were requested."
else
  # the per-map lines are already in statusLog, written as each one finished,
  # so only the tally gets appended here
  for ii in "${!mapFiles[@]}"; do
    printf "%-18s %s\n" "${mapStatus[$ii]}" "${mapFiles[$ii]}"
  done
fi

{
echo "----------------------------------------------------------------"
echo "${#mapFiles[@]} maps attempted, $nFail failed"
echo "# map generation finished `date`"
} | tee -a "$statusLog"

echo "Status log: $statusLog"

if [ $nFail -ne 0 ]; then
  exit 1
fi
exit 0
