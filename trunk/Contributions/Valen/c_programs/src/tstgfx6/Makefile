# Project specific vars
prjname    = tstgfx6
prjobjects = obj/tstgfx6.o 
linkopt    = --code-loc 0x5A80  --data-loc 0
stack      = 0xFFFF

# Include main makefile
include ../../Makefile_inc

# Project specific rules
obj/tstgfx6.o : tstgfx6.c
	sdcc -c -o obj/ --std-sdcc99   -mz80   --opt-code-speed --use-stdout  -DOWN_SP=$(stack) tstgfx6.c 


