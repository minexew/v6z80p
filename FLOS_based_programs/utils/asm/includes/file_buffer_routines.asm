
fill_source_buffer
	
	ld hl,source_buffer
	ld (working_src_buffer_addr),hl			;restart at beginning of memory buffer
	
	ld a,(working_src_vol)
	ld de,(working_src_cluster)
	call set_dir_vol
	
	ld hl,working_src_filename	
	call kjt_find_file
	jr nz,file_error
		
	ld (working_src_file_size),iy
	ld (working_src_file_size+2),ix
	
	ld iy,(working_src_file_pointer)
	ld ix,(working_src_file_pointer+2)
	call kjt_set_file_pointer
	
	ld ix,0
	ld iy,src_buffer_size
	call kjt_set_read_length
	
	ld b,0
	ld hl,source_buffer				; load to bank 0
	call kjt_read_from_file
	jr z,file_ok
	cp $1b						; attempted to read beyond end of file?
	jr nz,file_error
	ld de,(working_src_file_pointer)		; if yes: zero-terminate source in buffer
	ld hl,(working_src_file_size)
	xor a
	sbc hl,de
	ld de,source_buffer
	add hl,de
	xor a
	ld (hl),a

file_ok	xor a
	ret


file_error
	
	ld a,5
	or a
	ret
	

get_dir
	call kjt_get_dir_cluster
	ld (original_dir),de
	call kjt_get_volume_info
	ld (original_vol),a
	ret


restore_dir

	ld a,(original_vol)
	call kjt_change_volume
	ld de,(original_dir)
	call kjt_set_dir_cluster
	ret
	
	
set_dir_vol

	push de
	call kjt_change_volume
	pop de
	call kjt_set_dir_cluster
	ret


get_dir_vol

	call kjt_get_dir_cluster
	push de
	call kjt_get_volume_info
	pop de
	ret
	
;---------------------------------------------------------------------------------------------------------------
	
	
find_file_all_included_dirs
 	
	ld a,(src_base_vol)				;all paths are relative to project base dir
	ld de,(src_base_cluster)
	call set_dir_vol
	
	ld hl,pathfn	
	call extract_path_and_filename		
        ld hl,path_txt
        call kjt_parse_path          			;change dir according to the path part of the string
        ret nz
	ld hl,filename_txt
	call kjt_open_file
	ret z
	
	ld hl,dirvol_include_list			;look in included dirs too
	ld (inc_list_addr),hl
	
findfile_lp

	ld hl,(inc_list_addr)				;scan the assign list for included dirs
scnilst ld a,(hl)
	cp $ff
	jr z,file_error
	ld (inc_list_addr),hl
	ld a,(hl)					;get vol in A
	inc hl
	ld e,(hl)
	inc hl
	ld d,(hl)					;get cluster in DE
	inc hl
	ld (inc_list_addr),hl
	call set_dir_vol
	
	ld hl,filename_txt
	call kjt_open_file
	ret z
	jr findfile_lp
			
		
;---------------------------------------------------------------------------------------------------------------

push_working_file_info

	ld a,(stack_level)
	cp max_stack_levels
	jr nz,stklevok
	ld a,7						; ERROR 7 - too many nested includes
	or a	
	ret
	
stklevok	

	ld hl,(working_src_buffer_addr)			;adjust file pointer by depth into RAM source buffer
	ld de,source_buffer
	xor a
	sbc hl,de
	ex de,hl
	ld hl,(working_src_file_pointer)
	ld bc,(working_src_file_pointer+2)
	add hl,de
	jr nc,pwf_mswok
	inc bc

pwf_mswok
	
	ld (working_src_file_pointer),hl
	ld (working_src_file_pointer+2),bc
	
	ld de,(stack_addr)
	ld bc,12
	ld hl,working_src_filename
	ldir
	ld iy,(stack_addr)
	ld de,(working_src_line_count)
	ld (iy+13),e
	ld (iy+14),d
	ld de,(working_src_file_pointer)
	ld (iy+15),e
	ld (iy+16),d
	ld de,(working_src_file_pointer+2)
	ld (iy+17),e
	ld (iy+18),d
	
	push iy
	call kjt_get_dir_cluster
	pop iy
	ld (iy+19),e
	ld (iy+20),d
	push iy
	call kjt_get_volume_info
	pop iy
	ld (iy+21),a
	
	ld a,(stack_level)
	inc a
	ld (stack_level),a
	ld hl,(stack_addr)
	ld de,stack_entry_size
	add hl,de
	ld (stack_addr),hl
	xor a
	ret
	
;----------------------------------------------------------------------------------------------------------------

