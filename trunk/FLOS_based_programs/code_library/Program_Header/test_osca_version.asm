
; A header for programs to test that required OSCA version (or above) is running.
;
; Include this as in-line code at start of program, DO NOT call it as routine!
;
; set "required_osca" label 

;--------- Test OSCA version -----------------------------------------------------------


		push af
		push bc
		push de
		push hl
		push ix
		push iy
		
		call kjt_get_version	
		ex de,hl
		ld de,required_osca 	
		xor a
		sbc hl,de
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
		
		pop iy
		pop ix
		pop hl
		pop de
		pop bc
		pop af
		cp a
		ret

old_osca_txt

		db "Program requires OSCA v",0
hwhex_txt	db "----+",11,11,0


osca_ok		pop iy
		pop ix
		pop hl
		pop de
		pop bc
		pop af

;--------------------------------------------------------------------------------------
; user code continues here...
;--------------------------------------------------------------------------------------
