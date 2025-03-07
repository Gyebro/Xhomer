# Makefile for xhomer

# To build xhomer:
#
#   1. make clean
#   2. make
#
# To make a new archive tarball, perform the following steps:
#
#   1. make clean
#   2. make date
#   3. make archive

#######
# Use MIT shared memory in X-windows (for better performance)

USE_SHM = N

#######
# Setting this causes the emulated realtime clock to be
# locked to the realtime clock on the host system.
# Unset this only for testing purposes.

USE_RTC = Y

#######
# Provide extra information in the window title bar
# (at this point, this adds TLB hit statistics)

# USE_EXTRA_STATUS = Y

#######
# Build id.rom and pro350.rom into executable
#
# If this option is not defined, then xhomer expects to find
# id.rom and pro350.rom in the directory it was run from.

USE_BUILTIN_ROMS = Y


#######
# Do not set the following feature.  it is not fully
# functional.

# USE_LIMIT = Y

USE_CURSES = Y
USE_SDL = Y
USE_X = Y


################
# PDP11 features

CCDEFS = -DMM_CACHE=8
CCDEFS += -DPERF_MONITOR
# Skip boundary conditions for shift operations in the fp
# code.  (No check for shift by 0 or >=64 if you define this.)
# CCDEFS += -DF_SH_FAST
# CCDEFS += -DTRACE
# CCDEFS += -DIOTRACE

# Set version variable (for later use by make archive)
PRO_VERSION = `cat VERSION`


##########################
# C-Compiler configuration

# All the rest of the flags in this section assume gcc
CC=gcc -Wall
# -Wchar-subscripts -W -Wshadow -Wconversion
# -Wtraditional -Wstrict-prototypes

# This prevents "undesirable excess precision" on some machines, says gcc
CC += -ffloat-store

# The 1st choice runs about 15% slower than the 2nd (-O3 -fomit-frame-pointer).
# but it (re)compiles faster and unlike the second choice, it is debuggable.
CC += -g -O0 -fno-inline
#CC += -O3 -Winline -fomit-frame-pointer

# Some older gcc's need this on i386 to work around a bug.  As long as
# omit-frame-pointer is also set, it doesn't seem to hurt performance, so
# uncomment it if you think your gcc might have the bug.
# CC += -fno-strength-reduce
# Here are some more options from the man page but didn't seem to help much.
# CC += -finline-functions -ffast-math -fexpensive-optimizations

TARGET = $(shell echo `uname -s`-`uname -r | cut -d . -f 1`)

CCINCS =
CCDEFS += -DLOCAL=static -DGLOBAL=extern -DPRO -DDGA -DDGA2
CCLIBS =
CCLINK = -lm -lXxf86vm -l:libXxf86dga.a -lXext
CCLINKSTATIC = -static -ldl


#########################
# Files (base + graphics)
SOURCES = $(shell /bin/ls src/simh/pdp11*.c src/simh/scp*.c src/pro*.c)
SOURCES += src/term/term_generic.c src/term/term_curses.c src/term/term_sdl.c $(shell /bin/ls src/term/term*x11.c)


# Some Pro features require extra libraries and defines
ifeq ($(USE_RTC),Y)
  CCDEFS += -DRTC
endif
ifeq ($(USE_LIMIT),Y)
  CCDEFS += -DLIMIT
endif
ifeq ($(USE_SHM),Y)
  CCDEFS += -DSHM
endif
ifeq ($(USE_EXTRA_STATUS),Y)
  CCDEFS += -DEXTRA_STATUS
endif
ifeq ($(USE_BUILTIN_ROMS),Y)
  CCDEFS += -DBUILTIN_ROMS
endif


ifeq ($(USE_CURSES),Y)
#Mac#  CCINCS += 
#Linux#  CCINCS += 
#Cygwin#  CCINCS += -I/usr/include/ncurses
  CCINCS +=
  CCDEFS += -DHAS_CURSES
#Mac#  CCLIBS = -lcurses
#Linux#  CCLIBS = -lcurses -ltermcap
#Cygwin#  CCLIBS = -lcurses
  CCLIBS = -lcurses -ltermcap
endif
ifeq ($(USE_SDL),Y)
#Mac#  CCINCS += -I/opt/local/include/SDL
#Linux#  CCINCS += -I/usr/include/SDL
#Cygwin#  CCINCS += -I/usr/local/include/SDL
  CCINCS += -I/usr/include/SDL
