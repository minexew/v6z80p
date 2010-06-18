;----------------------------------------------------------------------------------------------
; SERIAL CODE
;-----------------------------------------------------------------------------------------------

s_getblock

; loads a block of 256 bytes to HL (L must be 0), and 2 extra bytes for CRC checksum
; carry flag is set on time out CRC error

	ld c,0
	exx
	ld hl,$ffff			; initial CRC checksum value
	exx
s_lgb	call receive_serial_byte
	ret c				; timed out if carry = 1	
	ld (hl),a
	call crc_calc
	inc hl				; hl = next dest address for data bytes
	ld a,h
	or l
	jr nz,samebank
	in a,(sys_mem_select)		; overflow from $FFFF, next bank!
	inc a
	out (sys_mem_select),a
	ld h,$80				; wrap dest addr around to $8000
samebank	dec c
	jr nz,s_lgb
	exx				; hl = calculated CRC

	call receive_serial_byte		; get 2 more bytes - block checksum in bc
	ret c
	ld c,a
	call receive_serial_byte
	ret c		
	ld b,a
	
	xor a				; compare checksum
	sbc hl,bc
	exx				; put address back in HL before exit
	ret z
	scf
	ret

	
;-------------------------------------------------------------------------------------------


crc_calc
	exx
	xor h				; do CRC calculation from A, to 'HL		
	ld h,a				
	ld b,8
rxcrcbyte	add hl,hl
	jr nc,rxcrcnext
	ld a,h
	xor 10h
	ld h,a
	ld a,l
	xor 21h
	ld l,a
rxcrcnext	djnz rxcrcbyte
	exx
	ret

		
;--------------------------------------------------------------------------------------------


s_goodack	push de
	ld de,$4f4b			; send "OK" ack to host
	call send_serial_bytes
	pop de
	ret


;---------------------------------------------------------------------------------------------
		

receive_serial_byte
	
	ld b,0
wait_sb	in a,(sys_joy_com_flags)		; if bit 6 of status flags = 1, byte is in buffer 
	bit 6,a
	jr nz,sbyte_in
	in a,(sys_irq_ps2_flags)
	and 4				; if bit 2 of status flags = 1, timer has overflowed
	jr z,wait_sb
	out (sys_clear_irq_flags),a		; clear timer overflow flag
	djnz wait_sb				
	scf 				; time out after 1 second
	ret
sbyte_in	in a,(sys_serial_port)		; get serial byte in A - this also clears bit 6 of status flags
	or a			
	ret
	
	
;------------------------------------------------------------------------------------------------

send_serial_bytes

; set D to the first byte to send
; and E to the second byte to send

	ld c,2
s_wait	in a,(sys_joy_com_flags)		; ensure no byte is still being transmitted
	bit 7,a
	jr nz,s_wait
	ld a,d
	out (sys_serial_port),a
	ld b,32				; limit send speed (gap between bytes)
ssplim	djnz ssplim
	ld d,e
	dec c
	jr nz,s_wait
	ret
	
;------------------------------------------------------------------------------------------------
