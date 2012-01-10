;-----------------------------------------------------------------------------------------------
; "KEYMAP.EXE" = Change the default keymap. v1.02
;-----------------------------------------------------------------------------------------------

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


;------------------------------------------------------------------------------------------------
; Actual program starts here..
;------------------------------------------------------------------------------------------------


fnd_param	ld a,(hl)				; examine argument text, if 0: show use
	or a			
	jr z,no_param

	call kjt_store_dir_position
	ld (filename_loc),hl
	call kjt_find_file			;get header info, does file exist in current dir?
	jr c,hw_err
	jr z,got_km

	call kjt_root_dir			;change to root dir, look for keymaps dir
	ld hl,keymaps_fn
	call kjt_change_dir
	jr c,hw_err
	jr nz,exit
	ld hl,(filename_loc)		;try loading specified file again
	call kjt_find_file
	ret c
	jr nz,exit	

got_km	ld a,%10000000		
	out (sys_alt_write_page),a		; write "under" the video registers

	ld ix,0
	ld iy,$62
	call kjt_set_load_length
	ld hl,keymaps
	ld b,0
	call kjt_force_load			; overwrite default keymap
	jr c,hw_err

	ld ix,0
	ld iy,$62
	call kjt_set_load_length
	ld hl,keymaps+$80
	ld b,0
	call kjt_force_load	
	jr c,hw_err

	ld ix,0
	ld iy,$62
	call kjt_set_load_length
	ld hl,keymaps+$100
	ld b,0
	call kjt_force_load	
	jr c,hw_err		

	xor a	
	out (sys_alt_write_page),a		; normal video register write mode

	ld hl,km_set_txt			
all_done	call kjt_print_string		
	call kjt_restore_dir_position
	xor a				; all OK
	ret


no_param	ld hl,no_param_txt
	jr all_done
	
	
hw_err	push af
	xor a	
	out (sys_alt_write_page),a		; normal video register write mode
	call kjt_restore_dir_position
	pop af
	ret
	
exit	push af				; save A and flags
	call kjt_restore_dir_position
	pop af
	ret
	
;-------------------------------------------------------------------------------------------		

filename_loc

	dw 0

keymaps_fn

	db "keymaps",0
		
km_set_txt

	db "Keymap set",11,0

no_param_txt

	db "USE: KEYMAP [filename]",11,0


;-------------------------------------------------------------------------------------------