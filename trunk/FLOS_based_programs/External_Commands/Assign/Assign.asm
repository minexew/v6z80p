
; App: Assign - set a path environment variable. By Phil @ retroleum
; Usage: Assign "proxy_name" "path" (proxy name 3 chars max. If no path is
; supplied, the current dir is assigned)
;
; V1.00

;======================================================================================
; Standard equates for OSCA and FLOS
;======================================================================================

include "kernal_jump_table.asm"
include "osca_hardware_equates.asm"
include "system_equates.asm"

;--------------------------------------------------------------------------------------
; Header code - Force program load location and test FLOS version.
;--------------------------------------------------------------------------------------

my_location	equ $f000
my_bank		equ $0e
include 		"force_load_location.asm"

required_flos	equ $594
include 		"test_flos_version.asm"

;-------- Parse command line arguments -------------------------------------------------


	push hl
	call kjt_get_dir_cluster	;by default, use the current drive and dir as the %proxy values
	ld (var_data),de
	ld (orig_cluster),de
	call kjt_get_volume_info
	ld (var_data+2),a
	ld (orig_volume),a
	xor a
	ld (var_data+3),a
	pop hl

	ld a,(hl)			; examine name argument text, if 0: show use
	or a			
	jp z,no_args
	
	cp "%"
	jp z,inv_proxy
	push hl
	ld de,var_name+1
	ld b,3
evnclp	ld a,(hl)
	cp " "
	jr z,evncdone
	ld (de),a
	inc hl
	inc de
	djnz evnclp
evncdone	pop hl

fnd_spc	inc hl
	ld a,(hl)			; locate next space
	or a
	jp z,set_var
	cp " "
	jr nz,fnd_spc

fnd_para2	ld a,(hl)			; examine path argument text, if encounter 0: give up and use
	or a			; the current dir for path
	jp z,set_var
	cp " "			; ignore leading spaces...
	jr nz,para2_ok
	inc hl
	jr fnd_para2

para2_ok	push hl			
	pop ix			; analyse the path string
	ld a,(ix+4)
	cp ":"			; volume specified?
	jr nz,nxt_path
	ld de,vol_txt
	ld b,3
	push ix
	call kjt_compare_strings
	pop ix
	jp nc,bad_path
	ld a,(ix+3)		; get volume digit char
	sub $30
	push ix
	call kjt_change_volume
	pop ix
	jp nz,bad_path		; error if new volume is invalid

	ld de,5
	add ix,de			; move past "VOLx:"
	push ix
	call kjt_root_dir		; go to new drive's root block as drive has changed
	pop ix
	ld a,(ix)			; if "/" follows "VOLx:" then skip the fwdslash
	cp $2f
	jr nz,nxt_path
	inc ix

nxt_path	ld de,filename_txt		;step through args changing dirs as apt
	call skip_spaces
	jr z,path_done
cpypslp	ld a,(ix)
	cp $2f
	jr z,path_break
	cp 33
	jr c,path_break
	ld (de),a
	inc ix
	inc de
	jr cpypslp
	
path_break

	xor a
	ld (de),a			;zero terminate this dir string
	ld hl,filename_txt
	push ix
	call kjt_change_dir		
	pop ix
	jr nz,bad_path
	
	ld a,(ix)
	cp 33
	jr c,path_done
	inc ix
	jr nxt_path		;next char in path string
				

skip_spaces

	ld a,(ix)
	or a
	ret z
	cp 32
	ret nz
	inc ix
	jr skip_spaces


path_done

	call kjt_get_dir_cluster	;use this updated drive and dir as the %proxy values
	ld (var_data),de
	call kjt_get_volume_info
	ld (var_data+2),a

set_var	

	ld hl,var_name		;set the environment variable
	ld de,var_data
	call kjt_set_envar
	jr z,all_done
	ld hl,no_room_txt
	jr err_quit

all_done	ld a,(orig_volume)		;restore original current drive and dir
	call kjt_change_volume
	ld de,(orig_cluster)
	call kjt_set_dir_cluster
	xor a
	ret

no_args	ld hl,missing_args_txt
err_quit	call kjt_print_string
	jr all_done

inv_proxy	ld hl,bad_proxy_txt
	jr err_quit

bad_path	ld hl,bad_path_txt
	jr err_quit
		
;-------------------------------------------------------------------------------------------

vol_txt	   db "VOL",0

filename_txt ds 16,0

var_name	   db "%xxx",0

var_data     ds 5,0

orig_cluster dw 0

orig_volume  db 0

missing_args_txt	db 11,"ASSIGN.EXE (v1.00)",11,11
		db "Usage: ASSIGN PROXY [PATH]",11,11
		db "PROXY is a 3 character (maximum)",11
		db "environment variable to be used as",11
		db "a substitute for a long path string.",11
		db "Apps accepting paths can utilize the",11
		db "proxy (prefixed with %) to make a",11
		db "shortcut to the final dir.",11,11
		db "PATH is optional, if it isn't supplied",11
		db "then the current dir is used.",11,11,0
		

no_room_txt	db "Not enough space for assignment.",11,11,0
bad_path_txt	db "The path specified is invalid.",11,11,0
bad_proxy_txt	db "Bad proxy name.",11,11,0
		
;-------------------------------------------------------------------------------------------

