# Project specific vars
prjname    = fs
prjobjects = obj/fs_walk.rel
linkopt    = --code-loc 0x5A80  --data-loc 0
stack      = 0xffff

# Include main makefile
include ../../Makefile_inc

# Project specific rules
obj/fs_walk.rel : fs_walk.c os_cmd.c os_onexit.c list_view.c user_actions.c config.c util.c display_flos.c display_tilemap.c display.h ../../inc/fs_walk/fs_walk.h
	sdcc -c -o obj/ $(INC) --std-sdcc99  -mz80   --opt-code-speed $(use_stdout)  -DOWN_SP=$(stack) fs_walk.c 



