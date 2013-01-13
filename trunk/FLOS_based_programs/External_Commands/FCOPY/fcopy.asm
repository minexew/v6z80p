
; FCOPY.EXE command - COPY FILE - for FLOS, By Phil @ retroleum.co.uk
;
; USE: FCOPY src dst
;
; Changes: 0.02 - first version
;
; Notes: Source TAB size = 8
;
;======================================================================================
; Standard equates for OSCA and FLOS
;======================================================================================

include "equates\kernal_jump_table.asm"
include "equates\osca_hardware_equates.asm"
include "equates\system_equates.asm"

;--------------------------------------------------------------------------------------
; Header code - Force program load location and test FLOS version.
;--------------------------------------------------------------------------------------

my_location	equ $b000
my_bank		equ $0e
include 	"flos_based_programs\code_library\program_header\inc\force_load_location.asm"

required_flos	equ $608
include 	"flos_based_programs\code_library\program_header\inc\test_flos_version.asm"

;------------------------------------------------------------------------------------------------
; Actual program starts here..
;------------------------------------------------------------------------------------------------

file_buffer_length	equ $4000
file_buffer_bank	equ my_bank

max_path_length 	equ 40


		call save_dir_vol
		call copy_file_cmd
		call restore_dir_vol
		ret
		
;------------------------------------------------------------------------------------------------

copy_file_cmd	ld (args_loc),hl
		ld a,(hl)				;if args = null, show use
		or a    
		jp z,show_use

		call extract_path_and_filename		;find vol:cluster of source file
		ld a,(path_txt)
		or a
		jr z,no_path1
		ld hl,path_txt
		call kjt_parse_path			;change dir according to the path part of the string
		ret nz
no_path1	ld hl,filename_txt
		ld de,src_filename_txt
		ld bc,12
		ldir	
		ld hl,src_filename_txt
		call kjt_open_file			;does file exist in current dir?
		ret nz
		call note_src_dirvol
		
		call restore_dir_vol			;go back to original dir for relative path base for destination 
				
		ld hl,(args_loc)			;find dest dir (if none specified, use current dir)
		call find_next_argument
		ret nz
		call extract_path_and_filename		;split dir and file 
		ld a,(path_txt)
		or a
		jr z,no_path2
		ld hl,path_txt
		call kjt_parse_path			;change dir according to the path part
		ret nz
		
no_path2	ld hl,filename_txt
		ld a,(hl)				;if no dest filename supplied, use source filename for dest
		or a
		jr nz,dstfn_supplied
		ld hl,src_filename_txt
dstfn_supplied	ld de,dst_filename_txt
		ld bc,12
		ldir	
		call note_dst_dirvol
		
		xor a					;are src and dst filenames the same?
		ld (same_fn),a	
		ld hl,src_filename_txt			
		ld de,dst_filename_txt
		ld b,12
		call kjt_compare_strings
		jr nc,notsame_fn		
		ld a,1
		ld (same_fn),a
		
notsame_fn	ld a,(src_vol)				;are src and dst dirs the same?
		ld hl,dst_vol
		cp (hl)
		jr nz,notsame_dv
		ld hl,(src_cluster)
		ld de,(dst_cluster)
		xor a
		sbc hl,de
		jr nz,notsame_dv			
		ld a,(same_fn)
		or a					;if so, are src+dst filenames the same?
		jr z,notsame_dv		
		ld hl,same_file_txt			;if so, report same and..
		call kjt_print_string
		ld a,$80				;return with silent error code $80
		or a
		ret
	
notsame_dv	ld hl,dst_filename_txt
		call kjt_open_file			;does a file of same name already exist in the dest?
		jr z,file_exists
		cp 2
		jr z,new_dst_file			;ok to proceed if "file not found"
		cp 6
		ret nz
		ld a,$25				;if a dir exists with this filename, return "filename mismatch"
		or a
		ret

file_exists	ld hl,file_exists_txt			;if dest file already exists, ask if want to append data, overwrite or cancel
		call kjt_print_string
		ld a,1
		call kjt_get_input_string	
		call new_line
		or a
		jr z,aborted
		ld a,(hl)
		cp "o"
		jr z,overwrite
		cp "O"
		jr z,overwrite
		cp "a"
		jr z,append
		cp "A"
		jr z,append
aborted		ld a,$2d				;return "Aborted" error
		or a
		ret
		
new_dst_file	ld hl,copying_txt
		call kjt_print_string
		ld hl,src_filename_txt
		call kjt_print_string
		ld a,(same_fn)
		or a
		jr nz,create_dest			;if same filenames src+dst, no need to show " to dest"
		ld hl,to_txt
		call kjt_print_string		
		jr show_destfn

append		ld hl,appending_txt
		call kjt_print_string
		ld hl,src_filename_txt
		call kjt_print_string
		ld a,(same_fn)
		or a
		jr nz,ok_to_copy			;if same filenames src+dst, no need to show " to dest"
		ld hl,to_txt
		call kjt_print_string		
		ld hl,dst_filename_txt
		call kjt_print_string
		jr ok_to_copy
		
overwrite	ld hl,dst_filename_txt			;erase existing file in dest dir
		call kjt_erase_file			
		ret nz
		ld hl,overwriting_txt
		call kjt_print_string

