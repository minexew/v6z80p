;Tests rename kernal call

;---Standard source header for OSCA and FLOS ------------------------------------------

include "kernal_jump_table.asm"	; essential equates
include "OSCA_hardware_equates.asm"	; ""	""
include "system_equates.asm"		; ""	""

	org $5000

;----------------------------------------------------------------------------------------------


	ld hl,filename
	ld de,newname
	call kjt_rename_file
	ret
	

filename	db "test",0

newname	db "newtest",0
	