;-----------------------------------------------------------------------
;"?" - List commands. V6.04
;-----------------------------------------------------------------------

os_cmd_list			;"?" - display command list

	ld hl,packed_cmd_list
cmdlstlp	call os_show_packed_text
	inc hl
	ld a,(hl)
	cp $ff
	jr nz,cmdlstlp
	xor a
	ret
		
	
;-----------------------------------------------------------------------
	