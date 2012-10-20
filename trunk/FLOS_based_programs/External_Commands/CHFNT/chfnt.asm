
; Chfnt [filename] command - switches FLOS font - originally by Daniel
; Updated for FLOS v6.02 By Phil (V1.05) 7-7-2012
;
; Changes:
; --------
;
; v1.05 - Supports path in filename
;
; V1.04 - Now supports upto 256 chars, sequential-char format font files (.fff) for FLOS v6.02.
;         Uses patch_font kernal call
;	Usage:
;	CHFNT filename.fnt
;         or
;         CHFNT filename.fff [HEX_VALUE]
;         (HEX_VALUE = For .fff fonts only, specifies 1st ASCII char to patch (0 if not specified))
;
; V1,03 - Loads high in memory
; V1.02 - Looks in ROOT/FONTS folder as well as current dir for filename
;         Restores original directory on exit
;
;
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
		call change_font
		call restore_dir_vol
		ret
			
change_font


;-------- Parse command line arguments ---------------------------------------------------------

	
fnd_param	ld (args_loc),hl

		ld a,(hl)				;if args = 0, show use
		or a    
		jp z,show_use

		call extract_path_and_filename
		ld a,(path_txt)
		or a
		jr z,no_path
		ld hl,path_txt

		call kjt_parse_path			;change dir according to the path part of the string
		ret nz
		jr find_font_file

;------------------------------------------------------------------------------------------------

no_path		ld hl,filename_txt
		call kjt_open_file			;does file exist in current dir?
		jr z,got_fn

		ld hl,font_dir_txt			;change to root dir, look for appropriate dir
		call kjt_parse_path
		ret nz

find_font_file

		ld hl,filename_txt			;try loading specified file again
		call kjt_open_file
		ret nz	
got_fn	

;-------------------------------------------------------------------------------------------------
; Examine filename extension
;-------------------------------------------------------------------------------------------------

examine_ext

		ld hl,filename_txt
ffne		inc hl
		ld a,(hl)
		or a
		jr z,old_font
		cp "."
		jr nz,ffne
		inc hl
		ld a,"F"
		cp (hl)
		jr nz,old_font
		inc hl
		cp (hl)
		jr nz,old_font
		inc hl
		cp (hl)
		jr nz,old_font

;-----------------------------------------------------------------------------------------------
; Check for start char (new .fff files only)
;-----------------------------------------------------------------------------------------------

		ld hl,(args_loc)
spar1		inc hl
		ld a,(hl)
		or a
		jr z,new_font
		cp " "
		jr nz,spar1
		
spar2		inc hl
		ld a,(hl)
		or a
		jr z,new_font			
		cp " "
		jr z,spar2
			
		call kjt_ascii_to_hex_word
		or a
		jp nz,bad_param
		ld a,e
		ld (start_char),a
		jp new_font

;------------------------------------------------------------------------------------------------	
;  Do the stuff necessary for the command        
;-----------------------------------------------------------------------------------------------	

old_font	push ix				;make sure font size = 768
		pop hl
		ld a,h
		or l
		jp nz,bad_font
		ld de,$300
		xor a
		push iy
		pop hl
		sbc hl,de
		jp nz,bad_font
			
		ld b,my_bank
		ld hl,fnt_data
		call kjt_read_from_file
			ret nz
		
		ld ix,fnt_data				;for 96 planar  font
		ld c,32
chlp4		push ix				
		pop hl
		ld de,char_stack			;build linear sequence character def for patch font routine
		ld b,8
chlp3		ld a,(hl)
		ld (de),a
		push bc
		ld bc,96
		add hl,bc
		pop bc
		inc de
		djnz chlp3

		push bc
		push ix
		ld hl,char_stack
		ld a,c
		call kjt_patch_font
		pop ix
		pop bc
		
		inc ix
		inc c
		ld a,c
		cp 128
		jr nz,chlp4
		
		jp fnt_done



		  
new_font	push iy
		pop hl
		srl h
		rr l
		srl h
		rr l
		srl h
		rr l
		ld a,l
		ld (char_count),a
		
		ld ix,0
		ld iy,2048
		call kjt_set_read_length			;max load length
		
		ld b,my_bank
		ld hl,fnt_data
		call kjt_read_from_file
		jr z,nfflok
		cp $1b
		jr z,nfflok					;dont care about EOF error
		ret

nfflok		ld ix,char_count
		ld hl,fnt_data	
		ld a,(start_char)
		
fplp1		push hl
		push af
		call kjt_patch_font	
		pop af
		pop hl
			
		ld de,8
		add hl,de
		
		dec (ix)
		jr z,fnt_done
		
		inc a
		jr nz,fplp1
		
			
fnt_done

;----------------------------------------------------------------------------------------------
;  Clean up and exit
;----------------------------------------------------------------------------------------------

		ld hl,font_set_txt			
all_done	call kjt_print_string		
		xor a					; all OK
		ret


bad_param	ld hl,bad_param_txt
		jr all_done

bad_font	ld hl,bad_font_txt
		jr all_done	
		
		
;----------------------------------------------------------------------------------------------

show_use	ld hl,no_param_txt			; no arguments supplied
		call kjt_print_string
		xor a
		ret
		
;----------------------------------------------------------------------------------------------

include "flos_based_programs\code_library\string\inc\extract_path_and_filename.asm"

include "flos_based_programs\code_library\loading\inc\save_restore_dir_vol.asm"

;----------------------------------------------------------------------------------------------

font_dir_txt

	db "VOL0:FONTS/",0
		
font_set_txt

	db "Font set",11,0

no_param_txt

	db 11,"CHFNT.EXE V1.05",11
	db "USE: CHFNT filename [xx]",11
	db "xx = start char (.fff files only)",11,0

bad_param_txt

	db "ERROR - Unknown parameter",11,0

bad_font_txt

	db "ERROR - Not an old FLOS font file",11,0

		
args_loc	dw 0

char_stack 	ds 8,0

char_count 	db 0

start_char 	db 0


;-------------------------------------------------------------------------------------------
; Data specific to this command
;-------------------------------------------------------------------------------------------

fnt_data	db 0
 

;-------------------------------------------------------------------------------------------

