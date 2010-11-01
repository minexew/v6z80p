;-----------------------------------------------------------------------------------------
;"Colour" - Change UI colours v6.02
;-----------------------------------------------------------------------------------------

os_cmd_colour

	call os_scan_for_non_space		;find save length
	or a
	jp z,os_no_args_error

	ld b,4
	ld ix,current_pen
	
chcollp	call hexword_or_bust	;the call only returns here if the hex in DE is valid
	jr z,colrdone		;any more data?
	inc hl
	ld (ix),e
	ld (ix+1),d
	inc ix
	inc ix
	djnz chcollp

colrdone	call os_set_ui_colours	
	xor a
	ret

;------------------------------------------------------------------------------------------
