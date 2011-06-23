;----------------------------------------------------
; Project: LoadVid.zdsp
; Main File: LoadVid.asm
; Date: 22-6-11 22:37:38
;
; Created with zDevStudio - Z80 Development Studio.
;
;----------------------------------------------------

; Load file to video memory

;---Standard header for OSCA and FLOS ----------------------------------------

include "kernal_jump_table.asm"
include "osca_hardware_equates.asm"
include "system_equates.asm"

	org $5000

;-------- Parse command line arguments ---------------------------------------------------------

	ld de,$5000		; if being run from G command, HL which is normally
	xor a			; the argument string will be $5000
	sbc hl,de
	jr nz,argok
	ld hl,test_fn		; if so, use a test filename defined in this source
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
	ld (length_hi),ix		; ix:iy = size of file (bytes-to-go)
	ld (length_lo),iy
	
	ld hl,loading_txt
	call kjt_print_string

b_loop	ld a,(vid_page)
	ld (vreg_vidpage),a

	ld de,(length_hi)		; de:hl = bytes to go..
	ld hl,(length_lo)
	ld bc,8192		; ix:iy = default load length (normally 8KB buffer size)	
	xor a
	sbc hl,bc
	jr nc,btg_ok		
	ex de,hl
	ld bc,0
	sbc hl,bc			; do the borrow for hi word
	ex de,hl
	jr nc,btg_ok
	ld bc,8192
	add hl,bc			; bytes to go, is less than a full buffer: only load the bytes required
	ld (read_bytes),hl
	call transfer
	xor a
	ret
btg_ok	ld (length_hi),de		; update bytes to go
	ld (length_lo),hl
	ld bc,8192
	ld (read_bytes),bc
	call transfer
	jr b_loop



transfer	ld ix,0
	ld bc,(read_bytes)
	ld a,b			; if read bytes count = 0, dont do anything
	or c
	ret z
	push bc
	pop iy
	call kjt_set_load_length	; ix:iy = load length 

	ld hl,load_buffer
	ld b,0
	call kjt_force_load		; load 8kb to a buffer in sys ram
	
	in a,(sys_mem_select)	; page video ram in at $2000
	or $40
	out (sys_mem_select),a
	ld hl,load_buffer		; copy the buffered bytes to VRAM
	ld de,video_base
	ld bc,(read_bytes)
	ldir
	in a,(sys_mem_select)	; page out video ram
	and $bf
	out (sys_mem_select),a

	ld a,(vid_page)		; next video page
	inc a
	ld (vid_page),a
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

use_txt		db "USAGE: LOADVID [filename] - load data to video RAM",11,0

test_fn		db "data.bin",0

load_error_txt	db "Load error - File not found?",11,0

vid_page		db 0

filename		ds 32,0

length_hi		dw 0
length_lo		dw 0
read_bytes	dw 0

load_buffer	ds 8192,0

;-------------------------------------------------------------------------------------------------
