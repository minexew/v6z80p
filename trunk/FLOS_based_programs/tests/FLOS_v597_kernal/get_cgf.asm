
; Tests loading an external file from the vol+dir as the
; program itself loaded from.

;---Standard header for OSCA and FLOS ----------------------------------------

include "kernal_jump_table.asm"
include "OSCA_hardware_equates.asm"
include "system_equates.asm"


	org $5000
	
	ld (prog_vol),a		;when programs start, A = volume. DE = dir cluster
	ld (prog_dir),de

	call kjt_get_dir_cluster	;cache the current vol+dir
	ld (orig_dir),de
	call kjt_get_volume_info
	ld (orig_vol),a

	ld a,(prog_vol)		;change to the vol+dir that the program loaded from
	call kjt_change_volume
	ld de,(prog_dir)
	call kjt_set_dir_cluster


	ld hl,filename		;look for file in new dir
	call kjt_find_file
	jr nz,file_not_found
	ld hl,file_data		;load it if present
	ld b,0
	call kjt_read_from_file
	jr nz,file_not_found
	
	ld hl,msg_good		;report success
	call kjt_print_string
	call restore_dir
	ret

	
file_not_found

	ld hl,msg_bad		;report failure
	call kjt_print_string
	call restore_dir
	ret
		

restore_dir

	ld a,(orig_vol)		;go back to original dir
	call kjt_change_volume
	ld de,(orig_dir)
	call kjt_set_dir_cluster
	ret



;-----------------------------------------------------------------------------

orig_vol	db 0
orig_dir	dw 0

prog_vol	db 0
prog_dir	dw 0

;-----------------------------------------------------------------------------

filename	db "prog.cfg",0

msg_good	db "OK, prog.cfg file loaded.",11,0
msg_bad	db "Did not find prog.cfg",11,0

file_data	db 0

;-----------------------------------------------------------------------------
