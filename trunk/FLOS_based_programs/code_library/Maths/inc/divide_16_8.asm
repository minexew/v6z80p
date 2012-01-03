;----------------------------------------------------------------------------------------------------
;Thanks to Milos "baze" Bazelides: http://baze.au.com/misc/z80bits.html for collecting these routines
;----------------------------------------------------------------------------------------------------

divide_16_8	

;Input:  HL = Dividend, C = Divisor
;Output: HL = Quotient, A = Remainder

	xor a
	
	add hl,hl		
	rla		
	cp c		
	jr c,divit1	
	sub c		
	inc l		

divit1	add hl,hl		
	rla		
	cp c		
	jr c,divit2	
	sub c		
	inc l		

divit2	add hl,hl		
	rla		
	cp c		
	jr c,divit3	
	sub c		
	inc l		

divit3	add hl,hl		
	rla		
	cp c		
	jr c,divit4	
	sub c		
	inc l		

divit4	add hl,hl		
	rla		
	cp c		
	jr c,divit5	
	sub c		
	inc l		

divit5	add hl,hl		
	rla		
	cp c		
	jr c,divit6	
	sub c		
	inc l		

divit6	add hl,hl		
	rla		
	cp c		
	jr c,divit7	
	sub c		
	inc l		

divit7	add hl,hl		
	rla		
	cp c		
	jr c,divit8	
	sub c		
	inc l		

divit8	add hl,hl		
	rla		
	cp c		
	jr c,divit9	
	sub c		
	inc l		

divit9	add hl,hl		
	rla		
	cp c		
	jr c,divit10	
	sub c		
	inc l		

divit10	add hl,hl		
	rla		
	cp c		
	jr c,divit11	
	sub c		
	inc l		

divit11	add hl,hl		
	rla		
	cp c		
	jr c,divit12	
	sub c		
	inc l		

divit12	add hl,hl		
	rla		
	cp c		
	jr c,divit13	
	sub c		
	inc l		

divit13	add hl,hl		
	rla		
	cp c		
	jr c,divit14	
	sub c		
	inc l		

divit14	add hl,hl		
	rla		
	cp c		
	jr c,divit15	
	sub c		
	inc l		

divit15	add hl,hl		
	rla		
	cp c		
	jr c,divit16	
	sub c		
	inc l		

divit16	ret



;--------------------------------------------------------------------------------------------------
