; just counts upwards - value written to port 0


	org $0
	
;-----------------------------------------------------------------------------

	di
	
	ld e,0
	
	ld bc,0			;wait 65536 loops
lp1	inc bc
	ld a,b
	or c
	jr nz,lp1
	
	ld a,e
	out (0),a
	inc e
	
	jr lp1

;-----------------------------------------------------------------------------
			