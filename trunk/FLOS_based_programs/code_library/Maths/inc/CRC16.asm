;----------------------------------------------------------------------------------------------------
;Thanks to Milos "baze" Bazelides: http://baze.au.com/misc/z80bits.html for collecting these routines
;----------------------------------------------------------------------------------------------------

; makes checksum in HL, src addr = DE, length = C bytes

crc_16

	ld hl,$ffff		
crcloop	ld a,(de)			
	xor h			
	ld h,a			
	ld b,8
crcbyte	add hl,hl
	jr nc,crcnext
	ld a,h
	xor 10h
	ld h,a
	ld a,l
	xor 21h
	ld l,a
crcnext	djnz crcbyte
	inc de
	dec c
	jr nz,crcloop
	ret
	
;--------------------------------------------------------------------------------------------------
