load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"

begin

  ;
  ; Which field to plot
  ;
  plotfield = "h"
;  plotfield = "ke"
;  plotfield = "vorticity"

  ;
  ; Whether to plot wind vectors
  ;
;  winds    = True
  winds    = False

  ;
  ; Whether to do color-filled plot (filled=True) or
  ;   to plot contours of height field (filled=False)
  ;
;  filled   = True
  filled   = False

  ;
  ; The (lat,lon) the plot is to be centered over
  ;
  cenLat   = 40.
  cenLon   = -97.5

  ;
  ; Projection to use for plot
  ;
  projection = "Orthographic"
;  projection = "CylindricalEquidistant"


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


  r2d = 57.2957795             ; radians to degrees

  maxedges = 7 

  wks = gsn_open_wks("pdf","atm_map_conus")

  colors = (/"white","black","lightskyblue1","lightskyblue1","bisque"/)
  gsn_define_colormap(wks,colors)

;  fname = getenv("FNAME")
;  f = addfile("Mesh/grid_new_2.nc","r")
;  f = addfile("x20.835586.grid.nc","r")
;  f = addfile("x20.835586.central_us_0.nc","r")
;  f = addfile("x20.835586.texas_0.nc","r")
;  f = addfile("x20.835586.andes.nc","r")

;  f = addfile("mpas_scrip_60-3_central_us.nc","r")
;  f = addfile("mpas_scrip_60-3_texas.nc","r")
  f = addfile("mpas_scrip_15-3_conus.nc","r")

;  lonCell   = f->lonCell(:) * r2d
;  latCell   = f->latCell(:) * r2d
  lonCell   = f->grid_center_lon * r2d
  latCell   = f->grid_center_lat * r2d

  res                      = True
  res@gsnMaximize          = True
  res@gsnSpreadColors      = True

  if (plotfield .eq. "h" .or. plotfield .eq. "ke") then
     res@sfXArray             = lonCell
     res@sfYArray             = latCell
  end if
  if (plotfield .eq. "vorticity") then
     res@sfXArray             = lonVertex
     res@sfYArray             = latVertex
  end if

  res@cnFillMode           = "AreaFill"

  if (filled) then
     res@cnFillOn             = True
     res@cnLinesOn            = False
     res@cnLineLabelsOn       = False
  else
     res@cnFillOn             = False
     res@cnLinesOn            = True
     res@cnLineLabelsOn       = True
  end if

  res@cnContourMethod = "ManualLevels"
  res@cnMinLevelValF = 0.
  res@cnMaxLevelValF = 5.
  res@cnLevelSpacingF = 0.5
  res@cnInfoLabelOn        = True

  res@lbLabelAutoStride    = True
  res@lbBoxLinesOn         = False

  res@mpProjection      = projection
  res@mpDataBaseVersion = "MediumRes"
  res@mpCenterLatF      = cenLat
  res@mpCenterLonF      = cenLon
  res@mpGridAndLimbOn   = True
  res@mpGridAndLimbDrawOrder = "Draw"
;  res@mpGridLineColor   = "Foreground"
  res@mpGridLineColor   = "Grey"
  res@mpGridSpacingF = 15.0
;  res@mpGridSpacingF = 5./3.
;  res@mpGridPolarLonSpacingF = 5./3.
  res@mpGridPolarLonSpacingF = 15.
  res@mpOutlineOn       = True
;  res@mpOutlineOn       = False
  res@mpDataBaseVersion = "Ncarg4_1"
  res@mpDataSetName     = "Earth..3"
  res@mpOutlineBoundarySets = "GeophysicalAndUSStates"
;  res@mpOutlineBoundarySets = "AllBoundaries"
  res@mpFillOn          = True
  res@mpPerimOn         = True
  res@gsnFrame          = False
  res@cnLineThicknessF  = 2.0
  res@cnLineColor       = "NavyBlue"
  res@mpOceanFillColor  = 3
  res@mpInlandWaterFillColor  = 3
  res@mpLandFillColor  = 4
  res@tiMainString     = "US refinement (40N, 97.5W), CAM refinement factor"

  t = stringtointeger(getenv("T"))
  if (plotfield .eq. "h") then
;     fld = 3.0/(f->meshDensity(:)^0.25)
     fld = f->rrfac
     print(" min and max rr "+min(fld)+" "+max(fld))
  end if
  if (plotfield .eq. "ke") then
     fld = f->ke(t,:,0)
  end if
  if (plotfield .eq. "vorticity") then
     fld = f->vorticity(t,:,0)
  end if
  res@cnLineDashPattern = 0
  map = gsn_csm_contour_map(wks,fld,res)

  frame(wks)

end

