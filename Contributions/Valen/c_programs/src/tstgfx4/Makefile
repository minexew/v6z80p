# Project specific vars
prjname    = tstgfx4
prjobjects = obj/tstgfx4.rel 
linkopt    = --code-loc 0x5A80  --data-loc 0
stack      = 0xFFFF

# Include main makefile
include ../../Makefile_inc

# Project specific rules
obj/tstgfx4.rel : tstgfx4.c ../lib/sprites.c
	sdcc -c -o obj/ $(INC) --std-sdcc99   -mz80   --opt-code-speed --use-stdout  -DOWN_SP=$(stack) tstgfx4.c 


