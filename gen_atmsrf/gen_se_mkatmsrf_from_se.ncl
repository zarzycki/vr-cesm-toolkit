;========================================================
; TC_cross_and_latlon.ncl:   plots the PS, U, V, and T.
;========================================================
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/shea_util.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/esmf/ESMF_regridding.ncl"
;========================================================

begin

; need to be modified by the user
dstName="ne0np4colorado.ne30x16"
dstGridDir="/glade/u/home/zarzycki/work/grids/scrip/"
dstGridFile=dstName+".g_scrip.nc"

; default settings only modify if necessary
InterpMethod="patch"   ;bilinear, patch, conserve
infile="/glade/p/cesmdata/inputdata/atm/cam/chem/trop_mam/atmsrf_ne120np4_181018.nc"
srcName="ne120np4"
srcGridDir="/glade/p/cesmdata/cseg/mapping/grids/"
srcGridFile="ne120np4_pentagons_100310.nc"


wgtFileDir="./"
if (InterpMethod .eq. "patch") then
  interpString="patc"
end if
if (InterpMethod .eq. "bilinear") then
  interpString="blin"
end if
if (InterpMethod .eq. "conserve") then
  interpString="aave"
end if
cdate=systemfunc("date +%y%m%d")
wgtFileName="map_"+srcName+"_TO_"+dstName+"_"+interpString+"."+cdate+".nc"

;----------------------------------------------------------------------

srcGridName=srcGridDir+"/"+srcGridFile
dstGridName=dstGridDir+"/"+dstGridFile

;----------------------------------------------------------------------
; Now generate weights file
;----------------------------------------------------------------------

Opt                      = True
Opt@InterpMethod         = InterpMethod
Opt@ForceOverwrite       = True
Opt@PrintTimings         = True

ESMF_regrid_gen_weights(srcGridName,dstGridName,wgtFileDir+"/"+wgtFileName,Opt)

delete(Opt)


; ==========================================================================================

fin = addfile(infile,"r")

fraction_landuse_in = fin->fraction_landuse
soilw_in = fin->soilw

Opt         = True
fraction_landuse_out  = ESMF_regrid_with_weights(fraction_landuse_in,wgtFileDir+"/"+wgtFileName,Opt)
soilw_out  = ESMF_regrid_with_weights(soilw_in,wgtFileDir+"/"+wgtFileName,Opt)

if(any(ismissing(soilw_out))) then
  print("soilw_out contains some missing values. Exiting.")
  exit
end if
if(any(ismissing(fraction_landuse_out))) then
  print("fraction_landuse_out contains some missing values. Exiting.")
  exit
end if

soilw_out!1="ncol"
fraction_landuse_out!1="ncol"

delete_VarAtts(soilw_out,(/"lat1d","lon1d","remap","_FillValue","missing_value"/))
delete_VarAtts(fraction_landuse_out,(/"lat1d","lon1d","remap","_FillValue","missing_value"/))

cdate=systemfunc("date +%y%m%d")
OUTNAME="atmsrf_"+dstName+"_"+cdate+".nc"
system("/bin/rm -f "+OUTNAME)   ; remove any pre-existing file
ncdf = addfile(OUTNAME ,"c")  ; open output netCDF file

;===================================================================
; create global attributes of the file (optional)
;===================================================================
fAtt               = True            ; assign file attributes
fAtt@source_file   = srcGridDir+"/"+srcGridFile
fAtt@regrid_file   = wgtFileDir+"/"+wgtFileName
fAtt@creation_date = systemfunc ("date")
fileattdef( ncdf, fAtt )            ; copy file attributes

ncdf->fraction_landuse = fraction_landuse_out
ncdf->soilw  = soilw_out

;
;netcdf atmsrf_ne120np4_110920 {
;dimensions:
;	ncol = 777602 ;
;	class = 11 ;
;	month = 12 ;
;variables:
;	double fraction_landuse(class, ncol) ;
;	double soilw(month, ncol) ;
;}

; cleanup
print("cleanin up...")
system("rm "+wgtFileDir+"/"+wgtFileName)


end
