#!/bin/bash

source /global/common/software/e3sm/anaconda_envs/load_latest_e3sm_unified_pm-cpu.sh

atm_grid_file=~/m2637/E3SM_SCREAM_files/grids/scrip/Guam_ne128x8_lon145W_lat15N_pg2_SCRIP.nc
atm_scrip_grid_file=~/m2637/E3SM_SCREAM_files/grids/scrip/Guam_ne128x8_lon145W_lat15N_pg2_SCRIP.nc
ocn_grid_file=/global/cfs/cdirs/e3sm/inputdata/ocn/mpas-o/oRRS15to5/ocean.RRS.15-5km_scrip_151209.nc
lnd_grid_file=${atm_scrip_grid_file}

atm_name=Guam_ne128x8_lon145W_lat15N_pg2
ocn_name=oRRS15to5
lnd_name=${atm_name}

## Conservative, monotone maps.

alg_name=mono

thisdate=$(date "+%y%m%d")

# function run {
#     echo "src $src dst $dst map $map"
#     ncremap -a tempest --src_grd=$src --dst_grd=$dst -m $map \
#         -W '--in_type fv --in_np 1 --out_type fv --out_np 1 --out_format Classic --correct_areas' \
#         $extra
# }

function run {
    echo "src $src dst $dst map $map"
    ncremap -a aave --src_grd=$src --dst_grd=$dst -m $map $extra
}

extra=""

src=$ocn_grid_file
dst=$atm_grid_file
map="map_${ocn_name}_to_${atm_name}_${alg_name}.${thisdate}.nc"
run

exit

src=$atm_grid_file
dst=$ocn_grid_file
map="map_${atm_name}_to_${ocn_name}_${alg_name}.${thisdate}.nc"
extra=--a2o
run
extra=""

src=$lnd_grid_file
dst=$atm_grid_file
map="map_${lnd_name}_to_${atm_name}_${alg_name}.${thisdate}.nc"
run

src=$atm_grid_file
dst=$lnd_grid_file
map="map_${atm_name}_to_${lnd_name}_${alg_name}.${thisdate}.nc"
run

## Nonconservative, monotone maps.

alg_name=bilin

src=$atm_scrip_grid_file
dst=$lnd_grid_file
map="map_${atm_name}_to_${lnd_name}_${alg_name}.${thisdate}.nc"
ncremap -a bilinear -s $src -g $dst -m $map -W '--extrap_method  nearestidavg'

src=$atm_scrip_grid_file
dst=$ocn_grid_file
map="map_${atm_name}_to_${ocn_name}_${alg_name}.${thisdate}.nc"
ncremap -a bilinear -s $src -g $dst -m $map -W '--extrap_method  nearestidavg'