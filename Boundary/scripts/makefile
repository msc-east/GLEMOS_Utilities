FC = /home/alex/Soft/OracleDeveloperStudio12.6-linux-x86-bin/developerstudio12.6/bin/f95
FFLAGS1 = -m64 -f77=output -fpp
FFLAGS2 = -c -fast -g -w1 -o
FFLAGS = $(FFLAGS1) -moddir=$(MODDIR) $(FFLAGS2)
LDLIBSOPTIONS = -L/home/alex/netcdf-fortran-4.5.2/fortran/.libs -lnetcdff
PRJDIR =  /home/alex/GLEMOS_WorkSpace/GLEMOS_Utilities/Boundary
SRCDIR =  /home/alex/GLEMOS_WorkSpace/GLEMOS_Utilities/Boundary/src
OBJDIR =  /home/alex/GLEMOS_WorkSpace/GLEMOS_Utilities/Boundary/build/objs
MODDIR =  /home/alex/GLEMOS_WorkSpace/GLEMOS_Utilities/Boundary/build/mods
NSRCDIR = /home/alex/netcdf-fortran-4.5.2/fortran
OBJS = \
  $(OBJDIR)/ncf/typeSizes.o \
  $(OBJDIR)/ncf/netcdf.o \
  $(OBJDIR)/params_boundary.o \
  $(OBJDIR)/read_boundary.o \
  $(OBJDIR)/proc_boundary.o 
  $(PRJDIR)/proc_boundary: $(OBJS)
	$(FC) -o $(PRJDIR)/proc_boundary $(OBJS) ${LDLIBSOPTIONS}
  $(OBJDIR)/ncf/typeSizes.o: $(NSRCDIR)/typeSizes.f90
	$(FC) $(FFLAGS) $(OBJDIR)/ncf/typeSizes.o $(NSRCDIR)/typeSizes.f90
  $(OBJDIR)/ncf/netcdf.o: $(NSRCDIR)/netcdf.f90
	$(FC) $(FFLAGS) $(OBJDIR)/ncf/netcdf.o $(NSRCDIR)/netcdf.f90
  $(OBJDIR)/params_boundary.o: $(SRCDIR)/params_boundary.f95
	$(FC) $(FFLAGS) $(OBJDIR)/params_boundary.o $(SRCDIR)/params_boundary.f95
  $(OBJDIR)/read_boundary.o: $(SRCDIR)/read_boundary.f95
	$(FC) $(FFLAGS) $(OBJDIR)/read_boundary.o $(SRCDIR)/read_boundary.f95
  $(OBJDIR)/proc_boundary.o: $(SRCDIR)/proc_boundary.f95
	$(FC) $(FFLAGS) $(OBJDIR)/proc_boundary.o $(SRCDIR)/proc_boundary.f95
clean:
	rm -f /home/alex/GLEMOS_WorkSpace/GLEMOS_Utilities/Boundary/build/objs/*.o
	rm -f /home/alex/GLEMOS_WorkSpace/GLEMOS_Utilities/Boundary/build/objs/ncf/*.o
	rm -f /home/alex/GLEMOS_WorkSpace/GLEMOS_Utilities/Boundary/build/mods/*.mod
	rm -f /home/alex/GLEMOS_WorkSpace/GLEMOS_Utilities/Boundary/proc_boundary