pop_working_file_info

	ld a,(stack_level)
	dec a
	ld (stack_level),a
	ld hl,(stack_addr)
	ld de,stack_entry_size
	xor a
	sbc hl,de
	ld (stack_addr),hl
	ld de,working_src_filename
	ld bc,12
	ldir
	ld iy,(stack_addr)
	ld e,(iy+13)
	ld d,(iy+14)
	ld (working_src_line_count),de
	ld e,(iy+15)
	ld d,(iy+16)
	ld (working_src_file_pointer),de
	ld e,(iy+17)
	ld d,(iy+18)
	ld (working_src_file_pointer+2),de
	
	ld e,(iy+19)
	ld d,(iy+20)
	ld a,(iy+21)
	ld (working_src_vol),a
	ld (working_src_cluster),de
	xor a
	ret
	
;----------------------------------------------------------------------------------------------------------------

handle_incbin
	
	ld hl,0
	ld (incbin_file_pointer),hl

	call find_file_all_included_dirs
	jp nz,file_error
	ld (incbin_file_size),iy
	push ix
	pop hl
	ld a,h
	or l
	jr z,ibfsok

	ld a,9					;Error 9 - incbin file > 64KB
	or a
	ret
	
ibfsok	ld ix,0
	ld iy,(incbin_file_pointer)
	call kjt_set_file_pointer
	ld de,incbin_buffer_size
	add iy,de
	ld (incbin_file_pointer),iy
	
	ld ix,0
	ld iy,incbin_buffer_size
	call kjt_set_read_length
	
	ld b,0
	ld hl,incbin_buffer			; load to bank 0
	ld a,(pass_count)
	or a
	jr z,ibfrne				; on pass zero, dont bother actually reading the data
	call kjt_read_from_file
	jr z,ibfrne
	cp $1b
	jr nz,incbflerr				; dont care about read beyond eof error
ibfrne	ld hl,(incbin_file_size)
	ld de,incbin_buffer_size		
	xor a					; filesize - buffersize = bytes left to read
	sbc hl,de
	ld (incbin_file_size),hl		;
	jr z,incblast				; if zero all the bytes were read
	jr c,incblast				; if borrow all the bytes were read
	
	ld bc,incbin_buffer_size
	call incbin_data_copy
	jr nz,incbflerr
	ld hl,filename_txt	
	call kjt_find_file
	jp nz,file_error			; note: file will need to be reopened if output byte routine saves
	jr ibfsok				; data prior to end of assembly (currently it does not).
					
incblast	

	add hl,de
	push hl
	pop bc
	call incbin_data_copy		

incbflerr	

	ret	
		


	
incbin_data_copy
	
		ld hl,incbin_buffer
incbloop	ld a,(hl)
		push hl
		push bc
		call output_data_byte
		pop bc
		pop hl
		ret nz
		inc hl
		dec bc
		ld a,b
		or c
		jr nz,incbloop
		xor a
		ret
	
	
;----------------------------------------------------------------------------------------------------------------

copy_fnpath_no_quotes

; set DE to dest filename string

		ld de,pathfn
		ld hl,opcode_arg1_string
		ld b,255
cinclfn		ld a,(hl)
		inc hl
		cp $22				; skip any quotes
		jr z,cinclfn
		ld (de),a
		inc de
		or a
		ret z
		djnz cinclfn
		ret

;----------------------------------------------------------------------------------------------------------------
	
	
save_assembled_binary

		ld a,(src_base_vol)		;save in main project base dir
		ld de,(src_base_cluster)
		call set_dir_vol

		ld hl,working_src_filename	;convert source filename.asm to filename.exe
		ld b,8
find_dot	ld a,(hl)
		cp "."
		jr z,got_dot
		inc hl
		djnz find_dot
got_dot		ld (hl),"."
		inc hl
		ld (hl),"E"
		inc hl
		ld (hl),"X"
		inc hl
		ld (hl),"E"

		ld hl,working_src_filename	;delete a file with this .exe name (if exists)
		call kjt_erase_file		;dont care about errors

		ld hl,(bin_addr)
		ld de,(min_addr)
		ld c,0
		xor a
		sbc hl,de
		jr nz,save_flok			;if save = 0 bytes dont attempt save unless overflow set
		ld a,(mem_overflow)		;then save 65536 bytes
		or a
		jr z,nothing_to_save
		ld c,1
save_flok	ex de,hl			;C:DE length of file
		xor a
		ld hl,(min_addr)		;convert flat mem to bank+addr
		sla h
		rla
		scf
		rr h
		inc a
		ld b,a				;B = bank to save from
		push hl
		pop ix				;IX = address to save from
		ld hl,working_src_filename
		call kjt_save_file
		ret z

		ld a,11				;error 11 - save problem
		or a
		ret

nothing_to_save

		ld a,12				;error 12 - nothing to save
		or a
		ret
			
;----------------------------------------------------------------------------------------------------------------
	

	
	