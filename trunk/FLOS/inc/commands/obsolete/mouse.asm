;-----------------------------------------------------------------------------------------------
; "MOUSE" = Init mouse driver and activate pointer v6.01
;-----------------------------------------------------------------------------------------------

os_cmd_mouse

	ld hl,OS_window_cols*8
	ld de,OS_window_rows*8
	call os_init_mouse
	or a
	jr z,minit_ok
	ld hl,no_mouse_msg
	call os_show_packed_text
	xor a
	ret
	
minit_ok	ld a,1
	ld (use_mouse_pointer),a
	ld hl,mouse_enabled_msg
	call os_show_packed_text
	xor a
	ret

;-----------------------------------------------------------------------------------------------
	