
; Load file to video memory v1.03
;
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

my_location	equ $f000
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
				

buffer_size equ 512			

loadvram

;-------- Parse command line arguments ---------------------------------------------------------

		ld a,(hl)			; examine argument text, if 0: show use
		or a
		jp z,show_use
		
		call extract_path_and_filename

;-------------------------------------------------------------------------------------------------

		call find_next_arg		; is a destination address specified?
		ret nz
		
		ld (addr_txt_loc),hl
		call kjt_ascii_to_hex32
		ret nz
		ld hl,$0007
		xor a
		sbc hl,bc
		jp c,out_of_range
		
		ld a,e				; convert linear address to 8KB page and address between 2000-3fff
		ld (page_address),a
		ld a,d
		and $1f
		or $20
		ld (page_address+1),a
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
		and $7f
		cp $40
		jp nc,out_of_range
		ld (video_page),a	
		
;-------------------------------------------------------------------------------------------------

		ld hl,path_txt
		call kjt_parse_path		;change dir according to the path part of the string
		ret nz

		ld hl,filename_txt		; does filename exist?
		call kjt_find_file
		jp nz,load_error
		ld (length_hi),ix		; ix:iy = size of file (bytes-to-go)
		ld (length_lo),iy
		
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

		ld a,(video_page)	
		ld (vreg_vidpage),a

b_loop		ld de,(length_hi)		; de:hl = bytes to go..
		ld hl,(length_lo)
		ld bc,buffer_size		; ix:iy = default load length (buffer size)	
		xor a
		sbc hl,bc
		jr nc,btg_ok		
		ex de,hl
		ld bc,0
		sbc hl,bc			; do the borrow for hi word
		ex de,hl
		jr nc,btg_ok
		ld bc,buffer_size
		add hl,bc			; bytes-to-go is less than a full buffer: only load the bytes required
		ld (read_bytes),hl
		call fill_buffer
		ret nz
		call copy_buffer_to_vram
		jp nz,out_of_range
		xor a
		ret
		
btg_ok		ld (length_hi),de		; update bytes-to-go
		ld (length_lo),hl
		
		ld bc,buffer_size
		ld (read_bytes),bc
		call fill_buffer
		ret nz
		call copy_buffer_to_vram
		jr nz,out_of_range
		jr b_loop


;----------------------------------------------------------------------------------------------------------

fill_buffer


		ld bc,(read_bytes)
		ld a,b				; if read bytes count = 0, dont do anything
		or c
		ret z

		push bc
		pop iy
		ld ix,0
		call kjt_set_load_length	; ix:iy = load length (normally a full buffer)

		ld hl,load_buffer
		ld b,my_bank
		call kjt_force_load		; load to a buffer in sys ram
		ret
		
;----------------------------------------------------------------------------------------------------------

		
copy_buffer_to_vram
		
		call kjt_page_in_video
		
		ld bc,(read_bytes)
		ld a,b				; if read bytes count = 0, dont do anything
		or c
		jr z,cpy_done	

		ld hl,(page_address)
		add hl,bc
		ld a,h
		and $c0
		jr z,sp_copy			; will the bytes in buffer spill into a new video page?
			
		ld de,(page_address)		; always between 2000-3fff
		ld hl,load_buffer	
		ld bc,(read_bytes)
cpylp		ldi				; this is the slow copy, when the video page buffer will
		bit 6,d				; change during the write
		jr z,samepage
		ld d,$20
		ld a,(video_page)		; next video page
		inc a
		cp $40
		jr nc,bad_addr
		ld (video_page),a
		ld (vreg_vidpage),a
samepage	ld a,b
		or c
		jr nz,cpylp
		ld (page_address),de
		jr cpy_done
		
sp_copy		ld de,(page_address)		; always between 2000-3fff	
		ld hl,load_buffer		; copy the buffered bytes to VRAM
		ld bc,(read_bytes)	
		ldir				; this is the faster copy when the video page wont be changed
		ld (page_address),de

cpy_done	call kjt_page_out_video
		xor a
		ret
		
bad_addr	call kjt_page_out_video
		xor a			
		inc a
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
		
		
;-------------------------------------------------------------------------------------------------
; argument string parsing routines
;-------------------------------------------------------------------------------------------------
		
get_arg_size

		push hl			;get string length from (hl) to space or null, in B
		call gas_main
		pop hl
		ret

gas_main	ld b,0
argslp		ld a,(hl)
		or a
		ret z
		cp " "
		ret z
		inc b
		inc hl
		jr argslp
		
		
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
		
		
;--------------------------------------------------------------------------------------

include "flos_based_programs\code_library\string\inc\extract_path_and_filename.asm"

include "flos_based_programs\code_library\loading\inc\save_restore_dir_vol.asm"

;---------------------------------------------------------------------------------------
	
loading_txt	db "Loading: ",0
to_txt		db " to VRAM $",0

addr_txt_loc	dw 0
cr_txt		db 11,0

use_txt		db "LOADVRAM v1.03 - USAGE:",11
		db "LOADVRAM Filename VRAM_Address",11,0

load_error_txt	db "Load error - File not found?",11,0

range_error_txt	db "Video RAM address out of range!",11,0

video_page	db 0
page_address	dw 0

length_hi	dw 0
length_lo	dw 0
read_bytes	dw 0

load_buffer	ds buffer_size,0

;-------------------------------------------------------------------------------------------------
