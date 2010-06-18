;-----------------------------------------------------------------------
; PQFS "dir" show directory command. V6.01
;-----------------------------------------------------------------------

os_cmd_dir:

	call fs_check_disk_format
	ret c
	or a
	ret nz
	
	xor a
	ld (os_linecount),a
	
	call fs_get_dir_block		;first, show name of current dir
	ld a,0
	call fs_read_sector_new_lba
	ret c
	ld hl,sector_buffer+$10		;current directory name offset
	ld de,output_line
	ld a,11
	ld (de),a
	inc de
	ld a,"["
	ld (de),a
	inc de
	ld a,(sector_buffer+$20)		;length of dir name
	and $1f
	ld b,a
os_dcdnl:	ld a,(hl)
	ld (de),a
	inc de
	inc hl
	djnz os_dcdnl
	ld hl,dir_name_line			;the close bracket bit
	ld bc,3
	ldir
	call os_print_output_line
	call div_line
		
	call fs_goto_first_dir_entry

os_dfllp	call fs_get_dir_entry		;line list loop starts here
	ret c
	jr nz,os_dlr			;end of dir?
	push bc
	call os_print_string		;show filename
	call os_get_cursor_position		;move cursor to x = 20
	ld b,18
	call os_set_cursor_position	
	pop bc
	bit 0,b				;is this entry a file?
	jr z,os_deif		
	ld hl,dir_txt			;write [dir] next to name
	jr os_dpl
	
os_deif	ld hl,os_hex_prefix_txt		;its a file - write length next to name
	call os_print_string
	ld hl,output_line
	push hl
	push ix
	pop de
	call hexword_to_ascii
	push iy
	pop de
	call hexword_to_ascii
	ld (hl),0
	pop hl
	ld b,7				;skip only 7 out of 8 hex digits
	call os_skip_leading_ascii_zeros
os_dpl	call os_print_string
	call os_new_line
	
	call fs_goto_next_dir_entry
	jr nz,os_dlr			;end of dir?
	call os_count_lines
	ld a,"y"
	cp b
	jr z,os_dfllp
	


os_dlr:	call div_line			;now calc and show remaining disk space
	
	call fs_get_total_sectors
	ld b,6				;divide by 64 to get capacity total in blocks 
dcstb	srl c
	rr d
	rr e
	djnz dcstb
	
	push de
	pop iy				;capacity countdown
	ld ix,0				;all entries listed - now count free blocks
	ld c,1				;start at sector 1
os_dcb3:	push bc	
	ld a,c			
	cp $40
	jr z,os_gfbc
	
	ld de,0				;block zero
	call fs_read_sector_new_lba
	jr nc,os_dbcok
	pop bc
	ret				;return on ide error

os_dbcok:	ld bc,$200
	ld hl,sector_buffer
os_dcb1:	xor a
	or (hl)
	jr nz,os_dsk1
	inc ix				;inc free block count
os_dsk1:	inc hl
	dec iy				;dec max capacity count
	push iy
	pop de
	ld a,d
	or e
	jr z,os_gfbc
	dec bc
	ld a,b
	or c
	jr nz,os_dcb1

	pop bc
	inc c
	jr os_dcb3
	
os_gfbc:	pop bc				;all sectors of BAT read
	push ix				;ix = number of free blocks
	pop de				
	ld hl,0				;convert blocks in ix to KB in hl:de
	ld b,5
btokblp	sla e
	rl d
	rl l
	djnz btokblp

	call os_hex_to_decimal		;pass hl:de longword to decimal convert routine
	ld de,9
	add hl,de				;move to MSB of decimal digits
	ld b,10
	ld de,output_line
	push de
dec2strlp	ld a,(hl)				;scan for non-zero MSB
	or a
	jr nz,ndecchar
	dec hl
	djnz dec2strlp
	jr decdone
ndecchar	ld a,(hl)
	add a,$30
	ld (de),a
	inc de
	dec hl
	djnz ndecchar
decdone	xor a
	ld (de),a
	pop hl				;output line address
	call os_print_string
	
	ld hl,kb_spare_txt
	call os_print_string
	xor a
	ret

;-----------------------------------------------------------------------

div_line	ld a,"-"
	ld b,24
	ld hl,output_line
mdivline	ld (hl),a
	inc hl
	djnz mdivline
	ld (hl),0
	call os_print_output_line
	call os_new_line
	ret


;-----------------------------------------------------------------------

dir_txt		db "[DIR]",0

kb_spare_txt	db " KB Free",11,0

dir_name_line	db "]",11,0

;-----------------------------------------------------------------------
	