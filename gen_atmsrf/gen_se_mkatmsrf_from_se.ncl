load "$NCARG_ROOT/lib/ncarg/nclscripts/esmf/ESMF_regridding.ncl"

begin

; can be modified by user if not passed in
if (.not.isvar("dstName"))
  dstName="TClandfall-001_ne32x4_pg2"
end if
if (.not.isvar("dstGridDir"))
  dstGridDir="/global/homes/c/czarzyck/m2637/E3SM_SCREAM_files/grids/scrip/"
end if
if (.not.isvar("dstGridFile"))
  dstGridFile="TClandfall-001_ne32x4_pg2_SCRIP.nc"
end if
if (.not.isvar("dstGridFile"))
  atmsrfDir="/global/homes/c/czarzyck/m2637/E3SM_SCREAM_files/atmsrf/"
end if
if (.not.isvar("dstGridFile"))
  wgtFileDir="/pscratch/sd/c/czarzyck/"
end if

;infile="/glade/p/cesmdata/inputdata/atm/cam/chem/trop_mam/atmsrf_ne120np4_181018.nc"
;srcName="ne120np4"
;srcGridDir="/glade/p/cesmdata/cseg/mapping/grids/"
;srcGridDir="/glade/p/cesmdata/inputdata/share/scripgrids/"
;srcGridFile="ne120np4_pentagons_100310.nc"
infile="/global/homes/c/czarzyck/inputdata/atm/cam/chem/trop_mam/atmsrf_ne512pg2_200212.nc"
srcName="ne512pg2"
srcGridDir="/global/homes/c/czarzyck/mapping-e3sm/grids/"
srcGridFile="ne512pg2_scrip_20221011.nc"

print("gen_se_mkatmsrf_from_se.ncl:  dstName: "+dstName)
print("gen_se_mkatmsrf_from_se.ncl:  dstGridDir: "+dstGridDir)
print("gen_se_mkatmsrf_from_se.ncl:  dstGridFile: "+dstGridFile)
print("gen_se_mkatmsrf_from_se.ncl:  atmsrfDir: "+atmsrfDir)
print("gen_se_mkatmsrf_from_se.ncl:  wgtFileDir: "+wgtFileDir)
print("gen_se_mkatmsrf_from_se.ncl:  infile: "+infile)
print("gen_se_mkatmsrf_from_se.ncl:  srcName: "+srcName)
print("gen_se_mkatmsrf_from_se.ncl:  srcGridDir: "+srcGridDir)
print("gen_se_mkatmsrf_from_se.ncl:  srcGridFile: "+srcGridFile)

;----------------------------------------------------------------------

InterpMethod="patch"   ;bilinear, patch, conserve

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

quote = inttochar(34)
wcStrt     = systemfunc("date "+quote+"+%a %b %d %T %Z %Y"+quote)
print(wcStrt+"")

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
OUTNAME=atmsrfDir+"/atmsrf_"+dstName+"_"+cdate+".nc"
system("/bin/rm -f "+OUTNAME)   ; remove any pre-existing file
ncdf = addfile(OUTNAME ,"c")  ; open output netCDF file

print("writing: "+OUTNAME)

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
system("rm -v "+wgtFileDir+"/"+wgtFileName)

wallClockElapseTime(wcStrt, "Script runtime", 0)

end
