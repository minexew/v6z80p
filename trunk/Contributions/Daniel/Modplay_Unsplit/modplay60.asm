;=======================================================================================
;
; COMMAND LINE PROTRACKER PLAYER FOR V5Z80P OS
;
; Usage: modplay [songname]
;
; Requires modules to be split into pattern and sample files. The pattern (*.pat) is loaded low
; in memory and the sample file (*.sam) is loaded to upper 128KB (sound accessible RAM)
; Max pattern file size = around 32K
; Max sample file size = 128K
;
; V1.02mod: included direct mod-file loading
;
; V1.02 - This version seperates the positions on the frame where the two parts of the
;         playing process are called, but that is purely for visual clarity (in order to
;         judge the processing times)
;
;=======================================================================================


;---Standard header for V5Z80P and OS ----------------------------------------

include "kernal_jump_table.asm"
include "OSCA_hardware_equates.asm"
include "system_equates.asm"

	org $5000

;=======================================================================================

	ld a,0
	call kjt_forcebank

;--------- Load and init -------------------------------------------------------------------------

fnd_para	ld a,(hl)			; find actual argument text, if encounter 0
	or a			; then give up
	jr z,no_fn
	cp " "			
	jr nz,fn_ok
skp_spc	inc hl
	jr fnd_para
	
no_fn	ld hl,nfn_text
	call kjt_print_string
	xor a
	ret
	
fn_ok	push hl
	call kjt_clear_screen
	pop hl
	
	ld de,modu_filename		; create extended filenames
;	ld de,patt_filename		; create extended filenames
;	ld bc,samp_filename
cpyfn	ld a,(hl)
	or a
	jr z,modex
	cp " "
	jr z,modex
	cp "."
	jr z,modex
	ld (de),a
;	ld (bc),a
	inc de
;	inc bc
	inc hl
	jr cpyfn
	
;patex	ld hl,pat_ext		;append ".pat"
;pexlp	ld a,(hl)
;	or a
;	jr z,samex
;	ld (de),a
;	inc hl
;	inc de
;	jr pexlp
	
;samex	ld hl,sam_ext		;append ".sam"
;samexlp	ld a,(hl)
;	or a
;	jr z,samexdone
;	ld (bc),a
;	inc hl
;	inc bc
;	jr samexlp
;
;samexdone
;	
modex	ld hl,mod_ext		;append ".sam"
modexlp	ld a,(hl)
	or a
	jr z,modexdone
	ld (de),a
	inc hl
	inc de
	jr modexlp

modexdone
	
	ld hl,mload_text
	call kjt_print_string
	ld hl,modu_filename	
	call kjt_print_string
	
	ld hl,modu_filename		; load pattern data
	call kjt_find_file
	jp nz,load_prob

    ld (filelen),iy
    ld (filelenhi),ix

    ld iy,1084
    ld ix,0
    call kjt_set_load_length
    ld b,0
    ld hl,music_module
    call kjt_force_load
    jp nz,load_prob

	ld hl,music_module+952	; find highest used pattern in order to locate 
	ld b,128			; the address where samples start
	ld c,0
pt1	ld a,(hl)	
	cp c
	jr c,ptl
	ld c,a
ptl	inc hl
	djnz pt1
	inc c

	sla c
	sla c
	ld h,c
	ld l,0

    ld bc,1084
    add hl,bc

    ld (pattlen),hl
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
    ld (samplelenhi),hl

    ld hl,modu_filename		; load pattern data
	call kjt_find_file
	jp nz,load_prob

    ld iy,(pattlen)
    ld ix,0
    call kjt_set_load_length

    ld b,0
    ld hl,music_module
    call kjt_force_load
    jp nz,load_prob
		
    ld iy,(samplelen)
    ld ix,(samplelenhi)
    call kjt_set_load_length

	ld b,3			; bank 3 (audio ram base)
	ld hl,$8000		; address to load to 
	call kjt_force_load
	jp nz,load_prob
	
	ld hl,0
	ld (force_sample_base),hl	
	call init_tracker		;initialize mod with forced sample_base

	ld hl,playing_text
	call kjt_print_string

	
;--------- Main loop ---------------------------------------------------------------------	
	
wvrtstart	ld a,(vreg_read)		; wait for VRT
	and 1
	jr z,wvrtstart
wvrtend	ld a,(vreg_read)
	and 1
	jr nz,wvrtend

wait_bord	ld a,(vreg_read)		; wait until raster on screen so we can see how much
	bit 2,a			; time the actual music playing routine is taking
	jr z,wait_bord

	ld hl,$f00 		; border colour = red
	ld (palette),hl
	call play_tracker		; main z80 tracker code
	ld hl,$007 		; border colour = green
	ld (palette),hl



wait_brd2	ld a,(vreg_read)		; wait until the bottom border to see how much time
	bit 2,a			; the register update / V5Z80P conversion is taking
	jr nz,wait_brd2
	
	ld hl,$0f0 		; border colour = green
	ld (palette),hl
	call update_sound_hardware	; update v5z80p sound hardware
	ld hl,$007		; border colour = blue 
	ld (palette),hl


	
	call kjt_get_key		; non-waiting key press test
	or a
	jr z,wvrtstart		; loop if no key pressed

	xor a
	out (sys_audio_enable),a	; silence channels
	xor a			; and quit
	ret
	

; ---------------------------------------------------------------------------------------------------	

	
load_prob	ld hl,error_text+2
	call kjt_hex_byte_to_ascii
	ld hl,error_text
	call kjt_print_string
	xor a
	ret
			
;---------------------------------------------------------------------------------------------------

nfn_text		db "Use: modplay [modname]",11,0
;pat_ext		db ".PAT",0
;sam_ext		db ".SAM",0
mod_ext         db ".MOD",0

error_text	db 11,"$xx - loading error!",11,0
mload_text	db 11,"Loading module: ",0
;pload_text	db 11,"Loading pattern: ",0
;sload_text	db 11,"Loading samples: ",0
playing_text	db 11,"Playing tune. Any key to quit.",11,11,0

filelen         dw 0
filelenhi       dw 0
pattlen         dw 0 
samplelen       dw 0
samplelenhi     dw 0

include 		"valen_Protracker_code_v510.asm"
;include 		"Protracker_code_v510.asm"

;-------------------------------------------------------------------------------------------------

;patt_filename  	ds 32,0
;samp_filename	ds 32,0
modu_filename   ds 32,0

;-------------------------------------------------------------------------------------------------

	org (($+2)/2)*2		;WORD align song module in RAM

music_module	db 0

;-------------------------------------------------------------------------------------------------
