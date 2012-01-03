;----------------------------------------------------------------------------------------------------
;Thanks to Milos "baze" Bazelides: http://baze.au.com/misc/z80bits.html for collecting these routines
;----------------------------------------------------------------------------------------------------

;Input: HL = Radicand
;Output: A = Radix 

square_root16

	ld	a,-1
	ld	d,a
	ld	e,a
Sqrt16	add	hl,de
	inc	a
	dec	e
	dec	de
	jp	c,Sqrt16	

	ret
	
;--------------------------------------------------------------------------------------------------
