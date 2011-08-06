# Project specific vars
prjname    = pong
prjobjects = obj/pong.rel \
             obj/util.rel obj/sprites.rel obj/disk_io.rel  obj/loading_icon.rel \
             obj/obj_.rel \
             obj/obj_anim.rel obj/obj_score.rel obj/obj_rocket.rel obj/obj_bat.rel \
             obj/obj_ball.rel obj/obj_youwin.rel obj/obj_gamemenu.rel \
             obj/v6assert.rel obj/math.rel obj/background.rel \
             obj/keyboard.rel obj/joystick.rel obj/ai.rel \
             obj/pool_gameobj.rel obj/pool_sprites.rel \
             obj/data_loader.rel obj/debug.rel \
             obj/sound_fx.rel \
             obj/low_memory_container.rel 
prjbinaries = sound_fx/sfx_proxy.asm.bin
linkopt    = -Wl-b_LOW_MEM_CODE=0x6A80    --code-loc 0x8000  --data-loc 0
# -Wl-b_SOUND_FX_CODE=0x6A80
# stack: 5A80 - 6A80
stack      = 0x6A80

# uncomment next line to redirect all sdcc output to stdout (this is just for windows shell)
# use_stdout = "--use-stdout"

# Include main makefile
include ../../Makefile_inc

# Project specific rules

obj/pong.rel            : pong.c pong.h
obj/util.rel            : util.c util.h
obj/sprites.rel         : sprites.c sprites.h
obj/disk_io.rel         : disk_io.c disk_io.h
obj/loading_icon.rel    : loading_icon.c loading_icon.h
obj/obj_.rel            : obj_.c obj_.h
obj/obj_anim.rel        : obj_anim.c obj_anim.h
obj/obj_score.rel       : obj_score.c obj_score.h
obj/obj_rocket.rel      : obj_rocket.c obj_rocket.h
obj/obj_bat.rel         : obj_bat.c obj_bat.h
obj/obj_ball.rel        : obj_ball.c obj_ball.h
obj/obj_youwin.rel      : obj_youwin.c obj_youwin.h
obj/obj_gamemenu.rel    : obj_gamemenu.c obj_gamemenu.h
obj/v6assert.rel        : v6assert.c v6assert.h
obj/math.rel            : math.c math.h
obj/background.rel      : background.c background.h
obj/keyboard.rel        : keyboard.c keyboard.h
obj/joystick.rel        : joystick.c joystick.h
obj/ai.rel              : ai.c ai.h
obj/pool_gameobj.rel    : pool_gameobj.c pool_gameobj.h
obj/pool_sprites.rel    : pool_sprites.c pool_sprites.h
obj/data_loader.rel     : data_loader.c data_loader.h
obj/debug.rel           : debug.c debug.h
obj/sound_fx.rel        : sound_fx/sound_fx.c sound_fx/sound_fx.h









obj/low_memory_container.rel : low_memory_container.c low_memory_container.h sound_fx/sound_fx.h pong.h
	sdcc -c -o obj/ $(INC) --std-sdcc99  -mz80   --opt-code-speed $(use_stdout)    --codeseg LOW_MEM_CODE low_memory_container.c


# ---> Begin Sound FX
# SOUND_FX interface - asm proxy 
# binary file <-- pasmo .asm files
sound_fx/sfx_proxy.asm.bin : sound_fx/sfx_proxy.asm sound_fx/inc/sfx_routine.asm
	%v6z80pdir%\pasmo\pasmo.exe -d -I %v6z80pdir%\equates          \
        -I sound_fx\inc  \
        -I sound_fx\data \
        sound_fx/sfx_proxy.asm sound_fx/sfx_proxy.asm.bin > sound_fx/a
# this line is for copy to my z: disk, you can remove this line
	copy sound_fx\sfx_proxy.asm.bin z:\\
# <--- End Sound FX



obj/%.rel : %.c
	sdcc  -c -o obj/ $(INC) --std-sdcc99   -mz80   --opt-code-speed $(use_stdout)  -DOWN_SP=$(stack) --verbose $< 
obj/%.rel : sound_fx/%.c
	sdcc  -c -o obj/ $(INC) --std-sdcc99   -mz80   --opt-code-speed $(use_stdout)  -DOWN_SP=$(stack) --verbose $< 