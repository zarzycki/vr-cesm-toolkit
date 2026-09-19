#!/usr/bin/env python3

# Drop-in replacement for HOMME2SCRIP.ncl that uses netCDF4/numpy instead of
# NCL. Arguments are accepted in the same NCL style, i.e.
#   python HOMME2SCRIP.py 'name="ne0np4"' ne=0 np=4
#
#   read a HOMME grid template file and convert to SCRIP format
#   Mark Taylor 2008

import os
import sys

import numpy as np
from netCDF4 import Dataset

# NCL's default _FillValue for double, carried by anything built with new()
NCL_DOUBLE_FILL = 9.969209968386869e+36

opts = {}
for arg in sys.argv[1:]:
  key, _, value = arg.partition("=")
  opts[key.strip()] = value.strip().strip('"').strip("'")

name = opts["name"]
ne = int(opts["ne"])

if "np" not in opts:
  np_ = 4
  print("NPTS not specified on command line. Using default 4.")
else:
  np_ = int(opts["np"])

template = name + "_tmp.nc"
output = name + "_scrip.nc"
if os.path.exists(output):
  os.remove(output)
print("input: "+template+" output:"+output)

fin = Dataset(template, "r")
fin.set_auto_mask(False)

# ne>512 grids are too big for the classic netCDF-3 format NCL writes by default
out_format = "NETCDF4" if ne > 512 else "NETCDF3_CLASSIC"
fout = Dataset(output, "w", format=out_format)

in_lat = fin.variables["lat"][:]
in_lon = fin.variables["lon"][:]

grid_size = in_lat.shape[0]
print("grid_size = "+str(grid_size))
grid_rank = 1

# see if there are any hexagons:
grid_corners = 0
if "cv_lon" in fin.variables:
  cv_lon = fin.variables["cv_lon"]
  cv_lat = fin.variables["cv_lat"]
  if cv_lon.ndim != 2:
    raise ValueError("expected cv_lon to be 2D (corners,grid_size), got "
                     + str(cv_lon.shape))
  kmax = cv_lon.shape
  for k in range(1, kmax[0]):
    maxlon = np.max(np.abs(cv_lon[k, :]))
    if maxlon < 0.000000001 and grid_corners == 0:
      grid_corners = k
  if grid_corners == 0:
    print(" Failed to find max number of nodes per element.")
  else:
    if grid_corners == 4:
      print("all control volumes are at most squares")
    else:
      if grid_corners == 5:
        print("detected pentagon control volumes")
      else:
        if grid_corners == 6:
          print("detected hexagon control volumes ")
        else:
          print("detected unstructured control volumes. Max Corners: "+str(grid_corners))

print("lon min/max = "+str(np.min(in_lon))+" "+str(np.max(in_lon)))
print("lat min/max = "+str(np.min(in_lat))+" "+str(np.max(in_lat)))

grid_area = np.array(fin.variables["area"][:], dtype="f8")

grid_center_lat = np.array(in_lat, dtype="f8")
grid_center_lon = np.array(in_lon, dtype="f8")

if grid_corners > 0:
  grid_corner_lon = np.full((grid_size, grid_corners), NCL_DOUBLE_FILL, dtype="f8")
  grid_corner_lat = np.full((grid_size, grid_corners), NCL_DOUBLE_FILL, dtype="f8")
  print("dims of cv_lon: "+str(cv_lon.shape))
  print("dims of grid_corner_lat: "+str(grid_corner_lat.shape))

  for k in range(0, grid_corners):
    grid_corner_lon[:, k] = cv_lon[k, :]
    grid_corner_lat[:, k] = cv_lat[k, :]

# reverse orientation at pole point
  for i in range(0, grid_size):
    if abs(90 - abs(grid_center_lat[i])) < 1e-9:
      print("i="+str(i)+" pole point: "+str(grid_center_lat[i])+" "+str(grid_center_lon[i]))
      print("cv: "+str(grid_corner_lat[i, :])+" "+str(grid_corner_lon[i, :]))
                                # 1 2 3 4  ->  1 4 3 2    swap pos 1,3

grid_imask = np.ones((grid_size,), dtype="f8")

grid_rank = 1
grid_dims = np.array([1], dtype="i4")

# write the 'title' global attribute
print("writing attributes...")
fout.title = "ne"+str(ne)+"np"+str(np_)
fout.Created_by = "HOMME2SCRIP.ncl mt 2009"
fout.history = "HOMME2SCRIP.ncl mt 2009"

# write all the data to the output field:
print("writing grid data....")
fout.createDimension("grid_size", grid_size)
if grid_corners > 0:
  fout.createDimension("grid_corners", grid_corners)
fout.createDimension("grid_rank", grid_rank)

v = fout.createVariable("grid_area", "f8", ("grid_size",))
v.units = "radians^2"
v.long_name = "area weights"
v[:] = grid_area

v = fout.createVariable("grid_center_lat", "f8", ("grid_size",))
v.units = "degrees"
v[:] = grid_center_lat

v = fout.createVariable("grid_center_lon", "f8", ("grid_size",))
v.units = "degrees"
v[:] = grid_center_lon

if grid_corners > 0:
  v = fout.createVariable("grid_corner_lon", "f8", ("grid_size", "grid_corners"),
                          fill_value=NCL_DOUBLE_FILL)
  v.units = "degrees"
  v[:] = grid_corner_lon

  v = fout.createVariable("grid_corner_lat", "f8", ("grid_size", "grid_corners"),
                          fill_value=NCL_DOUBLE_FILL)
  v.units = "degrees"
  v[:] = grid_corner_lat

v = fout.createVariable("grid_imask", "f8", ("grid_size",),
                        fill_value=NCL_DOUBLE_FILL)
v[:] = grid_imask

v = fout.createVariable("grid_dims", "i4", ("grid_rank",))
v[:] = grid_dims

fout.close()
fin.close()
