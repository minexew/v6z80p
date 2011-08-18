; Shows info about loaded program - truncated load

;---Standard header for OSCA and FLOS ----------------------------------------

include "kernal_jump_table.asm"
include "osca_hardware_equates.asm"
include "system_equates.asm"

	org $5000
	
;-----------------------------------------------------------------------------

	ld hl,fn_txt
	ld ix,$c000
	ld b,1
	call kjt_load_file
	ret
	
;-----------------------------------------------------------------------------

fn_txt	db "testfile.bin",0
