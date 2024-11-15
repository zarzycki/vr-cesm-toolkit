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
