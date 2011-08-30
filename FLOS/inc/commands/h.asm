;-----------------------------------------------------------------------
;"H" - Hunt in memory command V6.06
;-----------------------------------------------------------------------

os_cmd_h

	call get_start_and_end	;this routine only returns here if start/end data is valid
	
	push hl
	ld hl,(cmdop_start_address)
	xor a			
	sbc hl,de
	pop hl
	jp nc,os_range_error	;abort if end addr <= start addr
	
	ld (find_hexstringascii),hl	;address in command string where search bytes start
	ld b,0			;count bytes in string to find
cntfbyts	call hexword_or_bust	;the call only returns here if the hex in DE is valid
	jr z,gthexstr
	inc b
	inc hl
	jr cntfbyts
gthexstr	ld a,b
	or b
	jp z,os_no_args_error	

	ld ix,(cmdop_start_address)	;start the search
fndloop1	push ix
	pop iy
	ld c,b			;renew length of string counter
	ld hl,(find_hexstringascii)
fcmloop	call ascii_to_hexword	;e holds byte on return
	ld a,(iy)
	cp e
	jr nz,nofmatch
	inc iy
	inc hl
	dec c
	jr nz,fcmloop

	push ix			;complete match found, show address
	pop de			;get address in DE
	push ix
	push bc
	call os_show_hex_word
	call os_new_line
	pop bc
	pop ix
	
nofmatch	inc ix
	push ix
	pop de
	ld a,(cmdop_end_address)
	cp e
	jr nz,fndloop1
	ld a,(cmdop_end_address+1)
	cp d
	jr nz,fndloop1
	
	jp ret_ok_msg		;OK completion message


;-----------------------------------------------------------------------
