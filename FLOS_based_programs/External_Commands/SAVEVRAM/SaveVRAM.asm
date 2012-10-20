
; SAVEVRAM.EXE (External command to save video memory)
;
; V1.02 - allowed path in filename 

;======================================================================================
; Standard equates for OSCA and FLOS
;======================================================================================

include "equates\kernal_jump_table.asm"
include "equates\osca_hardware_equates.asm"
include "equates\system_equates.asm"

;--------------------------------------------------------------------------------------
; Header code - Force program load location and test FLOS version.
;--------------------------------------------------------------------------------------

my_location	equ $d000
my_bank		equ $0e
include 	"flos_based_programs\code_library\program_header\inc\force_load_location.asm"

required_flos	equ $607
include 	"flos_based_programs\code_library\program_header\inc\test_flos_version.asm"

;---------------------------------------------------------------------------------------------

max_path_length equ 40

	call save_dir_vol
	call save_vram
	call restore_dir_vol
	ret
			
save_vram

;-------- Parse command line arguments ---------------------------------------------------------

	
	ld a,(hl)				; examine argument text, if 0: show use
	or a
	jp z,show_use
	
	call extract_path_and_filename
	
	push hl
	ld hl,path_txt
	call kjt_parse_path			;change dir according to the path part of the string
	pop hl
	ret nz

;-------------------------------------------------------------------------------------------------

	call find_next_argument			; is address specified?
	jp nz,no_src_addr
	ld (arg_addr),hl

	call ascii_to_hex_bcde
	jp nz,bad_hex
	ld (addr_linear_lo),de
	ld (addr_linear_hi),bc
	push bc
	ld h,b
	ld l,c
	xor a
	ld bc,8
	sbc hl,bc
	pop bc
	jp nc,out_of_range
	ld l,e					; convert linear address in C:DE to 8KB page (A) 
	ld a,d					; and address between 2000-3fff (HL)
	and $1f	
	or $20
	ld h,a
	srl c
	rr d
	srl c
	rr d
	srl c
	rr d
	srl c
	rr d
	srl c
	rr d
	ld a,d
	ld (video_page),a
	ld (video_address),hl
	
	
	ld hl,(arg_addr)
	call find_next_argument			; is length specified?
	jp nz,no_length
	
	call ascii_to_hex_bcde
	jp nz,bad_hex
	ld (length_lo),de
	ld (length_hi),bc
	ld a,b
	or c
	or d
	or e
	jp z,len_zero				;abort if length = 0
	dec de					;dec BC:DE for following calc
	ld a,d
	and e
	cp $ff
	jr nz,noundfl
	dec bc

noundfl	ld hl,(addr_linear_lo)
	add hl,de
	ld hl,(addr_linear_hi)
	adc hl,bc
	jp c,out_of_range			;abort if overlaps end of VRAM
	ld bc,$0008
	xor a
	sbc hl,bc
	jp nc,out_of_range
		

;-------------------------------------------------------------------------------------------------


	ld hl,filename_txt			;try to make new file stub		
	call kjt_create_file
	jr z,new_file
	cp 9					;if error 9, file exists already. If other error quit.
	ret nz			
	ld hl,save_append_txt			;ask if want to append data to existing file
	call kjt_print_string
	call kjt_wait_key_press
	ld a,"y"
	cp b
	jr z,new_file
	ld a,$2d				;aborted message
	or a
	ret
	
new_file

	ld hl,saving_txt
	call kjt_print_string

;-------------------------------------------------------------------------------------------------
	

save_loop

	ld a,(video_page)			;copy 8KB video page from $2000-$3fff to sysRAM buffer
	ld (vreg_vidpage),a
	inc a
	ld (video_page),a
	call kjt_page_in_video
	ld hl,video_base
	ld de,sysram_buffer
	ld bc,8192				;size of video page / sysram save buffer
	ldir
	call kjt_page_out_video
	
	ld hl,video_base+8192			;how many bytes from offset to end of video page?
	ld de,(video_address)
	xor a
	sbc hl,de
	ld (save_chunk_size),hl			;default chunk size (to end of buffer)
	
	ld a,(length_hi)			;if length is (still) > 64KB, use default chunk size
	or a
	jr nz,save_buffer
	ld hl,(video_address)
	ld de,(length_lo)
	add hl,de
	jr c,save_buffer			;if length + video buffer index > $4000, use default chunk size
	ld a,h
	cp ((video_base+8192)/256)
	jr nc,save_buffer
	ld (save_chunk_size),de			;otherwise truncate chunk size to remaining length
	

