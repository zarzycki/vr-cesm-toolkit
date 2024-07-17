#!/bin/bash

#SBATCH --qos=regular
#SBATCH --time=08:00:00
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --constraint=cpu

date

e3sm_root=/global/homes/c/czarzyck/E3SM-20230714/

source_inic_file=/global/homes/c/czarzyck/inputdata/lnd/clm2/initdata/20221218.F2010-CICE.ne30pg2_ne1024pg2.elm.r.2020-01-20-00000.nc
output_inic_file=/global/homes/c/czarzyck/scratch/e3sm_scratch/pm-cpu/Philly-F2010SCREAMHRDYAMOND2-Philly128x8-101-control/run/Philly-F2010SCREAMHRDYAMOND2-Philly128x8-101-control.elm.r.2020-01-21-00000.nc

cd ${e3sm_root}/components/elm/tools/interpinic
./interpinic -i ${source_inic_file} -o ${output_inic_file}

date
