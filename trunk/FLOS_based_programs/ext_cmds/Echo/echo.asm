
; ECHO.EXE - Shows a line of text
; Usage: echo.exe Text_to_display

;---Standard header for OSCA and FLOS ----------------------------------------------------------

include "kernal_jump_table.asm"
include "osca_hardware_equates.asm"
include "system_equates.asm"


	org $5000

	push hl				;home cursor
	call kjt_get_cursor_position
	ld b,0
	call kjt_set_cursor_position
	pop hl
	
	push hl				;look for end of line
feol	ld a,(hl)
	inc hl
	or a
	jr nz,feol
flc	dec hl				;look for last char 
	ld a,(hl)
	cp $20
	jr nz,flc
	inc hl
	ld (hl),11			;<CR> at end of line
	inc hl
	ld (hl),0
	
	pop hl
	call kjt_print_string
	xor a
	ret

;---------------------------------------------------------------------------------------------