show_destfn	ld hl,dst_filename_txt
		call kjt_print_string
create_dest	ld hl,dst_filename_txt			;create new file on dest dir
		call kjt_create_file
		ret nz


ok_to_copy	call new_line
		
		call copy_file
		ret nz
		
		ld hl,ok_txt
		call kjt_print_string
		xor a
		ret

;------------------------------------------------------------------------------------------------

copy_file

; Put ASCII filename string at "filename_txt" before calling


		call go_src_dirvol
	
		ld hl,src_filename_txt			
		call kjt_open_file
		ret nz
		ld (file_length_hi),ix			;note the file length
		ld (file_length_lo),iy
		xor a
		ld (fc_eof),a				;zero end of file flag
		ld hl,0
		ld (file_pointer_lo),hl			;zero the file pointer
		ld (file_pointer_hi),hl

fc_loop		call go_src_dirvol
	
		ld hl,src_filename_txt			;set up pointers (in)to source file	
		call kjt_open_file
		ret nz
	
		push ix				;if source file = zero bytes in length dont do anything else
		push iy
		pop hl
		ld a,l
		or h
		pop hl
		or l
		or h
		jr z,fc_done
		ld ix,(file_pointer_hi)
		ld iy,(file_pointer_lo)
		call kjt_set_file_pointer
		ld ix,0
		ld iy,file_buffer_length
		call kjt_set_load_length
		ld hl,file_buffer			;read a chunk of file into buffer
		ld b,file_buffer_bank
		call kjt_read_from_file
		jr z,fc_slok
		cp $1b					;dont care if tried to load beyond end of file
		ret nz
		
fc_slok		call go_dst_dirvol
	
		ld hl,file_buffer_length		;is the buffer size bigger than the remaining bytes in file?
		ld de,(file_length_lo)
		xor a
		sbc hl,de
		ld hl,0
		ld de,(file_length_hi)
		sbc hl,de
		jr nc,fc_ufl
		ld de,file_buffer_length		;if not, use the buffer length as the write length
		ld c,0
		jr fc_ufbl
fc_ufl		ld de,(file_length_lo)			;otherwise use bytes remaining as the write length and flag EOF
		ld bc,(file_length_hi)
		ld a,1
		ld (fc_eof),a				;set end of file flag
fc_ufbl		ld b,file_buffer_bank
		ld hl,dst_filename_txt
		ld ix,file_buffer
		call kjt_write_to_file			;append buffer bytes to dest file
		ret nz
		
		ld a,(fc_eof)				;reached end of source file?
		or a
		jr z,fc_mbytd
fc_done		xor a					;exit: ALL OK
		ret
	
fc_mbytd	ld hl,(file_pointer_lo)			;move file pointer along by buffer_length
		ld de,file_buffer_length
		add hl,de
		ld (file_pointer_lo),hl
		ld hl,(file_pointer_hi)
		ld de,0
		adc hl,de
		ld (file_pointer_hi),hl
	
		ld hl,(file_length_lo)			;decrease the bytes remaining by buffer_length
		ld de,file_buffer_length
		xor a
		sbc hl,de
		ld (file_length_lo),hl
		ld hl,(file_length_hi)
		ld de,0
		sbc hl,de
		ld (file_length_hi),hl
		
		ld hl,dot_txt
		call kjt_print_string			;show indication of progress
		
		jp fc_loop

	
fc_eof		db 0

file_length_lo	dw 0
file_length_hi	dw 0
file_pointer_lo	dw 0
file_pointer_hi	dw 0

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
	
;----------------------------------------------------------------------------------------------

new_line	push af
		push hl
		ld hl,newline_txt
		call kjt_print_string
		pop hl
		pop af
		ret

;----------------------------------------------------------------------------------------------
		

show_use	ld hl,no_args_txt			
		call kjt_print_string
		xor a
		ret

;----------------------------------------------------------------------------------------------
		
no_args_txt	db 11,"FCOPY.FLX (FILE COPY) V0.02",11
		db "USE: FCOPY src dest",11,11,0

same_file_txt	db 11,"ERROR: The source and destination",11
		db "cannot be the same file.",11,0

file_exists_txt	db 11,"A file with this name already exists",11
		db "in the destination dir.",11,11 
		db "[O]verwrite, [A]ppend or [C]ancel? ",0

copying_txt	db "Copying ",0
to_txt		db " to ",0

overwriting_txt db "Overwriting ",0

appending_txt	db "Appending ",0

ok_txt		db 11,"OK",11,0

dot_txt		db ".",0

newline_txt	db 11,0

src_filename_txt	ds 13,0

dst_filename_txt	ds 13,0

same_fn		db 0
		
;-------------------------------------------------------------------------------------------		

include "FLOS_based_programs\code_library\loading\inc\save_restore_dir_vol.asm"

include "FLOS_based_programs\code_library\string\inc\extract_path_and_filename.asm"

include "FLOS_based_programs\code_library\string\inc\find_next_argument.asm"

;-------------------------------------------------------------------------------------------

args_loc	dw 0

;-------------------------------------------------------------------------------------------

file_buffer	db 0			;start of file buffer - do not place any variables beyond this point


