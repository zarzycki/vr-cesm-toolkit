#!/usr/bin/env python3

# Drop-in replacement for gen_X_to_Y_wgts.ncl that uses NCO's ncremap (which
# drives ESMF_RegridWeightGen under the hood) instead of NCL's ESMF_regridding.
# Arguments are accepted in the same NCL style, i.e.
#   python gen_X_to_Y_wgts.py 'srcName="..."' 'srcGridName="..."' ...

import glob
import os
import subprocess
import sys
from datetime import datetime

#InterpMethod="patch"   ;bilinear, patch, conserve
#
#srcName="0.25degNH"
#srcGridName="/glade/p/work/zarzycki/grids/scrip/caminterp_0.25_NHonly_SCRIP.nc"
#
#dstName="0.5degNH"
#dstGridName="/glade/p/work/zarzycki/grids/scrip/caminterp_0.5_NHonly_SCRIP.nc"
#
#wgtFileDir="/glade/scratch/zarzycki/"

opts = {}
for arg in sys.argv[1:]:
  key, _, value = arg.partition("=")
  opts[key.strip()] = value.strip().strip('"').strip("'")

srcName = opts["srcName"]
srcGridName = opts["srcGridName"]
dstName = opts["dstName"]
dstGridName = opts["dstGridName"]
wgtFileDir = opts["wgtFileDir"]
InterpMethod = opts["InterpMethod"]

print("srcName: "+srcName)
print("dstName: "+dstName)
print("-----")
print("srcGridName: "+srcGridName)
print("dstGridName: "+dstGridName)
print("-----")
print("InterpMethod: "+InterpMethod)
print("wgtFileDir: "+wgtFileDir)

# interpString is the shorthand used in the map file name, algString is the
# matching ncremap --alg_typ
algString = InterpMethod
interpString = InterpMethod

cdate = datetime.now().strftime("%y%m%d")
wgtFileName = "map_"+srcName+"_TO_"+dstName+"_"+interpString+"."+cdate+".nc"

OUTNAME_ALL = sorted(glob.glob(wgtFileDir+"/"+"map_"+srcName+"_TO_"+dstName+"_"+interpString+"*.nc"))
print("OUTNAME_ALL: "+str(OUTNAME_ALL))

# ncremap picks the weight generator from alg_typ. Only ESMF_RegridWeightGen
# understands the option string below; for TempestRemap and the NCO algorithms
# ncremap builds its own, algorithm-specific option string, and --wgt_opt
# *replaces* it wholesale rather than adding to it, so passing these flags with
# a Tempest alg_typ both feeds GenerateOfflineMap flags it rejects (--no_log)
# and throws away the --in_type/--out_type/--method flags that define the map.
ESMF_CONSERVE = {"conserve", "esmfaave", "conservative", "cns", "c1", "aave"}
ESMF_ALGS = ESMF_CONSERVE | {"bilinear", "esmfbilin", "bilin", "blin", "bln",
                             "conserve2nd", "conservative2nd", "c2", "c2nd",
                             "nearestdtos", "esmfndtos", "ndtos", "dtos", "nds",
                             "neareststod", "esmfnstod", "nstod", "stod", "nsd",
                             "patch", "patc", "pch"}
useESMF = InterpMethod in ESMF_ALGS

# ncremap defaults, minus the PET log file, plus the degenerate-cell and
# normalization handling that NCL's ESMF_regrid_gen_weights turns on
wgtOpt = ""
if useESMF:
  wgtOpt = "--no_log --ignore_unmapped --ignore_degenerate --check"
  if InterpMethod in ESMF_CONSERVE:
    wgtOpt = wgtOpt+" --norm_type fracarea"

rgnOpt = []

# check for regional domains
if srcName == "gland4km":
  rgnOpt.append("--rgn_src=Yes")
if dstName == "gland4km":
  rgnOpt.append("--rgn_dst=Yes")

# ESMF unstructured grid files hold their cell centers in "centerCoords" and
# SCRIP files do not. ESMF needs to be told to use the corners of such a grid,
# but only for the non-conservative methods, it rejects that flag for conserve
def is_ESMF(gridName):
  header = subprocess.run(["ncdump", "-h", gridName], capture_output=True, text=True).stdout
  return "centerCoords" in header

for which, gridName in (("source", srcGridName), ("dest", dstGridName)):
  if not is_ESMF(gridName):
    continue
  print(gridName+" "+which+" is an ESMF file")
  if not useESMF:
    # TempestRemap's mesh readers only handle SCRIP and Exodus
    print("WARNING: "+InterpMethod+" does not use ESMF_RegridWeightGen, so the "
          +which+" grid must be SCRIP or Exodus, not ESMF unstructured")
  elif InterpMethod not in ESMF_CONSERVE:
    wgtOpt = wgtOpt+(" --src_loc corner" if which == "source" else " --dst_loc corner")

if not OUTNAME_ALL:
  print("Generating "+wgtFileName)
  cmd = ["ncremap", "--no_stdin", "-D", "1", "--devnull=No",
         "--alg_typ="+algString,
         "--grd_src="+srcGridName,
         "--grd_dst="+dstGridName,
         "--map_fl="+os.path.join(wgtFileDir, wgtFileName)] + rgnOpt
  if wgtOpt:
    cmd.append("--wgt_opt="+wgtOpt)
  print(" ".join(cmd))
  rc = subprocess.run(cmd).returncode
  if rc != 0:
    print("ERROR: ncremap failed generating "+wgtFileName)
    sys.exit(rc)
else:
  print("wgtFileDir/wgtFileName: "+OUTNAME_ALL[0]+" already exists!")
