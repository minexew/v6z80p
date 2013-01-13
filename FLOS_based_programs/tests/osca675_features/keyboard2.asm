
; Tests keyboard - osca675

;---Standard header for OSCA and FLOS  -----------------------------------------------------------------------

include "equates\kernal_jump_table.asm"
include "equates\OSCA_hardware_equates.asm"
include "equates\system_equates.asm"

		org $5000


;-------------------------------------------------------------------------------------------------------------

		call pause_1_second
		
;		call kb_rd_test
;		call do_echo
;		call do_reset
		call do_capson
;		call do_capsoff
		
		ei
		xor a
		ret


time_out_txt	db "Time out error!",11,0

;----------------------------------------------------------------------------------------------------------

		
do_echo		di
		ld a,$ee			;echo command				
		call show_send
		ret c
		call show_response
		ret 
		
do_reset	di
		ld a,$ff			;reset command
		call show_send
		ret c
		call show_response
		ret c
		call show_response
		ret


do_capson	di
		ld a,$ed			;set status leds command
		call show_send
		ret c
		call show_response
		ret c
		
		ld a,$04			;caps lock bit
		call show_send
		ret c
		call show_response
		ret	


do_capsoff	di
		ld a,$ed			;set status leds command				
		call show_send
		ret c
		call show_response
		ret c
		
		ld a,$00			;no leds
		call show_send
		ret c
		call show_response
		ret



kb_rd_test	di
		call kjt_clear_screen			; show scancodes
		ld hl,kb_read_test_txt
		call kjt_print_string
		xor a
		out (sys_ps2_joy_control),a		; make sure the keyboard clk+datalines are not being driven manually
		
readloop	in a,(sys_irq_ps2_flags)		; wait for keyboard IRQ flag to be set
		bit 0,a
		jr z,readloop
		in a,(sys_keyboard_data)		; read kb data byte
		push af
		ld a,%00000001
		out (sys_clear_irq_flags),a		; clear kb IRQ		
		pop af
		cp $76
		ret z
		call show_rec_byte
		jr readloop
			

kb_read_test_txt

		db "Reporting scan codes..",11,11,0




show_send	call show_send_byte
		call kb_send_byte
		ret nc
		ld hl,send_to_txt
		call kjt_print_string
		scf
		ret

send_to_txt	db "Send timed out",11,0




show_response	call kb_get_response
		jr c,rec_timedout
		call show_rec_byte
		ret

rec_timedout	ld hl,rec_to_txt
		call kjt_print_string
		scf
		ret

rec_to_txt	db "Timed out waiting for response",11,0

;-------------------------------------------------------------------------------------------


pause_2_seconds

		call pause_1_second

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
		
;---------------------------------------------------------------------------------------------------------
		
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

;-----------------------------------------------------------------------------------------------------------

include "flos_based_programs/code_library/peripherals/inc/keyboard_low_level.asm"

;-----------------------------------------------------------------------------------------------------------
