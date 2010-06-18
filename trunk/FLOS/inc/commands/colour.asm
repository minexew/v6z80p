;-----------------------------------------------------------------------
;"Colour" - Change UI colours
;-----------------------------------------------------------------------

os_cmd_colour:

	ld b,4
	ld ix,current_pen
	
chcollp	call ascii_to_hexword	;get find start address
	cp $c
	ret z
	cp $1f
	jr z,colrdone
	inc hl
	ld (ix),e
	ld (ix+1),d
	inc ix
	inc ix
	djnz chcollp

colrdone	call os_set_ui_colours	
	xor a
	ret

;-----------------------------------------------------------------------
