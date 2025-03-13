#!/bin/bash -l
##=======================================================================
#PBS -N MPAS
#PBS -A UPSU0032 
#PBS -l walltime=2:59:00
#PBS -q regular
#PBS -j oe
#PBS -l select=1:ncpus=1:mpiprocs=1:mem=109GB
##=======================================================================
./init_atmosphere_model
