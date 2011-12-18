;=======================================================================================
;
; COMMAND LINE PROTRACKER PLAYER FOR FLOS V1.03 by Phil Ruston & Daniel Illgen
;
; Usage: modplay [songname]
;
; Max pattern file size = around 36K
; Max sample file size = 128K
;
; V1.03 - included direct mod-file loading (By Daniel Illgen)
;       - tests for outsize pattern and sample data
;
;=======================================================================================


;---Standard header for OSCA and FLOS --------------------------------------------------

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

fn_ok	ld de,modu_filename		; create extended filename
cpyfn	ld a,(hl)
	or a
	jr z,modex
	cp " "
	jr z,modex
	cp "."
	jr z,modex
	ld (de),a
	inc de
	inc hl
	jr cpyfn
	
modex	ld hl,mod_ext		;append ".mod" to filename
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
	jp nz,load_problem

	ld (filelen),iy		; note the module's filelength
	ld (filelenhi),ix
	ld iy,1084
	ld ix,0
	call kjt_set_load_length
	ld b,0
	ld hl,music_module
	call kjt_force_load		; load the first 1084 bytes of the module
	jp nz,load_problem

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

	ld (pattlen),hl		; length of pattern data part of file
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
	ld (samplelenhi),hl		; length of sample data part of file

	ld hl,music_module		; check pattern and sample sizes
	ld bc,(pattlen)
	add hl,bc
	jp c,pattern_too_big
	ld hl,(samplelenhi)
	ld a,l
	cp 2
	jp nc,samples_too_big

	ld hl,modu_filename		; load pattern data
	call kjt_find_file
	jp nz,load_problem
	ld iy,(pattlen)
	ld ix,0
	call kjt_set_load_length
	ld b,0
	ld hl,music_module
	call kjt_force_load
	jp nz,load_problem
		
	ld iy,(samplelen)		; load samples data
	ld ix,(samplelenhi)
	call kjt_set_load_length
	ld b,3			; bank 3 (audio ram base)
	ld hl,$8000		; address to load to 
	call kjt_force_load
	jp nz,load_problem
	
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

	ld hl,$0f0 		; border colour = green
	ld (palette),hl
	call update_sound_hardware	; update OSCA sound hardware

	ld hl,$f00 		; border colour = red
	ld (palette),hl
	call play_tracker		; main z80 tracker code

	ld hl,$00a		; border colour = blue 
	ld (palette),hl
	call kjt_get_key		; non-waiting key press test
	or a
	jr z,wvrtstart		; loop if no key pressed

	xor a
	out (sys_audio_enable),a	; silence channels
	xor a			; and quit
	ret
	

;---------------------------------------------------------------------------------------------------	

load_problem	

	ld hl,load_error_text+2
	call kjt_hex_byte_to_ascii
	ld hl,load_error_text
	call kjt_print_string
	xor a
	ret

pattern_too_big

	ld hl,pattern_error_text
	call kjt_print_string
	xor a
	ret


samples_too_big

	ld hl,samples_error_text
	call kjt_print_string
	xor a
	ret

			
;---------------------------------------------------------------------------------------------------

nfn_text		db "Modplay version 1.03",11,"Usage: Modplay [modname]",11,0
mod_ext         	db ".MOD",0

load_error_text	db 11,"$xx - loading error!",11,0
mload_text	db 11,"Loading module: ",0
playing_text	db 11,"Playing tune. Any key to quit.",11,11,0
pattern_error_text	db 11,"Pattern data is too big!",11,11,0
samples_error_text	db 11,"Sample data is too big!",11,11,0

filelen         	dw 0
filelenhi       	dw 0
pattlen         	dw 0 
samplelen       	dw 0
samplelenhi     	dw 0

include 		"50Hz_60Hz_Protracker_code_v513.asm"

;-------------------------------------------------------------------------------------------------

modu_filename   	ds 32,0

;-------------------------------------------------------------------------------------------------

	org (($+2)/2)*2		;WORD align song module in RAM

music_module	db 0

;-------------------------------------------------------------------------------------------------
