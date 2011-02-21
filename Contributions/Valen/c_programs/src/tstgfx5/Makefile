# Project specific vars
prjname    = tstgfx5
prjobjects = obj/tstgfx5.rel 
linkopt    = --code-loc 0x5A80  --data-loc 0
stack      = 0xFFFF

# Include main makefile
include ../../Makefile_inc

# Project specific rules
obj/tstgfx5.rel : tstgfx5.c ../lib/sprites.c ../lib/mouse.c
	sdcc -c -o obj/ $(INC) --std-sdcc99   -mz80   --opt-code-speed $(use_stdout)  -DOWN_SP=$(stack) tstgfx5.c 


