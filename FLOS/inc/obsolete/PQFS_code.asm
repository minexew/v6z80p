;---------------------------------------------------------------------------------------------
; PQFS File System..  v5.07
;
; Changes: 5.01 - Filenames no longer case sensitive
;          5.02 - Rename function added
;	 5.03 - Changed fs_save_file to fs_create_file and fs_write_bytes_to_file
;                 (allows data to be appended to existing files)
;          5.05 - Some code-length optimizations
;          5.06 - Directory listing routines added.
;               - To standardize with FAT16 routines, renamed:
;               -  read_sector -> read_sector_new_lba
;               -  write_sector -> write_sector_new_lba
;	      -  read_sector_existing_lba -> read_sector
;               -  write_sector_existing_lba -> write_sector   
;          5.07 -  File seek speeded up

;---------------------------------------------------------------------------------------------
	
;fs_[x]_command returns:

;carry=1, a =   Hardware error register bits	(0=timeout) 	

;carry=0,	a=0 : operation completed ok
;	a=1 : disk is full
;	a=2 : file not found
;	a=3 : directory is full
;	a=4 : not a directory
;	a=5 : directory is not empty
;	a=6 : this is directory not a file
;	a=7 : file length is zero
;	a=8 : source/dest address out of memory range
;	a=9 : filename already exists
;	a=10: already at root block
;	a=19: disk not expected format
;         a=27: requested bytes beyond end of file
;         a=36: end of directory list
	
;---------------------------------------------------------------------------------------------
; For commands that access files put file / dir name in "fs_filename" before call
;---------------------------------------------------------------------------------------------


fs_check_disk_format

	call fs_check_disk_available
	or a
	ret nz
go_chpqfs xor a			;read block 0 sector 0
	ld d,a
	ld e,a
	call fs_read_sector_new_lba
	ret c			;quit on h/w error

	ld hl,sector_buffer		;first 4 bytes should be "PQFS"..
	ld de,fs_pqfs_txt
	ld b,4
fs_cpqfs:	ld a,(de)
	cp (hl)
	jr nz,fs_notpqfs
	inc hl
	inc de
	djnz fs_cpqfs
	ld a,1			;..followed by a 1 for BAT block
	cp (hl)
	jr nz,fs_notpqfs
	xor a			;carry = 0,  A = 0 -> OK to proceed
	ret

fs_notpqfs

	xor a
	ld a,$13			;"not a pqfs disk" error code
	ret	



;------------------------------------------------------------------------------------------------


fs_format_command:

	
	call fs_clear_sector_buffer

	ld bc,0			;clear true LBA sector 0 (the MBR / boot sector of
	ld d,b			;FAT drives)
	ld e,b
	call kjt_set_sector_lba
	call fs_write_sector
	ret c
	
	call fs_do_pqfs
	ld (hl),1			;block id = 1: Block Allocation Table 
	xor a			;sector offset = 0	
	ld d,a			;block 0 (first block of available disk space)
	ld e,a
	call fs_write_sector_new_lba
	ret c
	
	call fs_clear_sector_buffer
	ld hl,$0101
	ld (sector_buffer),hl	;bat: 2nd sector (mark 1st two disk blocks in use)
	ld a,1
	call fs_write_sector_new_lba
	ret c

	ld c,2			;start at sector 2
	ld b,$3e			;write out 62 blank sectors
	ld de,0			;clear rest of bat
	call fs_write_blank_sectors	;(clears sector buffer too)
	ret c
		
	call fs_do_pqfs		;init root directory
	ld (hl),2			;mark as directory block
	ld de,sector_buffer+$10	;copy dir name to sector header
	ld hl,os_root_dir_text	;root dir (disk) name and name length
	ld bc,5
	ldir
	ld a,4
	ld (sector_buffer+$20),a
	ld de,1			;block 1
	xor a			;sector 0
	call fs_write_sector_new_lba
	ret c
	
	ld c,1			;sector 1 to start
	ld b,$3f			;write out 63 blank sectors
	ld de,1			;clear rest of root sectors
	call fs_write_blank_sectors	;(clears sector buffer too)
	ret c
	
	ld de,1			;set current dir to root block
	call fs_update_dir_block
	xor a			;op completed ok: a = 0, carry = 0
	ret
	

;----------------------------------------------------------------------------------------------

fs_rename_command

	call fs_get_filename_length	;get length of replacement filename
	ret nz
	call fs_find_name_entry	;does a file/dir already exist with that name?
	ret c			;h/w error?
	cp 2			
	jr z,fs_nfnok		;if error = 2 (file not found), its OK to proceed
	xor a			;clear carry flag
	ld a,9			;error 9: "filename already exists"
	ret

fs_nfnok	ld hl,fs_filename		;stash replacement filename for now
	ld de,fs_filename_buffer
	ld bc,16
	ldir
	ld hl,fs_alt_filename	;get existing filename
	ld de,fs_filename
	ld bc,16
	ldir
	call fs_get_filename_length
	ret nz
	call fs_find_name_entry	;does it exist?
	ret c
	cp 2
	ret z			;file/dir not found - return with error
	
	push hl
	ld hl,fs_filename_buffer	;put replacement filename back in active filename 	
	ld de,fs_filename
	ld bc,16
	ldir
	call fs_get_filename_length
	pop hl
	call fs_replace_filename	;overwrite original filename in sector buffer
	inc hl
	inc hl
	ld e,(hl)			;get location of file/dir's block
	inc hl
	ld d,(hl)
	ld (fs_next_block),de	;make a note of first block
	call fs_write_sector
	ret c

	ld de,(fs_next_block)	;now go to the file's actual start block and..
