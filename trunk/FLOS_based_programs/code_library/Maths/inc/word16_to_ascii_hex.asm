;----------------------------------------------------------------------------------------------------
;Thanks to Milos "baze" Bazelides: http://baze.au.com/misc/z80bits.html for collecting these routines
;----------------------------------------------------------------------------------------------------

;16-bit Integer to ASCII (hexadecimal)
;Hexadecimal conversion operates directly on nibbles and takes advantage of nifty DAA trick.
;Input: HL = number to convert, DE = location of ASCII string
;Output: ASCII string at (DE)
;Includes leading zeroes

word16_to_ascii_hex

	ld	a,h
	call	Num1
	ld	a,h
	call	Num2
	ld	a,l
	call	Num1
	ld	a,l
	jr	Num2

Num1	rra
	rra
	rra
	rra
Num2	or	F0h
	daa
	add	a,A0h
	adc	a,40h

	ld	(de),a
	inc	de
	ret
	
;--------------------------------------------------------------------------------------------------
