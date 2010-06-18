;--------------------------------------------------------------------------------------------------

; input : none
; output: HL = random number 


get_rand	ld	de,(seed)		
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
