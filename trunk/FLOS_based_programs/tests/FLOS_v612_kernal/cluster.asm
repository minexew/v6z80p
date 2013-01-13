; Test dir cluster update when supplied with value

;======================================================================================
; Standard equates for OSCA and FLOS
;======================================================================================

include "\equates\kernal_jump_table.asm"
include "\equates\osca_hardware_equates.asm"
include "\equates\system_equates.asm"
	
	
	ld de,$1234
	call kjt_set_dir_cluster
	ret
	
	