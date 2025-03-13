# gen_domain notes

```
atmName="ne120np4"
atmGridName="/glade/campaign/cesm/cesmdata/inputdata/share/scripgrids/ne120np4_pentagons_100310.nc"
ocnName="sx0.66av1"
ocnGridName="/glade/u/home/zarzycki/work/CESM_files/grids/esmf/ESMF_mesh_sx0.66av1.nc"
OUTBASE="/glade/work/zarzycki/CESM_files/grids/domains/"
PATH_TO_MAPPING="/glade/work/zarzycki/cesm2_2_1/cime/tools/mapping/"
MACHINE="derecho"

./genUnigridDomains.sh $atmName $atmGridName $ocnName $ocnGridName $OUTBASE $PATH_TO_MAPPING $MACHINE
```

```
./genUnigridDomains.sh \
  SnowEater_WUS_30x8_pg2 \
  /global/homes/c/czarzyck/m2637/E3SM_SCREAM_files/grids/scrip/SnowEater_WUS_30x8_pg2_scrip.nc \
  oRRS18to6v3 \
  /global/cfs/cdirs/e3sm/inputdata/ocn/mpas-o/oRRS18to6v3/ocean.oRRS18to6v3.scrip.181106.nc \
  /global/cfs/cdirs/m2637/E3SM_SCREAM_files/grids/domains/ \
  /global/homes/c/czarzyck/E3SM-20230714/cime/tools/mapping/ \
  NERSC
```

