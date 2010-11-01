;-----------------------------------------------------------------------
;"T" - Show memory as ascii text command. V6.03
;-----------------------------------------------------------------------

os_cmd_t:	
	
	call hexword_or_bust	;the call only returns here if the hex in DE is valid
	jr nz,unaddr
	ld de,(memmonaddrl)

unaddr:	ld b,16
smaalp:	push bc
	ld hl,output_line		;input: de = address
	ld (hl),'>'
	inc hl
	ld (hl)," "
	inc hl
	call hexword_to_ascii
	ld (hl)," "
	inc hl
	ld (hl),$22
	ld b,16
mabllp:	inc hl
	ld a,(de)	
	cp $20
	jr c,chchar
	cp $7f
	jr c,nchchar
chchar:	ld a,$7c
nchchar:	ld (hl),a
	inc de
	djnz mabllp
	ld (memmonaddrl),de
	inc hl
	ld (hl),$22
	inc hl
	ld (hl),11
	inc hl
	ld (hl),0
	call os_print_output_line
	ld de,(memmonaddrl)
	pop bc
	djnz smaalp
	xor a
	ret
	
;-----------------------------------------------------------------------
