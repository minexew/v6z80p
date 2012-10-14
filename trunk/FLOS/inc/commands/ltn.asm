;-----------------------------------------------------------------------------------------
; OS "<" Command: Update mem hex bytes and re-disassemble v6.03
;------------------------------------------------------------------------------------------

os_cmd_ltn:

	ld a,(cursor_y)
	ld (scratch_pad),a
	call hexword_or_bust	;the call only returns here if the hex in DE is valid
	jp z,os_no_args_error	;if no address followed the "<" quit
	push de
	pop ix			;ix is now dest for bytes
	ld (DISADD),de	
				
hexbtmlp	ld b,255
	dec hl			;hl = source text			
nsplp	inc b
	inc hl			
	ld a,(hl)			
	or a			
	jr z,redisa		
	cp " "
	jr z,nsplp
	ld a,b			;if 2 consecutive spaces encountered, end the byte copy
	cp 2
	jr nc,redisa
	call ascii_to_hexw_no_scan	;copy hex bytes from line to RAM
	cp $c
	jp z,os_no_args_error
	ld (ix),e
	inc ix
	jr hexbtmlp

redisa	ld a,(cursor_y)
	dec a
	ld (cursor_y),a
	
	ld b,20
ltndlp	push bc
	ld hl,mdis_txt
	call os_print_string	; show "> "
	ld de,(DISADD)
	call z80dis_jk
	ld (DISADD),de		; new location
	call os_new_line
	pop bc
	djnz ltndlp
	
	ld a,(scratch_pad)		;put cursor back to a useful position
	cp OS_window_rows-20	;IE: compare with rows - lines displayed
	jr c,lcposok
	ld a,5
lcposok	ld c,a
	ld b,7
	ld (cursor_y),bc

	xor a
	ret


;------------------------------------------------------------------------------------------
	