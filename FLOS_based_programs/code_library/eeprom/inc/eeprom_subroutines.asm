
;------------------------------------------------------------------------------------------
; EEPROM SUBROUTINES - DISABLE INTERRUPTS AROUND THEsE CALLS
;----------------------------------------------------------------------------------------
;
; Subroutine list:
; ----------------
; send_pic_command - Set HL to command string (first byte = number of bytes in string)
; send_byte_to_pic - Send byte in A to PIC
; wait_pic_busy    - Read a byte from the PIC into A
; read_pic_byte    - Wait until PIC/EEPROM is not busy (Carry flag set on return if timed out) Note: Uses sys_timer
;
;-------- EEPROM CONSTANTS -------------------------------------------------------------

pic_data_input	 equ 0	; from FPGA to PIC (bit 0 of sys_pic_comms)
pic_clock_input	 equ 1	; from FPGA to PIC (bit 1 of sys_pic_comms)

pic_clock_output equ 3	; from PIC to FPGA (bit 3 of sys_hw_flags) 

;-----------------------------------------------------------------------------------	

	
send_pic_command

		push bc
		call pic_delay
		ld b,(hl)
spc_loop	inc hl
		ld a,(hl)
		call send_byte_to_pic
		djnz spc_loop
		pop bc
		ret

			
;-----------------------------------------------------------------------------------	


send_byte_to_pic

; put byte to send in A
; Bit rate ~ 50KHz (Transfer ~ 4.7KBytes/Second)

		push bc
		push de
		ld c,a			
		ld d,8

ee_bit_loop	xor a
		rl c
		jr nc,ee_zero_bit
		set pic_data_input,a

ee_zero_bit	out (sys_pic_comms),a		; present new data bit
		set pic_clock_input,a
		out (sys_pic_comms),a		; raise clock line
		
		ld b,12
ee_psbwlp1	djnz ee_psbwlp1			; keep clock high for 10 microseconds
			
		res pic_clock_input,a
		out (sys_pic_comms),a		; drop clock line
		
		ld b,12
ee_psbwlp2	djnz ee_psbwlp2			; keep clock low for 10 microseconds
		
		dec d
		jr nz,ee_bit_loop

		ld b,60				; short wait between bytes ~ 50 microseconds
ee_pdswlp	djnz ee_pdswlp			; allows time for PIC to act on received byte
		pop de				; (PIC will wait 300 microseconds for next clock high)
		pop bc
		ret			


;----------------------------------------------------------------------------------------
		

read_pic_byte	push bc
		push de
		
		call pic_delay			; wait a while to ensure PIC is ready
		
		ld e,0
		ld c,8				                 

ee_nxt_bit	sla e
		ld a,1<<pic_clock_input		; prompt PIC to present next bit by raising PIC clock line
		out (sys_pic_comms),a
		
		call pic_delay
		
		in a,(sys_hw_flags)		; read the bit into shifter
		bit 3,a
		jr z,ee_nobit
		set 0,e
ee_nobit		
		xor a				; drop clock line again
		out (sys_pic_comms),a
		
		call pic_delay
		
		dec c
		jr nz,ee_nxt_bit
		
		ld a,e
		pop de
		pop bc
		ret


pic_delay	ld b,0
pic_dloop	djnz pic_dloop
		ret


;-------------------------------------------------------------------------------------------


wait_pic_busy
		
		xor a
		out (sys_timer),a		; set timer irq interval
		
		push de
		ld de,0
	
wait_pic	in a,(sys_irq_ps2_flags)	; check for timer overflow..
		and 4
		jr z,test_pic	
		out (sys_clear_irq_flags),a	; clear timer overflow flag
		inc de				; inc count of overflows
		ld a,d
		cp 5
		jr nz,test_pic			; every 256 DE increments = 1 second		
		pop de
		scf				; timed out error - carry flag set
		ret
	
test_pic	in a,(sys_hw_flags)		; if PIC is holding its clock output high it is
		bit pic_clock_output,a		; busy and cannot accept data bytes at this time
		jr nz,wait_pic
		pop de
		scf
		ccf				; carry flag zero if OK
		ret


;-----------------------------------------------------------------------------------------
