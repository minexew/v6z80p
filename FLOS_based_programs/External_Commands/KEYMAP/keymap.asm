;-----------------------------------------------------------------------------------------------
; "KEYMAP.EXE" = Change the default keymap. v1.03
;-----------------------------------------------------------------------------------------------

; v1.03 - Supports path in filename

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
include 	"flos_based_programs\code_library\program_header\force_load_location.asm"

required_flos	equ $607
include 	"flos_based_programs\code_library\program_header\test_flos_version.asm"

;---------------------------------------------------------------------------------------------

max_path_length equ 40

	call save_dir_vol
	call change_keymap
	call restore_dir_vol
	ret
			

change_keymap


;-------- Parse command line arguments ---------------------------------------------------------


fnd_param	ld (args_loc),hl
		ld a,(hl)				; examine argument text, if 0: show use
		or a			
		jr z,no_param

		call extract_path_and_filename
		ld a,(path_txt)
		or a
		jr z,no_path
		
		ld hl,path_txt
		call kjt_parse_path			; change dir according to the path part of the string
		ret nz
		jr find_keymap_file

;------------------------------------------------------------------------------------------------

no_path		ld hl,filename_txt
		call kjt_open_file			; does file exist in current dir?
		jr z,got_km

		ld hl,keymap_dir_txt			; change to vol0:keymaps
		call kjt_parse_path
		ret nz

find_keymap_file

		ld hl,filename_txt			;try loading specified file again
		call kjt_open_file
		ret nz	

got_km		ld a,%10000000		
		out (sys_alt_write_page),a		; write "under" the video registers

		ld ix,0
		ld iy,$62
		call kjt_set_load_length
		ld hl,keymaps
		ld b,0
		call kjt_read_from_file			; overwrite default non qualified key map
		ret nz
			
key1ok		ld ix,0
		ld iy,$62
		call kjt_set_load_length
		ld hl,keymaps+$80
		ld b,0
		call kjt_read_from_file			; shift-ed keys
		jr z,key2ok	
		cp $1b					; if EOF error, this is a short keymap just end
		jr z,keymdone
		ret
		
key2ok		ld ix,0
		ld iy,$62
		call kjt_set_load_length
		ld hl,keymaps+$100
		ld b,0
		call kjt_read_from_file			; alt-ed keys
		jr z,keymdone
		cp $1b					; if EOF error, this is a short keymap just end
		jr z,keymdone
		ret
		
keymdone	xor a	
		out (sys_alt_write_page),a		; normal video register write mode

		ld hl,km_set_txt			
all_done	call kjt_print_string		
		xor a					; all OK
		ret


no_param	ld hl,no_param_txt
		jr all_done
		
		
;-------------------------------------------------------------------------------------------		

include "flos_based_programs\code_library\string\inc\extract_path_and_filename.asm"

include "flos_based_programs\code_library\loading\inc\save_restore_dir_vol.asm"

;----------------------------------------------------------------------------------------------

args_loc		dw 0

keymap_dir_txt	db "VOL0:KEYMAPS/",0
		
km_set_txt	db "Keymap set",11,0

no_param_txt	db "USE: KEYMAP [filename]",11,0


;-------------------------------------------------------------------------------------------