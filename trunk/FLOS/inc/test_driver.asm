;-------------------------------------------------------------------------------------------------
; STANDARDIZED DRIVER HEADER FOR V6Z80P / FLOS 564+
;-------------------------------------------------------------------------------------------------

test_driver			; label of driver code

	db "TESTDRV",0		; 0 - 7 = desired ASCII name of device type
	
	jp test_read_sector		; $8 = jump to read sector routine
	jp test_write_sector	; $B = jump to write sector routine
				; $E = init / get hardware ID routine

;--------------------------------------------------------------------------------------------------
; Carry is set if routines complete OK
;--------------------------------------------------------------------------------------------------

test_get_id

	ld hl,test_message
	ld bc,$0022
	ld de,$0011
	scf
	ret

test_read_sector

	xor a
	ld hl,sector_buffer
	ld bc,512
	call os_bchl_memfill
	scf
	ret

test_write_sector
	
	scf
	ret
	
;--------------------------------------------------------------------------------------------------


test_message

	db "JUST A TEST DRIVER!",0
	