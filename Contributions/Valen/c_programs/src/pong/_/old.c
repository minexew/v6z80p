# ---> Begin Sound FX
# SOUND_FX interface for C  (object file)
sound_fx/obj/sound_fx_code.o : sound_fx/sound_fx_code.c
	sdcc -c -o sound_fx/obj/ --std-sdcc99  -mz80   --opt-code-speed --use-stdout --constseg SOUND_FX_CODE \
	sound_fx/sound_fx_code.c
# SOUND_FX interface - asm proxy 
# C source file <-- binary file <-- pasmo .asm files
sound_fx/sound_fx_code.c : sound_fx/sfx_proxy.asm sound_fx/inc/sfx_routine.asm
	%v6z80pdir%\pasmo\pasmo.exe -d -I %v6z80pdir%\equates          \
        -I sound_fx\inc  \
        -I sound_fx\data \
        sound_fx/sfx_proxy.asm sound_fx/sfx_proxy.asm.bin > sound_fx/a
# Generate C source from binary file
	echo /* Machine generated. Dont edit. */ const > sound_fx/sound_fx_code.c
	$(basedir)/c_support/tools/xd.exe -dsound_fx_code sound_fx/sfx_proxy.asm.bin >> sound_fx/sound_fx_code.c
# this line is for copy to my z: disk, you can remove this line
	copy sound_fx\sfx_proxy.asm.bin z:\
# <--- End Sound FX