fs_fbllp	xor a			
	call fs_read_sector_new_lba
	ld hl,fs_filename
	ld de,sector_buffer+$10
	ld bc,16
	ldir			;..overwrite the filename there as well	
	ld a,(fs_filename_length)
	ld (de),a
	call fs_write_sector
	ld a,(sector_buffer+4)
	cp $2			;is this a directory we're renaming?
	jr z,fs_rndone		;if so, there cannot be any more blocks to do
	ld de,(sector_buffer+8)	
	ld a,d			;this is a file, are there any more blocks
	or e			;in this chain? If there are, update their headers too
	jr nz,fs_fbllp
	
fs_rndone	xor a
	ret
	
;----------------------------------------------------------------------------------------------


fs_make_dir_command:		

	call fs_get_filename_length	;get length of req'd filename
	ret nz
	call fs_find_free_block
	ret c			;hardware error?
	cp 1			;a=1: disk full?
	ret z
	call fs_find_name_entry	;does a file/dir already exist with that name?
	ret c			;hardware error?
	cp 2			;a=2: file not found?
	jr z,fs_nfwtn		;
	xor a			;clear carry flag
	ld a,9			;error 9: "filename already exists"
	ret
fs_nfwtn:	call fs_find_free_dir_line
	ret c			;hardware error?
	cp 3			;3 = dir table is full
	ret z
	call fs_copy_name
	ld (hl),1			;set attrib byte to 1 (dir)
	inc hl
	inc hl
	ld de,(fs_free_block)	;fill in prepared block address
	ld (hl),e
	inc hl
	ld (hl),d
	call fs_write_sector
	ret c			;update this directory sector
	
	call fs_clear_sector_buffer	;create new directory 
	call fs_do_pqfs
	ld (hl),2			;block id byte = 2 (directory)
	inc hl
	inc hl
	call fs_get_dir_block	;fill in parent block address (ie:current pos)
	ld (hl),e
	inc hl
	ld (hl),d
	ld de,sector_buffer+$10	;copy dir name to sector header
	ld hl,fs_filename
	ld a,(fs_filename_length)
	ld b,a
fs_mdcnl:	ld a,(hl)
	ld (de),a
	inc hl
	inc de
	djnz fs_mdcnl
	ld a,(fs_filename_length)	;and also length of name
	ld (sector_buffer+$20),a
	ld de,(fs_free_block)
	xor a
	call fs_write_sector_new_lba	;write out 1st (header) sector
	ret c			;hardware error?
	
	ld c,1			;clear rest of sectors
	ld b,$3f			;write out following 63 blank sectors
	ld de,(fs_free_block)
	call fs_write_blank_sectors
	ret c			;hardware error?
		
	ld de,(fs_free_block)	;update the bat to show this block is now in use
	call fs_mark_block_used	;hardware error?	
	ret c
	xor a			;op completed ok: a = 0, carry = 0
	ret
	
	
;------------------------------------------------------------------------------------------------

	
fs_change_dir_command:
	
	call fs_get_filename_length	;get length of req'd filename
	ret nz
	call fs_find_name_entry
	ret c			;hw error?
	cp 2			;2 = file/dir not found		
	jr nz,dirfound		
	ld a,$23			;change error to *DIR* not found		
	ret			
dirfound:	ld bc,$10
	add hl,bc
	bit 0,(hl)
	jr nz,fs_cdir		;ok so far but is it a directory?
	xor a			;clear carry flag
	ld a,4			;error 4 = name is not a directory
	ret
fs_cdir:	inc hl
	inc hl
	ld e,(hl)
	inc hl
	ld d,(hl)
	call fs_update_dir_block	;update current position
	xor a			;op completed ok: a = 0, carry = 0
	ret


;-----------------------------------------------------------------------------------------------


fs_parent_dir_command:

	
	call fs_get_dir_block	;move up a dir level
	xor a
	call fs_read_sector_new_lba		;read 1st sector of current dir block
	ret c			;hardware error?
	ld ix,sector_buffer		;get parent block entry
	ld e,(ix+6)		;parent low
	ld d,(ix+7)		;parent high
	ld a,d
	or e
	jr nz,fs_dbok
	xor a
	ld a,10			;error 10 = already at root block
	ret
	
fs_dbok:	call fs_update_dir_block	;update current position
	xor a			;op completed ok: a = 0, carry = 0
	ret


;-------------------------------------------------------------------------------------------------


fs_goto_root_dir_command:

		
	ld de,1			
	call fs_update_dir_block	;set root dir	
	xor a			;op completed ok, a = 0, carry = 0
	ret	

;------------------------------------------------------------------------------------------------


fs_get_dir_info:

	call fs_get_dir_block	;returns parent block in DE
	xor a			;HL = pointer to dir name
	call fs_read_sector_new_lba			
	ret c
	ld hl,sector_buffer+$10
	ld a,(sector_buffer+6)
	ld e,a
	ld a,(sector_buffer+7)
	ld d,a
	xor a
	ret
	

;------------------------------------------------------------------------------------------------


fs_delete_dir_command:


	call fs_get_filename_length	;get length of req'd filename
	ret nz
	call fs_cache_current_dir_block
	call fs_change_dir_command	
	ret c			;hardware error?
	or a			;check it actually exists first
	ret nz

	ld b,$3f			;check that this dir is empty
	ld c,1			
fs_cne2:	call fs_get_dir_block	;get sector 1 of dir block moved to
	ld a,c
	call fs_read_sector_new_lba
	ret c			;hardware error?
	push bc
	ld b,16			;entries per sector count
	ld hl,sector_buffer
	xor a
	ld de,$20
