# Project specific vars
prjname    = tstgfx3
prjobjects = obj/tstgfx3.o 
linkopt    = --code-loc 0x5A80  --data-loc 0xA000
stack      = 0xFFFF

# Include main makefile
include ../../Makefile_inc

# Project specific rules
obj/tstgfx3.o : tstgfx3.c
	sdcc -c -o obj/ --std-sdcc99   -mz80   --opt-code-speed --use-stdout  -DOWN_SP=$(stack) tstgfx3.c 


