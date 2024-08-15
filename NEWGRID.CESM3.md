# New mesh in CESM3

## Files that need to be generated

- ESMF mesh file
- SCRIP grid (needed for other data generation)
- Exodus mesh file (HOMME/SE only)
- CAM topography file (bnd_topo)
- CAM initial condition file (ncdata)
- CAM dry deposition file (drydep_srf_file)
- CLM surface dataset (fsurdat)

## Files in CESM that need to be edited

- component_grids_nuopc.xml
- modelgrid_aliases_nuopc.xml

Optional:

---


Some notes:

- Currently, I do not believe nuopc supports tri-grid between ocn/land/atm. It works with land and atmosphere on the same grid, which is probably preferable anyway.

## The VR-CESM-toolkit

Colin Zarzycki maintains a hodgepodge of shell scripts and tools for generating new meshes in E3SM and CESM.

Github: https://github.com/zarzycki/vr-cesm-toolkit

Derecho:

```
/glade/u/home/zarzycki/VR-CESM-toolkit
```

The remainder of this document assumes VRTOOLKIT points to the root of this code (probably in your own directory so you have write access). E.g.,

```
export VRTOOLKIT=/glade/u/home/zarzycki/VR-CESM-toolkit
```

I set this in my `.profile` file.

### Generating datasets required

#### ESMF mesh file

NUOPC requires an ESMF mesh file. The easiest way to generate this is from a SCRIP grid file (see below) using ESMF tools. On Derecho:

```
module load conda
conda activate npl

INPUTFILE="/glade/campaign/cesm/cesmdata/inputdata/lnd/clm2/mappingdata/grids/SCRIPgrid_0.125x0.125_nomask_c170126.nc"
OUTPUTFILE="ESMF.nc"
DUALFLAG=0
OUTFORMAT="ESMF"

ESMF_Scrip2Unstruct $INPUTFILE $OUTPUTFILE $DUALFLAG $OUTFORMAT
```

This file is used by NUOPC and can also be used by ESMF to create other offline maps as needed.

#### SCRIP grid

For E3SM/EAM/EAMxx/HOMME, The easiest way to do this is using Paul Ullrich's TempestRemap tool.

```
module load conda
conda activate npl

EXODUS=/glade/work/zarzycki/grids/exodus/ne0np4natlanticref.ne30x4.g
NP=4
PG=2

### GLL nodes (np4)
GenerateVolumetricMesh --in ${EXODUS} --out np${NP}.g --np ${NP}
ConvertMeshToSCRIP --in np${NP}.g --out scrip_np${NP}.nc
rm -v np${NP}.g

### PG cells (uniform NxN)
GenerateVolumetricMesh --in ${EXODUS} --out pg${PG}.g --np ${PG} --uniform
ConvertMeshToSCRIP --in pg${PG}.g --out scrip_np${PG}.nc
rm -v pg${PG}.g
```

For CAM-SE:

```
EXODUSPATH="/glade/work/zarzycki/grids/exodus/"
EXODUSNAME="ne0np4natlanticref.ne30x4.g"

# Go to directory
cd $VRTOOLKIT ; cd generate_SE_GLL_scrip

## Make binary if doesn't exist
[ -f ./Gen_ControlVolumes.exe ] || make

# Inject Exodus file into namelist
sed -i.bak -e "s|^\s*GridPath\s*=.*|  GridPath = '${EXODUSPATH}'|" \
           -e "s|^\s*GridName\s*=.*|  GridName = '${EXODUSNAME}'|" input.nl

# Call program
./Gen_ControlVolumes.exe input.nl
```

For MPAS:

```
cd $VRTOOLKIT ; cd mpas2esmf

[ -f ./mpas2esmf ] || make

MPAS_GRID="/glade/work/zarzycki/grids/mpas/mpasa3-60-tclf001_mesh.nc"
MPAS_NAME="mpasa3-60-tclf001_mesh"

LD_LIBRARY_PATH=$LD_LIBRARY_PATH:${NCAR_LDFLAGS_NETCDF} ./mpas2esmf $MPAS_GRID $MPAS_NAME $(date +"%Y%m%d")
```

#### Topography

Use Peter and Julio's topo tool.

#### Initial condition file (atmosphere)

The easiest way (IMO) is to just generate this with Betacast. You can also use interpic, HICCUP, or other tools.

#### Dry deposition file (drydep_srf_file)

```
  cd gen_atmsrf/

  ATMSRFOUTLOC="${OUTBASE}/atmsrf/"
  mkdir -p "$ATMSRFOUTLOC"
  set +e
  date
  ncl gen_se_mkatmsrf_from_se.ncl \
    'dstName="'${atmName}'"' \
    'dstGridDir="'${atmGridName%/*}/'"' \
    'dstGridFile="'${atmGridName##*/}'"' \
    'atmsrfDir="'${ATMSRFOUTLOC}'"' \
    'wgtFileDir="'${SCRATCHDIR}'"' \
    'MACHINE="'${MACHINE}'"'
  date
  set -e

  cd ..
```

### Editing XML files in CIME

#### component_grids_nuopc.xml

Here, we need to specify the domain name which is the official grid description throughout the model. For unstructured meshes, nx is the equivalent of ncol and ny should be set to 1. Point to the ESMF mesh here.

Add this block:

```
  <domain name="mpasa3tclf001">
    <nx>835586</nx> <ny>1</ny>
    <mesh driver="nuopc">/glade/work/zarzycki/grids/esmf/mpasa3-60-tclf001_esmf.nc</mesh>
    <desc>CMZ - MPAS 3km mesh rotated to LF 001 mesh</desc>
  </domain>
```

#### modelgrid_aliases_nuopc.xml

Here, we define the short name that is used in create_newcase. Technically, I think you can build this manually when invoking create_newcase, but this seems like a safe way of ensuring the grid is set correctly. You should probably always set atm, lnd, ocnice. Other grids will default based on the compset, or you can specify them here (e.g., ROF, GLC, etc.)

Add this block:

```
  <model_grid alias="mpasa3tclf001_mpasa3tclf001" not_compset="_POP">
    <grid name="atm">mpasa3tclf001</grid>
    <grid name="lnd">mpasa3tclf001</grid>
    <grid name="ocnice">mpasa3tclf001</grid>
    <grid name="rof">r8th</grid>
    <mask>tx0.1v2</mask>
  </model_grid>
```

#### CAM namelist options

Note: these can be either set in the case in user_nl_cam or specified in namelist_defaults.xml

```
ncdata='MY_INITIAL_DATAFILE'
bnd_topo='MY_TOPO_FILE'
drydep_srf_file='MY_DRYDEP_FILE'

! For SE
se_mesh_file = 'MY_EXODUS_FILE'

! For MPAS
mpas_block_decomp_file_prefix='PATH/x20.835586.graph.info.part.'
```

#### CLM namelist options

Note: these can be either set in the case in user_nl_clm or specified in namelist_defaults.xml

```
fsurdat='MY_SURFACE_DATA'

! These may not be required, but force CLM to interpolate from a "default" FV file.
use_init_interp = .true.
init_interp_fill_missing_with_natveg = .true.
check_finidat_pct_consistency = .false.
check_finidat_year_consistency = .false.
```


