; Writes modulo value 0-255 on FLOS display
;
;---Standard header for OSCA and OS ----------------------------------------

include "kernal_jump_table.asm"
include "osca_hardware_equates.asm"
include "system_equates.asm"

	org $5000
	

;-----------------------------------------------------------------------------


wvrtstart	ld a,(vreg_read)		;wait for VRT
	and 1
	jr z,wvrtstart
wvrtend	ld a,(vreg_read)
	and 1
	jr nz,wvrtend

	call do_stuff
	
	in a,(sys_keyboard_data)
	cp $76
	jr nz,wvrtstart		; loop if ESC key not pressed
	xor a			; quit to FLOS
	ret


;--------------------------------------------------------------------------------------------------------

do_stuff	ld hl,counter
	inc (hl)
	ld a,(hl)
	ld (bitplane_modulo),a	;change modulo
	ret

;------------------------------------------------------------------------------------------------------

counter		db 0

;------------------------------------------------------------------------------
