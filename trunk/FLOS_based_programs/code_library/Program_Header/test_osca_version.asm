
; A header for programs to test that required OSCA version (or above) is running.


;--------- Test OSCA version -----------------------------------------------------------


; set "required_osca" label 


	push hl
	call kjt_get_version	
	ex de,hl
	ld de,required_osca 	
	xor a
	sbc hl,de
	pop hl
	jr nc,osca_ok
	ld hl,old_osca_txt
	call kjt_print_string
	ld hl,hwhex_txt
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

old_osca_txt

	db "Program requires OSCA v",0
hwhex_txt	db "----+",11,11,0


osca_ok	

;--------------------------------------------------------------------------------------
