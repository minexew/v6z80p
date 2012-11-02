;----------------------------------------------------------------------
;"A:HL flat address 0-7FFFF" to "FLOS Bank (B), 32KB Page address (HL)"
;----------------------------------------------------------------------
;
; Examples:
;
; Source A:HL = $05000, result B=$0,HL=$5000 (paging not used, first 64KB)
;             = $08000, result B=$0,HL=$8000 (paging not used, first 64KB)
;             = $12000, result B=$1,HL=$A000 (paging used, upper 32KB paged)
;             = $14000, result B=$2,HL=$C000 (paging used, upper 32KB paged)
;             = $18000, result B=$3,HL=$8000 (paging used, upper 32KB paged)
;
;-----------------------------------------------------------------

flat_to_banked_addr

;set A:HL to flat ram addr
;result in B:HL (also A:HL)
;
;if B < 15 ZF set = all OK.

	sla h			; Convert A:HL flat address to FLOS B:HL bank:address	
	rla			; (bank also returned in A)
	jr c,ftba_er
	
	or a
	jr nz,ftba_hi
	rr h
	ld b,a			; Result when A:HL < $08000
	cp a
	ret

ftba_hi	scf
	rr h
	dec a
	cp 15
	jr nc,ftba_er
ftba_ok	ld b,a
	cp a	
	ret
	
ftba_er	ld b,$ff		;set bank to an invalid value 
	ld a,$08		;return address out of range error if >$7ffff
	or a
	ret
	
;--------------------------------------------------------------------------
