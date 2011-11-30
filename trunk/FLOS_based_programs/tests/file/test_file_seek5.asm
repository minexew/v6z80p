
;---Standard header for OSCA and FLOS ----------------------------------------

include "kernal_jump_table.asm"
include "OSCA_hardware_equates.asm"
include "system_equates.asm"


	org $5000
	
	ld hl,filename
	call kjt_find_file
	or a
	ret nz
	
	ld ix,0
	ld iy,$f
	call kjt_set_file_pointer
	
	ld ix,0
	ld iy,$83f0
	call kjt_set_load_length
	
	ld hl,$8000
	ld b,0
	call kjt_force_load


	
	ld ix,0
	ld iy,1
	call kjt_set_load_length
	
	ld hl,$8000
	ld b,1
	call kjt_force_load
	ret
	
	
filename	db "testfile.bin",0