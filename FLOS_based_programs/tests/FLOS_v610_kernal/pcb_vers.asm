;======================================================================================
; Standard equates for OSCA and FLOS
;======================================================================================

include "\equates\kernal_jump_table.asm"
include "\equates\osca_hardware_equates.asm"
include "\equates\system_equates.asm"

	org $5000
	
	call kjt_get_version

	ld hl,hex
	ld a,b
	call kjt_hex_byte_to_ascii
	
	ld a,(ix+1)
	ld hl,bcv
	call kjt_hex_byte_to_ascii
	ld a,(ix)
	ld (bcv+2),a
	call kjt_hex_byte_to_ascii
	
	ld a,(ix+2)
	ld hl,bdb
	call kjt_hex_byte_to_ascii
	
	ld a,(ix+3)
	ld hl,obd
	call kjt_hex_byte_to_ascii
	
	ld hl,string
	call kjt_print_string
	ret
	
	
string	db 11,"PCB version byte: "
hex	db "xx",11,11
	db "00 = Unknown",11
	db "01 = V6Z80P (original)",11
	db "02 = V6Z80P+ v1.0",11
	db "03 = V6Z80P+ V1.1",11,11
	
	db "Bootcode version: $"
bcv	db "xxxx",11,11
	
	db "Bootdevs available byte: $"
bdb	db "xx",11,11
	
	db "OS boot device byte:$"
obd	db "xx",11,11,0
	

