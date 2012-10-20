;----------------------------------------------------------------------------------------------------
;Thanks to Milos "baze" Bazelides: http://baze.au.com/misc/z80bits.html for collecting these routines
;----------------------------------------------------------------------------------------------------

; input  H = multiplier, E = multiplicand
; output HL = product
	
multiply_8_8

		ld l,0			; Multiply H by E, result in HL
		ld d,l
		sla h		
		jr nc,muliter1
		ld l,e
muliter1	add hl,hl		
		jr nc,muliter2	
		add hl,de		
muliter2	add hl,hl		
		jr nc,muliter3	
		add hl,de		
muliter3	add hl,hl		
		jr nc,muliter4	
		add hl,de		
muliter4	add hl,hl		
		jr nc,muliter5	
		add hl,de		
muliter5	add hl,hl		
		jr nc,muliter6	
		add hl,de		
muliter6	add hl,hl		
		jr nc,muliter7	
		add hl,de		
muliter7	add hl,hl		
		jr nc,muliter8	
		add hl,de		
muliter8	ret
	
	
;--------------------------------------------------------------------------------------------------
