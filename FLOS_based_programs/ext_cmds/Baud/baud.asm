
; BAUD [speed] command - sets baud rate - v0.01 By Phil '09
;
;---Standard header for OSCA and FLOS ----------------------------------------------------------

include "kernal_jump_table.asm"
include "osca_hardware_equates.asm"
include "system_equates.asm"

	org $5000

;------------------------------------------------------------------------------------------------

fnd_param	ld a,(hl)			; examine argument text, if encounter 0: give up
	or a			
	jr z,no_param
	cp " "			; ignore leading spaces...
	jr nz,par_ok
skp_spc	inc hl
	jr fnd_param

par_ok	ld (args_start),hl
	ld de,baudslow_txt		;what baud rate was requested?
	ld b,5
	call kjt_compare_strings
	jr nc,nbaud1
	ld hl,txt_57600
	xor a
	jr bauddn	
	
nbaud1	ld de,baudfast_txt		
	ld hl,(args_start)
	ld b,6
	call kjt_compare_strings
	jr nc,nbaud2

	call kjt_get_version	;check hardware version
	ld hl,$266-1		;hardware revision required for 115200 BAUD
	xor a
	sbc hl,de
	jr nc,nbaud2
	ld hl,txt_115200
	ld a,1
bauddn	out (sys_baud_rate),a
	call kjt_print_string
	xor a
	ret
	

nbaud2	xor a					
	ld hl,bad_baud_txt			;unknown args/unsupported baud rate
	call kjt_print_string
	xor a
	ret

no_param	ld hl,no_param_txt
	call kjt_print_string
	xor a
	ret
	

;------------------------------------------------------------------------------------------------

args_start	dw 0

baudslow_txt	db "57600",0
baudfast_txt	db "115200",0
	
txt_57600		db "BAUD set at 57600",11,0
txt_115200	db "BAUD set at 115200",11,0
bad_baud_txt	db "Unsupported baud rate!",11,0

no_param_txt	db "Usage: BAUD [57600] [115200]",11,0

;------------------------------------------------------------------------------------------------
