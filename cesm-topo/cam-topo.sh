#!/bin/bash -l

#PBS -A P93300642
#PBS -N cam-topo-gen
#PBS -q main
#PBS -j oe
#PBS -l job_priority=premium
#PBS -l walltime=7:59:00
#PBS -l select=1:ncpus=128:mpiprocs=128:ompthreads=1

echo $SCRIPGRIDFILE
echo $OUTPUTGRIDNAME
echo $REFINELEV
echo $TOPODIR

cd /glade/u/home/zarzycki/work/cam_tools/NCAR-topo/cube_to_target
./cube_to_target \
  --grid_descriptor_file "$SCRIPGRIDFILE" \
  --intermediate_cs_name /glade/campaign/cgd/amp/pel/topo/cubedata/gmted2010_modis_bedmachine-ncube3000-220518.nc \
  --output_grid "$OUTPUTGRIDNAME" \
  --smoothing_scale 100.0 \
  --rrfac_max "$REFINELEV" \
  --name_email_of_creator 'Colin Zarzycki, cmz5202@psu.edu'

mv -v ./output/${OUTPUTGRIDNAME}_gmted2010*.nc $TOPODIR

echo "Done with topo generation!"
