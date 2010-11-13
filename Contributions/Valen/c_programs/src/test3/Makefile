# Project specific vars
prjname    = test3
prjobjects = obj/test3.rel
linkopt    = --code-loc 0x5A80  --data-loc 0
stack      = 0xffff

# Include main makefile
include ../../Makefile_inc

# Project specific rules
obj/test3.rel : test3.c 
	sdcc -c -o obj/ $(INC) --std-sdcc99   -mz80   --opt-code-speed --use-stdout  -DOWN_SP=$(stack) test3.c 



