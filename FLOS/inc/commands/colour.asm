;-----------------------------------------------------------------------------------------
;"Colour" - Change UI colours v6.04
;-----------------------------------------------------------------------------------------

os_cmd_colour

	call os_scan_for_non_space		;find save length
	or a
	jp z,os_no_args_error

	ld b,4
	ld ix,current_pen
	
chcollp	call hexword_or_bust		;the call only returns here if the hex in DE is valid
	jr z,colrdone			;any more data?
	inc hl
	ld (ix),e
	ld (ix+1),d
	inc ix
	inc ix
	djnz chcollp
	
colrdone	ld a,b				;dont update the colour list of only arg was pen colour
	cp 3
	ret z
	call default_colours		;this command changes the *default* FLOS colours
	xor a				;so will persist until the system is reset
	ret

;------------------------------------------------------------------------------------------
