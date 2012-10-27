; Displays mouse coordinates and mouse displacements

;---Standard source header for OSCA and FLOS ------------------------------------------

include "kernal_jump_table.asm"	; essential equates
include "OSCA_hardware_equates.asm"	; ""	""
include "system_equates.asm"		; ""	""

	org $5000
	
;--------------------------------------------------------------------------------------

	call kjt_clear_screen
	
lp1	call kjt_get_mouse_position	
	jr nz,error
	ex de,hl
	push af
	push hl
	ld hl,text1
	ld a,d
	call kjt_hex_byte_to_ascii
	ld a,e
	call kjt_hex_byte_to_ascii
	pop hl
	ex de,hl
	ld hl,text2
	ld a,d
	call kjt_hex_byte_to_ascii
	ld a,e
	call kjt_hex_byte_to_ascii
	pop af
	ld hl,text3
	call kjt_hex_byte_to_ascii
	
	
	call kjt_get_mouse_motion
	jr nz,error
	ex de,hl
	push hl
	ld hl,disp1
	ld a,d
	call kjt_hex_byte_to_ascii
	ld a,e
	call kjt_hex_byte_to_ascii
	pop hl
	ex de,hl
	ld hl,disp2
	ld a,d
	call kjt_hex_byte_to_ascii
	ld a,e
	call kjt_hex_byte_to_ascii

	
	ld bc,0
	call kjt_set_cursor_position
	ld hl,mytext
	call kjt_print_string

	call kjt_get_key
	or a
	jr z,lp1
	xor a
	ret

error	ld hl,error_txt
	call kjt_print_string
	xor a
	ret
	
;--------------------------------------------------------------------------------------

mytext	db "Mouse x: $"
text1	db "xxxx",11,"Mouse y: $"
text2	db "yyyy",11,"Mouse buttons :$"
text3	db "bb",11,11

	db "Disp x: $"
disp1	db "xxxx",11,"Disp y: $"
disp2	db "yyyy",11,11,0 


error_txt	db "Mouse driver not installed.",11,11,0
	