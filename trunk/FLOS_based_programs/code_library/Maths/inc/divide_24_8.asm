;----------------------------------------------------------------------------------------------------
;Thanks to Milos "baze" Bazelides: http://baze.au.com/misc/z80bits.html for collecting these routines
;----------------------------------------------------------------------------------------------------

;Restoring 24-bit / 8-bit Unsigned

;Input: E:HL = Dividend, D = Divisor
;Output: E:HL = Quotient, A = Remainder 

divide_24_8

	xor a
	
	add	hl,hl		; iteration 1
	rl	e		; 
	rla			; 
	cp	d		; 
	jr	c,$+4		; 
	sub	d		; 
	inc	l		; 

	add	hl,hl		; iteration 2
	rl	e		; 
	rla			; 
	cp	d		; 
	jr	c,$+4		; 
	sub	d		; 
	inc	l		; 

	add	hl,hl		; iteration 3
	rl	e		; 
	rla			; 
	cp	d		; 
	jr	c,$+4		; 
	sub	d		; 
	inc	l		; 

	add	hl,hl		; iteration 4
	rl	e		; 
	rla			; 
	cp	d		; 
	jr	c,$+4		; 
	sub	d		; 
	inc	l		; 

	add	hl,hl		; iteration 5
	rl	e		; 
	rla			; 
	cp	d		; 
	jr	c,$+4		; 
	sub	d		; 
	inc	l		; 

	add	hl,hl		; iteration 6
	rl	e		; 
	rla			; 
	cp	d		; 
	jr	c,$+4		; 
	sub	d		; 
	inc	l		; 

	add	hl,hl		; iteration 7
	rl	e		; 
	rla			; 
	cp	d		; 
	jr	c,$+4		; 
	sub	d		; 
	inc	l		; 

	add	hl,hl		; iteration 8
	rl	e		; 
	rla			; 
	cp	d		; 
	jr	c,$+4		; 
	sub	d		; 
	inc	l		; 

	add	hl,hl		; iteration 9
	rl	e		; 
	rla			; 
	cp	d		; 
	jr	c,$+4		; 
	sub	d		; 
	inc	l		; 

	add	hl,hl		; iteration 10
	rl	e		; 
	rla			; 
	cp	d		; 
	jr	c,$+4		; 
	sub	d		; 
	inc	l		; 

	add	hl,hl		; iteration 11
	rl	e		; 
	rla			; 
	cp	d		; 
	jr	c,$+4		; 
	sub	d		; 
	inc	l		; 

	add	hl,hl		; iteration 12
	rl	e		; 
	rla			; 
	cp	d		; 
	jr	c,$+4		; 
	sub	d		; 
	inc	l		; 

	add	hl,hl		; iteration 13
	rl	e		; 
	rla			; 
	cp	d		; 
	jr	c,$+4		; 
	sub	d		; 
	inc	l		; 

	add	hl,hl		; iteration 14
	rl	e		; 
	rla			; 
	cp	d		; 
	jr	c,$+4		; 
	sub	d		; 
	inc	l		; 

	add	hl,hl		; iteration 15
	rl	e		; 
	rla			; 
	cp	d		; 
	jr	c,$+4		; 
	sub	d		; 
	inc	l		; 

	add	hl,hl		; iteration 16
	rl	e		; 
	rla			; 
	cp	d		; 
	jr	c,$+4		; 
	sub	d		; 
	inc	l		; 

	add	hl,hl		; iteration 17
	rl	e		; 
	rla			; 
	cp	d		; 
	jr	c,$+4		; 
	sub	d		; 
	inc	l		; 

	add	hl,hl		; iteration 18
	rl	e		; 
	rla			; 
	cp	d		; 
	jr	c,$+4		; 
	sub	d		; 
	inc	l		; 

	add	hl,hl		; iteration 19
	rl	e		; 
	rla			; 
	cp	d		; 
	jr	c,$+4		; 
	sub	d		; 
	inc	l		; 

	add	hl,hl		; iteration 20
	rl	e		; 
	rla			; 
	cp	d		; 
	jr	c,$+4		; 
	sub	d		; 
	inc	l		; 

	add	hl,hl		; iteration 21
	rl	e		; 
	rla			; 
	cp	d		; 
	jr	c,$+4		; 
	sub	d		; 
	inc	l		; 

	add	hl,hl		; iteration 22
	rl	e		; 
	rla			; 
	cp	d		; 
	jr	c,$+4		; 
	sub	d		; 
	inc	l		; 

	add	hl,hl		; iteration 23
	rl	e		; 
	rla			; 
	cp	d		; 
	jr	c,$+4		; 
	sub	d		; 
	inc	l		; 

	add	hl,hl		; iteration 24
	rl	e		; 
	rla			; 
	cp	d		; 
	jr	c,$+4		; 
	sub	d		; 
	inc	l		; 
	
	ret
	
	
;----------------------------------------------------------------------------------------
	