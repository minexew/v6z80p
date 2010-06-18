
;-------- EEPROM CONSTANTS -------------------------------------------------------------

pic_data_input	equ 0	; from FPGA to PIC (bit 0 of sys_pic_comms)
pic_clock_input	equ 1	; from FPGA to PIC (bit 1 of sys_pic_comms)

pic_clock_output	equ 3	; from PIC to FPGA (bit 3 of sys_hw_flags) 

send_byte_to_pic

; put byte to send in A
; Bit rate ~ 50KHz (Transfer ~ 4.7KBytes/Second)

	push bc
	push de
	ld c,a			
	ld d,8
bit_loop	xor a
	rl c
	jr nc,zero_bit
	set pic_data_input,a
zero_bit	out (sys_pic_comms),a	; present new data bit
	set pic_clock_input,a
	out (sys_pic_comms),a	; raise clock line
	
	ld b,12
psbwlp1	djnz psbwlp1		; keep clock high for 10 microseconds
		
	res pic_clock_input,a
	out (sys_pic_comms),a	; drop clock line
	
	ld b,12
psbwlp2	djnz psbwlp2		; keep clock low for 10 microseconds
	
	dec d
	jr nz,bit_loop

	ld b,60			; short wait between bytes ~ 50 microseconds
pdswlp	djnz pdswlp		; allows time for PIC to act on received byte
	pop de			; (PIC will wait 300 microseconds for next clock high)
	pop bc
	ret			


;-------------------------------------------------------------------------------------------


wait_pic_busy

	push de
	ld d,0
	
wait_pic	in a,(sys_irq_ps2_flags)	; check for timer overflow..
	and 4
	jr z,test_pic	
	out (sys_clear_irq_flags),a	; clear timer overflow flag
	inc d			; inc count of overflows
	jr nz,test_pic			
	pop de
	scf			; timed out error - carry flag set
	ret
	
test_pic	in a,(sys_hw_flags)		; if PIC is holding its clock output high it is
	bit pic_clock_output,a	; busy and cannot accept data bytes at this time
	jr nz,wait_pic
	pop de
	scf
	ccf			; carry flag zero if OK
	ret



page_lo	db 0
page_med	db 0
page_hi	db 0

erase_sector db 0

;------------------------------------------------------------------------------------------
