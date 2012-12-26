;=======================================================================================
;
; COMMAND LINE MUSIC .MOD PLAYER FOR FLOS V1.07 
;
; Usage: modplay [?] songname
;
; V1.07 - uses v5.15 version of player code (no limitation on pattern size)
;       - rejects unplayable mods
;
; V1.06 - allow path in filename
;
; V1.05 - Includes Proracker Player 5.14 - Supports large sample range 
;         Requires OSCA v672
;
; V1.04 - If "?" is first arg, show raster time.
;         Quit using normal FLOS error for file not found, load errors ($80 for others)
;
;=======================================================================================


;---Standard header for OSCA and FLOS --------------------------------------------------

include "equates\kernal_jump_table.asm"
include "equates\osca_hardware_equates.asm"
include "equates\system_equates.asm"

          org $5000

;----------------------------------------------------------------------------------------------

required_osca       equ $674
include             "flos_based_programs\code_library\program_header\inc\test_osca_version.asm"

required_flos       equ $610
include             "flos_based_programs\code_library\program_header\inc\test_flos_version.asm"

;---------------------------------------------------------------------------------------------

max_path_length equ 40

          call save_dir_vol
          call modplay
          call restore_dir_vol
          ret

                              
;-------- Parse command line arguments ---------------------------------------------------------
          
modplay   ld a,(hl)			; if no argument string then show use
          or a                          
          jr nz,fn_ok
          
no_fn     ld hl,nfn_text
          call kjt_print_string
          xor a
          ret

fn_ok     cp "?"
          jr nz,no_rast
          ld a,1
          ld (show_raster),a
findnarg  inc hl
          ld a,(hl)
          or a
          jr z,no_fn
          cp $20
          jr z,findnarg
          

no_rast   call extract_path_and_filename
          ld hl,path_txt
          call kjt_parse_path           ; change dir according to the path part of the string
          ret nz

          ld de,filename_txt            ; create extended filename
cpyfn     ld a,(de)
          or a
          jr z,modex
          cp " "
          jr z,modex
          cp "."
          jr z,modex
          ld (de),a
          inc de
          jr cpyfn
          
modex     ld hl,mod_ext                 ; append ".mod" to filename
          ld de,4
          ld bc,4
          ldir
modexdone

;--------- Init Player --------------------------------------------------------------------------


	  ld iy,filename_txt		; load module
	  ld hl,pt_module_loc_lo
	  ld a,pt_module_loc_hi
	  call load_flat
	  ret nz
	 
          call pt_init                  ; initialize tune
	  jr z,init_ok
	  ld hl,badmod_text
	  call kjt_print_string
	  xor a
	  ret
	  
init_ok   ld hl,playing_text
          call kjt_print_string

          call kjt_get_colours
          inc hl
          inc hl
          ld e,(hl)
          inc hl
          ld d,(hl)
          ld (orig_border_colour),de
 
         
	 
;--------- Main loop ---------------------------------------------------------------------          
         
 
wvrtstart ld a,(vreg_read)              ; wait for VRT
          and 1
          jr z,wvrtstart
wvrtend   ld a,(vreg_read)
          and 1
          jr nz,wvrtend



wait_bord in a,(sys_vreg_read)          ; wait until raster on screen so we can see how much
          bit 2,a                       ; time the actual music playing routine is taking
          jr z,wait_bord

          ld hl,$0f0                    ; border colour = green
          call change_border
          call osca_play_tracker        ; update OSCA sound hardware

          ld hl,(orig_border_colour)    ; border colour = blue 
          call change_border
          call kjt_get_key              ; non-waiting key press test
          or a
          jr z,wvrtstart                ; loop if no key pressed

          ld a,1                        ; restore audio high registers to $01 for backward
          out (audchan0_loc_hi),a       ; compatibility
          out (audchan1_loc_hi),a
          out (audchan2_loc_hi),a
          out (audchan3_loc_hi),a
          
	  call osca_silence		; hush all channels on exit
	  ret
          
;--------------------------------------------------------------------------------------------

change_border

          ld a,(show_raster)
          or a
          ret z
          ld (palette),hl
          ret
          
;---------------------------------------------------------------------------------------------------          

show_raster         db 0
orig_border_colour  dw 0

nfn_text            db "Modplay version 1.07",11,"Usage: MODPLAY [?] filename",11,0
mod_ext             db ".MOD",0

mload_text          db 11,"Loading module: ",0
playing_text        db 11,"Playing tune. Any key to quit.",11,11,0

badmod_text	    db "Incompatible module type!",11,0

;--------------------------------------------------------------------------------------

include "FLOS_based_programs\code_library\string\inc\extract_path_and_filename.asm"

include "FLOS_based_programs\code_library\loading\inc\save_restore_dir_vol.asm"

include "FLOS_based_programs\code_library\loading\inc\load_save_flat.asm"

include "FLOS_based_programs\code_library\protracker_player\inc\osca_modplayer_v515.asm"

;-------------------------------------------------------------------------------------------------

pt_module_loc_hi	equ 0

          org ($+1) & $FFFE  ; WORD align song module in RAM

pt_module_loc_lo	db 0

;-------------------------------------------------------------------------------------------------
