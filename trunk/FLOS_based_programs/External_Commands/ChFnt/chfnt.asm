
; Chfnt [filename] command - switches FLOS font - originally by Daniel
; Updated for FLOS v6.02 By Phil (V1.04) 7-7-2012
;
; Changes:
; --------
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

include "kernal_jump_table.asm"
include "osca_hardware_equates.asm"
include "system_equates.asm"

;--------------------------------------------------------------------------------------
; Header code - Force program load location and test FLOS version.
;--------------------------------------------------------------------------------------

my_location	equ $f000
my_bank		equ $0e
include 		"force_load_location.asm"

required_flos	equ $602
include 		"test_flos_version.asm"


;-----------------------------------------------------------------------------------------------	
;  Look for associated file
;-----------------------------------------------------------------------------------------------	
	
fnd_param	ld a,(hl)				;if args = 0, show use
    	or a    
    	jp nz,got_param

	ld hl,no_param_txt			; no arguments supplied
	call kjt_print_string
	xor a
	ret

;------------------------------------------------------------------------------------------------

got_param

	ld (filename_loc),hl
	
	call kjt_store_dir_position
	
	ld hl,(filename_loc)
	call kjt_open_file			;does file exist in current dir?
	jr z,got_fn

	call kjt_root_dir			;change to root dir, look for appropriate dir

	ld hl,fonts_dir_fn
	call kjt_change_dir
	jp nz,exit

	ld hl,(filename_loc)		;try loading specified file again
	call kjt_open_file
	jp nz,exit	
got_fn	

;-------------------------------------------------------------------------------------------------
; Examine filename extension
;-------------------------------------------------------------------------------------------------

	ld hl,(filename_loc)
ffne	inc hl
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

	ld hl,(filename_loc)
spar1	inc hl
	ld a,(hl)
	or a
	jr z,new_font
	cp " "
	jr nz,spar1
	
spar2	inc hl
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
         	jp nz,exit
	
	ld ix,fnt_data			;for 96 planar  font
	ld c,32
chlp4	push ix				
	pop hl
	ld de,char_stack			;build linear sequence character def for patch font routine
	ld b,8
chlp3	ld a,(hl)
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
    	jr z,nfflok				;dont care about EOF error
    	jp exit

nfflok	ld ix,char_count
	ld hl,fnt_data	
	ld a,(start_char)
	
fplp1	push hl
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
	call kjt_restore_dir_position
	xor a				; all OK
	ret


	
bad_param	ld hl,bad_param_txt
	jr all_done

bad_font	ld hl,bad_font_txt
	jr all_done	
	
	

		
exit	push af				; save A and flags
	call kjt_restore_dir_position
	pop af
	ret
	
;----------------------------------------------------------------------------------------------
;  Generic data
;----------------------------------------------------------------------------------------------

	
fonts_dir_fn

	db "fonts",0
		
font_set_txt

	db "Font set",11,0

no_param_txt

	db 11,"CHFNT.EXE V1.04",11
	db "USE: CHFNT filename [xx]",11
	db "xx = start char (.fff files only)",11,0

bad_param_txt

	db "ERROR - Unknown parameter",11,0

bad_font_txt

	db "ERROR - Not an old FLOS font file",11,0
		
filename_loc

	dw 0

char_stack ds 8,0

char_count db 0

start_char db 0


;-------------------------------------------------------------------------------------------
; Data specific to this command
;-------------------------------------------------------------------------------------------

fnt_data	db 0
 

;-------------------------------------------------------------------------------------------

