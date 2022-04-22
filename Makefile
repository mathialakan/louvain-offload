#===============================================================================
# Compiler Options
#===============================================================================

COMPILER    = llvm_nv
OPTIMIZE    = yes
DEBUG       = no
PROFILE     = no
SM = cc70   # --- NVIDIA arch
ARCH = gfx90a # --- AMD arch
ENABLE_OMP_OFFLOAD = 1
SAVE_TEMP = 0

#===============================================================================
# Program name & source code list
#===============================================================================

OBJ = main.o
SRC = main.cpp
TARGET = louvain_omp_$(COMPILER)

#===============================================================================
# Sets Flags
#===============================================================================

# Standard Flags
CFLAGS := -std=c++11 -Wall

# Linker Flags
LDFLAGS = -lm

OPTFLAGS = -DPRINT_DIST_STATS -DPRINT_EXTRA_NEDGES

# GCC Compiler
ifeq ($(COMPILER),gnu)
  CC = gcc
  CFLAGS += -fopenmp -flto
endif

# Intel Compiler
ifeq ($(COMPILER),intel)
  CC = icx 
  CFLAGS += -fiopenmp -fopenmp-targets=spir64 -D__STRICT_ANSI__ 
endif

# LLVM Clang Compiler 
ifeq ($(COMPILER),llvm_nv)
  CC = clang++
  CFLAGS += -fopenmp -fopenmp-targets=nvptx64-nvidia-cuda  -fopenmp-cuda-mode 
  #CFLAGS += -fopenmp -fopenmp-targets=nvptx64-nvidia-cuda -Xopenmp-target --cuda-path=${OLCF_CUDA_ROOT}    -fopenmp-new-driver -foffload-lto 
  #CFLAGS += -fopenmp -fopenmp-targets=nvptx64-nvidia-cuda -Xopenmp-target --cuda-path=${OLCF_CUDA_ROOT}  -Xcuda-ptxas --maxrregcount=120 -fopenmp-new-driver -foffload-lto -fopenmp-assume-no-thread-state
  #CFLAGS += -fopenmp -fopenmp-targets=nvptx64-nvidia-cuda -Xopenmp-target --cuda-path=${OLCF_CUDA_ROOT}  -Xcuda-ptxas --maxrregcount=120
endif

# IBM XL Compiler
ifeq ($(COMPILER),ibm)
  CC = xlC
  CFLAGS += -qsmp=omp -qoffload
endif

# NVIDIA NVHPC Compiler 
ifeq ($(COMPILER),nvhpc)
  CC = nvc++
  CFLAGS += -mp=gpu -gpu=${SM}
  #CFLAGS += -mp=gpu -Minfo=mp -gpu=${SM}
endif

# AOMP Compiler
ifeq ($(COMPILER),llvm_amd)
  CC = clang++
  CFLAGS += -fopenmp -fopenmp-targets=amdgcn-amd-amdhsa -Xopenmp-target=amdgcn-amd-amdhsa -march=${ARCH}
endif

# Debug Flags
ifeq ($(DEBUG),yes)
  CFLAGS += -g
  LDFLAGS  += -g
endif

# Profiling Flags
ifeq ($(PROFILE),yes)
  CFLAGS += -pg
  LDFLAGS  += -pg
endif

# Optimization Flags
ifeq ($(OPTIMIZE),yes)
  CFLAGS += -O3
endif

# Using device offload
ifeq ($(ENABLE_OMP_OFFLOAD),1)
  CFLAGS += -DUSE_OMP_OFFLOAD
else
  CFLAGS += -fopenmp -DGRAPH_FT_LOAD=1 #-I/usr/lib/gcc/x86_64-redhat-linux/4.8.5/include/
endif

# Compiler Trace  
ifeq ($(SAVE_TEMPS),1)
CFLAGS += -save-temps
endif

TS=32

# Team size
ifeq ($(TS), 16)
  OPTFLAGS += -DTS16
else ifeq ($(TS), 32)
  OPTFLAGS += -DTS32
else ifeq ($(TS), 64)
  OPTFLAGS += -DTS64
else ifeq ($(TS), 128)
  OPTFLAGS += -DTS128
else ifeq ($(TS), 256)
  OPTFLAGS += -DTS256
else ifeq ($(TS), 512)
  OPTFLAGS += -DTS512
else
  OPTFLAGS += -DTS32
endif

TARGET := $(TARGET)_$(TS)

#===============================================================================
# Targets to Build
#===============================================================================

#$(LDAPP) $(CXX) $(CXXFLAGS_THREADS) -o $@ $+ $(LDFLAGS) $(CXXFLAGS)
CFLAGS += -I. $(OPTFLAGS)

OBJS = $(OBJ)
TARGETS = $(TARGET)

all: $(TARGETS)

$(TARGET):  $(OBJ)
	$(CC) $(CFLAGS) -o $@ $+ $(LDFLAGS)

$(OBJ): $(SRC)
	$(CC) $(INCLUDE) $(CFLAGS) -c $< -o $@

.PHONY: clean

clean:
	rm -rf *~ *.dSYM nc.vg.* $(OBJS) $(TARGETS)

run:
	./$(TARGET) -n 1000
