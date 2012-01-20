; Reads 64KB, split into two 32KB reads
;
;---Standard header for OSCA and FLOS ----------------------------------------

include "kernal_jump_table.asm"
include "OSCA_hardware_equates.asm"
include "system_equates.asm"


	org $5000
	
	ld hl,msg
	call kjt_print_string
	
	ld hl,filename
	call kjt_find_file
	ret nz
	
	ld ix,0
	ld iy,$8000
	call kjt_set_load_length
	
	ld hl,$8000
	ld b,0
	call kjt_read_from_file
		
	ld ix,0
	ld iy,$8000
	call kjt_set_load_length
	call kjt_set_file_pointer
	
	ld hl,$8000
	ld b,1
	call kjt_read_from_file
	ret
	
	

ld_addr	dw 0
	
filename	db "testfile.bin",0

msg	db "Testing file read",11,0

;-----------------------------------------------------------------------------
