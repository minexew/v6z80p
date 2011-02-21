# Project specific vars
prjname    = pong
prjobjects = obj/pong.rel  obj/low_memory_container.rel 
prjbinaries = sound_fx/sfx_proxy.asm.bin
linkopt    = -Wl-b_LOW_MEM_CODE=0x6A80    --code-loc 0x8000  --data-loc 0xE000   
# -Wl-b_SOUND_FX_CODE=0x6A80
# stack: 5A80 - 6A80
stack      = 0x6A80

# Include main makefile
include ../../Makefile_inc

# Project specific rules
obj/pong.rel : pong.h v6assert.h util.h sprites.h disk_io.h loading_icon.h obj_.h obj_anim.h obj_score.h obj_rocket.h obj_bat.h obj_ball.h obj_youwin.h obj_gamemenu.h sound_fx/sound_fx.h low_memory_container.h pong.c v6assert.c math.c sprites.c background.c keyboard.c joystick.c ai.c disk_io.c loading_icon.c util.c obj_.c obj_anim.c obj_score.c obj_rocket.c obj_ball.c obj_youwin.c obj_bat.c obj_gamemenu.c pool_gameobj.c pool_sprites.c sound_fx/sound_fx.c debug.c low_memory_container.c
	sdcc  -c -o obj/ $(INC) --std-sdcc99   -mz80   --opt-code-speed $(use_stdout)  -DOWN_SP=$(stack) --verbose pong.c 


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