;-----------------------------------------------------------------------------------------------
; "KEYMAP.EXE" = Change the default keymap. v1.02
;-----------------------------------------------------------------------------------------------

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


;------------------------------------------------------------------------------------------------
; Actual program starts here..
;------------------------------------------------------------------------------------------------


fnd_param	ld a,(hl)				; examine argument text, if encounter 0: give up
	or a			
	jr z,no_param
	cp " "				; ignore leading spaces...
	jr nz,par_ok
skp_spc	inc hl
	jr fnd_param

par_ok	call kjt_store_dir_position
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