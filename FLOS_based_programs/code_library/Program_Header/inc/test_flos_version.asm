
; A header for programs to test that required FLOS version (or above) is running.
;
; Include this as in-line code at start of program, DO NOT call it as routine!
;
; set "required_flos" label

;--------- Test FLOS version -----------------------------------------------------------


		push af
		push bc
		push de
		push hl
		push ix
		push iy

		call kjt_get_version	
		ld de,required_flos 	
		xor a
		sbc hl,de
		jr nc,flos_ok

		ld hl,old_flos_txt
		call kjt_print_string
		ld hl,oshex_txt
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


old_flos_txt	db "Program requires FLOS v",0
oshex_txt	db "----+",11,11,0


flos_ok		pop iy
		pop ix
		pop hl
		pop de
		pop bc
		pop af

;--------------------------------------------------------------------------------------
; user code continues here...
;--------------------------------------------------------------------------------------