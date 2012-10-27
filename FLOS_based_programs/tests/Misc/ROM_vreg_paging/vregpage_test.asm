
;---Standard header for OSCA and OS ----------------------------------------

include "kernal_jump_table.asm"	; essential equates
include "OSCA_hardware_equates.asm"	; ""	""
include "system_equates.asm"		; ""	""

; Tests paging out of video registers ($200-$7ff)
; Writes 02,03,04,05,06,07 to relevent lo ram pages, reads and copies to $8000
; (Should NOT affect video registers between $200-$7ff)

	org $5000

;=======================================================================================

	ld a,$80
	out (sys_alt_write_page),a	;page out video registers $200-$7ff
	
	ld hl,$200
lp1	ld (hl),h
	inc hl
	ld a,h
	cp 8
	jr nz,lp1

	ld hl,$200
	ld de,$8000
	ld bc,$600
	ldir
	
	xor a
	out (sys_alt_write_page),a	;page video registers back in
	
	xor a	
	ret
		
	
;--------------------------------------------------------------------------------------
	
