;-----------------------------------------------------------------------
;"?" - List commands. V6.03
;-----------------------------------------------------------------------

os_cmd_help			;"?" - display help text

	ld hl,packed_help1
	call show_wait
	call show_wait
	jr show_page

	
show_page	call os_show_packed_text
	push hl
	call os_new_line
	pop hl
	inc hl			;skip end of line byte ($00)
	ld a,(hl)
	cp $ff			;last line in help file
	jr nz,show_page
	xor a
	ret
	
	
show_wait	call show_page
		
wait_page	push hl
	call os_wait_key_press
	pop hl
	inc hl
	ret
	
	
;-----------------------------------------------------------------------
	