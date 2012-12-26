;======================================================================================
; Standard header for OSCA and FLOS
;======================================================================================

include "equates\kernal_jump_table.asm"
include "equates\osca_hardware_equates.asm"
include "equates\system_equates.asm"

          org $5000

	ld hl,$1000				;repeat n times
tloop	dec hl
	ld a,h
	or l
	jr z,done
	push hl
	call get_eeprom_size
	ld a,(eeprom_id_byte)
	ld b,a
	ld a,(eeprom_type)
	ld c,a
	ld a,(number_of_slots)
	ld d,a
	pop hl
	jr z,tloop

fail	push hl
	ld hl,failed_txt
	call kjt_print_string
	pop hl
	xor a
	ret

done	ld hl,done_txt
	call kjt_print_string
	xor a
	ret


done_txt

	db "Done",11,0
	
failed_txt

	db "FAILED!",11,0
	
page_buffer

	ds 256,0
	

include "FLOS_based_programs\code_library\eeprom\inc\eeprom_routines.asm"

