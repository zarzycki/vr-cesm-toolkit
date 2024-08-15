begin

  a=addfile("mpas_scrip.nc","r")
  rrfac = a->rrfac
  print(" min and max rrfac "+min(rrfac)+" "+max(rrfac))

end