#Mac#  CCDEFS += -DHAS_SDL -D_GNU_SOURCE=1 -D_THREAD_SAFE
#Linux#  CCDEFS += -DHAS_SDL -D_GNU_SOURCE=1 -D_REENTRANT
#Cygwin#  CCDEFS += -DHAS_SDL
  CCDEFS += -DHAS_SDL -D_GNU_SOURCE=1 -D_REENTRANT
#Mac#  CCLIBS += -L/opt/local/lib
#Linux#  CCLIBS += 
#Cygwin#  CCLIBS += -L/usr/local/lib
  CCLIBS += 
#Mac#  CCLINK += -lSDLmain -lSDL -Wl,-framework,Cocoa
#Linux#  CCLINK += -lSDL -lpthread
#Cygwin#  CCLINK += -lSDLmain -lSDL
  CCLINK += -lSDL -lpthread
#Mac#  CCLINKSTATIC += /opt/local/lib/libSDLmain.a /opt/local/lib/libSDL.a -Wl,-framework,OpenGL -Wl,-framework,Cocoa -Wl,-framework,ApplicationServices -Wl,-framework,Carbon -Wl,-framework,AudioToolbox -Wl,-framework,AudioUnit -Wl,-framework,IOKit
#Linux#  CCLINKSTATIC += -lSDL -lpthread -lm -ldl -lpthread
#Cygwin#  CCLINKSTATIC += -lSDLmain -lSDL -luser32 -lgdi32 -lwinmm -ldxguid
  CCLINKSTATIC += -lSDL -lpthread -lm -ldl -lpthread
endif
ifeq ($(USE_X),Y)
  X11DIR = /usr/X11R6
  CCINCS += -I$(X11DIR)/include -I/usr/X11/include
  CCDEFS += -DHAS_X11
  CCLIBS += -L$(X11DIR)/lib -L/usr/X11/lib
  CCLINK += -lX11
  
  ifeq ($(USE_SHM),Y)
    CCLINK += -lXext
  endif
    
  # But some vendors put things in non-standard places
  ifeq ($(TARGET), HP-UX-A)
    # HP-UX 9
    CCINCS += -I/usr/include/X11R5
    CCLIBS += -L/usr/lib/X11R5
  else
  ifeq ($(TARGET), HP-UX-B)
    # HP-UX 10
    CCINCS += -I/usr/include/X11R6
    CCLIBS += -L/usr/lib/X11R6
  else
  ifeq ($(TARGET), SunOS-5)
    CCINCS += -I/usr/openwin/include
    CCLIBS += -L/usr/openwin/lib
    CCLINK += -lsocket -lnsl
  endif
  endif
  endif
endif

ifeq ($(TARGET), SunOS-4)
  CCDEFS += -DSUNOS -D__USE_FIXED_PROTOTYPES__ -DEXIT_FAILURE=1 -DEXIT_SUCCESS=0
endif

###################
# Rules, etc

OBJECTS = $(SOURCES:%.c=%.o)

%.o:	%.c; $(CC) -DINLINE=inline $(CCINCS) $(CCDEFS) -c $*.c -o $@

all: xhomer

xhomer: $(OBJECTS)
	$(CC) $^ $(CCLIBS) $(CCLINK) -o $@

xhomer.static: $(OBJECTS)
	$(CC) $^ $(CCLIBS) $(CCLINK) $(CCLINKSTATIC) -o $@
	strip $@

date:
	./make_version
	@echo -n "#define PRO_VERSION \"" > pro_version.h
	@echo -n `cat VERSION` >> pro_version.h
	@echo "\"" >> pro_version.h

archive:
	./make_archive

clean:
	-@rm -f *.o *~ xhomer xhomer.static texthomer texthomer.static sdlhomer sdlhomer.static convert_roms

dep depend:
	@egrep -e "# Dependencies" Makefile > /dev/null || \
	echo "# Dependencies" >> Makefile
	sed '/^\#\ Dependencies/q' < Makefile > Makefile.New
	$(CC) -MM $(CCINCS) $(CCDEFS) $(SOURCES) >> Makefile.New
	mv Makefile Makefile.bak
	mv Makefile.New Makefile

