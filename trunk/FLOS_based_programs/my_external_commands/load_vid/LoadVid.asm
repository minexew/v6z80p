;----------------------------------------------------
; Project: LoadVid.zdsp
; Main File: LoadVid.asm
; Date: 22-6-11 22:37:38
;
; Created with zDevStudio - Z80 Development Studio.
;
;----------------------------------------------------

; Load file to video memory

;======================================================================================
; Standard header for OSCA and FLOS
;======================================================================================

include "kernal_jump_table.asm"
include "osca_hardware_equates.asm"
include "system_equates.asm"

;======================================================================================
; Program Location File Header:
; FLOS v568+ will use this data to load the program a specific location
; Earlier versions of FLOS will ignore it and load the program to $5000
;======================================================================================

my_location	equ $f000
my_bank		equ $0e


	org my_location	; desired load address
	
load_loc	db $ed,$00	; header ID (Invalid Z80 instruction)
	jr exec_addr	; jump over remaining header data
	dw load_loc	; location file should load to
	db my_bank	; upper bank the file should load to
	db 0		; dont truncate the program load

exec_addr	


;=======================================================================================	
; Location Check:
; As an earlier version of FLOS may have loaded the program, or it has
; simply been loaded into memory somwhere as a binary file we can check to
; see if it is in the desired location before the main code attempts to run.
;=======================================================================================

	push hl		; Tests to see if code is located in the correct place to run
	ld hl,sector_buffer	; use sector buffer location 0 for the test routine
	ld a,(hl)		; preserve the byte that was there
	ld (hl),$c9	; place a RET instruction there	
	call sector_buffer	; Call the RET, PC of true_loc is pushed on stack and returns back here
true_loc	ld (hl),a		; put the preserved byte back where RET was placed
	ld ix,0		
	add ix,sp		; get SP in IX
	ld l,(ix-2)	; HL = PC of true_loc from stack (load_loc + 8 + 11)
	ld h,(ix-1)
	ld de,true_loc-load_loc
	xor a
	sbc hl,de		; HL = actual location that program was loaded to
	push hl
	pop ix		
	ld e,(ix+4)
	ld d,(ix+5)	; DE = address where program is SUPPOSED to be located
	xor a
	sbc hl,de		; are we in the right place?
	pop hl	
	jr z,loc_ok	
	push ix		; No, so show an error message (using relative addressing)
	pop hl
	ld de,locer_txt-load_loc
	add hl,de
	call kjt_print_string
	xor a	
	ret

locer_txt	db "Program cannot run from this location.",11,0	

loc_ok	


;=======================================================================================		
;  Main App Code starts here
;=======================================================================================


buffer_size equ 512			


;-------- Parse command line arguments ---------------------------------------------------------

	ld de,$5000		; if being run from G command, HL which is normally
	xor a			; the argument string will be $5000
	sbc hl,de
	jr nz,argok
	ld hl,test_args		; if so, use a test filename defined in this source
	ld de,0

argok	add hl,de
fnd_para	ld a,(hl)			; examine argument text, if encounter 0: give up
	or a
	jp z,show_use
	cp " "			; ignore leading spaces...
	jr nz,fn_ok
skp_spc	inc hl
	jr fnd_para

fn_ok	ld de,filename		; copy args to working filename string
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
	

;-------------------------------------------------------------------------------------------------

	call find_next_arg		; is a destination address specified?
	jr nz,parse_dest
	ld hl,0
	ld de,0
	jr got_dest

parse_dest

	ld (addr_txt_loc),hl
	call get_arg_size
	ld a,b
	cp 5
	jr c,lword

	push hl
	call kjt_ascii_to_hex_word	; 5 char address
	pop hl
	or a
	ret nz
	inc hl
	push de			; push higher word
	call kjt_ascii_to_hex_word
	pop hl			; hl = higher word (chars 4,3,2,1) , DE = chars 3,2,1,0
	or a
	ret nz
	srl h
	srl h
	srl h
	srl h
	jr got_dest
lword	call kjt_ascii_to_hex_word	; standard 4 char address in DE
	or a
	ret nz
	ld hl,0

got_dest	ld a,e			; convert linear address to 8KB page and address between 2000-3fff
	ld (page_address),a
	ld a,d
	and $1f
	or $20
	ld (page_address+1),a
	srl h
	rr d
	srl h
	rr d
	srl h
	rr d
	srl h
	rr d
	srl h
	rr d
	ld a,d
	and $7f
	cp $40
	jp nc,out_of_range
	ld (video_page),a	
	
;-------------------------------------------------------------------------------------------------


	ld hl,filename		; does filename exist?
	call kjt_find_file
	jp nz,load_error
	ld (length_hi),ix		; ix:iy = size of file (bytes-to-go)
	ld (length_lo),iy
	
	ld hl,loading_txt
	call kjt_print_string
	ld hl,filename
	call kjt_print_string
	ld hl,to_txt
	call kjt_print_string
	ld hl,(addr_txt_loc)
	call kjt_print_string
	ld hl,cr_txt
	call kjt_print_string

	ld a,(video_page)	
	ld (vreg_vidpage),a

b_loop	ld de,(length_hi)		; de:hl = bytes to go..
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
	
btg_ok	ld (length_hi),de		; update bytes-to-go
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
	ld a,b			; if read bytes count = 0, dont do anything
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
	ld a,b			; if read bytes count = 0, dont do anything
	or c
	jr z,cpy_done	

	ld hl,(page_address)
	add hl,bc
	ld a,h
	and $c0
	jr z,sp_copy		; will the bytes in buffer spill into a new video page?
	
	ld de,(page_address)	; always between 2000-3fff
	ld hl,load_buffer	
	ld bc,(read_bytes)
cpylp	ldi			; this is the slow copy, when the video page buffer will
	bit 6,d			; change during the write
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
	
sp_copy	ld de,(page_address)	; always between 2000-3fff	
	ld hl,load_buffer		; copy the buffered bytes to VRAM
	ld bc,(read_bytes)	
	ldir			; this is the faster copy when the video page wont be changed
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
argslp	ld a,(hl)
	or a
	ret z
	cp " "
	ret z
	inc b
	inc hl
	jr argslp
	
	
	
find_next_arg

	ld a,(hl)			;move to hl start of next string, if ZF is set - no string
	or a
	ret z
	cp " "
	ret nz
	inc hl
	jr find_next_arg
	
	
;-------------------------------------------------------------------------------------------------

loading_txt	db "Loading: ",0
to_txt		db " to VRAM $",0

addr_txt_loc	dw 0
cr_txt		db 11,0

use_txt		db "USAGE:",11
		db "LOADVID Filename [VRAM Address]",11,0

test_args		db "sprites.bin 60000",0

load_error_txt	db "Load error - File not found?",11,0

range_error_txt	db "Video RAM address out of range!",11,0

filename		ds 32,0

video_page	db 0
page_address	dw 0

length_hi		dw 0
length_lo		dw 0
read_bytes	dw 0

load_buffer	ds buffer_size,0

;-------------------------------------------------------------------------------------------------
