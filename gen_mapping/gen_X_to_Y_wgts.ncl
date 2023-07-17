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

;InterpMethod="patch"   ;bilinear, patch, conserve
;
;srcName="0.25degNH"
;srcGridName="/glade/p/work/zarzycki/grids/scrip/caminterp_0.25_NHonly_SCRIP.nc"
;
;dstName="0.5degNH"
;dstGridName="/glade/p/work/zarzycki/grids/scrip/caminterp_0.5_NHonly_SCRIP.nc"
;
;wgtFileDir="/glade/scratch/zarzycki/"


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
; Now generate weights file
;----------------------------------------------------------------------

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

ESMF_regrid_gen_weights(srcGridName,dstGridName,wgtFileDir+"/"+wgtFileName,Opt)

delete(Opt)

end
