; Test dir cluster when deleting a cluster:
; G 5000, delete the dir, then G 5100

;======================================================================================
; Standard equates for OSCA and FLOS
;======================================================================================

include "\equates\kernal_jump_table.asm"
include "\equates\osca_hardware_equates.asm"
include "\equates\system_equates.asm"
	
	org $5000
		
	call kjt_get_dir_cluster
	ld (old_cluster),de
	xor a
	ret
	
	org $5100
	
	ld de,(old_cluster)
	call kjt_set_dir_cluster
	ret
	
old_cluster dw 0
