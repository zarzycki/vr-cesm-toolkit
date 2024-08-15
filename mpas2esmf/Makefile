FC = $(shell nf-config --fc)
FCINCLUDES = $(shell nf-config --fflags)
FCLIBS = $(shell nf-config --flibs)
CCLIBS = $(shell nc-config --libs)

all: mpas2esmf.f90
	$(FC) -o mpas2esmf mpas2esmf.f90 ${FCINCLUDES} ${FCLIBS} ${CCLIBS}

clean:
	rm -f mpas2esmf read_mesh.mod write_desc.mod
