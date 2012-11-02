
; App: Assign - set a path environment variable. By Phil @ retroleum
; Usage: Assign "proxy_name" "path" (proxy name 3 chars max. If no path is
; supplied, the current dir is assigned)
;
; V1.01 - use kernal for path parsing

;======================================================================================
; Standard equates for OSCA and FLOS
;======================================================================================

include "equates\kernal_jump_table.asm"
include "equates\osca_hardware_equates.asm"
include "equates\system_equates.asm"

;--------------------------------------------------------------------------------------
; Header code - Force program load location and test FLOS version.
;--------------------------------------------------------------------------------------

my_location	equ $f000
my_bank		equ $0e
include 	"flos_based_programs\code_library\program_header\inc\force_load_location.asm"

required_flos	equ $607
include 	"flos_based_programs\code_library\program_header\inc\test_flos_version.asm"

;---------------------------------------------------------------------------------------------

max_path_length equ 40

		call save_dir_vol
		call assign
		call restore_dir_vol
		ret
			
assign

;-------- Parse command line arguments ---------------------------------------------------------


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
		jr nz,nproxyp			; if proxy named as "%xxx", skip the %
		inc hl
		
nproxyp		push hl
		ld de,var_name+1
		ld b,3
evnclp		ld a,(hl)
		cp " "
		jr z,evncdone
		ld (de),a
		inc hl
		inc de
		djnz evnclp
evncdone	pop hl

fnd_spc		inc hl
		ld a,(hl)			; locate next space
		or a
		jp z,set_var
		cp " "
		jr nz,fnd_spc

fnd_para2	ld a,(hl)			; examine path argument text, if encounter 0: give up and use
		or a				; the current dir for path
		jp z,set_var
		cp " "				; ignore leading spaces...
		jr nz,para2_ok
		inc hl
		jr fnd_para2

para2_ok	call kjt_parse_path
		ret nz

		call kjt_get_dir_cluster	;use this updated drive and dir as the %proxy values
		ld (var_data),de
		call kjt_get_volume_info
		ld (var_data+2),a

set_var		ld hl,var_name			;set the environment variable
		ld de,var_data
		call kjt_set_envar
		ret z
		ld hl,no_room_txt
		jr err_quit

no_args		ld hl,missing_args_txt
err_quit	call kjt_print_string
		xor a
		ret
			
;-------------------------------------------------------------------------------------------		

include 	"flos_based_programs\code_library\loading\inc\save_restore_dir_vol.asm"

;----------------------------------------------------------------------------------------------


var_name	db "%xxx",0

var_data     	ds 5,0

orig_cluster 	dw 0

orig_volume  	db 0

missing_args_txt

		db 11,"ASSIGN.EXE (v1.00)",11,11
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
		
;-------------------------------------------------------------------------------------------

