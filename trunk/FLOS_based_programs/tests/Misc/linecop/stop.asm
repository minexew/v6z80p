
; Tests linecop - writes an address with bit 0 clear, should disable linecop

;---Standard header for OSCA and FLOS  -----------------------------------------------------------------------

include "equates\kernal_jump_table.asm"
include "equates\OSCA_hardware_equates.asm"
include "equates\system_equates.asm"

	org $5000


linecop_code	equ $0			; $0000 to $FFFE = $70000 to $7FFFE in sys RAM (must be even)

;--------------------------------------------------------------------------------------------------------------

		ld a,0
		ld de,0
		ld (linecop_addr0),de		; set h/w location of line cop list
		or $80
		ld (linecop_addr2),a
		xor a				; and quit
		ret
