

;---Standard header for OSCA and FLOS ---------------------------------------------------------

include "kernal_jump_table.asm"
include "osca_hardware_equates.asm"
include "system_equates.asm"

	org $5000

;--------------------------------------------------------------------------------------------



	ld hl,var1			;delete
	call kjt_delete_envar
	jr z,endit
	ld hl,error2_txt
	call kjt_print_string
endit	xor a
	ret	
	

;--------------------------------------------------------------------------------------------

var1	db "PHIL"
data1	db $01,$02,$03,$04
var2	db "BEEP"
data2	db $05,$06,$07,$08

error1_txt	db "Not enough space for variable",11,0
error2_txt	db "Cant find that variable",11,0

