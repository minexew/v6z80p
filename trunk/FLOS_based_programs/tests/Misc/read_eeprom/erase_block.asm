; Test slot erase feature

;---Standard header for OSCA and FLOS ----------------------------------------

include "kernal_jump_table.asm"
include "OSCA_hardware_equates.asm"
include "system_equates.asm"

	org $5000

;-----------------------------------------------------------------------------

page_buffer equ $8000
	
	di
	ld a,0
	ld (sector_number),a	; 64KB sector to erase


	ld a,(sector_number)		
	ld hl,erase_chars
	call kjt_hex_byte_to_ascii
	ld hl,erasing_txt		; show "erasing slot xx" text
	call kjt_print_string

	ld a,(sector_number)	; erase the required 2 x 64KB eeprom sectors 
	call erase_eeprom_sector

	ld hl,checking_txt		; checks bytes are all FF
	call kjt_print_string

	ld a,(sector_number)
	ld d,a
	ld e,0
cse1	push de
	call read_eeprom_page
	or a
	jr nz,time_out
	call all_ff
	pop de
	jr nz,verror
	inc e
	jr nz,cse1
		
	ld hl,ok_txt
done	call kjt_print_string
	ei
	xor a
	ret
		
verror	ld hl,bad_txt
	jr done

time_out
	pop de
	ld hl,time_out_txt
	jr done	

all_ff	ld hl,page_buffer
	ld b,0
	ld a,$ff
lp1	cp (hl)
	ret nz
	inc hl
	djnz lp1
	xor a
	ret

;------------------------------------------------------------------------------

include "eeprom_routines.asm"
	
;------------------------------------------------------------------------------

sector_number	db 0

erasing_txt	db "Erasing sector :$"
erase_chars	db "xx...",11,11,0

checking_txt	db "Verifying erasure..",11,11,0

ok_txt		db "OK",11,11,0

bad_txt		db "Sector is not blank!",11,11,0

time_out_txt	db "Error: Timed out.",11,11,0

notbusy_txt	db "PIC Busy Flag low",11,11,0

;-------------------------------------------------------------------------------
