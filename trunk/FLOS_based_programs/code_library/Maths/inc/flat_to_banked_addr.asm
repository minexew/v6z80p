
;--------------------------------------------------------------------------

flat_to_banked_addr

;set A:HL to flat ram addr
;result in B:HL
;if B < 15 ZF set: all OK.

	sla h			; Convert A:HL flat address to FLOS B:HL bank:address	
	rla			; (bank also returned in A)
	jr c,ftba_er
	
	or a
	jr nz,ftba_hi
	rr h
	ld b,a			; Result when A:HL < $08000
	ret

ftba_hi	scf
	rr h
	dec a
	ld b,a
	cp 15
	jr nc,ftba_er
ftba_ok	cp a	
	ret
	
ftba_er	xor a
	dec a
	ld b,a
	ret
	
;--------------------------------------------------------------------------
