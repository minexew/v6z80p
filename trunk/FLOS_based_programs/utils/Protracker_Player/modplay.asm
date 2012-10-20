;=======================================================================================
;
; COMMAND LINE PROTRACKER PLAYER FOR FLOS V1.06 by Phil Ruston & Daniel Illgen
;
; Usage: modplay [?] songname
;
; Max pattern file size = approx 37K
; Max sample file size = 448KB
;
; V1.06 - allowe path in filename
;
; V1.05 - Includes Proracker Player 5.14 - Supports large sample range 
;         Requires OSCA v672
;
; V1.04 - If "?" is first arg, show raster time.
;         Quit using normal FLOS error for file not found, load errors ($80 for others)
;
; V1.03 - included direct mod-file loading (By Daniel Illgen)
;       - tests for outsize pattern and sample data
;
;=======================================================================================


;---Standard header for OSCA and FLOS --------------------------------------------------

include "equates\kernal_jump_table.asm"
include "equates\osca_hardware_equates.asm"
include "equates\system_equates.asm"

          org $5000

;----------------------------------------------------------------------------------------------

required_osca       equ $672
include             "flos_based_programs\code_library\program_header\inc\test_osca_version.asm"

required_flos       equ $607
include             "flos_based_programs\code_library\program_header\inc\test_flos_version.asm"

;---------------------------------------------------------------------------------------------

max_path_length equ 40

          call save_dir_vol
          call modplay
          call restore_dir_vol
          ret
                              
;-------- Parse command line arguments ---------------------------------------------------------
          
modplay   ld a,0
          call kjt_forcebank

;--------- Load and init -------------------------------------------------------------------------

fnd_para  ld a,(hl)                     ; find actual argument text, if encounter 0
          or a                          ; then show use
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
          
modex     ld hl,mod_ext                 ;append ".mod" to filename
          ld de,4
          ld bc,4
          ldir

modexdone
          
          ld hl,filename_txt            ; find module
          call kjt_find_file
          ret nz

          ld hl,mload_text              ; show "loading.."
          call kjt_print_string
          ld hl,filename_txt  
          call kjt_print_string


          ld (filelen),iy               ; note the module's filelength
          ld (filelenhi),ix
          ld iy,1084
          ld ix,0
          call kjt_set_load_length
          ld b,0
          ld hl,music_module
          call kjt_force_load           ; load the first 1084 bytes of the module
          ret nz

          ld hl,music_module+952        ; find highest used pattern in order to locate 
          ld b,128                      ; the address where samples start
          ld c,0
pt1       ld a,(hl) 
          cp c
          jr c,ptl
          ld c,a
ptl       inc hl
          djnz pt1
          inc c

          sla c
          sla c
          ld h,c
          ld l,0

          ld bc,1084
          add hl,bc

          ld (pattlen),hl               ; length of pattern data part of file
          ld b,h
          ld c,l
          ld hl,(filelen)
          ccf
          sbc hl,bc
          ld (samplelen),hl
          ld b,0
          ld c,0
          ld hl,(filelenhi)
          sbc hl,bc
          ld (samplelenhi),hl           ; length of sample data part of file

          ld hl,music_module            ; check pattern and sample sizes
          ld bc,(pattlen)
          add hl,bc
          jp c,pattern_too_big
          
          ld hl,(samplelenhi)
          ld a,l
          cp 7
          jp nc,samples_too_big

          ld hl,filename_txt            ; load pattern data
          call kjt_find_file
          ret nz
          ld iy,(pattlen)
          ld ix,0
          call kjt_set_load_length
          ld b,0
          ld hl,music_module
          call kjt_force_load
          ret nz
                    
          ld iy,(samplelen)             ; load samples data to $10000
          ld ix,(samplelenhi)
          call kjt_set_load_length
          ld b,1                        ; bank 1
          ld hl,$8000                   ; address $8000 
          call kjt_force_load
          ret nz
          
          ld a,$01
          ld hl,$0000
          call pt_set_sample_base       ;set sample_base to $10000 in player
          
          call pt_init                  ;initialize tune

          ld hl,playing_text
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
          
          xor a
          out (sys_audio_enable),a      ; silence channels
          ret
          
;--------------------------------------------------------------------------------------------

change_border

          ld a,(show_raster)
          or a
          ret z
          ld (palette),hl
          ret
          
;---------------------------------------------------------------------------------------------------          


pattern_too_big

          ld hl,pattern_error_text
          call kjt_print_string
          ld a,$80
          or a
          ret


samples_too_big

          ld hl,samples_error_text
          call kjt_print_string
          ld a,$80
          or a
          ret

                              
;---------------------------------------------------------------------------------------------------

show_raster         db 0
orig_border_colour  dw 0

nfn_text            db "Modplay version 1.06",11,"Usage: MODPLAY [?] [fileame]",11,0
mod_ext             db ".MOD",0

mload_text          db 11,"Loading module: ",0
playing_text        db 11,"Playing tune. Any key to quit.",11,11,0
pattern_error_text  db 11,"Pattern data is too long!",11,11,0
samples_error_text  db 11,"Sample data is too long!",11,11,0

filelen             dw 0
filelenhi           dw 0
pattlen             dw 0 
samplelen           dw 0
samplelenhi         dw 0


;--------------------------------------------------------------------------------------

include "FLOS_based_programs\code_library\string\inc\extract_path_and_filename.asm"

include "FLOS_based_programs\code_library\loading\inc\save_restore_dir_vol.asm"

include "FLOS_based_programs\code_library\protracker_player\inc\Protracker_code_v514.asm"

;-------------------------------------------------------------------------------------------------

          org (($+2)/2)*2               ;WORD align song module in RAM

music_module        db 0

;-------------------------------------------------------------------------------------------------
