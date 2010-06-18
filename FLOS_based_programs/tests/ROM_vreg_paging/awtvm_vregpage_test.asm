
;---Standard header for OSCA and OS ----------------------------------------

include "kernal_jump_table.asm"	; essential equates
include "OSCA_hardware_equates.asm"	; ""	""
include "system_equates.asm"		; ""	""

; Tests paging out of video registers ($200-$7ff) WITH ALL WRITES TO VIDEO MODE
; Writes 02,03,04,05,06,07 to relevent lo ram pages,
; enables all writes to video mode
; fills 0-$fff with $55
; disables all writes to video mode
; reads and copies 200-7ff to $8000 - pages should be 2,3,4,5,6,7

	org $5000

;=======================================================================================

	di
	
	ld a,$80
	out (sys_alt_write_page),a	;page out video registers $200-$7ff
	
	ld hl,$200		;put 2,3,4,5,6,7 at apt pages
lp1	ld (hl),h
	inc hl
	ld a,h
	cp 8
	jr nz,lp1

	ld a,$20
	out (sys_mem_select),a	; set all writes to video mode
	
	ld hl,0			; fill $0000-FF00 with AA 
lp3	ld (hl),$55
	inc hl
	ld a,h
	cp $ff
	jr nz,lp3
	
	xor a
	out (sys_mem_select),a	; disable all writes to video mode

	ld hl,$200
	ld de,$8000
	ld bc,$600
	ldir

	xor a
	out (sys_alt_write_page),a	;page video registers back in

	ei
	xor a	
	ret
		
	
;--------------------------------------------------------------------------------------
	
