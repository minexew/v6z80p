;-------------------------------------------------------
; Low level manual comms mouse routines - for OSCA675
; ------------------------------------------------------
;
; Timing is quite critical! Ensure no IRQs are active when using these routines.
;
;-------------------------------------------------------------------------------------------

ms_send_byte

; Put byte to send to mouse in A. If comms problem, CARRY FLAG will be set on return.
;
; NOTE: From OSCA v676, sending a byte does NOT cause the mouse IRQ flag to become set
; (in fact it clears the mouse IRQ flag).


		ld e,a
		
		ld a,%00000010
		out (sys_clear_irq_flags),a		; clear buffer (ensure not holding clock low)
		
		ld a,%01000000				; pull clock line low
		out (sys_ps2_joy_control),a

		ld a,240				; wait 256 microseconds
		call set_timer
ms_twait	call test_timer	
		jr z,ms_twait
		
		ld a,%11000000
		out (sys_ps2_joy_control),a		; pull data line low (too)
		call ms_wait_data_low			; ensure line has gone low
		ret c
		ld a,%10000000
		out (sys_ps2_joy_control),a		; release clock line (data still pulled low)
		call ms_wait_clk_high			; ensure clock line is released
		ret c
		
		call ms_wait_clk_low			; wait for 1st device generated clock (low)
		ret c

		ld d,1					; d = odd parity tally 
		ld b,8					; 8 data bits + 1 parity bit	
ms_bitlp	call ms_send_bit			
		ret c
		srl e
		djnz ms_bitlp
		ld e,d					; send parity bit
		call ms_send_bit
		ret c
		
		xor a
		out (sys_ps2_joy_control),a		; make sure data line is released (for high stop bit)
		
		call ms_wait_data_high
		ret c
		call ms_wait_data_low			; wait for mouse to pull data low (ack)
		ret c
		call ms_wait_clk_low			; wait for mouse to pull clock low
		ret c
		
		call ms_wait_data_high			; wait for mouse to release data and clock
		ret c
		call ms_wait_clk_high
		ret


;-------------------------------------------------------------------------------------------

ms_get_response

; Wait for a byte from mouse (which placed in A.) Times out if nothing received (CARRY FLAG SET)

		ld b,0
ms_tcd		xor a					; set response wait time out to 1 second
		call set_timer			
ms_wait_rlp	in a,(sys_irq_ps2_flags)		; wait for mouse IRQ flag to be set
		bit 1,a
		jr nz,ms_byte_rdy
		call test_timer				
		jr z,ms_wait_rlp
		djnz ms_tcd
		scf					; timed out, carry flag set
		ret

ms_byte_rdy	in a,(sys_mouse_data)			; read mouse data byte
		push af
		ld a,%00000010
		out (sys_clear_irq_flags),a		; clear mouse IRQ		
		pop af
		cp a
		ret
		
		
;------------------------------------------------------------------------------------------------
; SUBROUTINES
;------------------------------------------------------------------------------------------------

; bit to send is bit 0 of E	

ms_send_bit	xor a
		bit 0,e
		jr nz,ms_bit_pw			
		inc d					; update parity in d
		ld a,%10000000
ms_bit_pw	out (sys_ps2_joy_control),a		; set mouse data line accordingly (note: writing 1 pulls down line to 0)
		
		call ms_wait_clk_high			
		ret c
		call ms_wait_clk_low
		ret
					
;-------------------------------------------------------------------------------------------

ms_wait_clk_low	ld h,%00000000
ms_waitclk	ld l,%01000000				; bit 6 is clock line		

ms_wait		ld c,4					; time out = approx 16 milliseconds

ms_wlllp	xor a					
		call set_timer
					
ms_wlp1		call ms_test_line_status
		ret z					; if ZF set, condidition is met
		call test_timer
		jr z,ms_wlp1
		dec c
		jr nz,ms_wlllp
		scf					; carry flag = timed out
		ret
		

ms_wait_clk_high
		
		ld h,%11111111				; inverse	
		jr ms_waitclk
		


ms_wait_data_low

		ld h,%00000000
ms_waitdata	ld l,%10000000				; bit 7 is data line
		jr ms_wait
		


ms_wait_data_high

		ld h,%11111111				; inverse
		jr ms_waitdata
		


ms_test_line_status

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

