#!/usr/bin/env python3
"""
gen_se_mkatmsrf_from_se.py

Generate a CAM/EAM atmsrf file (fraction_landuse, soilw) on an arbitrary SE/pg2
target grid by remapping an existing high-resolution atmsrf file.

Python port of gen_se_mkatmsrf_from_se.ncl. Weights are generated with NCO
(ncremap) instead of ESMF_regrid_gen_weights, and are applied here as a sparse
matrix multiply so that the output file contains exactly the two variables CAM
expects:

  netcdf atmsrf_ne120np4_110920 {
  dimensions:
      ncol = 777602 ;
      class = 11 ;
      month = 12 ;
  variables:
      double fraction_landuse(class, ncol) ;
      double soilw(month, ncol) ;
  }
"""

import argparse
import glob
import os
import shutil
import subprocess
import sys
import time

import numpy as np
from netCDF4 import Dataset
from scipy.sparse import csr_matrix

PREFIX = os.path.basename(__file__) + ": "

# Source (high-res) atmsrf file + its SCRIP grid, per machine
MACHINE_SETTINGS = {
    "NCAR": {
        "infile": "/glade/p/cesmdata/inputdata/atm/cam/chem/trop_mam/atmsrf_ne120np4_181018.nc",
        "srcName": "ne120np4",
        "srcGridDir": "/glade/p/cesmdata/inputdata/share/scripgrids/",
        "srcGridFile": "ne120np4_pentagons_100310.nc",
    },
#     "NERSC": {
#         "infile": "/global/homes/c/czarzyck/inputdata/atm/cam/chem/trop_mam/atmsrf_ne512pg2_200212.nc",
#         "srcName": "ne512pg2",
#         "srcGridDir": "/global/homes/c/czarzyck/mapping-e3sm/grids/",
#         "srcGridFile": "ne512pg2_scrip_20221011.nc",
#     },
    "NERSC": {
        "infile": "/global/cfs/cdirs/ccsm1/inputdata/atm/cam/chem/trop_mam/atmsrf_ne240np4_110920.nc",
        "srcName": "ne240np4",
        "srcGridDir": "/global/homes/c/czarzyck/mapping-e3sm/grids/",
        "srcGridFile": "ne240np4_091227_pentagons.nc",
    },
}

# ncremap algorithm -> map file name tag
INTERP_STRINGS = {"patch": "patc", "ncoaave": "aave", "ncoidw": "idw", "trbilin": "blin", "esmfbilin": "blin", "esmfaave": "aave"}

# Destination cells with frac_b below this are considered unmapped
FRAC_B_TOL = 1.0e-6

# soilw outside this range is unphysical and gets interpolated from the good
# months. The lower bound is loose because clean months carry O(1e-17) negative
# roundoff, while a corrupt month runs to O(-1e4).
SOILW_MIN = -0.0001
SOILW_MAX = 0.45

#----------------------------------------------------------------------
# Settings (can be modified by user if not passed in)
#----------------------------------------------------------------------

parser = argparse.ArgumentParser(description=__doc__,
                                 formatter_class=argparse.RawDescriptionHelpFormatter)
parser.add_argument("--dstName", default="TClandfall-001_ne32x4_pg2",
                    help="short name of target grid, used in output file names")
parser.add_argument("--dstGridDir", default="/global/homes/c/czarzyck/m2637/E3SM_SCREAM_files/grids/scrip/",
                    help="directory holding the target SCRIP grid file")
parser.add_argument("--dstGridFile", default="TClandfall-001_ne32x4_pg2_SCRIP.nc",
                    help="target SCRIP grid file name")
parser.add_argument("--atmsrfDir", default="/global/homes/c/czarzyck/m2637/E3SM_SCREAM_files/atmsrf/",
                    help="output directory for the atmsrf file")
parser.add_argument("--wgtFileDir", default="/pscratch/sd/c/czarzyck/",
                    help="scratch directory for the intermediate map file")
