# Project specific vars
prjname    = tstgfx2
prjobjects = obj/tstgfx2.rel 
linkopt    = --code-loc 0x5A80  --data-loc 0
stack      = 0xFFFF

# Include main makefile
include ../../Makefile_inc

# Project specific rules
obj/tstgfx2.rel : tstgfx2.c object_32x28.c
	sdcc -c -o obj/ $(INC) --std-sdcc99   -mz80   --opt-code-speed $(use_stdout)  -DOWN_SP=$(stack) tstgfx2.c 


object_32x28.c : data/object_32x28.bin data/object_palette.bin
	echo /* Machine generated. Dont edit. */ const > object_32x28.c
	"../../c_support/tools/xd.exe" -dobject_32x28_pixels data/object_32x28.bin >> object_32x28.c
	echo const >> object_32x28.c
	"../../c_support/tools/xd.exe" -dobject_32x28_palette data/object_palette.bin >> object_32x28.c