##############
# Dependencies
pdp11_cpu.o: src/simh/pdp11_cpu.c src/simh/pdp11_defs.h src/simh/sim_defs.h src/pro_defs.h src/pro_version.h src/pro_config.h
pdp11_fp.o: src/simh/pdp11_fp.c src/simh/pdp11_defs.h src/simh/sim_defs.h src/pro_defs.h src/pro_version.h src/pro_config.h
pdp11_sys.o: src/simh/pdp11_sys.c src/simh/pdp11_defs.h src/simh/sim_defs.h src/pro_defs.h src/pro_version.h src/pro_config.h
pro_2661kb.o: src/pro_2661kb.c src/pdp11_defs.h src/sim_defs.h src/pro_defs.h src/pro_version.h src/pro_config.h
pro_2661ptr.o: src/pro_2661ptr.c src/pdp11_defs.h src/sim_defs.h src/pro_defs.h src/pro_version.h src/pro_config.h
pro_clk.o: src/pro_clk.c src/pdp11_defs.h src/sim_defs.h src/pro_defs.h src/pro_version.h src/pro_config.h
pro_com.o: src/pro_com.c src/pdp11_defs.h src/sim_defs.h src/pro_defs.h src/pro_version.h src/pro_config.h
pro_digipad.o: src/pro_digipad.c src/pdp11_defs.h src/sim_defs.h src/pro_defs.h src/pro_version.h src/pro_config.h
pro_eq.o: src/pro_eq.c src/pdp11_defs.h src/sim_defs.h src/pro_defs.h src/pro_version.h src/pro_config.h
pro_init.o: src/pro_init.c src/pdp11_defs.h src/sim_defs.h src/pro_defs.h src/pro_version.h src/pro_config.h
pro_int.o: src/pro_int.c src/pdp11_defs.h src/sim_defs.h src/pro_defs.h src/pro_version.h src/pro_config.h
pro_kb.o: src/pro_kb.c src/pdp11_defs.h src/sim_defs.h src/pro_defs.h src/pro_version.h src/pro_config.h
pro_la50.o: src/pro_la50.c src/pdp11_defs.h src/sim_defs.h src/pro_defs.h src/pro_version.h src/pro_config.h
pro_lk201.o: src/pro_lk201.c src/pdp11_defs.h src/sim_defs.h src/pro_defs.h src/pro_version.h src/pro_lk201.h src/pro_config.h 
pro_maint.o: src/pro_maint.c src/pdp11_defs.h src/sim_defs.h src/pro_defs.h src/pro_version.h src/pro_config.h
pro_mem.o: src/pro_mem.c src/pdp11_defs.h src/sim_defs.h src/pro_defs.h src/pro_version.h src/pro_config.h
pro_menu.o: src/pro_menu.c src/pdp11_defs.h src/sim_defs.h src/pro_defs.h src/pro_version.h src/pro_lk201.h src/pro_config.h
pro_null.o: src/pro_null.c src/pdp11_defs.h src/sim_defs.h src/pro_defs.h src/pro_version.h src/pro_config.h
pro_ptr.o: src/pro_ptr.c src/pdp11_defs.h src/sim_defs.h src/pro_defs.h src/pro_version.h src/pro_config.h
pro_rd.o: src/pro_rd.c src/pdp11_defs.h src/sim_defs.h src/pro_defs.h src/pro_version.h src/pro_config.h
pro_reg.o: src/pro_reg.c src/pdp11_defs.h src/sim_defs.h src/pro_defs.h src/pro_version.h src/id.h src/pro350.h src/pro_config.h
pro_rx.o: src/pro_rx.c src/pdp11_defs.h src/sim_defs.h src/pro_defs.h src/pro_version.h src/pro_config.h
pro_serial.o: src/pro_serial.c src/pdp11_defs.h src/sim_defs.h src/pro_defs.h src/pro_version.h src/pro_config.h
pro_vid.o: src/pro_vid.c src/pdp11_defs.h src/sim_defs.h src/pro_defs.h src/pro_version.h src/pro_config.h
scp.o: src/simh/scp.c src/sim_defs.h src/pro_defs.h src/pro_version.h src/pro_config.h
scp_tty.o: src/simh/scp_tty.c src/sim_defs.h
term_generic.o: src/term/term_generic.c src/term/term_gfx.h src/pro_defs.h src/pro_version.h src/pro_config.h src/pro_lk201.h
term_curses.o: src/term/term_curses.c src/term/term_gfx.h src/pro_defs.h src/pro_version.h src/pro_lk201.h src/pro_config.h
term_x11.o: src/term/term_x11.c src/term/term_gfx.h src/pro_defs.h src/pro_version.h src/pro_lk201.h src/pro_config.h
term_sdl.o: src/term/term_sdl.c src/term/term_gfx.h src/pro_defs.h src/pro_version.h src/pro_lk201.h src/pro_config.h
  
