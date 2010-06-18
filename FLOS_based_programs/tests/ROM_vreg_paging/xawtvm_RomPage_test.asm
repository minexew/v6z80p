
;---Standard header for OSCA and OS ----------------------------------------

include "kernal_jump_table.asm"	; essential equates
include "OSCA_hardware_equates.asm"	; ""	""
include "system_equates.asm"		; ""	""


; Tests paging out ROM / Palette from $0-$1ff WITH "ALL WRITES TO VIDEO MODE"
; BUT WITH $000-$FFF exception

; 1. Pages out ROM
; 2. writes ff-00-ff to $000-$1ff
; 3. Sets all writes to video mode with 4k exception
; 4. Fills 0000-1FF with $aa (should go to sys ram)
; 5. Fills 1000-$ff00 with $bb (should go to video ram)
; 6. Disables all writes to video mode
; 7. Copies $000-$1ff to $8000
; 8. pages ROM / palette back in
; 9. 8000 should read $AA

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


	ld a,$60
	out (sys_mem_select),a	; set all writes to video mode with $0-$fff exception
	
	ld hl,0			; fill $0000-1FF with AA 
lp3	ld (hl),$aa
	inc hl
	ld a,h
	cp $2
	jr nz,lp3

	ld hl,$1000		; fill $1000-FF00 with BB 
lp4	ld (hl),$bb
	inc hl
	ld a,h
	cp $f0
	jr nz,lp4

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
	
