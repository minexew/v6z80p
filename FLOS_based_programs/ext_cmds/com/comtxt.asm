
; COMTXT.EXE - sends characters to the com port
; Usage: com.exe Text_to_send (characters up to first space are sent)

;---Standard header for OSCA and FLOS ----------------------------------------------------------

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


	push hl				;look for end of line
feol	ld a,(hl)
	inc hl
	or a
	jr nz,feol
flc	dec hl				;look for last char 
	ld a,(hl)
	cp $20
	jr nz,flc
	inc hl
	ld (hl),13			;<CR> at end of line
	inc hl
	ld (hl),10
	pop hl
	
comlp	ld a,(hl)
	push hl
	push af
	call kjt_serial_tx_byte
	pop af
	pop hl
	inc hl
	cp 10
	jr nz,comlp
	
	xor a
	ret

;---------------------------------------------------------------------------------------------
