# Project specific vars
prjname    = tstgfx3
prjobjects = obj/tstgfx3.rel 
linkopt    = --code-loc 0x5A80  --data-loc 0
stack      = 0xFFFF

# Include main makefile
include ../../Makefile_inc

# Project specific rules
obj/tstgfx3.rel : tstgfx3.c ../lib/sprites.c
	sdcc -c -o obj/ $(INC) --std-sdcc99   -mz80   --opt-code-speed $(use_stdout)  -DOWN_SP=$(stack) tstgfx3.c 


