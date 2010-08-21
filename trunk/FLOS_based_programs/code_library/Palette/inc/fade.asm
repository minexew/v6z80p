;---------------------------------------------------------------------------------
; Reads a source palette and brightens or darkens the RGB nybbles before
; writing the values to the a destination (normally the hardware palette registers)
;----------------------------------------------------------------------------------
;
;set ix = source colours
;set iy = dest palette
;set a = colour offset ($00-$0F = brighten, $0F = whitest / $F0-$FF = darken, F0 = darkest)
;set b = number of colours to do
	
palette_adjust
	
	bit 7,a
	jr nz,drkcols
	
	and $f
	ld e,a
	rrca
	rrca
	rrca
	rrca
	ld d,a
colwlp	ld a,(ix)
	ld l,a
	and $f
	add a,e
	bit 4,a
	jr z,nocar1
	ld a,$f
nocar1	ld h,a
	ld a,l
	and $f0
	add a,d
	jr nc,nocar2
	ld a,$f0
nocar2	or h
	ld (iy),a
	ld a,(ix+1)
	and $f
	add a,e
	bit 4,a
	jr z,nocar3
	ld a,$f
nocar3	ld (iy+1),a
	inc ix
	inc ix
	inc iy
	inc iy
	djnz colwlp
	ret

drkcols	neg
	and $f
	ld e,a
	rrca
	rrca
	rrca
	rrca
	ld d,a
colblp	ld a,(ix)
	ld l,a
	and $f
	sub e
	jr nc,nocar4
	xor a
nocar4	ld h,a
	ld a,l
	and $f0
	sub d
	jr nc,nocar5
	xor a
nocar5	or h
	ld (iy),a
	ld a,(ix+1)
	and $f
	sub e
	jr nc,nocar6
	xor a
nocar6	ld (iy+1),a
	inc ix
	inc ix
	inc iy
	inc iy
	djnz colblp
	ret
	
;---------------------------------------------------------------------------------------------