fs_cne1:	or (hl)
	jr nz,fs_nee
	add hl,de
	djnz fs_cne1
	pop bc
	inc c
	djnz fs_cne2

	call fs_get_dir_block	;dir is empty, so we can proceed
	ld (fs_free_block),de
	call fs_mark_block_free	;de-allocate its pos in BAT
	ret c
	call fs_restore_cached_dir_block
	call fs_find_name_entry
	ret c			;hardware error?
	call fs_clear_name_entry
	call fs_write_sector
	ret c			;write back last read sector
	xor a			;op completed ok: a = 0, carry = 0
	ret

fs_nee:	pop bc
	call fs_restore_cached_dir_block
	xor a			;clear carry flag
	ld a,5			;a = error 5, directory is not empty.
	ret
	
	
;------------------------------------------------------------------------------------------------
		
fs_open_file_command:

; This routine sets up the "file_info" data structure ready to load a file...
; File pointer is reset to zero

	call fs_get_filename_length		;get length of req'd filename
	ret nz
	call fs_find_name_entry		;set fs_filename ascii string before calling!
	ret c				;h/w error?
	cp 2			
	ret z				;2 = name file not found
				
	push hl				;store "filename in sector" address
	pop iy				;hl -> iy
	ld bc,$10				;move to attribute position
	add hl,bc
	bit 0,(hl)			;is this a file or dir?
	jr nz,fs_nisd
	inc hl
	inc hl
	ld bc,9
	ld de,fs_file_info		
	ldir				;copy file info to registers

	call fs_backup_and_test_filelength	;default load length = file length
	ld hl,0				;(dont care if filesize is zero here)
	ld (fs_file_pointer),hl		;default file offset = 0
	ld (fs_file_pointer+2),hl
	ld de,(fs_file_block)
	xor a				;op completed ok: a = 0, carry = 0
	ld (fs_filepointer_valid),a		;invalidate filepointer
	ret

fs_nisd	xor a				;clear carry flag
	ld a,6				;error 6 - name is a directory, not a file
	ret
	
		
fs_backup_and_test_filelength

	ld hl,(fs_file_length)		;default load length = file length
	ld bc,(fs_file_length+2)
	ld (fs_file_length_temp),hl
	ld (fs_file_length_temp+2),bc
	ld a,h					
	or l
	or b
	or c
	ret
	
;------------------------------------------------------------------------------------------------

	
;*******************************************
;*** "fs_open_file" must be called first ***
;*******************************************


fs_read_data_command:		

	call os_cachebank			;bank preserving header
	ld a,(fs_z80_bank)		
	ld de,(fs_z80_address)	
	bit 7,d				;if load starts < $8000, start at bank 0
	jr nz,fs_loadhi
	xor a	
fs_loadhi	call os_forcebank		
	call fs_load
	push af
	call os_restorebank
	pop af
	ret

fs_load	ld hl,(fs_file_length_temp)		;check that file length (load length req) > 0
	ld bc,(fs_file_length_temp+2)
	ld a,h
	or l
	or b
	or c
	jr nz,fs_btrok
fs_fliz	xor a				;clear carry flag
	ld a,7				;error 7 - requested file length is zero
	ret
 
fs_btrok	ld hl,(fs_z80_address)		;load routine affects working register copy only
	ld (fs_z80_address_temp),hl

	ld hl,(fs_file_length)		;check file pointer position is valid
	ld bc,(fs_file_pointer)		;compare against TOTAL file length (ie: not
	xor a				;the temp working copy, which may be truncated)
	sbc hl,bc
	ld d,h
	ld e,l
	ld hl,(fs_file_length+2)
	ld bc,(fs_file_pointer+2)
	sbc hl,bc
	jp c,fs_fpbad
	jr nz,fs_fpok
	ld a,d
	or e
	jr nz,fs_fpok
fs_fpbad	xor a
	ld a,27				;error = requested bytes beyond end of file
	ret


fs_fpok	ld a,(fs_filepointer_valid)		; if the file pointer has been changed, we need
	or a				; to seek again from start of file
	jr z,seek_strt
		
	ld de,(fs_z80_address_temp)		; otherwise restore CPU registers and jump back into
	ld bc,(fs_sector_pos_cnt)		; main load loop
	push bc
	ld bc,(fs_fp_sector_offset)
	ld hl,sector_buffer+$200		; Set HL to sector buffer address
	xor a
	sbc hl,bc		
	jp fs_dadok
	

seek_strt	ld a,1
	ld (fs_filepointer_valid),a
	ld hl,(fs_file_block)		
	ld (fs_file_block_temp),hl

	ld de,(fs_file_pointer+2)		;move into file - sub $7e00 bytes and advance
	ld hl,(fs_file_pointer)		;a block if no carry 
fs_fpblp	ld bc,$7e00
	xor a
	sbc hl,bc
	jr nc,fs_fpgnb
	dec de
	ld a,d
	and e
	inc a
	jr z,fs_fpgbo
fs_fpgnb	push de
	push hl
	ld de,(fs_file_block_temp)
	xor a
	call fs_read_sector_new_lba
	jr nc,fs_ghok
	pop hl
	pop de
	ret
fs_ghok	ld bc,(sector_buffer+8)		;get next block pos
	ld (fs_file_block_temp),bc
	pop hl
	pop de
	jr fs_fpblp

fs_fpgbo	add hl,bc				;offset in HL now = $0 - $7dff
	ld a,h
	srl a			
	inc a				
	ld c,a				;c = sector offset 1-3f	
	ld a,$40
	sub c
	ld b,a				;b = number of sectors to read
	ld a,h
	and $01
	ld d,a
	ld e,l
	ld (fs_fp_sector_offset),de		;bytes offset into sector
	
