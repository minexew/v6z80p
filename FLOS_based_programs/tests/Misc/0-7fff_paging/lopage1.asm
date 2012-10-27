; Lower page test - pages sysram $08000-0FFFF at Z80:$0000-$7FFF

;---Standard header for OSCA and FLOS ----------------------------------------

include "kernal_jump_table.asm"
include "osca_hardware_equates.asm"
include "system_equates.asm"

	org $5000

;-----------------------------------------------------------------------------
	
	ld hl,info_txt
	call kjt_print_string
	di
	jp test
	
;------------------------------------------------------------------------------

	org $8038
	
	
	
	
	

start	ld hl,0
loop	ld (palette),hl
	inc hl
	jr loop
	
;-----------------------------------------------------------------------------

	ds 256,0
	
;-----------------------------------------------------------------------------

test	ld a,1			;put $08000-0FFFF at Z80:$0000-$7FFF
	out ($20),a		;video registers intact
	jp $800
	
;------------------------------------------------------------------------------


info_txt	db 11,"Tests lower 32KB paging.",11
	db "Border colour should cycle.",11
	db "(Reset to quit)",11,0
