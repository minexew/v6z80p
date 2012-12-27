;-----------------------------------------------------------------------------------------------------------------
; EEPROM / PIC programming related routines
;-----------------------------------------------------------------------------------------------------------------
;
; Routine List
; ------------
;
; read_eeprom_page - read in EEPROM page "DE" to internal array "page_buffer" (each page is 256 bytes)
;
;------------------------------------------------------------------------------------------------------------------

read_eeprom_page

		di
		push hl			; put page number to read to buffer in DE
		push de
		push bc
		
		in a,(sys_eeprom_byte)		; at outset, clear input byte shift count with a read
		
		ld (rep_addr+1),de		; fill in values for databurst command sequence 
		ld a,0
		ld (rep_addr+0),a
	
		ld hl,databurst_sequence	; send PIC the commands to send data from EEPROM
		call send_pic_command
		
		ld hl,page_buffer		; download loop.. 
		ld bc,$100			; page = 256 bytes                 

rep_nxt_byte	ld d,0				; D counts timer overflows
		ld a,1<<pic_clock_input		; raise clock to prompt PIC to send a byte
		out (sys_pic_comms),a

rep_wbc_byte	in a,(sys_hw_flags)		; have 8 bits been received?		
		bit 4,a
		jr nz,rep_gbcbyte
		in a,(sys_irq_ps2_flags)	; check for timer overflow..
		and 4
		jr z,rep_wbc_byte	
		out (sys_clear_irq_flags),a	; clear timer overflow flag
		inc d				; inc count of overflows,
		jr nz,rep_wbc_byte			
		call kjt_get_key		; as IRQs were switched off, clear the keyboard buffer in case of mangled input		
		pop bc
		pop de
		pop hl
		ei
		ld a,1
		or a
		ret
						
rep_gbcbyte	xor a				; drop pic clock
		out (sys_pic_comms),a	
		in a,(sys_eeprom_byte)		; read byte received (clears bit count)
		ld (hl),a			; copy to dest, loop back to wait for next byte
		inc hl
		dec bc
		ld a,b
		or c
		jr nz,rep_nxt_byte
		call kjt_get_key		; as IRQs were switched off, clear the keyboard buffer in case of mangled input
		pop bc
		pop de
		pop hl
		ei
		xor a
		ret		


databurst_sequence

		db 12
		
		db $88,$d4			; $88,$d4 = set address
rep_addr	db $00,$00,$00			; (low,mid,high)

		db $88,$e2			; $88,$e2 = set length
rep_length	db $00,$01,$00			; (low,mid,high)

		db $88,$c9			; $88,$c9 = begin transfer!

				    
page_buffer	ds 256,0

