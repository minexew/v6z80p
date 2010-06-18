; tests responses to code started from GOTO command


;---Standard header for OSCA and OS ----------------------------------------

include "kernal_jump_table.asm"	; essential equates
include "OSCA_hardware_equates.asm"	; ""	""
include "system_equates.asm"		; ""	""

	org $5000

;=======================================================================================


	ld a,$20		
	or a			;should report normal OS error ("OK")
	ret	
	
	
	
	org $5010
	
	xor a
	ld a,1			;nothing should happen as ZF is set on exit
	ret
	
	
	
	org $5020
		
	ld b,$12			;should report driver error bits	
	ld a,1
	or a
	ld a,0
	ret
	
	
	org $5030
	
	xor a
	ld a,$ff			;restart
	ret

	
	org $5040
	
	xor a
	ld a,$fe			; spawn
	ld hl,comline
	ret


;--------------------------------------------------------------------------------------

comline	db "cd hats",0
