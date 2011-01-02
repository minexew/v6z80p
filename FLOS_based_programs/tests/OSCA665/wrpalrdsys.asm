
;---Standard header for OSCA and OS ----------------------------------------

include "kernal_jump_table.asm"	; essential equates
include "OSCA_hardware_equates.asm"	; ""	""
include "system_equates.asm"		; ""	""


; Tests wr_palette/rd_sysram_mode

; 1. selects sysram @ 0-1ff mode
; 2. writes ff->00->ff to $000-$1ff (palette should NOT change)
; 3. copy $0-$1ff to $8000
; 3. Selects wr_palette/rd_system mode
; 4. write some values to $000-$1ff (palette SHOULD change)
; 5. copy $0-$1ff to $8200
; 6. Deselects wr_palette/rd_system mode
; 7. Data at $8000 and $8200 should be same as that written in stage 2


	org $5000

;=======================================================================================

	di
		
	ld a,$40
	out (sys_alt_write_page),a	; select sysram rd/wr at $000-$1ff

	ld de,$1000
loop5	ld b,$ff
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
	dec de
	ld a,d
	or e
	jr nz,loop5
	ld hl,0			; copy $0000-$01ff to $8000
	ld de,$8000
	ld bc,$200
	ldir



	ld a,$10
	out (sys_alt_write_page),a	; select wr_pal/rd_sysram mode
	ld de,$1000
loop4	ld hl,$000
	ld b,0
loop3	ld (hl),d
	inc hl
	ld (hl),e
	inc hl
	djnz loop3
	dec de
	ld a,d
	or e
	jr nz,loop4
	ld hl,0			; copy $0000-$01ff to $8200
	ld de,$8200
	ld bc,$200
	ldir

	xor a
	out (sys_alt_write_page),a	; Normal mode: rd_ROM / wr_palette

	ld a,$ff			;restart OS
	ei
	ret
		
	
;--------------------------------------------------------------------------------------
