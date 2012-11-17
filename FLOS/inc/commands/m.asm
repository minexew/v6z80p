;-----------------------------------------------------------------------
;"m" - Show memory as hex bytes command. V6.03
;-----------------------------------------------------------------------

os_cmd_m	

	call hexword_or_bust	;the call only returns here if the hex in DE is valid
	jr nz,validhex
	ld de,(memmonaddrl)

validhex:	ld b,16			;shows 16 lines of bytes
smbllp:	push bc			;starting from current cursor position
	ld hl,output_line		;input: de = address
	ld (hl),":"
	inc hl
	ld (hl)," "
	inc hl
	call hexword_to_ascii
	ld b,8
mmbllp:	ld (hl)," "
	inc hl
	ld a,(de)	
	call hexbyte_to_ascii
	inc de
	djnz mmbllp
	ld (hl),11
	inc hl
	ld (hl),0
	call os_print_output_line
	pop bc
	djnz smbllp
	ld (memmonaddrl),de
	xor a
	ret

;-----------------------------------------------------------------------