fs_flns:	ld a,c				;first sector of actual file	
	ld de,(fs_file_block_temp) 
	call fs_read_sector_new_lba	
	ret c				;h/w error?

	push bc
	ld de,(fs_fp_sector_offset)
	ld hl,512
	xor a
	sbc hl,de
	push hl
	pop bc				;bc = number of bytes to read from sector
	ld hl,sector_buffer			;source base
	add hl,de				;add filepointer offset to source
	ld de,(fs_z80_address_temp)		;dest address for file bytes
fs_cblp:	ldi
	call fs_filelength_countdown		;a=0 on return if last byte
	or a
	jr z,fs_bdld
	ld a,d				;check destination address hasnt wrapped to 0
	or e
	jr nz,fs_dadok
	ld de,$8000			;loop around to $8000 and inc bank
	call os_incbank
	or a
	jr nz,fs_flerr

fs_dadok:	ld a,b				;last byte of sector?
	or c
	jr nz,fs_cblp

	ld (fs_z80_address_temp),de		;update destination address
	ld bc,0
	ld (fs_fp_sector_offset),bc		;for all following sectors offset is zero
	pop bc				;next sector
	inc c
	djnz fs_flns

	ld de,(fs_file_block_temp)		;read in header (first sector of block) to find
	xor a				;location of the next block in this file's chain
	call fs_read_sector_new_lba
	ret c				;h/w error?
	ld de,(sector_buffer+8)		;de = next block location
	ld (fs_file_block_temp),de
	ld a,d
	or e
	jp z,fs_fpbad			;next block must not be zero
fs_nfbok	ld c,1				;following blocks have no offset		
	ld b,$3f				;and read upto 63 sectors
	jr fs_flns		

fs_bdld	ld (fs_fp_sector_offset),bc		; all requested bytes transferred
	pop bc				; back up regs for any following sequential read
	ld (fs_sector_pos_cnt),bc
	xor a				; op completed ok: a = 0, carry = 0
	ret

fs_flerr:	pop bc
	or a				;clears carry flag
	ret			
			
;------------------------------------------------------------------------------------------------

fs_create_file_command

; *********************************************************************
; * set up fs_z80_address, fs_z80_bank and fs_filename before calling *
; *********************************************************************

		
 	call fs_get_filename_length		;get length of desired filename
	ret nz				;return with error if not valid
	
	call fs_find_free_block		;look for a free block on disk (updates fs_free_block)
	ret c				;h/w error?
	cp 1				;1= disk full?
	ret z

	call fs_find_name_entry		;check if file/dir already exists
	ret c				;h/w error?
	cp 2				;2 = file not found
	jr z,fs_nsff		
	xor a				;clear carry flag
	ld a,9				;error 9: "filename already exists"
	ret

fs_nsff	call fs_find_free_dir_line		;look for a free space in directory table
	ret c				;h/w error?
	cp 3				;3 = dir table is full
	ret z
	
	call fs_copy_name			;wipe 32 bytes in free slot, copy filename there
	inc hl				;no attribute to set for a file
	inc hl
	ex de,hl				;hl -> de for destination	
	ld hl,fs_free_block			;fill in the new file's block address
	ld bc,2			
	ldir			
	inc de				;leave default length at $00,00,00,00
	inc de
	inc de
	inc de
	ld hl,fs_z80_address		;fill in z80 load address and bank
	ld bc,3				
	ldir
	call fs_write_sector	;update this directory sector
	ret c				

	call fs_create_file_header		;make a file header sector in buffer 
	ld de,(fs_free_block)		;de = block number
	xor a				;a  = sector offset (zero for header)
	call fs_write_sector_new_lba		;write out the file header sector to the free block
	ret c				;h/w error?
		
	call fs_mark_block_used		;update BAT (mark fs_free_block in DE = in use)
	ret c				;h/w error?
	xor a	
	ret				;return A=0, carry clear = All OK.


;-----------------------------------------------------------------------------------------------------

fs_write_bytes_to_file_command
	
; ********************************************************************
; * set up fs_file_length (of new data), fs_filename, fs_z80_address *
; * and z80_bank before calling                                      *
; ********************************************************************


	call os_cachebank			;bank preserving header
	ld a,(fs_z80_bank)		
	ld de,(fs_z80_address)	
	bit 7,d				;if save starts < $8000, start at bank 0
	jr nz,fs_appnhi
	xor a	
fs_appnhi	call os_forcebank		
	call fs_append
	push af
	call os_restorebank
	pop af
	ret

fs_append	call fs_backup_and_test_filelength
	jp z,fs_fliz			;if append data length is zero, return with error	
	 
fs_apflnz	call fs_get_filename_length		;get filename length
	ret nz				;quit with error if A returns non zero
	
	call fs_find_name_entry		;find this file within current directory
	ret c				;quit on h/w error
	cp 2				
	ret z				;if error 2 ("file not found") quit op
	
	push hl				;hl = address of 32 byte directory entry (in sector buffer)
	pop ix				
	bit 0,(ix+$10)			;test dir/file attribute bit
	jr z,fs_oknad			
	xor a				;clear carry flag
	ld a,6				;error 6 - name is a directory, not a file
	ret

fs_oknad	ld e,(ix+$12)
	ld d,(ix+$13)
	ld (fs_file_block),de		;DE = first block of existing file

	ld l,(ix+$14)			;add new data length to existing length		
	ld h,(ix+$15)			;hl = original filelength (low)
	ld (fs_existing_file_length),hl	;store original filelength (low)
	ld bc,(fs_file_length)		
	add hl,bc				;add low words
	ld (ix+$14),l
	ld (ix+$15),h
	ld l,(ix+$16)			;hl = original filelength (hi)		
	ld h,(ix+$17)
	ld (fs_existing_file_length+2),hl	;store original filelength (hi)
	ld bc,(fs_file_length+2)
	adc hl,bc				;add high words
	ld (ix+$16),l
	ld (ix+$17),h
	jr nc,fs_apafnc
	ld a,7				;file length > $FFFFFFFF error (fairly unlikely!)
	ret	
