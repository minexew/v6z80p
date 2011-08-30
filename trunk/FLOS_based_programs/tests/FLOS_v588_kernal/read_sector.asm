
; Test low-level sector access
; With user defined sector buffer

;---Standard header for OSCA and OS ----------------------------------------

include "kernal_jump_table.asm"	; essential equates
include "OSCA_hardware_equates.asm"	; ""	""
include "system_equates.asm"		; ""	""

	org $5000

;=======================================================================================


	ld a,0
	call kjt_get_sector_read_addr	; get read routine for device 0

;HL = Address of sector read routine
;DE = Location of the LSB of the 32bit LBA variable
;BC = Location of the sector buffer location variable 


	push bc
	pop iy
	ld (iy),$00
	ld (iy+1),$80		; set sector buffer location to $8000
	
	push de
	pop ix
	ld (ix),0
	ld (ix+1),0
	ld (ix+2),0
	ld (ix+3),0		; set LBA to 0
	
	call fast_sector_read
	ret
	
		
fast_sector_read

	jp (hl)
	ret
	
;--------------------------------------------------------------------------------------
