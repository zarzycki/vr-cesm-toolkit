#!/bin/bash

# CESMROOT = top-level directory from CESM source tree
# ORIGFILE = SE "template" file containing the ncol points on the VR grid
# LEVELFILE = CAM ncdata file containing the vertical coordinate you want to use (any dycore)
# INTERPFILE = CAM ncdata file to interpolate from (FV preferred)
# OUTFILE = CAM ncdata file for use with VR grid
# Notes
# A.) This script requires interpic_new to be build. See below.
#
#

CESMROOT="/glade/u/home/zarzycki/work/cesm-release/"
ORIGFILE=/glade/u/home/zarzycki/work/CAM-SE-tools/Gen_ControlVolumes/DIAG_LATLON_nl.nc
LEVELFILE=/glade/u/home/zarzycki/sewx-cam-forecast/atm_to_cam/L32template.nc
INTERPFILE=/glade/p/cesmdata/inputdata/atm/cam/inic/fv/cami-mam4_0000-01-01_0.9x1.25_L32_c150403.nc
OUTFILE=./VRncdata.nc

INTERPIC=${CESMROOT}/components/cam/tools/interpic_new/interpic
if [ ! -f ${INTERPIC} ]; then
  echo "interpic binary doesn't exist. Either re/build interpic or correct path"
  echo "BINARY: ${INTERPIC}"
  echo "... aborting"
  # To build...
  # $USER> cd ${CESMROOT}/components/cam/tools/interpic_new/
  # $USER> make
  exit
fi

# Strip lat/lon arrays from SE template file
ncks -v lat,lon ${ORIGFILE} SE_template.nc

# Attach vertical coordinates to template file
ncks -A -v hyai,hyam,hybi,hybm ${LEVELFILE} SE_template.nc

# Run interpic to interpolate to SE grid.
${INTERPIC} -t SE_template.nc ${INTERPFILE} ${OUTFILE}

# Rename US and VS (assuming FV inic) to U,V for SE
ncrename -v US,U -v VS,V ${OUTFILE}

# Cleanup unneeded files
rm SE_template.nc
