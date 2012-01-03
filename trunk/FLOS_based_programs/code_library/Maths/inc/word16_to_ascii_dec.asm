;----------------------------------------------------------------------------------------------------
;Thanks to Milos "baze" Bazelides: http://baze.au.com/misc/z80bits.html for collecting these routines
;----------------------------------------------------------------------------------------------------

word16_to_ascii_dec

; HL = word to convert
; DE = location of output string

; Note: Includes leading zeroes

	ld	bc,-10000
	call	Num1
	ld	bc,-1000
	call	Num1
	ld	bc,-100
	call	Num1
	ld	c,-10
	call	Num1
	ld	c,-1

Num1	ld	a,'0'-1
Num2	inc	a
	add	hl,bc
	jr	c,Num2
	sbc	hl,bc

	ld	(de),a
	inc	de
	ret
	
;----------------------------------------------------------------------------------------------
	