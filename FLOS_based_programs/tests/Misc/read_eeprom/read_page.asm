;======================================================================================
; Standard header for OSCA and FLOS
;======================================================================================

include "equates\kernal_jump_table.asm"
include "equates\osca_hardware_equates.asm"
include "equates\system_equates.asm"

source		equ $fb00			;address within EEPROM block from which to get bytes
src_block 	equ $03				;block number from which to get bytes

length		equ $0100
len_msb		equ $00				;number of bytes required from EEPROM (minimum = $000001)

          org $5000

	ld hl,$100				;repeat n times
tloop	dec hl
	ld a,h
	or l
	jr z,done
	
	push hl
	ld de,$03fb
	call read_eeprom_page
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

		org ($+255)&$ff00
page_buffer

	ds 256,0
	
	
include "FLOS_based_programs\code_library\eeprom\inc\eeprom_routines.asm"

