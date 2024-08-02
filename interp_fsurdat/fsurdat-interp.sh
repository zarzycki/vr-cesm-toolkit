#!/bin/bash

ORIGFSURDAT=/glade/work/youweima/f09_sx0.66av1/surfdata_BAQUA_CLM5_f09.c191026.nc
REMAPFILE=/glade/work/zarzycki/CESM_files/grids/maps/map_f09_TO_ne120np4.pg3_patc.240802.nc
DOMAINFILE=/glade/work/zarzycki/CESM_files/grids/domains/domain.lnd.ne120np4.pg3_sx0.66av1.240802.nc
OUTFILE=./surfdata_BAQUA_CLM5_ne120pg3.c240802.nc

# Function to get dimension list
function ncvardmnlst {
  ncks --trd -m -v "${1}" "${2}" | grep -E -i "^${1} dimension [0-9]+: " | cut -f 4 -d ' ' | sed 's/,//'
}

# Add a new variable called PCT_OCEAN for CLM5
ncap2 -O -s 'PCT_OCEAN=PFTDATA_MASK+100' ${ORIGFSURDAT} tmp.nc
ncap2 -O -s 'where(PCT_OCEAN > 100) PCT_OCEAN=0; elsewhere PCT_OCEAN=100;' tmp.nc tmp.nc

# Add --rgr col_nm to write gridcell instead of ncol for unstructured meshes, otherwise this does nothing on structured grids (e.g., FV)
ncremap -R "--rgr col_nm=gridcell" -i tmp.nc -o tmp2.nc -m $REMAPFILE
rm -v tmp.nc

# Attach xc,yc coordinates from lnd domain file
ncks -v xc,yc $DOMAINFILE domain_coords.nc
ncks -A domain_coords.nc tmp2.nc
rm -v domain_coords.nc

fix_fractions() {
  local file=$1

  var_to_test="PCT_GLC_MEC"

  # Get dimensions of the file and count
  local dims=$(ncvardmnlst "$var_to_test" "$file")
  local num_dims=$(echo "$dims" | wc -w)

  if [[ $num_dims -eq 3 ]]; then
    echo "Processing structured data (k, lat, lon)..."
    ncap2 -O -s 'PCT_GLC_MEC(:,:,:)=0.0' $file $file
    ncap2 -O -s 'PCT_GLC_MEC(0,:,:)=100.0' $file $file
    ncap2 -O -s 'PCT_NAT_PFT(:,:,:)=0.0' $file $file
    ncap2 -O -s 'PCT_NAT_PFT(0,:,:)=100.0' $file $file
    ncap2 -O -s 'PCT_CFT(:,:,:)=0.0' $file $file
    ncap2 -O -s 'PCT_CFT(0,:,:)=100.0' $file $file
    ncap2 -O -s 'PCT_NATVEG(:,:)=0.0' $file $file
    ncap2 -O -s 'PCT_CROP(:,:)=0.0' $file $file
    ncap2 -O -s 'PCT_GLACIER(:,:)=0.0' $file $file
    ncap2 -O -s 'PCT_WETLAND(:,:)=100.0' $file $file
  elif [[ $num_dims -eq 2 ]]; then
    echo "Processing unstructured data (k, gridcell)..."
    ncap2 -O -s 'PCT_GLC_MEC(:,:)=0.0' $file $file
    ncap2 -O -s 'PCT_GLC_MEC(0,:)=100.0' $file $file
    ncap2 -O -s 'PCT_NAT_PFT(:,:)=0.0' $file $file
    ncap2 -O -s 'PCT_NAT_PFT(0,:)=100.0' $file $file
    ncap2 -O -s 'PCT_CFT(:,:)=0.0' $file $file
    ncap2 -O -s 'PCT_CFT(0,:)=100.0' $file $file
    ncap2 -O -s 'PCT_NATVEG(:)=0.0' $file $file
    ncap2 -O -s 'PCT_CROP(:)=0.0' $file $file
    ncap2 -O -s 'PCT_GLACIER(:)=0.0' $file $file
    ncap2 -O -s 'PCT_WETLAND(:)=100.0' $file $file
  else
    echo "Error: Unknown dimensions ($num_dims dimensions found). Expected 2 or 3 dimensions for $var_to_test."
    exit 1
  fi
}

fix_fractions tmp2.nc

mv -v tmp2.nc $OUTFILE

