; Reads a 2 x 40 byte section of file
;
;---Standard header for OSCA and FLOS ----------------------------------------

include "kernal_jump_table.asm"
include "OSCA_hardware_equates.asm"
include "system_equates.asm"


	org $5000
	
	ld hl,msg
	call kjt_print_string
	
	ld hl,$8000
	ld (ld_addr),hl
	
	ld hl,filename
	call kjt_find_file
	ret nz
	
	ld ix,0
	ld iy,40
	call kjt_set_load_length
	
	ld hl,$8000
	ld b,0
	call kjt_read_from_file
	
	ld ix,0
	ld iy,40
	call kjt_set_file_pointer
	call kjt_set_load_length
	
	ld hl,$8100
	ld b,0
	call kjt_read_from_file
	xor a
	ret
	

ld_addr	dw 0
	
filename	db "test1.scr",0

msg	db "Testing file read",11,0

;-----------------------------------------------------------------------------
