;-----------------------------------------------------------------------

wibble	equ $500		 	; beep!
wobble	equ wibble+$50 		;
wubble	equ $5
total	equ wibble + wobble + wubble 	; stuff!

;-----------------------------------------------------------------------

first	ld a,10*3+(8-6)

some_place equ $38

	ld hl,total
	dec (ix-1)
	rl (ix-1)
	rr (ix-1)
	rlc (ix-1)
	rrc (ix-1)
	sra (ix-1)
	SRL (IX-1)
	sla (ix-1)
	sub (ix-1)
 	adc a,(ix-1)
	add a,(ix-1)
	cp (ix-1)
	inc (ix-1)
	ld (ix-1),wubble
	rst $0
	rst $8
	rst some_place
	bit 0,(ix-1)
	bit wubble,(iy+1)
	res 1,(ix-1)
	res wubble,(iy+1)
	set 0,(ix-1)
	set wubble,(iy+1)
	ld hl,first  ; blah
 	jp first
	jp $1000
	jr nz,first
	djnz first

 	ld a,(ix-1)
	ld a,(iy-2)
	ld (ix-3),a
 	ld (iy-4),a


 	db 5,4,3,2,1 ;guff
	
	dw $8005,$8104,$8203,$8302,$8301 ;guff
 	
 	ds 16,240

 
 	ld a,(ix+1)
 	ld a,(iy+2)
 	ld (ix+3),a
 	ld (iy+4),a
 	ld a,(ix-wubble)
 	ld a,(iy-wubble)
 	ld (ix-wubble),a
 	ld (iy-wubble),a
 	ld a,(ix+wubble)
 	ld a,(iy+wubble)
 	ld (ix+wubble),a
 	ld (iy+wubble),a
 	ld hl,($8000)		; blah
 	ld hl,(first)		; blah
 	ld a,33/11	
 	ld a,50>>1		;junk
	ld a,7<<2		;junk
	ld a,50>>0		;junk
  	ld a,7<<0		;junk
  	ld a,255		;junk
  	ld a,'z'		;junk
  	ld hl,'y'		;junk
 	ld hl,256+$3+%1010	;junk
	adc a,$10		;junk
	add a,%10100101		;junk
	and 230			;junk
	call $6581   		;junk
	call c,32768   		;junk
	call m,%1   		;junk
	call nc,$5f0   		;junk
	call nz,1001   		;junk
	call p,$3  		;junk
	call pe,4   		;junk
	call po,%1  		;junk
	call z,%0   		;junk
	ld hl,($8000)		; blah
	ld hl,(%1000000000000000)	; blah
	ld hl,(32768)		; blah
	ld (65535),hl		; blah
	ld a,($1011) 		; blah
	ld ($1012),a		; blah
	ld hl,(first)		; blah
	ld a,(first)		; blah
          ld hl,(wibble)		; blah
          ld (wobble),hl		; blah
          ld a,($1492) 		; blah
          ld ($1066),a		; blah
          ld a,(ix+25)		; blah
last      ld (iy-25),b		; blah

;-----------------------------------------------------------------------





