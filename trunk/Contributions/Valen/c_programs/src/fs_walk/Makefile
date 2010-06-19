# Project specific vars
prjname    = fs_walk
prjobjects = obj/fs_walk.o
linkopt    = --code-loc 0x5A80  --data-loc 0x8280
stack      = 0xffff

# Include main makefile
include ../../Makefile_inc

# Project specific rules
obj/fs_walk.o : fs_walk.c os_cmd.c os_onexit.c list_view.c user_actions.c config.c util.c ../../inc/fs_walk/fs_walk.h
	sdcc -c -o obj/ --std-sdcc99  -mz80   --opt-code-speed --use-stdout  -DOWN_SP=$(stack) fs_walk.c 



