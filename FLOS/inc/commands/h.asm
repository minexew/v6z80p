;-----------------------------------------------------------------------
;"H" - Hunt in memory command V6.10
;-----------------------------------------------------------------------

find_hexstringascii equ scratch_pad+4	; (cmdopstart and cmdopend are at scratchpad+0,scratchpad+2)

os_cmd_h

	call get_start_and_end	; this routine only returns here if start/end data is valid
	
	push hl
	call test_range_valid
	pop hl
	jp c,os_range_error		; abort if end addr <= start addr
	
	call os_scan_for_non_space
	jp z,os_no_args_error

	ld (find_hexstringascii),hl	; address in command string where search bytes start
	ld b,0			; count bytes in string to find
	
	ld a,(hl)			; are we dealing with text or hex?
	cp $22			; quote char?
	jr nz,cntfbyts


;---------Search for text string ------------------------------------------------------------------------


hcchars	inc hl			; search for a text string
	inc b			; b = chars in string
	ld a,(hl)
	or a
	jp z,os_bad_args_error
	cp $22			; string must have closing quotes
	jr nz,hcchars
	dec b
	jp z,os_bad_args_error

	ld de,(cmdop_start_address)	; compare range with ascii string
h_txtlp	ld hl,(find_hexstringascii)
	inc hl			; skip quote
	push bc
	call os_compare_strings
	call c,h_show_hit
	call compare_end_addr
	inc de
	pop bc
	jr nz,h_txtlp
	jr h_end


;---------Search for hex bytes ------------------------------------------------------------------------


cntfbyts	call hexword_or_bust	; the call only returns here if the hex in DE is valid
	jr z,gthexstr
	inc b
	inc hl
	jr cntfbyts
gthexstr	xor a			; b = number of bytes to find
	or b
	jp z,os_no_args_error	

	ld de,(cmdop_start_address)	; start the search
fndloop1	push de
	push de
	pop iy
	ld c,b			; renew length of string counter
	ld hl,(find_hexstringascii)
fcmloop	call ascii_to_hexword	; e holds byte on return
	ld a,(iy)
	cp e
	jr nz,nofmatch
	inc iy
	inc hl
	dec c
	jr nz,fcmloop

	pop de
	call h_show_hit
	push de
	
nofmatch	pop de
	call compare_end_addr
	inc de
	jr nz,fndloop1
	
h_end	jp ok_ret			;OK completion message


;---------------------------------------------------------------------------------------------------

compare_end_addr

	push hl
	ld hl,(cmdop_end_address)
	xor a
	sbc hl,de
	pop hl
	ret
	
;---------------------------------------------------------------------------------------------------
	
h_show_hit

	push de			; show address in DE
	push bc
	call os_show_hex_word
	call os_new_line
	pop bc
	pop de
	ret

;---------------------------------------------------------------------------------------------------
	
		
test_range_valid

	ld hl,(cmdop_end_address)	
	ld de,(cmdop_start_address)
	xor a		
	sbc hl,de
	ret
	
	
;---------------------------------------------------------------------------------------------------	