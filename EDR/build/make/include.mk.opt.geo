#Makefile include include.mk.opt.ubuntu
############################################################################

# Environment variables containing HDF:
# SCC_HDF5_LIB=/share/pkg/hdf5/1.8.16/install/lib
# SCC_HDF5_DIR=/share/pkg/hdf5/1.8.16
# LD_LIBRARY_PATH=/share/pkg/hdf5/1.8.16/install/lib:/share/pkg/armadillo/7.400.2/install/lib:/share/pkg/intel/2016/install/mkl/lib/intel64:/share/pkg/gcc/6.2.0/install/libexec/gcc/x86_64-unknown-linux-gnu/6.2.0:/share/pkg/gcc/6.2.0/install/lib/gcc/x86_64-unknown-linux-gnu/6.2.0/32:/share/pkg/gcc/6.2.0/install/lib/gcc/x86_64-unknown-linux-gnu/6.2.0:/share/pkg/gcc/6.2.0/install/lib64:/share/pkg/gcc/6.2.0/install/lib:/share/pkg/postgresql/9.4.4/install/lib:/share/pkg/netcdf/4.4.0/install/lib:/share/pkg/udunits/2.2.20/install/lib:/share/pkg/jags/4.0.0/install/lib
# PATH=/share/pkg/hdf5/1.8.16/install/bin:/share/pkg/vim/8.0/install/bin:/share/pkg/gcc/6.2.0/install/bin:/share/pkg/postgresql/9.4.4/install/bin:/share/pkg/netcdf/4.4.0/install/bin:/share/pkg/udunits/2.2.20/install/bin:/share/pkg/jags/4.0.0/install/bin:/share/pkg/tmux/2.0/install/bin:/share/pkg/git/2.11.1/install/bin:/share/pkg/r/3.3.2/install/bin:/usr/java/default/jre/bin:/usr/java/default/bin:/usr/lib64/qt-3.3/bin:/usr/local/bin:/bin:/usr/bin:/usr/local/sbin:/usr/sbin:/sbin:/usr3/graduate/ashiklom/dietzelab/.local/bin
# _LMFILES_=/share/module/programming/R/3.3.2:/share/module/utilities/git/2.11.1:/share/module/utilities/tmux/2.0:/share/module/statistics/jags/4.0.0:/share/module/libraries/udunits/2.2.20:/share/module/libraries/netcdf/4.4.0:/share/module/programming/postgresql/9.4.4:/share/module/programming/gcc/6.2.0:/share/module/libraries/armadillo/7.400.2:/share/module/utilities/vim/8.0:/share/module/libraries/hdf5/1.8.16
# LOADEDMODULES=R/3.3.2:git/2.11.1:tmux/2.0:jags/4.0.0:udunits/2.2.20:netcdf/4.4.0:postgresql/9.4.4:gcc/6.2.0:armadillo/7.400.2:vim/8.0:hdf5/1.8.16
# SCC_HDF5_BIN=/share/pkg/hdf5/1.8.16/install/bin
# SCC_HDF5_INCLUDE=/share/pkg/hdf5/1.8.16/install/include
# SCC_HDF5_EXAMPLES=/share/pkg/hdf5/1.8.16/install/share/hdf5_examples

# Define make (gnu make works best).
MAKE=/usr/bin/make

# libraries.
BASE=$(EDR_ROOT)/build/

# HDF 5  Libraries
USE_HDF5=1
HDF5_INCS=-I${SCC_HDF5_INCLUDE}
HDF5_LIBS=-L${SCC_HDF5_LIB} -lhdf5 -lm -lhdf5_fortran -lhdf5 -lhdf5_hl -lz
USE_COLLECTIVE_MPIO=0
 
# netCDF libraries
USENC=0
NC_LIBS=-L/dev/null

# interface
USE_INTERF=1

# MPI_Wtime
USE_MPIWTIME=1

# gfortran
CMACH=PC_LINUX1
F_COMP=mpif90
F_OPTS=-O3 -ffree-line-length-none  -fno-whole-file
C_COMP=mpicc
C_OPTS=-O3
LOADER=mpif90
LOADER_OPTS=${F_OPTS}
C_LOADER=mpicc
LIBS=
MOD_EXT=mod

# using MPI libraries:
MPI_PATH=
PAR_INCS=
PAR_LIBS=
PAR_DEFS=-DRAMS_MPI

# For IBM,HP,SGI,ALPHA,LINUX use these:
ARCHIVE=ar rs