save_buffer
	
	ld hl,(video_address)
	ld bc,video_base
	xor a
	sbc hl,bc
	ld bc,sysram_buffer
	add hl,bc
	push hl
	pop ix					;sysram buffer address to save from
	ld b,my_bank
	ld hl,filename_txt
	ld c,0
	ld de,(save_chunk_size)
	call kjt_write_to_file
	jr nz,save_error
	
	ld hl,video_base		
	ld (video_address),hl			;all following chunks save from video base addr
		
	ld bc,(length_hi)			;adjust remaining length
	ld hl,(length_lo)
	ld de,(save_chunk_size)
	xor a
	sbc hl,de
	ld (length_lo),hl
	jr nc,lhok
	dec bc
	ld (length_hi),bc

lhok	ld a,c					;loop until length = 0
	or h
	or l
	jp nz,save_loop
	
	ld a,$20				;"OK" return code
	or a
	ret
	
;-------------------------------------------------------------------------------------------------


len_zero	

	ld a,7				
	or a
	ret
	
	


no_src_addr


	ld a,$16
	or a
	ret



no_length

	ld a,$17
	or a
	ret
	


save_error

	ld a,$19
	or a
	ret



out_of_range

	ld a,$08
	or a
	ret




bad_hex	ld a,$0c
	or a
	ret
	
	
	
show_use

	ld hl,use_txt
	call kjt_print_string
	xor a
	ret

	
;-------------------------------------------------------------------------------------------------
; argument string parsing routines
;-------------------------------------------------------------------------------------------------
	
	
find_space

	inc hl
	ld a,(hl)			;move to hl start of next string, if ZF is set - no string
	or a
	ret z
	cp " "
	jr nz,find_space
	ret
	
find_non_space

	inc hl
	ld a,(hl)
	or a
	ret z			
	cp " "
	jr z,find_non_space
	ret
	

ascii_to_hex_bcde
	
	ld bc,0
	ld de,0
	
hexclp	ld a,(hl)		;quit on SPACE
	cp 32
	ret z
	or a			;error if NULL
	jr z,hexerr

	ld a,4			;shift bc:de 4 bits left
rollp	sla e
	rl d
	rl c
	rl b
	jr c,hexerr
	dec a
	jr nz,rollp

	ld a,(hl)		;char to hex nybble
	cp "a"
	jr c,loca
	sub $20
loca	sub $3a			
	jr c,zeronine
	add a,$f9

zeronine

	add a,$a
	or e
	ld e,a			;insert into double_word result, bits 3:0
	
	inc hl		
	jr hexclp		;next ascii char
	
hexerr	xor a
	inc a
	ret
	

;-------------------------------------------------------------------------------------------------

include "flos_based_programs\code_library\string\inc\extract_path_and_filename.asm"

include "flos_based_programs\code_library\string\inc\find_next_argument.asm"

include "flos_based_programs\code_library\loading\inc\save_restore_dir_vol.asm"

;---------------------------------------------------------------------------------------

saving_txt	db "Saving VRAM data..",11,0

use_txt		db 11,"USAGE:",11
		db "SAVEVRAM Filename VRAM_address Length",11,0

save_append_txt	db "File exists. Append data (y/n)",11,0

arg_addr	dw 0

addr_linear_lo	dw 0
addr_linear_hi	dw 0

video_page	db 0
video_address	dw 0

length_hi	dw 0
length_lo	dw 0

save_chunk_size	dw 0

sysram_buffer	db 0		;allow 8 KB to top of page

;-------------------------------------------------------------------------------------------------
