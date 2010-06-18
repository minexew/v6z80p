
;---Standard header for OSCA and OS ----------------------------------------

include "kernal_jump_table.asm"	; essential equates
include "OSCA_hardware_equates.asm"	; ""	""
include "system_equates.asm"		; ""	""


; Tests paging out ROM / Palette from $0-$1ff

; 1. pages out ROM
; 2. writes ff-00-ff to $000-$1ff (palette should NOT change) copies to $8000
; 3. pages ROM / palette back in
; 4. writes 55+ to 0-$1ff (palette SHOULD change)
; 5. pages ROM / palette out
; 6. copies $000-$1ff to $8200
; 7. pages ROM / palette back in
; 7. 8000-81ff and 8200-83ff should be the same


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

	ld hl,0			; copy $0000-$01ff to $8000
	ld de,$8000
	ld bc,$200
	ldir

	xor a
	out (sys_alt_write_page),a	; Normal mode: ROM/palette at $000

	ld a,$55
	ld hl,0			; fill $0000-$01ff with $55+
loop3	ld (hl),a			; this should write to the palette and not
	inc a			; change the memory under the ROM
	inc l			
	jr nz,loop3
loop4	ld (hl),a		 
	inc a
	inc l			
	jr nz,loop4

	ld a,$40
	out (sys_alt_write_page),a	; Page out ROM (set bit 5)

	ld hl,0			; copy $0000-$01ff to $8200
	ld de,$8200
	ld bc,$200
	ldir

	xor a
	out (sys_alt_write_page),a	; normal mode: ROM at $000

	ei
	ret
		
	
;--------------------------------------------------------------------------------------
	