parser.add_argument("--MACHINE", default="NERSC", choices=sorted(MACHINE_SETTINGS),
                    help="selects the source atmsrf file and its SCRIP grid")
parser.add_argument("--interp_method", default="trbilin", choices=sorted(INTERP_STRINGS),
                    help="ncremap weight-generation algorithm")
parser.add_argument("--keep_weights", action="store_true",
                    help="do not delete the map file when finished")
parser.add_argument("--force", action="store_true",
                    help="regenerate even if an atmsrf file for dstName already exists")
args = parser.parse_args()

machine = MACHINE_SETTINGS[args.MACHINE]
infile = machine["infile"]
srcName = machine["srcName"]

cdate = time.strftime("%y%m%d")
srcGridName = os.path.join(machine["srcGridDir"], machine["srcGridFile"])
dstGridName = os.path.join(args.dstGridDir, args.dstGridFile)
wgtFileName = os.path.join(args.wgtFileDir, f"map_{srcName}_TO_{args.dstName}_"
                                            f"{INTERP_STRINGS[args.interp_method]}.{cdate}.nc")
OUTNAME = os.path.join(args.atmsrfDir, f"atmsrf_{args.dstName}_{cdate}.nc")

for key, val in [("dstName", args.dstName), ("dstGridDir", args.dstGridDir),
                 ("dstGridFile", args.dstGridFile), ("atmsrfDir", args.atmsrfDir),
                 ("wgtFileDir", args.wgtFileDir), ("MACHINE", args.MACHINE),
                 ("infile", infile), ("srcName", srcName),
                 ("srcGridName", srcGridName), ("wgtFileName", wgtFileName)]:
    print(f"{PREFIX}{key}: {val}", flush=True)

OUTNAME_ALL = sorted(glob.glob(os.path.join(args.atmsrfDir, f"atmsrf_{args.dstName}_*.nc")))
if OUTNAME_ALL and not args.force:
    sys.exit(f"{PREFIX}OUTNAME {OUTNAME_ALL[0]} already exists!")

if shutil.which("ncremap") is None:
    sys.exit(f"{PREFIX}ncremap is not in the PATH. Please install/activate NCO.")
for path in (infile, srcGridName, dstGridName):
    if not os.path.isfile(path):
        sys.exit(f"{PREFIX}file does not exist: {path}")
os.makedirs(args.atmsrfDir, exist_ok=True)
os.makedirs(args.wgtFileDir, exist_ok=True)

wcStrt = time.time()
print(f"{PREFIX}{time.ctime()}", flush=True)

#----------------------------------------------------------------------
# Now generate weights file
#----------------------------------------------------------------------

cmd = ["ncremap", "-a", args.interp_method, "--vrb_lvl=9",
       "--src_grd=" + srcGridName, "--dst_grd=" + dstGridName, "--map_file=" + wgtFileName]
print(f"{PREFIX}generating weights: {' '.join(cmd)}", flush=True)
subprocess.run(cmd, check=True)

with Dataset(wgtFileName, "r") as fmap:
    fmap.set_auto_mask(False)
    n_a = len(fmap.dimensions["n_a"])
    n_b = len(fmap.dimensions["n_b"])
    row = fmap.variables["row"][:].astype(np.int64) - 1   # SCRIP maps are 1-based
    col = fmap.variables["col"][:].astype(np.int64) - 1
    S = fmap.variables["S"][:].astype(np.float64)
    frac_b = fmap.variables["frac_b"][:].astype(np.float64)

print(f"{PREFIX}map file has n_a: {n_a}  n_b: {n_b}  n_s: {S.size}", flush=True)
wgts = csr_matrix((S, (row, col)), shape=(n_b, n_a))
del row, col, S

n_unmapped = int(np.count_nonzero(frac_b <= FRAC_B_TOL))
if n_unmapped:
    sys.exit(f"{PREFIX}{n_unmapped} destination columns are unmapped (frac_b ~ 0). Exiting.")

# ==========================================================================================

