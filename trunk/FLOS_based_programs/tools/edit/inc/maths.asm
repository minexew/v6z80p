;-----------------------------------------------------------------------------------------------

ascii_dec_to_hex_word

; src number string in HL, output in DE (on return HL = first char not part of the number)
; CF set if > 65535. ZF not set if garbage encountered 

	ex de,hl
	call decimain
	ex de,hl
	ret

decimain	ld hl,0
deciloop	ld a,(de)
	or a
	jr z,deci_done
	sub $30			
	jr c,deci_bad
	cp $0a
	jr nc,deci_bad
	add hl,hl
	ret c
	push hl
	pop bc
	add hl,hl
	ret c
	add hl,hl
	ret c
	add hl,bc
	ret c
	ld b,0	
	ld c,a
	add hl,bc
	ret c
	inc de
	jr deciloop
	
deci_done	xor a
	ret
	
deci_bad	xor a
	inc a
	ret
	

;------------------------------------------------------------------------------------------------

