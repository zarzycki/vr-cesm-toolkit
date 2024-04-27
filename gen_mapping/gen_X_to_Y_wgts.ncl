load "$NCARG_ROOT/lib/ncarg/nclscripts/esmf/ESMF_regridding.ncl"

begin

;InterpMethod="patch"   ;bilinear, patch, conserve
;
;srcName="0.25degNH"
;srcGridName="/glade/p/work/zarzycki/grids/scrip/caminterp_0.25_NHonly_SCRIP.nc"
;
;dstName="0.5degNH"
;dstGridName="/glade/p/work/zarzycki/grids/scrip/caminterp_0.5_NHonly_SCRIP.nc"
;
;wgtFileDir="/glade/scratch/zarzycki/"

print("srcName: "+srcName)
print("dstName: "+dstName)
print("-----")
print("srcGridName: "+srcGridName)
print("dstGridName: "+dstGridName)
print("-----")
print("InterpMethod: "+InterpMethod)
print("wgtFileDir: "+wgtFileDir)

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

OUTNAME_ALL = systemfunc("ls "+wgtFileDir+"/"+"map_"+srcName+"_TO_"+dstName+"_"+interpString+"*.nc 2>/dev/null")

Opt                      = True
Opt@InterpMethod         = InterpMethod
Opt@ForceOverwrite       = True
Opt@PrintTimings         = True

; check for regional domains
if (srcName .eq. "gland4km") then
  Opt@SrcRegional=True
end if
if (dstName .eq. "gland4km") then
  Opt@DstRegional=True
end if

if (ismissing(OUTNAME_ALL)) then
  print("Generating "+wgtFileName)
  ESMF_regrid_gen_weights(srcGridName,dstGridName,wgtFileDir+"/"+wgtFileName,Opt)
else
  print("wgtFileDir/wgtFileName: "+OUTNAME_ALL(0)+" already exists!")
end if

delete(Opt)

end
