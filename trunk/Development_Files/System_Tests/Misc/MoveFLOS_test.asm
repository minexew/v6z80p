
; This just copies the contents of $1000-$4fff to $8000, allowing
; the status of FLOS to be examined, following a crash before the
; bootloader overwrites it with a fresh load.

include "OSCA_hardware_equates.asm"
include "system_equates.asm"

;-----------------------------------------------------------------------------------------
	org OS_location+$10		
;-----------------------------------------------------------------------------------------

	
	ld hl,$1000
	ld de,$8000
	ld bc,$4000
	ldir

	rst 0
	

;-----------------------------------------------------------------------------------------
