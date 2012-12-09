
; Load file to sprite memory - v1.02
;
; Changes: v1.02 - Uses standard bufferless load-to-sprite-ram routine
;          v1.01 - allowed path in filename

;======================================================================================
; Standard equates for OSCA and FLOS
;======================================================================================

include "equates\kernal_jump_table.asm"
include "equates\osca_hardware_equates.asm"
include "equates\system_equates.asm"

;--------------------------------------------------------------------------------------
; Header code - Force program load location and test FLOS version.
;--------------------------------------------------------------------------------------

my_location	equ $fc00
my_bank		equ $0e
include 	"flos_based_programs\code_library\program_header\inc\force_load_location.asm"

required_flos	equ $608
include 	"flos_based_programs\code_library\program_header\inc\test_flos_version.asm"

;---------------------------------------------------------------------------------------------

max_path_length equ 40

		call save_dir_vol
		call loadsprram
		call restore_dir_vol
		ret
		

;-------- Parse command line arguments ---------------------------------------------------------

loadsprram	ld a,(hl)			; examine argument text, if encounter 0: show use
		or a
		jp z,show_use

		call extract_path_and_filename
		
		call find_next_arg		; is a destination address specified?
		ret nz
		ld (addr_txt_loc),hl

		call kjt_ascii_to_hex32
		ld (load_addr),de
		ld (load_addr+2),bc		
		
		ld hl,$0002			; is dest addr < $20000
		xor a
		sbc hl,bc
		jp z,out_of_range
		jp c,out_of_range
		
;-------------------------------------------------------------------------------------------------

		ld hl,path_txt
		call kjt_parse_path		; change dir according to the path part of the string
		ret nz

		ld hl,filename_txt		; does filename exist?
		call kjt_find_file
		jp nz,load_error
				
		ld hl,loading_txt
		call kjt_print_string
		ld hl,filename_txt
		call kjt_print_string
		ld hl,to_txt
		call kjt_print_string
		ld hl,(addr_txt_loc)
		call kjt_print_string
		ld hl,cr_txt
		call kjt_print_string

		ld hl,filename_txt
		ld de,(load_addr)
		ld bc,(load_addr+2)
		call load_to_sprite_ram
		ret
		
;-------------------------------------------------------------------------------------------------



load_error	ld hl,load_error_txt
		call kjt_print_string
		xor a
		ret


out_of_range	ld hl,range_error_txt
		call kjt_print_string
		xor a
		ret


show_use	ld hl,use_txt
		call kjt_print_string
		xor a
		ret


;-------------------------------------------------------------------------------------------------
; argument string parsing routines
;-------------------------------------------------------------------------------------------------
		
	
find_next_arg

		ld a,(hl)			;move to hl start of next string, if ZF is not set - no more args
		or a
		jr z,mis_arg
		cp " "
		jr z,got_spc
		inc hl
		jr find_next_arg

got_spc		inc hl
		ld a,(hl)
		or a
		jr z,mis_arg
		cp " "
		jr z,got_spc
		cp a				;return with zero flag set, char in A
		ret
		
mis_arg		ld a,$1f			;return with zero flag unset, error code $1f
		or a
		ret
		
	
;-------------------------------------------------------------------------------------------------

include "flos_based_programs\code_library\loading\inc\load_to_sprite_ram.asm"

include "flos_based_programs\code_library\string\inc\extract_path_and_filename.asm"

include "flos_based_programs\code_library\loading\inc\save_restore_dir_vol.asm"

;---------------------------------------------------------------------------------------

loading_txt	db "Loading: ",0
to_txt		db " to Spr RAM $",0

addr_txt_loc	dw 0

cr_txt		db 11,0

use_txt		db "USAGE:",11
		db "LOADSPR Filename Sprite_RAM_Addr",11,0
		
load_error_txt	db "Load error - File not found?",11,0

range_error_txt	db "Sprite RAM address out of range!",11,0

load_addr	dw 0,0

;-------------------------------------------------------------------------------------------------