fs_apafnc	call fs_write_sector	;rewrite directory sector (new filelength)
	ret c	
	
	ld de,(fs_file_block)		;DE = first block of existing file
fs_apgfb	xor a				;A = sector 0 (header)
	call fs_read_sector_new_lba			;get header of file in sector buffer
	ret c				;quit on h/w error
	ld de,(sector_buffer+8)		;any more blocks in this file's chain?
	ld a,e				
	or d				;if DE = $0000 this is the last block of the file
	jr z,fs_apeof
	ld (fs_file_block),de		;update fileblock pointer to next block
	ld hl,(fs_existing_file_length)	;subtract a block's length ($7e00 bytes) from
	ld bc,$7e00			;original file length
	xor a
	sbc hl,bc
	ld (fs_existing_file_length),hl
	jr nc,fs_apgfb
	ld bc,(fs_existing_file_length+2)	;upper word adjust not strictly necessary..
	dec bc
	ld (fs_existing_file_length+2),bc
fs_apflnc	jr fs_apgfb

fs_apeof	ld hl,(fs_existing_file_length)	;HL = original file length (mod $7e00)
	ld a,h				
	srl a
	inc a				
	ld c,a				;c = sector within block where file continues
	ld a,$40
	sub c
	ld b,a				;b = free sectors remaining in this block
	jr z,fs_sfnbl			;if b = 0 file continuation is at $7E00, need to start a new block

	ld de,(fs_file_block)		;read in existing final sector of file
	ld a,c
	call fs_read_sector_new_lba			
	ret c				;h/w error?
	push bc				;store sector and count
	ld a,h
	and 1
	ld d,a
	ld e,l				;DE = $0 to $1FF, file continuation offset in sector
	ld hl,512
	xor a
	sbc hl,de
	ld b,h
	ld c,l				;BC = remaining bytes in sector
	ld hl,sector_buffer
	add hl,de
	ex de,hl				;DE = destination in sector buffer
	ld a,h			
	or l
	jr nz,fs_dcsb			;If at byte 0 of sector buffer clear buffer
fs_dbfil	call fs_clear_sector_buffer
fs_dcsb	ld hl,(fs_z80_address)		;HL = source of data to appended
fs_cbsb	ldi				;copy source byte to sector buffer
	call fs_filelength_countdown
	or a
	jr z,fs_lbof			;all bytes written?
	ld a,h				;check if source address has wrapped around to 0
	or l
	jr nz,fs_sadok
	ld hl,$8000			;set source address addr = $8000 and inc bank
	call os_incbank
	or a				;0 = mem in range ok
	jr z,fs_sadok
	pop bc
	or a				;quit with inc_bank error in A if bank too high
	ret
fs_sadok	ld a,b				;last byte of sector?
	or c
	jr nz,fs_cbsb			

	ld (fs_z80_address),hl		;update the source address count register
	pop bc				;retrieve the sector postition and count
	ld a,c
	ld de,(fs_file_block)	
	call fs_write_sector_new_lba		;write out this sector
	ret c				;quit on h/w error
	inc c				;inc sector count
	dec b
	jr z,fs_sfnbl			;any more sectors in this block?	
fs_sfns	push bc				
	ld bc,512				
	ld de,sector_buffer
	jr fs_dbfil			;loop back and do next sector of block
	
fs_sfnbl	call fs_find_free_block		;new block required
	ret c				;h/w error?
	cp 1				;1 = disk full?
	ret z
	
	ld de,(fs_file_block)		;read in header of block just written to
	xor a				;update header with the free block we just found
	call fs_read_sector_new_lba			
	ret c				
	ld de,(fs_free_block)		
	ld (sector_buffer+8),de		
	call fs_write_sector	;write out the updated sector
	ret c				;h/w error?
	call fs_mark_block_used		;update bat (mark free_block as 'in use') 
	ret c				;h/w error?

	call fs_create_file_header		;make a file header
	ld de,(fs_free_block)		;the active file_block is now free_block
	ld (fs_file_block),de
	xor a
	call fs_write_sector_new_lba		;write out the new file header sector
	ret c				;h/w error?
	ld b,$3f				;sectors left in block
	ld c,1				;sector position
	jr fs_sfns			;loop to block data fill
	
fs_lbof	pop bc
	ld a,c				;last sector required so write it out
	ld de,(fs_file_block)		
	call fs_write_sector_new_lba	
	ret c
	xor a				;A=0, carry clear = all done OK
	ret
		



fs_create_file_header

	call fs_clear_sector_buffer		;makes a file header in sector buffer using current
	call fs_do_pqfs			;file parameters
	ld (hl),3				;block id byte = 3 (file)
	inc hl
	inc hl
	call fs_get_dir_block		;fill in parent block address
	ld (hl),e				;next block in chain is zero at this point
	inc hl				;as its unknown whether file will take more
	ld (hl),d				;than one block
	ld de,sector_buffer+$10		;copy filename to sector header
	ld hl,fs_filename
	ld a,(fs_filename_length)
	ld b,a
fs_sfcnl:	ld a,(hl)
	ld (de),a
	inc hl
	inc de
	djnz fs_sfcnl
	ld a,(fs_filename_length)		;and also length of name
	ld (sector_buffer+$20),a
	ret
	
;-------------------------------------------------------------------------------------------------


