; Reads 1 byte at a time from $13ff (to 1024 bytes)
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
	ld iy,$13ff
	call kjt_set_file_pointer
	
nxt_ld	ld ix,0
	ld iy,1
	call kjt_set_load_length
	
	ld hl,(ld_addr)
	ld b,0
	call kjt_read_from_file
	ret nz
	
	ld hl,(ld_addr)
	inc hl
	ld (ld_addr),hl
	
	ld de,$8400
	xor a
	sbc hl,de
	jr nz,nxt_ld
	xor a
	ret
	

ld_addr	dw 0
	
filename	db "testfile.bin",0

msg	db "Testing file read",11,0

;-----------------------------------------------------------------------------
