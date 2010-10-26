
; Checks that the ROM resets the window back to $2000 
; (Should reboot normally).


vram equ $e000


;---Standard header for OSCA and FLOS ----------------------------------------

include "kernal_jump_table.asm"
include "OSCA_hardware_equates.asm"
include "system_equates.asm"

	org $5000

;-----------------------------------------------------------------------------

	ld a,vram/$2000
	out (sys_vram_location),a		; Locate 8KB VRAM page at Z80 $6000-$7FFF

	rst $0

;-----------------------------------------------------------------------------
	