fs_erase_file_command:
	
	call fs_get_filename_length		;get length of req'd filename
	ret nz

	call fs_open_file_command		;first, does file exist (in this dir)?
	ret c				;hardware error?
	or a				;if a = 0, its a file and its details have
	ret nz				;been copied to fs_file_info

	push iy				;iy -> hl
	pop hl				;start of name entry in dir (saved by open_file)
	call fs_clear_name_entry		;remove the 32 bytes there
	call fs_write_sector
	ret c				;update the dir (LBA hasnt changed)
	
fs_efbl:	ld de,(fs_file_block)		;get the file's start block address
	ld (fs_free_block),de		;set register for following routine
	call fs_mark_block_free		;update the BAT
	ret c				;hardware error?

	ld de,(fs_file_block)		;check file header for file continuation blocks
	xor a				;sector 0
	call fs_read_sector_new_lba			;get file header
	ret c				;hardware error?
	
	ld de,(sector_buffer+8)		;get "file continuation block" entry
	ld a,d			
	or e
	jr z,fs_efdun			;if it's zero there are no more blocks for this file
	ld (fs_file_block),de		;update block address for loop with continuation block
	jr fs_efbl			;loop around to clear BAT entries for next block

fs_efdun:	xor a				;op completed ok: a = 0, carry = 0
	ret


;----------------------------------------------------------------------------------------------------------------


fs_goto_first_dir_entry

	call fs_get_dir_block
	ld (fs_dir_entry_cluster),de
	ld a,1
	ld (fs_dir_entry_sector),a		; 1 to cluster size (64 on PQFS)
	ld de,0
	ld (fs_dir_entry_line_offset),de	; 0 to 480 incl, step 32.
	ret



fs_get_dir_entry

; No input parameters.
;
; Returns HL    = Location of null terminated filename string
;         IX:IY = Length of file (if applicable)
;         B     = File flag (1 = directory, 0 = file)
;         A     = Error code 0 = all OK. $24 = Reached end of directory.
;         Carry = Set if hardware error encountered (priority over A)


	ld a,(fs_dir_entry_sector)		
	ld de,(fs_dir_entry_cluster)		;DE = block, A = Sector offset. 
	call fs_read_sector_new_lba			;read the sector
	ret c				;exit upon hardware error
	
	ld hl,sector_buffer
	ld bc,(fs_dir_entry_line_offset)
	add hl,bc
	push hl
	pop ix
	ld a,(hl)
	or a				;dir line empty?
	jr z,fs_fadp		
		
	ld c,16				;char count
	ld de,output_line
fs_dcfnl	xor a
	or (hl)				;is this char a zero?
	jr nz,fs_dcnz
	ld a,32				;replace with aspace if so
fs_dcnz	ld (de),a
	inc hl
	inc de
	dec c
	jr nz,fs_dcfnl

	xor a 
	ld (de),a				;null terminate the filename
	ld b,a
	bit 0,(hl)			;is this entry a file?
	jr z,fs_fniaf		
	inc b				;on return, B = 1 if dir, 0 if file	
fs_fniaf	ld l,(ix+$14)			;on return IX:IY = filesize
	ld h,(ix+$15)
	ld e,(ix+$16)
	ld d,(ix+$17)
	push de
	pop ix
	push hl
	pop iy
	ld hl,output_line			;on return, HL = location of filename string
	xor a
	ret
	

fs_fadp	call fs_goto_next_dir_entry
	jp z,fs_get_dir_entry
	ret
	



fs_goto_next_dir_entry

; No input parameters
; Returns A = 0 if OK, $24 if end of directory is reached


	ld de,32
	ld hl,(fs_dir_entry_line_offset)
	add hl,de
	ld (fs_dir_entry_line_offset),hl
	bit 1,h
	jr z,ndlok
	ld hl,0				
	ld (fs_dir_entry_line_offset),hl	;line offset reset to 0
	
	ld hl,fs_dir_entry_sector
	inc (hl)				;next sector
	ld a,$40
	cp (hl)
	jr nz,ndlok
endofdir	ld a,$24
	or a				; a = $24, end of dir
	ret	

ndlok	xor a
	ret
	
	
;-------------------------------------------------------------------------------------------------
; file system internal subroutines
;-------------------------------------------------------------------------------------------------


fs_mark_block_free:

	xor a
	jr fs_mblk
	
fs_mark_block_used:

	ld a,1
fs_mblk:	ld (fs_bat_mark),a
	ld de,(fs_free_block)	;mark this block in bat
	srl d
	inc d		
	ld a,d			;a = sector offset from start of bat 
	ld de,0			;all on block 0 of course
	call fs_read_sector_new_lba		;read in relevent bat sector
	ret c
	ld hl,sector_buffer
	ld bc,(fs_free_block)
	ld a,b
	and 1
	ld b,a
	add hl,bc			;add 0-511 byte offset in sector
	ld a,(fs_bat_mark)
	ld (hl),a			;set byte to 0 - "free" or 1 - "in use"
	call fs_write_sector
	ret			;write sector back out

	
;-----------------------------------------------------------------------------------------------
	

fs_find_free_block:

	ld ix,0	
	ld c,1			;bat sector count
fs_ffbl2:	ld de,0			;block 0
	ld a,c			
	cp $40
	jr z,fs_dfull
	call fs_read_sector_new_lba
	ret c
	ld hl,sector_buffer
	ld b,0
fs_ffbl1:	xor a			;scan 512 bytes
	or (hl)
	jr z,fs_gotfb
	inc ix
	inc hl
	xor a
	or (hl)
	jr z,fs_gotfb
	inc ix
	inc hl
	djnz fs_ffbl1
	inc c
	jr fs_ffbl2
