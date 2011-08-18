; Shows info about loaded program - truncated load

;---Standard header for OSCA and FLOS ----------------------------------------

include "kernal_jump_table.asm"
include "osca_hardware_equates.asm"
include "system_equates.asm"

	org $5000
	
;-----------------------------------------------------------------------------

	ld hl,fn_txt
	call kjt_create_file
	ret nz
	
	ld hl,fn_txt
	ld ix,data1
	ld b,0
	ld c,0
	ld de,12
	call kjt_write_to_file
	ret nz
	
	ld hl,fn_txt
	ld ix,data2
	ld b,0
	ld c,0
	ld de,10
	call kjt_write_to_file
	ret
	
;-----------------------------------------------------------------------------

fn_txt	db "mytest2.bin",0

data1	db "123456789abc"

data2	db "ABCDEFGHIJ"
