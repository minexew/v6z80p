; Read video mode and frame rate flags

;---Standard header for OSCA and FLOS ----------------------------------------

include "kernal_jump_table.asm"
include "OSCA_hardware_equates.asm"
include "system_equates.asm"

	org $5000

;-----------------------------------------------------------------------------

	ld hl,hz50_txt
	in a,(sys_vreg_read)
	bit 5,a
	jr z,fifty_hz
	ld hl,hz60_txt
fifty_hz	call kjt_print_string

	ld hl,tv_txt
	in a,(sys_hw_settings)
	bit 5,a
	jr z,tv_mode
	ld hl,vga_txt
tv_mode	call kjt_print_string
		
	xor a
	ret

;-------------------------------------------------------------------------------

	
hz50_txt	db "The frame rate flag reports: 50Hz",11,0

hz60_txt	db "The frame rate flag reports: 60Hz",11,0

tv_txt	db "The video mode flag reports: TV mode",11,0

vga_txt	db "The video mode flag reports: VGA mode",11,0

;------------------------------------------------------------------------------
