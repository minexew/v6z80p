;-----------------------------------------------------------------------
;"m" - Show memory as hex bytes command. V6.01
;-----------------------------------------------------------------------

os_cmd_m	

	call ascii_to_hexword	; convert following ascii to address in DE
	cp $c			; if A is $1f on return, use last address (no address)
	ret z			; if A is $c hex address given is bad	
	cp $1f
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
	ld hl,output_line
	push de
	call os_print_string
	pop de
	pop bc
	djnz smbllp
	ld (memmonaddrl),de
	xor a
	ret

;-----------------------------------------------------------------------
