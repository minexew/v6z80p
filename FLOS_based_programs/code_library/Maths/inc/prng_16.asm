;----------------------------------------------------------------------------------------------------
;Thanks to Milos "baze" Bazelides: http://baze.au.com/misc/z80bits.html for collecting these routines
;----------------------------------------------------------------------------------------------------

; input : none
; output: HL = random number 


rand_16	ld	de,(seed)		
	ld	a,d
	ld	h,e
	ld	l,253
	or	a
	sbc	hl,de
	sbc	a,0
	sbc	hl,de
	ld	d,0
	sbc	a,d
	ld	e,a
	sbc	hl,de
	jr	nc,rand
	inc	hl
rand	ld	(seed),hl		
	ret
	
seed	dw $d297

;--------------------------------------------------------------------------------------------------