fs_dfull:	xor a			;clear carry flag
	ld a,1			;error a = 01: disk is full
	ret
fs_gotfb:	ld (fs_free_block),ix

	call fs_get_total_sectors	;check that the found block is within disk capacity
	ld b,6
fs_cstb	srl c			;convert sectors to blocks
	rr d
	rr e
	djnz fs_cstb
	
	ld bc,(fs_free_block)	
	ex de,hl
	xor a			;clear carry flag/zero accumulator
	sbc hl,bc
	jr c,fs_dfull
	ret
	

;-----------------------------------------------------------------------------------------------


fs_find_name_entry:

	ld b,$3f			;hl = name address string on return if found (a=0)
	ld c,1			
fs_nfns:	call fs_get_dir_block	;get sector 1 of current dir block
	ld a,c
	call fs_read_sector_new_lba
	ret c
	push bc

	ld b,16			;entries per sector count
	ld hl,sector_buffer
fs_fnls:	ld ix,fs_filename
	push hl			;hl -> iy
	pop iy			;hl -> iy
	ld a,(fs_filename_length)	;length of required filename
	ld c,a			;store for compare loop
	cp (iy+$11)		;compare with length of filename on disk
	jr nz,fs_nfnpos		;skip compare test if not equal
fs_ffnlp:	ld a,(ix)			;compare characters of filename and
	cp $61			;those in dir, match all 16 incl trailing zeros
	jr c,fs_supc1
	cp $7b
	jr nc,fs_supc1
	sub $20			;make chars uppercase for comparison
fs_supc1	ld e,a
	ld a,(iy)
	cp $61
	jr c,fs_supc2
	cp $7b
	jr nc,fs_supc2
	sub $20			
fs_supc2	cp e			
	jr nz,fs_nfnpos
	inc ix
	inc iy
	dec c
	jr nz,fs_ffnlp		;compare 'C' chars..
	pop bc
	xor a			;a = 0, found name entry. hl = its address
	ret	
fs_nfnpos	ld de,$20
	add hl,de
	djnz fs_fnls
	pop bc
	inc c
	djnz fs_nfns
fs_ffnf:	xor a			;clear carry flag
	ld a,2			;a = 2, file/dir not found.
	ret

	
;-----------------------------------------------------------------------------------------------


fs_find_free_dir_line:


	ld b,$3f			;hl = free name address on return if found (a=0)
	ld c,1			
fs_fdbl2:	call fs_get_dir_block	;get sector 1 of current dir block
	ld a,c
	call fs_read_sector_new_lba
	ret c			;hardware error?
	push bc
	ld b,16			;entries per sector count
	ld hl,sector_buffer
	ld de,$20
fs_fdbl1:	xor a
	or (hl)
	jr z,fs_gfdl		;a = 0, found empty name slot
fs_ffdln:	add hl,de
	djnz fs_fdbl1
	pop bc
	inc c
	djnz fs_fdbl2
	xor a			;clear carry flag
	ld a,3			;a = 3, dir table is full.
	ret

fs_gfdl:	pop bc
	xor a
	ret
	
;-----------------------------------------------------------------------------------------------
	
	
fs_write_blank_sectors:
	
	call fs_clear_sector_buffer	
fs_wbsl:	ld a,c			;set de (block) and c (start sector) before calling
	call fs_write_sector_new_lba
	ret c			;hardware error?
	inc c
	djnz fs_wbsl	
	xor a			;op completed ok: a=0, carry=0
	ret

;-----------------------------------------------------------------------------------------------
	

fs_filelength_countdown

	push hl				;count down number of bytes to transfer
	push bc

	ld b,4
	ld hl,fs_file_length_temp
	ld a,$ff
flcdlp	dec (hl)
	cp (hl)
	jr nz,fs_cdnu
	inc hl
	djnz flcdlp
	
fs_cdnu	ld b,4
	ld hl,fs_file_pointer		;advance the file pointer at the same time
fpinclp	inc (hl)
	jr nz,fs_fpino
	inc hl
	djnz fpinclp
	
fs_fpino	ld hl,(fs_file_length_temp)		;countdown = 0?
	ld a,h
	or l
	ld hl,(fs_file_length_temp+2)
	or h
	or l
	pop bc
	pop hl
	ret
	
	
;-------------------------------------------------------------------------------------------------

fs_get_filename_length:

	push bc			;gets length of requested filename
	push hl			
	ld hl,fs_filename
	ld b,16
	ld c,0
fs_fnlcl:	ld a,(hl)
	cp 33
	jr c,fs_glofn
	inc hl
	inc c
	djnz fs_fnlcl
fs_glofn:	ld a,c
	ld (fs_filename_length),a
	pop hl
	pop bc
	or a
	jr nz,fs_gflok
	ld a,$0d			;no filename error
	or a
	ret

fs_gflok:	xor a
	ret
	
;-------------------------------------------------------------------------------------------------

fs_replace_filename

	push hl			;hl is the destination, going in
	ld d,h
	ld e,l
	ld b,16			;wipe only the 16 bytes used for filename ASCII
	jr fs_cnwe

fs_copy_name

	push hl			;hl = destination, going in
	ld d,h
	ld e,l			
	ld b,32
fs_cnwe	ld (hl),0			;first, wipe 32 bytes at destination
	inc hl
	djnz fs_cnwe

	ld hl,fs_filename	
	ld b,16
	ld c,0
fs_cfnlp	ld a,(hl)			;first char < 33 = end
	cp 33
	jr c,fs_fncle
	ld (de),a
	inc hl
	inc de
	inc c
	djnz fs_cfnlp

fs_fncle	pop hl
	ld de,17
	add hl,de			
	ld (hl),c			;drops in length of filename at name+17
	dec hl			;returns with hl at name+16 (attrib pos)
	ret

	
