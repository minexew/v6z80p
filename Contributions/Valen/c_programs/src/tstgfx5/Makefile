# Project specific vars
prjname    = tstgfx5
prjobjects = obj/tstgfx5.o 
linkopt    = --code-loc 0x5A80  --data-loc 0xA000
stack      = 0xFFFF

# Include main makefile
include ../../Makefile_inc

# Project specific rules
obj/tstgfx5.o : tstgfx5.c ../lib/sprites.c ../lib/mouse.c
	sdcc -c -o obj/ --std-sdcc99   -mz80   --opt-code-speed --use-stdout  -DOWN_SP=$(stack) tstgfx5.c 


