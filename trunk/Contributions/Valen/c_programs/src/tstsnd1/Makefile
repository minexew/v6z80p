# Project specific vars
prjname    = tstsnd1
prjobjects = obj/tstsnd1.o fx_player/obj/fx_player_code.o
# where fx_player code will be located
sound_fx_code = 0xA800

linkopt    = --code-loc 0x5A80  --data-loc 0x8000 -Wl-b_FX_PLAYER_CODE=$(sound_fx_code)
stack      = 0x8000

# Include main makefile
include ../../Makefile_inc

# Project specific rules
obj/tstsnd1.o : tstsnd1.c  fx_player/sound_fx.h fx_player/sound_fx.c
	sdcc -c -o obj/ --std-sdcc99   -mz80   --opt-code-speed --use-stdout  -DSOUND_FX_CODE=$(sound_fx_code) \
        -DOWN_SP=$(stack)  tstsnd1.c

# compile fx_player code to separate segment FX_PLAYER_CODE
fx_player/obj/fx_player_code.o : fx_player/obj/fx_player_code.c
	sdcc -c -o fx_player/obj/ --std-sdcc99   -mz80   --opt-code-speed --use-stdout  \
        --constseg FX_PLAYER_CODE fx_player/obj/fx_player_code.c

# assemble fx_player_code
fx_player/obj/fx_player_code.asm.bin : fx_player/fx_player_code.asm fx_player/inc/fx_player.asm
	echo ; Generated from project Makefile. Dont edit.  >  fx_player/obj/sound_fx_code_address.asm
	echo org  $(sound_fx_code)                          >> fx_player/obj/sound_fx_code_address.asm
	%v6z80pdir%\pasmo\pasmo.exe -d -I %v6z80pdir%\equates          \
        -I fx_player\inc  \
        -I fx_player\demo_data \
        fx_player/fx_player_code.asm fx_player/obj/fx_player_code.asm.bin > fx_player/obj/fx_player_code.asm.out.txt

# convert binary to C include file
fx_player/obj/fx_player_code.c : fx_player/obj/fx_player_code.asm.bin
	echo /* Machine generated. Dont edit. */ const > fx_player/obj/fx_player_code.c
	"../../c_support/tools/xd.exe" -dfx_player_code  fx_player/obj/fx_player_code.asm.bin \
        >> fx_player/obj/fx_player_code.c