;-----------------------------------------------------------------------------------------------

	
fs_clear_name_entry:


	ld b,32			;hl = start of 32 byte entry upon call
fs_cnel:	ld (hl),0
	inc hl
	djnz fs_cnel
	ret	
	
;-----------------------------------------------------------------------------------------------

	
fs_cache_current_dir_block:
	
	call fs_get_dir_block
	ld (fs_parent_dir_block),de
	ret		
	
fs_restore_cached_dir_block:
	
	ld de,(fs_parent_dir_block)
	call fs_update_dir_block
	ret		
	

;-----------------------------------------------------------------------------------------------
	
	
fs_clear_sector_buffer:

	push bc
	ld hl,sector_buffer
	ld bc,0
fs_csblp:	ld (hl),c
	inc hl
	ld (hl),c
	inc hl
	djnz fs_csblp
	pop bc
	ret


;-----------------------------------------------------------------------------------------------
	
	
fs_do_pqfs:
	
	ld hl,sector_buffer		
	ld (hl),"P"		
	inc hl			
	ld (hl),"Q"		
	inc hl			
	ld (hl),"F"		
	inc hl			
	ld (hl),"S"		
	inc hl			
	ret			

;-----------------------------------------------------------------------------------------------

fs_block_to_lba


	push ix			; upon call: de = block, a = sector offset
	push de
	push bc
	inc de			; skip first 64 sectors of disk (leave PC MBR etc intact)
	and $3f
	ld b,a			; stash the sector offset for now
	xor a			; a = LSB
	srl d			; multiply de by 64
	rr e	
	rra
	srl d
	rr e
	rra
	or b			; or in the sector offset
	ld ix,sector_lba0		
	ld (ix),a			; put values in registers
	ld (ix+1),e
	ld (ix+2),d
	ld (ix+3),0		; PQFS doesnt use addresses this high
	pop bc
	pop de
	pop ix
	ret

	
;-----------------------------------------------------------------------------------------------

fs_read_sector_new_lba

	call fs_block_to_lba

fs_read_sector

	push bc
	push de
	push hl
	ld hl,device_type_table+2	;base address of "read_sector" routine
	call sector_access_redirect
secaccend	pop hl
	pop de
	pop bc
	ccf			;flip carry flag so that 1 = IDE error
	ret			;a = will be ide error reg bits in that case (00 = timeout)



fs_write_sector_new_lba	
	
	call fs_block_to_lba

fs_write_sector

	push bc
	push de
	push hl
	ld hl,device_type_table+4	;base address of "write_sector" routine
	call sector_access_redirect
	jr secaccend



sector_access_redirect

	push hl
	call fs_calc_dev_offset	;selects sector h/w code to run based on the device type
	ld hl,device_mount_list+1
	add hl,de
	ld a,(hl)
	rrca
	rrca
	rrca
	and %11100000
	ld e,a
	ld d,0
	pop hl
	add hl,de
	ld e,(hl)
	inc hl
	ld d,(hl)
	ex de,hl
	jp (hl)

	
;----------------------------------------------------------------------------------------------
	
fs_goto_root_dir
	
	push de
	ld de,1
	call fs_update_dir_block
	pop de
	ret

;-----------------------------------------------------------------------------------------------------------

fs_hl_to_alt_filename

	ld de,fs_alt_filename
	jr hltofngo


fs_hl_to_filename

; INPUT : HL = address of filename
; OUTPUT: HL = 1st character after filename
;         C  = number of chars in filename
     
        
        	ld de,fs_filename  
hltofngo	push de
	ld a,0
	ld b,16
csfnlp1	ld (de),a			; first, zero filename array
	inc de
	djnz csfnlp1
	pop de

	ld c,0			;copy filename..	
os_ctfnl	ld a,(hl)			;if char < 33, all done
	cp 33
	ret c
	cp $2f			;if char is "/" treat it as a seperator
	ret z
	ld (de),a
	inc hl
	inc de
	inc c
	ld a,c
	cp 16
	jr nz,os_ctfnl
	ret
		
	
;====================================================================================
; PQFS FILE SYSTEM RELATED DATA / VARIABLES
;====================================================================================

fs_parent_dir_block	db 0,0
fs_free_block	db 0,0
fs_next_block	db 0,0
fs_bat_mark	db 0
fs_filename	ds 16,0				;file/dir ascii name
fs_alt_filename	ds 16,0
fs_filename_buffer	ds 16,0
fs_filename_length  db 0
				
;-- file info data structure - do not seperate these variables ---------------------

fs_file_info		

fs_file_block	db 0,0		;0 - first block address
fs_file_length	db 0,0,0,0	;2 - file length in bytes (little endian)
fs_z80_address	db 0,0		;6 - z80 load/save address
fs_z80_bank	db 0		;8 - bank load/save (ie: what page at $8000-$ffff) 		
fs_file_pointer	db 0,0,0,0	;9 - desired start offset within a file (little endian)

;------------------------------------------------------------------------------------

fs_fp_sector_offset	    dw 0
fs_file_block_temp	    dw 0
fs_z80_address_temp     dw 0
fs_file_length_temp     db 0,0,0,0	

fs_existing_file_length db 0,0,0,0

;------------------------------------------------------------------------------------

fs_pqfs_txt	db "PQFS"

;------------------------------------------------------------------------------------

fs_dir_entry_cluster	dw 0
fs_dir_entry_line_offset	dw 0
fs_dir_entry_sector		db 0

;------------------------------------------------------------------------------------

fs_filepointer_valid	db 0
fs_sector_pos_cnt		dw 0

;------------------------------------------------------------------------------------
