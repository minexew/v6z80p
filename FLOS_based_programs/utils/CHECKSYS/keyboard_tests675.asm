;------------------------------------------------------------------------------------------

keyboard_tests	call kjt_clear_screen

kbtlp		ld hl,kbtest_txt
		call kjt_print_string

wait_key	call kjt_wait_key_press
		cp $76
		jr nz,notquit
		xor a
		ret
		
notquit		ld a,b
		cp "1"
		jp z,kb_reset
		cp "2"
		jp z,kb_capson
		cp "3"
		jp z,kb_capsoff
		cp "4"
		jp z,kb_echo
		cp "5"
		jp z,kb_rd_test
		jr wait_key
		
kb_reset	call do_reset
kbt_ret		push af
		call pause_1_second
		pop af
		ei
		jp nc,keyboard_tests
		call kjt_print_string
		jp keyboard_tests
		
kb_echo		call do_echo
		jr kbt_ret
		
kb_capson	call do_capson
		jr kbt_ret
		
kb_capsoff	call do_capsoff
		jr kbt_ret

kb_rd_test	call do_kb_rd_test
		ei
		jp keyboard_tests
		
kbtest_txt	db "Keyboard Test Menu",11,11
		db "Press:",11,11
		db "1. Reset keyboard",11
		db "2. Turn on caps lock LED",11
		db "3. Turn off caps lock LED",11
		db "4. Send ECHO command",11
		db "5. Report scancodes",11,11
		db "ESC - Main test menu",11,11,0

kb_read_test_txt

		db "Reporting scan codes..",11,11,0
			
;-----------------------------------------------------------------------------------------

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



do_kb_rd_test	ld hl,kb_read_test_txt
		call kjt_print_string
		
		di					; show scancodes
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
	


;----------------------------------------------------------------------------------------------


show_send	call show_send_byte
		call kb_send_byte
		ret nc
		ld hl,send_to_txt
		ret

send_to_txt	db "Send timed out",11,0




show_response	call kb_get_response
		jr c,rec_timedout
		call show_rec_byte
		xor a
		ret

rec_timedout	ld hl,rec_to_txt
		ret

rec_to_txt	db "Timed out waiting for response",11,0


;----------------------------------------------------------------------------------------------

pause_1_second
					
		ld b,0					; wait approx 1 second
twait1		call pause_4ms				; pauses 4ms
		djnz twait1				; loop 256 times
		ret

;---------------------------------------------------------------------------------------------------------
		
pause_4ms
		push af
		xor a					; set timer to count 256 x 65536 cycles
		call set_timer
pause_lp	call test_timer
		jr z,pause_lp			
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

include "flos_based_programs/code_library/peripherals/keyboard/inc/keyboard_low_level_main.asm"

;-----------------------------------------------------------------------------------------------------------
