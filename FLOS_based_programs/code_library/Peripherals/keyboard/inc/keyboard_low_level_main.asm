;-------------------------------------------------------
; Low level manual comms keyboard routines - for OSCA675
; ------------------------------------------------------
;
; Timing is quite critical! Ensure no IRQs are active when using these routines.
;
;-------------------------------------------------------------------------------------------

kb_send_byte

; Put byte to send to keyboard in A. If comms problem, CARRY FLAG will be set on return.
;
; NOTE: From OSCA v676, sending a byte does NOT cause the keyboard IRQ flag to become set
; (in fact it clears the keyboard IRQ flag).


		ld e,a

		ld a,%00000001
		out (sys_clear_irq_flags),a		; clear buffer (ensure not holding clock low)

		ld a,%00010000				; pull clock line low
		out (sys_ps2_joy_control),a

		ld a,240				; wait 256 microseconds
		call set_timer
kb_twait	call test_timer	
		jr z,kb_twait
		
		ld a,%00110000
		out (sys_ps2_joy_control),a		; pull data line low (too)
		call kb_wait_data_low			; ensure line has gone low
		ret c
		ld a,%00100000
		out (sys_ps2_joy_control),a		; release clock line (data still pulled low)
		call kb_wait_clk_high			; ensure clock line is released
		ret c
		
		call kb_wait_clk_low			; wait for 1st device generated clock (low)
		ret c

		ld d,1					; d = odd parity tally 
		ld b,8					; 8 data bits + 1 parity bit	
kb_bitlp	call kb_send_bit			
		ret c
		srl e
		djnz kb_bitlp
		ld e,d					; send parity bit
		call kb_send_bit
		ret c
		
		xor a
		out (sys_ps2_joy_control),a		; make sure data line is released (for high stop bit)
		
		call kb_wait_data_high
		ret c
		call kb_wait_data_low			; wait for keyboard to pull data low (ack)
		ret c
		call kb_wait_clk_low			; wait for keyboard to pull clock low
		ret c
		
		call kb_wait_data_high			; wait for keyboard to release data and clock
		ret c
		call kb_wait_clk_high
		ret


;-------------------------------------------------------------------------------------------

kb_get_response

; Wait for a byte from keyboard (which placed in A.) Times out if nothing received (CARRY FLAG SET)

		ld b,0
kb_tcd		xor a					; set response wait time out to 1 second
		call set_timer			
kb_wait_rlp	in a,(sys_irq_ps2_flags)		; wait for keyboard IRQ flag to be set
		bit 0,a
		jr nz,kb_byte_rdy
		call test_timer				
		jr z,kb_wait_rlp
		djnz kb_tcd
		scf					; timed out, carry flag set
		ret

kb_byte_rdy	in a,(sys_keyboard_data)		; read kb data byte
		push af
		ld a,%00000001
		out (sys_clear_irq_flags),a		; clear kb IRQ		
		pop af
		cp a
		ret
		
		
;------------------------------------------------------------------------------------------------
; SUBROUTINES
;------------------------------------------------------------------------------------------------

; bit to send is bit 0 of E	

kb_send_bit	xor a
		bit 0,e
		jr nz,kb_bit_pw			
		inc d					; update parity in d
		ld a,%00100000
kb_bit_pw	out (sys_ps2_joy_control),a		; set KB data line accordingly (note: writing 1 pulls down line to 0)
		
		call kb_wait_clk_high			
		ret c
		call kb_wait_clk_low
		ret
					
;-------------------------------------------------------------------------------------------

kb_wait_clk_low	ld h,%00000000
kb_waitclk	ld l,%00010000				; bit 4 is clock line		

kb_wait		ld c,4					; time out = approx 16 milliseconds

kb_wlllp	xor a					
		call set_timer
					
kb_wlp1		call kb_test_line_status
		ret z					; if ZF set, condidition is met
		call test_timer
		jr z,kb_wlp1
		dec c
		jr nz,kb_wlllp
		scf					; carry flag = timed out
		ret
		

kb_wait_clk_high
		
		ld h,%11111111				; inverse	
		jr kb_waitclk
		


kb_wait_data_low

		ld h,%00000000
kb_waitdata	ld l,%00100000				; bit 5 is data line
		jr kb_wait
		


kb_wait_data_high

		ld h,%11111111				; inverse
		jr kb_waitdata
		


kb_test_line_status

		in a,(sys_irq_ps2_flags)		; line must be continuously low for a few samples
		xor h
		and l
		ret nz
		in a,(sys_irq_ps2_flags)
		xor h
		and l
		ret nz
		in a,(sys_irq_ps2_flags)
		xor h
		and l
		ret


;------------------------------------------------------------------------------------------------
