FC = $(shell nf-config --fc)
FCINCLUDES = $(shell nf-config --fflags)
FCLIBS = $(shell nf-config --flibs)
CCLIBS = $(shell nc-config --libs)
FCLIBDIR = $(shell echo $(FCLIBS) | sed -n 's/.*-L\([^ ]*\).*/\1/p')
CCLIBDIR = $(shell echo $(CCLIBS) | sed -n 's/.*-L\([^ ]*\).*/\1/p')

all: mpas2esmf.f90
	$(FC) -o mpas2esmf mpas2esmf.f90 ${FCINCLUDES} ${FCLIBS} ${CCLIBS} -Wl,-rpath,$(FCLIBDIR) -Wl,-rpath,$(CCLIBDIR)

clean:
	rm -f mpas2esmf read_mesh.mod write_desc.mod
