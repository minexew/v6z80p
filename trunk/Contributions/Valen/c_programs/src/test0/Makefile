# Project specific vars
prjname    = test0
prjobjects = obj/test0.rel
linkopt    = --code-loc 0x5A80  --data-loc 0
stack      = 0xffff

# Include main makefile
include ../../Makefile_inc

# Project specific rules
obj/test0.rel : test0.c 
	sdcc -c -o obj/ $(INC) --std-sdcc99   -mz80   --opt-code-speed --use-stdout  -DOWN_SP=$(stack) test0.c 



