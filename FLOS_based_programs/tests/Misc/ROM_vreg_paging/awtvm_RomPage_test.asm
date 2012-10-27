
;---Standard header for OSCA and OS ----------------------------------------

include "kernal_jump_table.asm"	; essential equates
include "OSCA_hardware_equates.asm"	; ""	""
include "system_equates.asm"		; ""	""


; Tests paging out ROM / Palette from $0-$1ff WITH "ALL WRITES TO VIDEO MODE" ENABLED

; 1. Pages out ROM
; 2. writes ff-00-ff to $000-$1ff (palette should NOT change)
; 3. Sets all writes to video mode
; 4. Fills 0000-FF00 with $aa (should go to video ram)
; 5. Disables all writes to video mode
; 6. Copies $000-$1ff to $8000
; 7. pages ROM / palette back in
; 8. 8000 should read 0->ff->00

	org $5000

;=======================================================================================

	di

	ld a,$40
	out (sys_alt_write_page),a	; page out ROM (set bit6)

	ld b,$ff
	ld hl,$000		; fill $0000-$00ff with $ff-$00 
loop1	ld (hl),b
	dec b
	inc l
	jr nz,loop1
	ld hl,$100
loop2	ld (hl),b			; fill $0100-$01ff with $00-$ff 
	inc b
	inc l
	jr nz,loop2


	ld a,$20
	out (sys_mem_select),a	; set all writes to video mode
	
	ld hl,0			; fill $0000-FF00 with AA 
lp3	ld (hl),$aa
	inc hl
	ld a,h
	cp $ff
	jr nz,lp3
	
	xor a
	out (sys_mem_select),a	; disable all writes to video mode
	
	ld hl,0			; copy $0000-$01ff to $8000
	ld de,$8000
	ld bc,$200
	ldir

	xor a
	out (sys_alt_write_page),a	; Normal mode: ROM/palette at $000

	ei
	ret
		
	
;--------------------------------------------------------------------------------------
	
