;----------------------------------------------------------------------------------------
; Make bulk file V1.00 - Collates all files in current dir to a single
;                        file with index header
;----------------------------------------------------------------------------------------
;
;Index:
;------
;$00 1st entry $FF, 12 * 0, total length_of_index ((entries * 16) + 1) 
;$10 2nd entry: Filename.bin, 0, length_of_file (filename always padded to 12 chars, l-o-f is 24 bit)
;$20 3rd entry: Filename.bin, 0, length_of_file (filename always padded to 12 chars, l-o-f is 24 bit)
;.. for n entries..
;$00 - end of index
;
;Files
;-----
;File1
;File2
;File3
; 	
;---Standard header for OSCA and FLOS ----------------------------------------

include "kernal_jump_table.asm"
include "OSCA_hardware_equates.asm"
include "system_equates.asm"

	org $5000
	
;-----------------------------------------------------------------------------

required_flos	equ $607
include 		"program_header\test_flos_version.asm"

;-----------------------------------------------------------------------------

	ld a,(hl)
	or a
	jr nz,got_arg

	ld hl,show_use_txt
	call kjt_print_string
	xor a
	ret
	
	
got_arg	ld de,output_fn			; arg is copied to output_fn
	ld b,12
evnclp	ld a,(hl)
	cp " "
	jr z,evncdone
	ld (de),a
	inc hl
	inc de
	djnz evnclp
evncdone

	ld hl,output_fn			; does this file exist already?
	call kjt_open_file
	jr nz,fdne
	ld hl,file_exists_txt
	call kjt_print_string
	call kjt_wait_key_press
	ld a,b
	cp "y"
	jr z,delfile
	cp "Y"
	jr z,delfile
	ld a,$2d
	or a
	ret

delfile	ld hl,output_fn
	call kjt_erase_file
	ret nz	

fdne	ld hl,index+16
	ld (index_addr),hl
	
	call kjt_dir_list_first_entry		;go to first entry in current dir
	ret nz
	
	ld hl,adding_txt
	call kjt_print_string	
	
		
get_dir_entry

	call kjt_dir_list_next_entry
	jr z,dir_read_ok
	
	cp $24
	jr z,end_of_dir
	ret
	

dir_read_ok

	bit 0,b
	jr nz,get_dir_entry			;if entry is a dir, skip it
	
	push hl
	call kjt_print_string		;show the filename
	ld hl,crlf_txt
	call kjt_print_string
	pop hl
	
	ld de,(index_addr)			;copy filename to index
	ld bc,12
	ldir
	ex de,hl

	push iy				;length of file lo word				
	pop de
	ld (hl),0				;null terminate filename
	inc hl
	ld (hl),e				;copy filelength [15:0] to index
	inc hl
	ld (hl),d
	inc hl
	push ix				;length of file lo word
	pop de
	ld (hl),e				;copy filelength [23:16] to index
	inc hl
	ld (index_addr),hl
	
	ld a,h				;make sure index hasnt gone crazy sized
	or a
	jr nz,get_dir_entry
	ld hl,index_too_big_txt		
	call kjt_print_string
	ld a,$80
	or a
	ret

end_of_dir

	ld hl,(index_addr)			;were any files found?
	xor a
	ld de,index+16
	sbc hl,de
	jr nz,indok
	
	ld hl,nofiles_txt
	call kjt_print_string
	ld a,$81
	or a
	ret
				
indok	ld hl,(index_addr)
	ld (hl),0				;zero terminate index
	inc hl
	ld de,index
	xor a
	sbc hl,de
	ld (index+13),hl			;Put length of index in first entry
		
	ld hl,saving_index_txt		;Save index file
	call kjt_print_string	
	ld hl,output_fn
	ld ix,index
	ld b,0
	ld de,(index+13)
	ld c,0
	call kjt_save_file
	ret nz
	
	ld hl,index+16
	ld (index_addr),hl
	
nxt_apnd	ld hl,joining_txt			;load file (filename supplied by index) into memory: B 1, $8000
	call kjt_print_string
	ld hl,(index_addr)
	call kjt_print_string
	ld hl,crlf_txt
	call kjt_print_string
	ld hl,(index_addr)
	ld b,1
	ld ix,$8000
	call kjt_load_file
	ret nz				
	
	ld hl,output_fn
	ld b,1
	ld ix,$8000
	ld iy,(index_addr)
	ld e,(iy+13)
	ld d,(iy+14)
	ld c,(iy+15)
	call kjt_write_to_file
	ret nz
	
	ld hl,(index_addr)
	ld de,16
	add hl,de
	ld (index_addr),hl
	ld a,(hl)
	or a
	jr nz,nxt_apnd
	
	ld hl,ok_txt
	call kjt_print_string
	xor a
	ret	
	
	
;----------------------------------------------------------------------------------------

show_use_txt

	db 11,"Bulk File Maker V1.00",11,11
	db "USE: BULKFILE filename",11,11
	db "Consolidates all files in current dir",11
	db "to a single file with an index header",11,0
	
file_exists_txt

	db 11,"WARNING: This file already exists!",11,11
	db "Delete it? (y/n)",11,0
		
output_fn

	ds 16,0

	
index_too_big_txt

	db 11,"ERROR: Index is too big!",11,11,0


adding_txt
	
	db 11,"Building Index:",11,11,0
	
nofiles_txt

	db "ERROR: No files found",11,11,0
	
saving_index_txt

	db 11,"Saving Index..",11,11,0
	
joining_txt

	db "Joining: ",0
	
	
ok_txt	db 11,"OK - All done.",11,11,0


crlf_txt	db 11,0


index_addr	

	dw 0

index_length

	dw 0
	
;----------------------------------------------------------------------------------------

	
index	db $ff,0,0,0, 0,0,0,0, 0,0,0,0, 0,0,0,0

;dont put anything else here
