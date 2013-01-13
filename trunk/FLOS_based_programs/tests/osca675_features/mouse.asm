;-----------------------------------------------------------------------------------------------
; MOUSE init test
;
; for OSCA v675
;-----------------------------------------------------------------------------------------------

;======================================================================================
; Standard equates for OSCA and FLOS
;======================================================================================

include "equates\kernal_jump_table.asm"
include "equates\osca_hardware_equates.asm"
include "equates\system_equates.asm"

;-----------------------------------------------------------------------------------------------

		org $5000


		call pause_1_second
		
		call do_reset		
		ei
		xor a
		ret



do_reset	di
		ld a,$ff			;"reset" command
		call show_send
		ret c
		call show_response		;should be FA (ack)
		ret c
		call show_response		;should be AA (pass self test)
		ret c
		call show_response		;should be 00 (mouse ID)
		ret c
		
		ld a,$f4			;"enable data reporting" command
		call show_send
		ret c
		call show_response		;should be FA (ack)
		ret
		
		
		
show_send	call show_send_byte
		call ms_send_byte
		ret nc
		ld hl,send_to_txt
		call kjt_print_string
		scf
		ret

send_to_txt	db "Send timed out",11,0




show_response	call ms_get_response
		jr c,rec_timedout
		call show_rec_byte
		ret

rec_timedout	ld hl,rec_to_txt
		call kjt_print_string
		scf
		ret

rec_to_txt	db "Timed out waiting for response",11,0


;-----------------------------------------------------------------------------------------------


pause_1_second
					
		ld b,0					; wait approx 1 second
twait1		call pause_4ms				; pauses 4ms
		djnz twait1				; loop 256 times
		ret

		
;---------------------------------------------------------------------------------------------------------
		
pause_4ms
		push af
		xor a		
		call kjt_timer_wait			
		pop af
		ret
show_send_byte	push af
		push hl
		call do_hex_byte
		ld hl,send_txt
		call kjt_print_string
		ld hl,hex_txt
		call kjt_print_string
		pop hl
		pop af
		ret

show_rec_byte	push af
		push hl
		call do_hex_byte
		ld hl,rec_txt
		call kjt_print_string
		ld hl,hex_txt
		call kjt_print_string
		pop hl
		pop af
		ret

do_hex_byte	ld hl,hex_txt+1
		call kjt_hex_byte_to_ascii
		ret

rec_txt		db "REC : ",0
send_txt	db "SEND: ",0
hex_txt		db "$xx",11,0

		
;----------------------------------------------------------------------------------------------------------

include "flos_based_programs/code_library/peripherals/inc/mouse_low_level.asm"

;-----------------------------------------------------------------------------------------------------------