regridded = {}
with Dataset(infile, "r") as fin:
    fin.set_auto_mask(False)
    if len(fin.dimensions["ncol"]) != n_a:
        sys.exit(f"{PREFIX}infile ncol ({len(fin.dimensions['ncol'])}) does not match "
                 f"map file n_a ({n_a}). Exiting.")

    for varName in ("fraction_landuse", "soilw"):
        data = fin.variables[varName][:].astype(np.float64)
        # apply weights, then renormalize by the mapped fraction as ESMF does
        out = (wgts @ data.T).T
        out /= np.where(frac_b > FRAC_B_TOL, frac_b, 1.0)
        del data

        if not np.all(np.isfinite(out)):
            sys.exit(f"{PREFIX}{varName} contains non-finite values. Exiting.")
        print(f"{PREFIX}{varName}: min: {out.min():.6f}  max: {out.max():.6f}", flush=True)
        regridded[varName] = out

# fraction_landuse is a partition, so the classes must still sum to one
class_sum_err = np.abs(regridded["fraction_landuse"].sum(axis=0) - 1.0).max()
print(f"{PREFIX}max |sum(fraction_landuse) - 1|: {class_sum_err:.3e}", flush=True)

# rebuild any unphysical soilw by interpolating in time from good months. Bad months are
# masked out first, so a run of consecutive bad months is spanned rather than
# averaged from a neighbor that is itself bad.
soilw = regridded["soilw"]
nmonth = soilw.shape[0]
months = np.arange(nmonth)  # integer month array
bad = (soilw < SOILW_MIN) | (soilw > SOILW_MAX)

# If there are ANY bad columns...
if bad.any():
    print(f"{PREFIX}Uh oh, we found some questionable soil columns...")
    # Diagnostic: loop over months that have at least one bad value and print
    for month in np.flatnonzero(bad.any(axis=1)):
        print(f"{PREFIX}soilw month {month}: patching {bad[month].sum()} unphysical columns "
              f"(outside [{SOILW_MIN}, {SOILW_MAX}])", flush=True)
    # Edge case, where for the entire timeseries every data at a pixel is garbage
    if bad.all(axis=0).any():
        sys.exit(f"{PREFIX}{bad.all(axis=0).sum()} soilw columns are unphysical in every "
                 f"month, so there is nothing to interpolate from. Exiting.")

    # For every column that has at least a single bad value, fix it
    for col in np.flatnonzero(bad.any(axis=0)):
        good = ~bad[:, col]
        # repeat the year three times so np.interp wraps around the ends of the
        # year, i.e. December reaches forward to January and January back to December
        x_good = np.concatenate([months[good] - nmonth, months[good], months[good] + nmonth])
        y_good = np.tile(soilw[good, col], 3)
        # Set this column's bad months to the interpolated values (leave the good months)
        soilw[~good, col] = np.interp(months[~good], x_good, y_good)

    print(f"{PREFIX}soilw after patching: min: {soilw.min():.6f}  max: {soilw.max():.6f}", flush=True)

print(f"{PREFIX}writing: {OUTNAME}", flush=True)
with Dataset(OUTNAME, "w", format="NETCDF3_64BIT_OFFSET") as ncdf:
    ncdf.createDimension("ncol", n_b)
    ncdf.createDimension("class", regridded["fraction_landuse"].shape[0])
    ncdf.createDimension("month", regridded["soilw"].shape[0])

    ncdf.createVariable("fraction_landuse", "f8", ("class", "ncol"))[:] = regridded["fraction_landuse"]
    ncdf.createVariable("soilw", "f8", ("month", "ncol"))[:] = regridded["soilw"]

    ncdf.source_file = srcGridName
    ncdf.regrid_file = wgtFileName
    ncdf.creation_date = time.ctime()

# cleanup
if not args.keep_weights:
    print(f"{PREFIX}cleanin up {wgtFileName}", flush=True)
    os.remove(wgtFileName)

print(f"{PREFIX}Script runtime: {time.time() - wcStrt:.1f} seconds", flush=True)
