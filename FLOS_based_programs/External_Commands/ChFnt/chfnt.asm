
; Chfnt [filename] command - switches FLOS font - originally by Daniel
; Updated for FLOS 568 By Phil (V1.03)
;
; Changes:
; --------
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

required_flos	equ $594
include 		"test_flos_version.asm"


;-----------------------------------------------------------------------------------------------	
;  Look for associated file
;-----------------------------------------------------------------------------------------------	
	
fnd_param	ld a,(hl)				;if args = 0, show use
    	or a    
    	jp z,no_param

	call kjt_store_dir_position
	ld (filename_loc),hl
	call kjt_find_file			;does file exist in current dir?
	jr c,hw_err
	jr z,got_fn

	call kjt_root_dir			;change to root dir, look for appropriate dir
	ld hl,fonts_dir_fn
	call kjt_change_dir
	jr c,hw_err
	jr nz,exit
	ld hl,(filename_loc)		;try loading specified file again
	call kjt_find_file
	ret c
	jr nz,exit	
got_fn	

;------------------------------------------------------------------------------------------------	
;  Do the stuff necessary for the command        
;-----------------------------------------------------------------------------------------------	

	  
setup_font

    	ld b,my_bank
    	ld hl,fntdata
    	call kjt_force_load     
    	jp nz,exit

    	call kjt_page_in_video
    	ld a,15 				; VRAM $1E000
    	ld (vreg_vidpage),a

	ld hl,fntdata
	ld de,video_base+$400
	ld bc,$300
	ldir

	ld b,8
	ld hl,video_base+$45f+(7*$60)
	ld de,video_base+$45f+(7*$80)
reorgflp	push bc
	ld bc,96
	lddr
	ld bc,32
	ex de,hl
	xor a
	sbc hl,bc
	ex de,hl	
	pop bc
	djnz reorgflp
	
	ld bc,$400			; make inverse charset (@ $1E800)
	ld hl,video_base+$400
	ld de,video_base+$800
invloop	ld a,(hl)
	cpl
	ld (de),a
	inc hl
	inc de
	dec bc
	ld a,b
	or c
	jr nz,invloop

	call kjt_page_out_video

;----------------------------------------------------------------------------------------------
;  Clean up and exit
;----------------------------------------------------------------------------------------------

	ld hl,font_set_txt			
all_done	call kjt_print_string		
	call kjt_restore_dir_position
	xor a				; all OK
	ret


no_param	ld hl,no_param_txt			; no arguments supplied
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
	
;----------------------------------------------------------------------------------------------
;  Generic data
;----------------------------------------------------------------------------------------------

fonts_dir_fn

	db "fonts",0
		
font_set_txt

	db "Font set",11,0

no_param_txt

	db "USE: ChFnt [filename]",11,0

filename_loc

	dw 0


;-------------------------------------------------------------------------------------------
; Data specific to this command
;-------------------------------------------------------------------------------------------

fntdata	db 0
 

;-------------------------------------------------------------------------------------------

