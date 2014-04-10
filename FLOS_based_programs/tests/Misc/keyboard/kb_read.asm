
include "equates\kernal_jump_table.asm"
include "equates\osca_hardware_equates.asm"
include "equates\system_equates.asm"

		org $5000

;------------------------------------------------------------------------------------------

		call kjt_clear_screen

kbtlp		ld hl,kbtest_txt
		call kjt_print_string

		di
		
readloop	call read_kb_byte
		cp $76
		jp nz,readloop

		ei
		xor a
		ret


kbtest_txt	db 11,"Keyboard read test..",11,11,0
		

;-------------------------------------------------------------------------------------------

read_kb_byte	ld b,0
kb_tcd		xor a
		call set_timer				; clear timer overflow flag
wait_klp	in a,(sys_irq_ps2_flags)		; wait for keyboard IRQ flag to be set
		bit 0,a
		jr nz,kbyte_rdy
		call test_timer				
		jr z,wait_klp
		djnz kb_tcd
		scf					; timed out, carry flag set
		
kb_err		ld hl,timed_out_waiting_for_irq_txt	; timed out message
		ret

kbyte_rdy	ld a,%00000001
		out (sys_clear_irq_flags),a		; clear kb IRQ
		in a,(sys_keyboard_data)		; read kb data byte
		
		call show_rec_byte
		
		or a
		ret
		
;-------------------------------------------------------------------------------------------
			
timeout_kb_clk_low

		ld hl,to_clock_low_txt
		ret

timeout_kb_data_low

		ld hl,to_data_low_txt
		ret

;-------------------------------------------------------------------------------------------

wait_kb_clk_low	

		ld l,4
wkbcltlp	xor a
		call set_timer
		ld c,%00010000				; bit 4 is clock line
wkbcl_lp1	call test_kb_line_lo
		ret z
		call test_timer
		jr z,wkbcl_lp1
		dec l
		jr nz,wkbcltlp
		scf
		ret
		

wait_kb_data_low

		ld l,4
wkbdltlp	xor a
		call set_timer
		ld c,%00100000				; bit 5 is clock line
wkbdl_lp1	call test_kb_line_lo
		ret z
		call test_timer
		jr z,wkbdl_lp1
		dec l
		jr nz,wkbdltlp
		scf
		ret

		
		
test_kb_line_lo	in a,(sys_irq_ps2_flags)		; clk must be continuously low for a few samples
		and c
		ret nz
		in a,(sys_irq_ps2_flags)
		and c
		ret nz
		in a,(sys_irq_ps2_flags)
		and c
		ret z
	
	

wait_kb_clk_high

		ld c,%00010000				; clk must be continuously high for a few samples	

kb_data_test	in a,(sys_irq_ps2_flags)
		and c
		jr z,kb_data_test
		in a,(sys_irq_ps2_flags)		; no need for time out test as high is disconnected state (unlikely to become stuck low)
		and c					
		jr z,kb_data_test
		in a,(sys_irq_ps2_flags)
		and c
		jr z,kb_data_test
		ret


wait_kb_data_high

		ld c,%00100000				; data must be continuously high for a few samples	
		jr kb_data_test
		
	
;------------------------------------------------------------------------------------------------

send_kb_byte

; put byte to send in A

		call show_send_byte


		ld e,a

		ld a,%00010000				; pull clock line low
		out (sys_ps2_joy_control),a

		ld a,240				; wait 256 microseconds
		call set_timer
twait		call test_timer	
		jr z,twait
		
		ld a,%00110000
		out (sys_ps2_joy_control),a		; pull data line low (too)
		call wait_kb_data_low			; ensure line has gone low
		jp c,timeout_kb_data_low
		ld a,%00100000
		out (sys_ps2_joy_control),a		; release clock line (data still pulled low)
		call wait_kb_clk_high			; ensure clock line is released
		
		call wait_kb_clk_low			; wait for 1st device generated clock (low)
		jp c,timeout_kb_clk_low

		ld d,1					; d = odd parity tally 
		ld b,8					; 8 data bits + 1 parity bit	
kb_bitlp	call kb_send_bit			
		ret c
		srl e
		djnz kb_bitlp
		ld e,d					; send parity bit
		call kb_send_bit

		xor a
		out (sys_ps2_joy_control),a		; make sure data line is released (for high stop bit)
		call wait_kb_data_high
		
		call wait_kb_data_low			; wait for keyboard to pull data low (ack)
		jp c,timeout_kb_data_low
		call wait_kb_clk_low			; wait for keyboard to pull clock low
		jp c,timeout_kb_clk_low
		
		call wait_kb_data_high			; wait for keyboard to release data and clock
		call wait_kb_clk_high
		
		ld a,%00000001
		out (sys_clear_irq_flags),a		; clear kb IRQ
		xor a
		ret

;---------------------------------------------------------------------------------------------

; bit to send is bit 0 of E	

kb_send_bit	xor a
		bit 0,e
		jr nz,kb_bit_pw			
		inc d					; update parity in d
		ld a,%00100000
kb_bit_pw	out (sys_ps2_joy_control),a		; set KB data line accordingly (note: writing 1 pulls down line to 0)
		
		call wait_kb_clk_high			
		call wait_kb_clk_low
		ret
			
		
;------------------------------------------------------------------------------------------------


set_timer

; put timer reload value in A before calling, remember - timer counts upwards!

		out (sys_timer),a			;load and restart timer
		ld a,%00000100
		jr clr_tirq				;clear timer overflow flag


;------------------------------------------------------------------------------------------
		
test_timer

; zero flag is set on return if timer has not overflowed

		in a,(sys_irq_ps2_flags)		;check for timer overflow..
		and 4
		ret z	
clr_tirq	out (sys_clear_irq_flags),a		;clear timer overflow flag
		ret

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

ok_initialized_txt 	db 11,"Test complete - no errors",11,0

timed_out_waiting_for_irq_txt

	
			db 11,"Timed out waiting for byte from keyboard",11,0

to_data_low_txt		db 11,"Timed out waiting for keyboard data low",11,0
			
to_clock_low_txt	db 11,"Timed out waiting for keyboard clock low",11,0

