;----------------------------------------------------------------------------------------------
; SERIAL ROUTINES
;-----------------------------------------------------------------------------------------------

serial_port   equ $ff
serial_flags  equ $fe

serial_header equ $3c00

;------------------------------------------------------------------------------------------------

s_getblock

; loads a block of 256 bytes to HL, and 2 extra bytes for CRC checksum
; carry flag is set on CRC error

	ld c,0
	exx
	ld hl,$ffff			; initial CRC checksum value
	exx
s_lgb	call receive_serial_byte
	ld (hl),a
	call crc_calc
	and 7
	out (254),a
	inc hl				; hl = next dest address for data bytes
	dec c
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
	
wait_sb	in a,(serial_flags)			; if bit 5 of status flags = 1, byte is in buffer 
	bit 5,a
	jr z,wait_sb
	in a,(serial_port)			; get serial byte in A - this also clears rdy flag
	ret
	
	
;------------------------------------------------------------------------------------------------

send_serial_bytes

; set D to the first byte to send
; and E to the second byte to send

	ld c,2
s_wait	in a,(serial_flags)			; ensure no byte is still being transmitted
	bit 7,a
	jr nz,s_wait
	ld a,d
	out (serial_port),a
	ld b,32				; limit send speed (gap between bytes)
ssplim	djnz ssplim
	ld d,e
	dec c
	jr nz,s_wait
	ret
	
;------------------------------------------------------------------------------------------------
; END OF SERIAL CODE
;------------------------------------------------------------------------------------------------
