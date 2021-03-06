
; App: FCMP - compares files. V1.02 By Phil Ruston
;
; V1.02 - Allows paths in filenames
;
; Source TAB size = 8

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

required_flos	equ $598
include 	"flos_based_programs\code_library\program_header\inc\test_flos_version.asm"

;-------- Parse command line arguments -------------------------------------------------

window_rows	equ 25

buffer_size	equ $400

max_path_length equ 40


		call save_dir_vol
		call compare_files_cmd
		call restore_dir_vol
		ret
		
;------------------------------------------------------------------------------------------------

compare_files_cmd

		ld a,(hl)				; examine name argument text, if 0: show use
		or a			
		jp z,show_use
		
		cp '#'					; check for # = silent running
		jr nz,not_sr
		ld a,1
		ld (silent),a
		call find_next_argument
		ret nz
	
not_sr		ld (args_loc),hl
		call extract_path_and_filename		;find vol:cluster of file1
		ld a,(path_txt)
		or a
		jr z,no_path1
		ld hl,path_txt
		call kjt_parse_path			;change dir according to the path part of the string
		ret nz
no_path1	ld hl,filename_txt
		call kjt_open_file			;does file exist in this dir?
		ret nz
		ld (f1_len),iy
		ld (f1_len+2),ix
		call note_src_dirvol
		ld hl,filename_txt
		ld de,filename1
		ld bc,12
		ldir
		
		call restore_dir_vol			;go back to original dir for relative path base for destination 
		
		ld hl,(args_loc)
		call find_next_argument
		ret nz
		call extract_path_and_filename		;find vol:cluster of file2
		ld a,(path_txt)
		or a
		jr z,no_path2
		ld hl,path_txt
		call kjt_parse_path			;change dir according to the path part of the string
		ret nz
no_path2	ld hl,filename_txt
		call kjt_open_file			;does file exist in this dir?
		ret nz
		ld (f2_len),iy
		ld (f2_len+2),ix
		call note_dst_dirvol
		ld hl,filename_txt
		ld de,filename2
		ld bc,12
		ldir

		ld hl,(f1_len)				;are files same length?
		ld de,(f2_len)
		xor a
		sbc hl,de
		jr nz,notslen
		ld hl,(f1_len+2)
		ld de,(f2_len+2)
		xor a
		sbc hl,de
		jr z,fslen
notslen		ld hl,fdiff_len_txt
		call cond_print_string
		ld a,1
		ld (fs_diff),a
		ld a,5
		ld (line_count),a
		
fslen		ld hl,0					;init compare 
		ld (file_pointer),hl
		ld (file_pointer+2),hl
		xor a
		ld (diff_flag),a
		
		ld hl,comparing_txt
		call cond_print_string

;----------------------------------------------------------------------------------------------------------
		
comp_loop	ld hl,buffer_size			;compare whole buffer by default
		ld (compare_count),hl

		call go_src_dirvol
		ld hl,filename1				;read a chunk of file 1
		call kjt_open_file
		ret nz
		ld ix,0
		ld iy,buffer_size
		call kjt_set_load_length
		ld iy,(file_pointer)
		ld ix,(file_pointer+2)
		call kjt_set_file_pointer
		ld hl,buffer1
		ld b,my_bank
		call kjt_read_from_file
		jr z,f1loadok
		cp $1b					;if file load 1 encountered EOF, reduce buffer compare size
		jp nz,load_err
		ld hl,(f1_len)		
		ld (compare_count),hl
		
f1loadok	call go_dst_dirvol
		ld hl,filename2				;read a chunk of file 2
		call kjt_open_file
		ret nz
		ld ix,0
		ld iy,buffer_size
		call kjt_set_load_length
		ld iy,(file_pointer)
		ld ix,(file_pointer+2)
		call kjt_set_file_pointer
		ld hl,buffer2
		ld b,my_bank
		call kjt_read_from_file
		jr z,f2loadok
		cp $1b					;if file load 2 encountered EOF, reduce buffer compare size
		jp nz,load_err				;but only if smaller than it already is
		ld hl,(compare_count)
		ld de,(f2_len)
		xor a
		sbc hl,de
		jr c,f2loadok
		ld (compare_count),de
		
f2loadok	ld bc,(compare_count)			;if compare count has been reduced to zero, all done
		ld a,b
		or c
		jr z,all_done
		ld hl,buffer1				;compare the contents of the buffers
		ld de,buffer2	
bufcmplp	ld a,(de)
		cp (hl)
		jr z,byte_same
		call byte_diff
		jp nz,aborted				;long list was aborted
byte_same	inc hl
		inc de
		dec bc
		ld a,b
		or c
		jr nz,bufcmplp
		
		
		ld hl,(compare_count)			;if buffer size was reduced, this was the last compare
		ld de,buffer_size
		xor a
		sbc hl,de
		jr nz,all_done
			
		ld hl,(file_pointer)			;move file pointer
		ld de,buffer_size
		add hl,de
		ld (file_pointer),hl
		ld hl,(file_pointer+2)
		ld de,0
		adc hl,de
		ld (file_pointer+2),hl
		
		ld hl,(f1_len)				;lessen filesizes by buffer count
		ld de,buffer_size
		xor a
		sbc hl,de
		ld (f1_len),hl
		ld de,0
		ld hl,(f1_len+2)
		sbc hl,de
		ld (f1_len+2),hl
		
		ld hl,(f2_len)
		ld de,buffer_size
		xor a
		sbc hl,de
		ld (f2_len),hl
		ld de,0
		ld hl,(f2_len+2)
		sbc hl,de
		ld (f2_len+2),hl
		jp comp_loop
		
;-----------------------------------------------------------------------------------------------------

