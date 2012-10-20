;----------------------------------------------------------------------------------------------------
;Thanks to Milos "baze" Bazelides: http://baze.au.com/misc/z80bits.html for collecting these routines
;----------------------------------------------------------------------------------------------------

;Restoring 32-bit / 8-bit Unsigned
;Input: DE:HL = Dividend, C = Divisor
;Output: DE:HL = Quotient, A = Remainder 

divide_32_8

		ld 	b,32
		xor 	a
	
div32_8lp	add	hl,hl		; 32 iterations
		rl	e		; 
		rl	d		; 
		rla			; 
		cp	c		; 
		jr	c,$+4		; 
		sub	c		; 
		inc	l		; 

		djnz	div32_8lp
		ret

;------------------------------------------------------------------------------
	