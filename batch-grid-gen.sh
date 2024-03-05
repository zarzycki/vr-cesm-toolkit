#!/bin/bash -l

#INDEX="001"
INDEX=$1

EXODUSFILE="TClandfall-${INDEX}_ne48x4.g"

echo $EXODUSFILE

atmName="TClandfall-${INDEX}_ne48x4_pg2"
atmGridName="/global/homes/c/czarzyck/m2637/E3SM_SCREAM_files/grids/scrip/TClandfall-${INDEX}_ne48x4_pg2_scrip.nc"
lndName="ne128pg2"
lndGridName="/global/homes/c/czarzyck/m2637/E3SM_SCREAM_files/grids/scrip/ne128pg2_scrip.nc"
rofName="r0125"
rofGridName="/global/cfs/cdirs/e3sm/inputdata/lnd/clm2/mappingdata/grids/SCRIPgrid_0.125x0.125_nomask_c170126.nc"

#maskName="oRRS15to5"
#maskGridName="/global/cfs/cdirs/e3sm/inputdata/ocn/mpas-o/oRRS15to5/ocean.RRS.15-5km_scrip_151209.nc"
maskName="ICOS10"
maskGridName="/global/cfs/cdirs/e3sm/inputdata/ocn/mpas-o/ICOS10/ocean.ICOS10.scrip.211015.nc"

OUTBASE="/global/cfs/cdirs/m2637/E3SM_SCREAM_files/"
PATH_TO_MAPPING="/global/homes/c/czarzyck/E3SM-20230714/cime/tools/mapping/"
SCRATCHDIR="/pscratch/sd/c/czarzyck/"

# # Extract the path without the filename
# atmGridPath="${atmGridName%/*}/"
# # Extract the filename
# atmGridFilename="${atmGridName##*/}"

cdate=`date +%y%m%d`

conda activate e3sm_unified_1.8.1_nompi

set -e

#---------------------------------------------------------------------------------------------

cd e3sm/

date
sbatch --wait e3sm-topo.sh \
 $EXODUSFILE \
 $OUTBASE/grids/ \
 $OUTBASE/topo/
echo $? ; date

cd ..

#---------------------------------------------------------------------------------------------

cd gen_mapping/

date
(./merged-mapping.sh \
  --atmName "$atmName" \
  --atmGridName "$atmGridName" \
  --lndName "$lndName" \
  --lndGridName "$lndGridName" \
  --rofName "$rofName" \
  --rofGridName "$rofGridName" \
)
echo $? ; date

echo "Cleaning up gen_mapping"
mv -v ${SCRATCHDIR}/tmp.maps.$cdate/map_*.nc /global/cfs/cdirs/m2637/E3SM_SCREAM_files/grids/maps/
rm -rfv ${SCRATCHDIR}/tmp.maps.$cdate/

cd ..

#---------------------------------------------------------------------------------------------

cd gen_domain/

date
(./genUnigridDomains.sh \
  $atmName \
  $atmGridName \
  $maskName \
  $maskGridName \
  $OUTBASE/grids/domains \
  $PATH_TO_MAPPING \
)
echo $? ; date

# If the land and atm are different grids, do this again
if [ "$atmGridName" != "$lndGridName" ]; then
  (date
  ./genUnigridDomains.sh \
    $lndName \
    $lndGridName \
    $maskName \
    $maskGridName \
    $OUTBASE/grids/domains \
    $PATH_TO_MAPPING
  echo $? ; date)
fi


cd ..

#---------------------------------------------------------------------------------------------

cd gen_atmsrf/

set +e
date
ncl gen_se_mkatmsrf_from_se.ncl \
  'dstName="'${atmName}'"' \
  'dstGridDir="'${atmGridName%/*}/'"' \
  'dstGridFile="'${atmGridName##*/}'"' \
  'atmsrfDir="'${OUTBASE}'/atmsrf/"' \
  'wgtFileDir="'${SCRATCHDIR}'"'
date
set -e

cd ..
