# Generating ELM data on Cheyenne via CESM2.2

First, get the target version of E3SM

```
E3SMBASEDIR=~/scratch/my-E3SM/
cd ~/scratch/
git clone --recursive https://github.com/E3SM-Project/E3SM.git my-E3SM
```

Then we have to get CESM2.2 and call it ELM-filgen...

```
CESMBASEDIR=~/work/ELM-filegen/
cd ~/work/
git clone https://github.com/escomp/cesm.git ELM-filegen
cd ${CESMBASEDIR}
git checkout cesm2.2.0
./manage_externals/checkout_externals 
```

Now we have to "inject" the grids in mkmapdata

```
cd ${CESMBASEDIR}/components/clm/tools/mkmapdata/
sed -i 's/clmexp/elmexp/g' mkmapdata.sh
## edit mkmapdata.sh **SEE BELOW**
## vi ${E3SMBASEDIR}/components/elm/tools/mkmapdata/mkmapdata.sh
## vi mkmapdata.sh
```

Now we have to just straight up copy mksurfdata_map...

```
cd ${CESMBASEDIR}/components/clm/tools/
rm -rf mksurfdata_map/
cp -rf ${E3SMBASEDIR}/components/elm/tools/mksurfdata_map/ .
cd mksurfdata_map/src
gmake
cd ..
sed -i 's?.*my $CSMDATA.*?my $CSMDATA = "/glade/u/home/zarzycki/scratch/ELM-data/inputdata";?g' mksurfdata.pl
```

Now we have to merge namelist files...

```
cd ${CESMBASEDIR}/components/clm/bld/namelist_files/

## First, copy some things over
cp -v ${E3SMBASEDIR}/components/elm/bld/namelist_files/namelist_definition.xml .
cp -v ${E3SMBASEDIR}/components/elm/bld/namelist_files/namelist_defaults.xml .
cp -v ${E3SMBASEDIR}/components/elm/bld/namelist_files/namelist_defaults_tools.xml .

## --> May not need? cp -v ${E3SMBASEDIR}/components/elm/bld/namelist_files/namelist_definition_drv.xml .


## Create copies of these so we don't have to change naming conventions
cp -v namelist_defaults_tools.xml namelist_defaults_ctsm_tools.xml
cp -v namelist_definition.xml namelist_definition_ctsm.xml
## --> May not need? cp -v namelist_defaults.xml namelist_defaults_ctsm.xml
```

Now we can run our code

```
cd ~/VR-CESM-toolkit/gen_CLMsrfdata
qsub ELM_from_CLMsurfdata.sh 
```


 
 ### Grid injection
 
 `mkmapdata.sh` needs to contain information about the ELM input data grids, not CLM. The stupidest way to do this is overwrite this block (i.e., delete the grids var and copy in ELM grids var) in CLM from the ELM tree...
 
 ```
 if [ "$phys" = "clm4_5" ]; then

  grids=(                                     \
      "0.5x0.5_AVHRR"                         \
      "0.5x0.5_MODIS"                         \
      "3x3min_LandScan2004"                   \
      "3x3min_MODIS"                          \
      "3x3min_USGS"                           \
      "5x5min_nomask"                         \
      "5x5min_IGBP-GSDP"                      \
      "5x5min_ISRIC-WISE"                     \
      "10x10min_nomask"                       \
      "10x10min_IGBPmergeICESatGIS"           \
      "3x3min_GLOBE-Gardner"                  \
      "3x3min_GLOBE-Gardner-mergeGIS"         \
      "0.9x1.25_GRDC"                         \
      "360x720cru_cruncep"                    \
      "1km-merge-10min_HYDRO1K-merge-nomask"  \
      "0.5x0.5_GSDTG2000"                     \
    )

else
    echo "ERROR: Unknown value for phys: $phys"
    exit 1
fi
```
 