all_done	ld a,(silent)
		or a
		jr nz,skipetxt
		
		ld hl,done_txt
		call kjt_print_string
		ld a,(diff_flag)
		or a
		ld hl,identical_txt
		call z,kjt_print_string
		ld hl,new_line_txt
		call kjt_print_string	
		
skipetxt	ld b,$80
		ld a,(diff_flag)		;if different, error code = $80
		or a
		jr nz,got_code
		
		ld b,0
		ld a,(fs_diff)			;if file size is different but contents same: error code $81
		or a
		jr z,got_code
		ld b,$81
		
got_code	ld a,b
		or a
		ret
		

load_err	or a
		ret


aborted		ld a,$2d
		or a
		ret

;------------------------------------------------------------------------------------------------

byte_diff	ld a,1
		ld (diff_flag),a
		
		ld a,(silent)
		or a
		jp nz,bdiff_end
		
		push hl
		push de
		push bc

		ld hl,line_count			;screen filled with difference lines already?
		inc (hl)
		ld a,(hl)
		cp window_rows-1
		jr nz,show_more
		ld (hl),0
		ld hl,more_txt
		call kjt_print_string
		call kjt_wait_key_press
		ld a,b
		cp "y"
		jr z,show_more
		pop hl
		pop de
		pop bc
		ld hl,dmore_txt
		call kjt_print_string
		ld a,$2d				;aborted error code
		or a
		ret

show_more	pop bc
		pop de
		pop hl
		
		push hl
		push de
		push bc
		
		ld a,(hl)
		push af
		ld a,(de)
		ld hl,diff_str_b2
		call kjt_hex_byte_to_ascii
		pop af
		ld hl,diff_str_b1
		call kjt_hex_byte_to_ascii
		pop bc
		push bc
		ld hl,(compare_count)
		xor a
		sbc hl,bc
		ld de,(file_pointer)
		add hl,de
		ld (diff_addr),hl
		ld hl,(file_pointer+2)
		ld de,0
		adc hl,de
		ld (diff_addr+2),hl
		ld hl,diff_str_addr
		ld a,(diff_addr+3)
		call kjt_hex_byte_to_ascii
		ld a,(diff_addr+2)
		call kjt_hex_byte_to_ascii
		ld a,(diff_addr+1)
		call kjt_hex_byte_to_ascii
		ld a,(diff_addr)
		call kjt_hex_byte_to_ascii
		
		ld hl,diff_txt
		call kjt_print_string
		
		ld hl,diff_str_addr
		ld b,4
skipzero	ld a,(hl)
		cp "0"
		jr nz,got_fd
		inc hl
		djnz skipzero
		
got_fd		call kjt_print_string
		pop bc
		pop de
		pop hl

bdiff_end	xor a
		ret
		
;------------------------------------------------------------------------------------------------

cond_print_string

		ld a,(silent)
		or a
		ret nz
		call kjt_print_string
		ret

;------------------------------------------------------------------------------------------------
		
show_use	ld hl,usage_txt
		call kjt_print_string
		xor a
		ret
		
;------------------------------------------------------------------------------------------------

go_src_dirvol	push bc
		push de
		push hl
		ld a,(src_vol)
		call kjt_change_volume
		ld de,(src_cluster)
		call kjt_set_dir_cluster
		pop hl
		pop de
		pop bc
		ret



go_dst_dirvol	push bc
		push de
		push hl
		ld a,(dst_vol)
		call kjt_change_volume
		ld de,(dst_cluster)
		call kjt_set_dir_cluster
		pop hl
		pop de
		pop bc
		ret
	

note_src_dirvol	push bc
		push de
		push hl
		call kjt_get_dir_cluster
		ld (src_cluster),de
		call kjt_get_volume_info
		ld (src_vol),a
		pop hl
		pop de
		pop bc
		ret

	
	
note_dst_dirvol	push bc
		push de
		push hl
		call kjt_get_dir_cluster
		ld (dst_cluster),de	
		call kjt_get_volume_info
		ld (dst_vol),a
		pop hl
		pop de
		pop bc
		ret

src_vol		db 0
dst_vol		db 0
src_cluster	dw 0
dst_cluster	dw 0

;-------------------------------------------------------------------------------------------		

include "FLOS_based_programs\code_library\loading\inc\save_restore_dir_vol.asm"

include "FLOS_based_programs\code_library\string\inc\extract_path_and_filename.asm"

include "FLOS_based_programs\code_library\string\inc\find_next_argument.asm"

;----------------------------------------------------------------------------------------------

args_loc	dw 0

usage_txt	db 11,"FCMP.FLX (V1.02) - Compare files",11,11
		db "Usage: FCMP [#] FILE1 FILE2",11,11,0

fdiff_len_txt	db 11,"** Files are not the same length!  **",11
		db    "** Will compare to end of shortest **",11,11,0
		
comparing_txt	db "Comparing..",11,0

done_txt	db "Done",0
identical_txt	db " - File contents are identical.",0
new_line_txt	db 11,0

diff_txt	db "Offset: $",0
diff_str_addr	db "xxxxxxxx - $"
diff_str_b1	db "xx / $"
diff_str_b2	db "xx",11,0

more_txt	db "Show more? (y/n)",13,0
dmore_txt	db "                ",13,0

;------------------------------------------------------------------------------------------------


file_pointer	db 0,0,0,0
f1_len		db 0,0,0,0
f2_len		db 0,0,0,0

diff_flag	db 0
diff_addr	db 0,0,0,0

compare_count	dw 0

filename1	ds 13,0
filename2	ds 13,0

silent		db 0
fs_diff		db 0
line_count	db 0

;------------------------------------------------------------------------------------------------

buffer1		db 0

buffer2		equ buffer1+buffer_size

;------------------------------------------------------------------------------------------------
