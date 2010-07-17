# Project specific vars
prjname    = test1
prjobjects = obj/test1.o
linkopt    = --code-loc 0x5A80  --data-loc 0x7800
stack      = 0xffff

# Include main makefile
include ../../Makefile_inc

# Project specific rules
obj/test1.o : test1.c 
	sdcc -c -o obj/ --std-sdcc99   -mz80   --opt-code-speed --use-stdout  -DOWN_SP=$(stack) test1.c 



