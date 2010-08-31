
; BAUD [speed] command - sets baud rate - v0.02 By Phil '09

;-----------------------------------------------------------------------------------------------
; Standard header for OSCA and FLOS 
;-----------------------------------------------------------------------------------------------

include "kernal_jump_table.asm"
include "osca_hardware_equates.asm"
include "system_equates.asm"

;----------------------------------------------------------------------------------------------------
; As this is an external command, load program high in memory to help avoid overwriting user programs
;----------------------------------------------------------------------------------------------------

my_location	equ $8000
my_bank		equ $0c

	org my_location	; desired load address
	
load_loc	db $ed,$00	; header ID (Invalid, safe Z80 instruction)
	jr exec_addr	; jump over remaining header data
	dw load_loc	; location file should load to
	db my_bank	; upper bank the file should load to
	db 0		; no truncating required

exec_addr	

;-------------------------------------------------------------------------------------------------
; Test FLOS version 
;-------------------------------------------------------------------------------------------------

required_flos equ $568

	push hl
	di			; temp disable interrupts so stack cannot be corrupted
	call kjt_get_version
true_loc	exx
	ld ix,0		
	add ix,sp			; get SP in IX
	ld l,(ix-2)		; HL = PC of true_loc from stack
	ld h,(ix-1)
	ei
	exx
	ld de,required_flos
	xor a
	sbc hl,de
	pop hl
	jr nc,flos_ok
	exx
	push hl			;show FLOS version required
	ld de,old_fth-true_loc
	add hl,de			;when testing location references must be PC-relative
	ld de,required_flos		
	ld a,d
	call kjt_hex_byte_to_ascii
	ld a,e
	call kjt_hex_byte_to_ascii
	pop hl
	ld de,old_flos_txt-true_loc
	add hl,de	
	call kjt_print_string
	xor a
	ret

old_flos_txt

        db "Error: Requires FLOS version $"
old_fth db "xxxx+",11,11,0

flos_ok

;------------------------------------------------------------------------------------------------
; Actual program starts here..
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
