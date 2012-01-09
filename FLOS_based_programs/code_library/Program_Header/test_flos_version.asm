
; A header for programs to test that required FLOS version (or above) is running.


;--------- Test FLOS version -----------------------------------------------------------


; set "required_flos" 


	push hl
	call kjt_get_version	
	ld de,required_flos 	
	xor a
	sbc hl,de
	pop hl
	jr nc,flos_ok
	ld hl,old_flos_txt
	call kjt_print_string
	ld hl,hex_txt
	push hl
	ld a,d
	call kjt_hex_byte_to_ascii
	ld a,e
	call kjt_hex_byte_to_ascii
	pop hl
	inc hl
	call kjt_print_string
	xor a
	ret

old_flos_txt

	db "Program requires FLOS v",0
hex_txt	db "----+",11,11,0


flos_ok	

;--------------------------------------------------------------------------------------
; User's program goes below..
;--------------------------------------------------------------------------------------