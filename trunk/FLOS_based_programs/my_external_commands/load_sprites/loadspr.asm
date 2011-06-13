; Load file to sprite memory

;---Standard header for OSCA and FLOS ----------------------------------------

include "kernal_jump_table.asm"
include "OSCA_hardware_equates.asm"
include "system_equates.asm"

	org $5000

;-------- Parse command line arguments ---------------------------------------------------------
	
	ld de,$5000		; if being run from G command, HL which is normally
	xor a			; the argument string will be $5000
	sbc hl,de
	jr nz,argok
	ld hl,test_fn
	ld de,0
	
argok	add hl,de
fnd_para	ld a,(hl)			; examine argument text, if encounter 0: give up
	or a			
	jp z,show_use
	cp " "			; ignore leading spaces...
	jr nz,fn_ok
skp_spc	inc hl
	jr fnd_para

fn_ok	push hl			; copy args to working filename string
	ld de,filename
	ld b,16
fnclp	ld a,(hl)
	or a
	jr z,fncdone
	cp " "
	jr z,fncdone
	ld (de),a
	inc hl
	inc de
	djnz fnclp
fncdone	xor a
	ld (de),a			; null terminate filename
	pop hl


;-------------------------------------------------------------------------------------------------


	ld hl,filename		; does filename exist?
	call kjt_find_file
	jp nz,load_error

	ld hl,loading_txt
	call kjt_print_string

	in a,(sys_mem_select)	; page sprite ram in at $1000 for writes
	or $80
	out (sys_mem_select),a

b_loop	ld a,(spr_page)
	or $80
	ld (vreg_vidpage),a
	
	ld ix,0
	ld iy,4096
	call kjt_set_load_length	; load buffer (in sprite RAM) is 4KB

	ld hl,sprite_base
	ld b,0
	call kjt_force_load		; load 4kb
	jr nz,end_load		; assume any file error is end of file
	
	ld a,(spr_page)
	inc a
	ld (spr_page),a
	jr b_loop
		
end_load	in a,(sys_mem_select)	; page out sprite ram
	and $7f
	out (sys_mem_select),a
	xor a
	ret
	
;-------------------------------------------------------------------------------------------------

load_error

	ld hl,load_error_txt
	call kjt_print_string
	xor a
	ret


show_use
	ld hl,use_txt
	call kjt_print_string
	xor a
	ret

;-------------------------------------------------------------------------------------------------

loading_txt	db "Loading..",11,0

use_txt		db "USAGE: LOADSPR [filename] - load data to sprite RAM",11,0

test_fn		db "sprites.bin",0

load_error_txt	db "Load error - File not found?",11,0
	
spr_page		db 0

filename		ds 32,0

;-------------------------------------------------------------------------------------------------
