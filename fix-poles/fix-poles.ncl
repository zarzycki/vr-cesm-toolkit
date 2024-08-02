begin

CHECK_POLE_FIX=True
DO_POLE_FIX=False

if CHECK_POLE_FIX then
  ;f1 = addfile("fv0.9x1.25_141008_ESMFmesh.nc","r")
  ;f1 = addfile("tmp.nc","r")
  ;f2 = addfile("fv0.9x1.25_141008_polemod_ESMFmesh.nc","r")

  f1 = addfile("fv0.23x0.31_ESMFmesh_polemod_240726.nc","r")
  f2 = addfile("fv0.23x0.31_ESMFmesh_240726.nc","r")

  ;	double centerCoords(elementCount, coordDim) ;
  ;		centerCoords:units = "degrees" ;
  ;	double elementArea(elementCount) ;
  ;	int elementConn(elementCount, maxNodePElement) ;
  ;		elementConn:long_name = "Node indices that define the element connectivity" ;
  ;		elementConn:_FillValue = -1 ;
  ;	int elementMask(elementCount) ;
  ;	double nodeCoords(nodeCount, coordDim) ;
  ;		nodeCoords:units = "degrees" ;
  ;	byte numElementConn(elementCount) ;
  ;		numElementConn:long_name = "Number of nodes per element"

  vars = (/"centerCoords","elementArea","elementConn","elementMask","nodeCoords","numElementConn"/)

  do ii = 0,dimsizes(vars)-1
    var = vars(ii)

    var1 = f1->$var$
    var2 = f2->$var$

    diff = var1-var2

    a1D      = ndtooned(abs(diff))

    print(var+": "+num(a1D .gt. 1e-12))

    delete(var1)
    delete(var2)
    delete(diff)
    delete(a1D)

  end do
end if

if DO_POLE_FIX then
  f3 = addfile("fv0.23x0.31_ESMFmesh_polemod_240726.nc","w")

  nlat=768
  nlon=1152
  ncells=nlat*nlon

  ;nlat=192
  ;nlon=288
  ;ncells=nlat*nlon

  centerCoords = f3->centerCoords
  ;print(centerCoords)

  centerCoords(0:nlon-1,1) = -90.0
  centerCoords(ncells-nlon:ncells-1,1) = 90.0

  ;print(centerCoords)

  f3->centerCoords = centerCoords
end if

end