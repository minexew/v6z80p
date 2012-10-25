	org $5000
	
	ld a,($+3)
	ret
	
	org $5010
	
	jr $+2
	ret
	
	org $5020
	jp $+3
	ret
	
	org $5030
	jp $
	
	org $5040
	jr $-1
	
	
	org $5050
	
	ld a,-1
	djnz $+2
	call c,$
	jp c,$
	call nz,$
	jp nc,$
	jr nz,$-2
	
	ld a,5|$80		;test OR
	ld a,$ff&$aa>>1		;test AND
	ret
	
	org $+255&$ff00		;test page align
	
	di
	ei
	ret
	