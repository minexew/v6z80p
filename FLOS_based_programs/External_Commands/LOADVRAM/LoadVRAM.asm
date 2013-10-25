;--------------------------------
; Load file to video memory v1.04
;--------------------------------
;
; v1.04 - uses load_to_vram routine from library: no buffer required & fixes out-of-memory bug if ends on $7ffff
; V1.03 - uses kernal' ascii_to_hex32 routine
; v1.02 - allowed path in filename

;======================================================================================
; Standard equates for OSCA and FLOS
;======================================================================================

include "equates\kernal_jump_table.asm"
include "equates\osca_hardware_equates.asm"
include "equates\system_equates.asm"

;--------------------------------------------------------------------------------------
; Header code - Force program load location and test FLOS version.
;--------------------------------------------------------------------------------------

my_location	equ $dc00	;cannot be > $e000 as load_to_vram routine pages VRAM there! 
my_bank		equ $0e
include 	"flos_based_programs\code_library\program_header\inc\force_load_location.asm"

required_flos	equ $613
include 	"flos_based_programs\code_library\program_header\inc\test_flos_version.asm"

;---------------------------------------------------------------------------------------------

max_path_length equ 40

		call save_dir_vol
		call loadvram
		call restore_dir_vol
		ret
				
loadvram

;-------- Parse command line arguments ---------------------------------------------------------

		ld a,(hl)			; examine argument text, if 0: show use
		or a
		jp z,show_use
		
		call extract_path_and_filename

;-------------------------------------------------------------------------------------------------

		call find_next_argument		; is a destination address specified?
		ret nz
		
		ld (addr_txt_loc),hl
		call kjt_ascii_to_hex32
		ret nz				; exit if not a valid hex number
		ld (load_addr),de
		ld (load_addr+2),bc
	
;-------------------------------------------------------------------------------------------------

		ld hl,path_txt
		call kjt_parse_path		;change dir according to the path part of the string
		ret nz

		ld hl,filename_txt		; does filename exist? and get length of file in IX:IY
		call kjt_find_file
		jp nz,load_error	
		
		push ix			
		pop hl				
		ld bc,(load_addr)
		add iy,bc
		ld de,(load_addr+2)
		adc hl,de
		ld de,$ffff
		add iy,de
		ld de,$fff7
		adc hl,de
		jp c,out_of_range			
				
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
				
		ld bc,(load_addr)
		ld de,(load_addr+2)
		ld hl,filename_txt
		call load_to_video_ram
		ret
		
;-------------------------------------------------------------------------------------------------

load_error

		ld hl,load_error_txt
		call kjt_print_string
		xor a
		ret

out_of_range

		ld hl,range_error_txt
		call kjt_print_string
		xor a
		ret

show_use
		ld hl,use_txt
		call kjt_print_string
		xor a
		ret
		
				
;--------------------------------------------------------------------------------------

include "flos_based_programs\code_library\string\inc\extract_path_and_filename.asm"

include "flos_based_programs\code_library\string\inc\find_next_argument.asm"

include "flos_based_programs\code_library\loading\inc\save_restore_dir_vol.asm"

include "flos_based_programs\code_library\loading\inc\load_to_video_ram.asm"

;---------------------------------------------------------------------------------------
	
loading_txt	db "Loading: ",0
to_txt		db " to VRAM $",0

addr_txt_loc	dw 0
cr_txt		db 11,0

use_txt		db 11,"LOADVRAM v1.04 - USAGE:",11
		db "LOADVRAM Filename VRAM_Address",11,11,0

load_error_txt	db "File not found!",11,0

range_error_txt	db "VRAM address out of range!",11
		db "(No data loaded)",11,0

load_addr	dw 0,0


;-------------------------------------------------------------------------------------------------
