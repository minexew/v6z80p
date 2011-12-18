
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
;---Standard header for OSCA and FLOS ----------------------------------------------------------

include "kernal_jump_table.asm"
include "osca_hardware_equates.asm"
include "system_equates.asm"

;----------------------------------------------------------------------------------------------------
; As this is an external command, load program high in memory to help avoid overwriting user programs
;----------------------------------------------------------------------------------------------------

my_location	equ $8000
my_bank		equ $0c

	org my_location	; desired load address
	
load_loc	db $ed,$00	; header ID (Invalid, safe Z80 instruction)
	jr exec_addr	; jump over remaining header data
	dw load_loc	; location file should load to
	db my_bank	; upper bank the file should load to
	db 0		; no truncating required

exec_addr	

;-------------------------------------------------------------------------------------------------
; Test FLOS version 
;-------------------------------------------------------------------------------------------------

required_flos equ $568

	push hl
	di			; temp disable interrupts so stack cannot be corrupted
	call kjt_get_version
true_loc	exx
	ld ix,0		
	add ix,sp			; get SP in IX
	ld l,(ix-2)		; HL = PC of true_loc from stack
	ld h,(ix-1)
	ei
	exx
	ld de,required_flos
	xor a
	sbc hl,de
	pop hl
	jr nc,flos_ok
	exx
	push hl			;show FLOS version required
	ld de,old_fth-true_loc
	add hl,de			;when testing location references must be PC-relative
	ld de,required_flos		
	ld a,d
	call kjt_hex_byte_to_ascii
	ld a,e
	call kjt_hex_byte_to_ascii
	pop hl
	ld de,old_flos_txt-true_loc
	add hl,de	
	call kjt_print_string
	xor a
	ret

old_flos_txt

        db "Error: Requires FLOS version $"
old_fth db "xxxx+",11,11,0

flos_ok


;-----------------------------------------------------------------------------------------------	
;  Look for associated file
;-----------------------------------------------------------------------------------------------	
	
fnd_param	ld a,(hl)				;scan arguments string for filename
    	or a    
    	jp z,no_param
    	cp " "          
    	jr nz,param_ok
skp_spc 	inc hl
    	jr fnd_param
    
  
param_ok	call kjt_store_dir_position
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

