;----------------------------------------------------------------------------------------------------
;Thanks to Milos "baze" Bazelides: http://baze.au.com/misc/z80bits.html for collecting these routines
;----------------------------------------------------------------------------------------------------

;Input: A:C = Dividend, DE = Divisor
;Output: BC = Quotient, HL = Remainder 

div16_16
	ld	hl,0
	
	rl	c		; iteration 1
	rla			; 
	adc	hl,hl		; 
	sbc	hl,de		; 
	jr	nc,$+3		; 
	add	hl,de		; 

	rl	c		; iteration 2
	rla			; 
	adc	hl,hl		; 
	sbc	hl,de		; 
	jr	nc,$+3		; 
	add	hl,de		; 

	rl	c		; iteration 3
	rla			; 
	adc	hl,hl		; 
	sbc	hl,de		; 
	jr	nc,$+3		; 
	add	hl,de		; 
	
	rl	c		; iteration 4
	rla			; 
	adc	hl,hl		; 
	sbc	hl,de		; 
	jr	nc,$+3		; 
	add	hl,de		; 
	
	rl	c		; iteration 5
	rla			; 
	adc	hl,hl		; 
	sbc	hl,de		; 
	jr	nc,$+3		; 
	add	hl,de		; 
		
	rl	c		; iteration 6
	rla			; 
	adc	hl,hl		; 
	sbc	hl,de		; 
	jr	nc,$+3		; 
	add	hl,de		; 
		
	rl	c		; iteration 7
	rla			; 
	adc	hl,hl		; 
	sbc	hl,de		; 
	jr	nc,$+3		; 
	add	hl,de		; 
		
	rl	c		; iteration 8
	rla			; 
	adc	hl,hl		; 
	sbc	hl,de		; 
	jr	nc,$+3		; 
	add	hl,de		; 
	
	rl	c		; iteration 9
	rla			; 
	adc	hl,hl		; 
	sbc	hl,de		; 
	jr	nc,$+3		; 
	add	hl,de		; 
		
	rl	c		; iteration 10
	rla			; 
	adc	hl,hl		; 
	sbc	hl,de		; 
	jr	nc,$+3		; 
	add	hl,de		; 
	
	rl	c		; iteration 11
	rla			; 
	adc	hl,hl		; 
	sbc	hl,de		; 
	jr	nc,$+3		; 
	add	hl,de		; 
	
	rl	c		; iteration 12
	rla			; 
	adc	hl,hl		; 
	sbc	hl,de		; 
	jr	nc,$+3		; 
	add	hl,de		; 
	
	rl	c		; iteration 13
	rla			; 
	adc	hl,hl		; 
	sbc	hl,de		; 
	jr	nc,$+3		; 
	add	hl,de		; 
	
	rl	c		; iteration 14
	rla			; 
	adc	hl,hl		; 
	sbc	hl,de		; 
	jr	nc,$+3		; 
	add	hl,de		; 
	
	rl	c		; iteration 15
	rla			; 
	adc	hl,hl		; 
	sbc	hl,de		; 
	jr	nc,$+3		; 
	add	hl,de		; 

	rl	c		; iteration 16
	rla			; 
	adc	hl,hl		; 
	sbc	hl,de		; 
	jr	nc,$+3		; 
	add	hl,de		; 
	
	rl	c
	rla
	cpl
	ld	b,a
	ld	a,c
	cpl
	ld	c,a

	ret
	
;--------------------------------------------------------------------------------------------------
	