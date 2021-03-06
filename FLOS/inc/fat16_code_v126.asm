;----------------------------------------------------------------------------------------------
; Z80 FAT16 File System code for FLOS by Phil @ Retroleum
;----------------------------------------------------------------------------------------------
;
; Changes:	1.26 - Optimization: Added "fs_test_dir_cluster" routine to check for root dir
;		1.25 - Reformatted source to TAB size = 8.
;                    -  Whenever a file system error code is returned in A, the Zero Flag is not set (calling progs
;			should, upon return, test the Carry flag first for hardware errors, then Zero Flag for FS errors)
;
;		1.24 - Dir scan now stops when 1st byte of entry = 0
;      	 	1.23 - Added backslash detect in "fs_hl_to_filename"
;		1.22 - Bugfix: Previously, when a file load ended on last byte of RAM, memory error $08 was being returned.
;		1.21 - Removed "fs_z80_working_bank" (was unused) and "fs_z80_working_address" (only
;	       		"fs_z80_address" is used now and is updated after a file read)
;	       		"fs_z80_bank" is also updated after a file read
;		1.20 - Fixed missing EOF error introduced in v118
;	      		 Moved fs_get_dir_block and fs_update_dir_block (from main FLOS) here
;                	"fs_goto_root_dir_command" clears A and ZF on return
;		1.19 - Changed error codes $25 to $2e (removed: $26 as it was never used)
;		1.18 - Speeded up fs_read_file
;		1.17 - Converts filenames to upper case (work around an annoying Microsoft convention..)
;		1.16 - Indirect sector buffer is set to OS sector buffer in read/write sector routines
;		1.15 - Changed re-direct wrapper for SD card driver 1.10 (ZF/CF)
;	    	     - "Make dir" code size optimized a bit
;	    	     - Fixed format command sector capacity truncate
;		1.14 - bugfix: when no disk label is found in the root dir, the label from the partition record is now used.
;		1.13 - bugfix: "fs_sectors_per_fat" was not being updated by "fs_check_disk_format"
;             	     - speeded up directory read routine
;		1.12 - "hl_to_filename" - If filename has forward slash at 9th (dot) character, it now counts as end of filename
;		1.11 - "Dir not found" error now always $23 ($0b no longer used)
;		1.10 - changes for Volume based file access (IE: multiple partitions)
;             	     - added "fs_get_volume_label"
;             	     - added "fs_calc_free_space"
;             	     - fixed "find_free_cluster" - now uses "sectors per fat" comparison to find end of fat 
;             	     - "fs_return dir name" now null terminates strings at first space
;		1.09 - changed dir listing code a little to fix a tiny anomaly
;		1.08 - made cluster-based search check filename is valid.
;		1.07 - added "fs_get_current_dir_name"
;         	1.06 - made sequential file load more efficient: Only seeks from start if filepointer changed.  
;		1.05 - added fat16 format, free cluster scan now checks against actual maximum fat clusters
;		1.04 - added directory listing routines
;         	1.03 - checks for MBR at LBA 0 (FAT16 partition must be within first 65536 sectors)
;
;
; Known issues:
; ---------------
; If a disk full error is returned during a file write: The file reported length is not truncated
; Allows a file to be created in root even if there's no space for it
;        
;----------------------------------------------------------------------------------------------
;
; All routines return carry clear / zero flag set if OK
;
; Carry set = hardware error, A = error byte from hardware 
;
; Carry clear, A = 	$00 - Command comleted OK
;			$01 - Disk full
;			$02 - file not found
;                   	$03 - (root) dir table is full
;			$04 - directory requested is actually a file
;                  	$05 - cant delete dir, it is not empty
;			$06 - not a file
;			$07 - file length is zero
;                   	$08 - file too big for memory
;			$09 - filename already exists
;			$0a - already at root directory
;			$0e - invalid volume
;			$13 - unknown/incorrect disk format
;			$1b - requested bytes beyond EOF
;                  	$22 - device not present		
;			$23 - directory not found		     
;                   	$24 - end of directory list
;                   	$2e - device does not use MBR


;-----------------------------------------------------------------------------------------------
; Main routines called by external programs
;-----------------------------------------------------------------------------------------------

fs_format_device_command

; Creates a single partition (truncated to 2GB)

		call fs_clear_sector_buffer		;wipe sectors 0-767 sectors
		ld de,0					;(this range covers (max fat length * 2) + root length
		ld c,0					;+ reserved sectors.)
form_ws		call set_lba_and_write_sector
		ret c
		inc de
		ld a,d
		cp 3
		jr nz,form_ws
		
		ld a,(device_count)			;find current driver's entry in the device info table
		ld b,a
		ld hl,host_device_hardware_info
fdevinfo	ld a,(current_driver)
		cp (hl)
		jr z,got_dev_info
		ld de,32
		add hl,de
		djnz fdevinfo
		ld a,$22
		or a
		ret	
	
got_dev_info

		inc hl
		ld e,(hl)
		inc hl
		ld d,(hl)
		inc hl
		ld c,(hl)				;got device capacity in BC:DE
		inc hl
		ld b,(hl)
		ld a,b
		or a
		jr nz,fs_truncs
		ld a,c
		cp $3f
		jr c,fs_fssok				;if more than $3f0000 sectors, fix at $3f0000
fs_truncs	ld de,$0000
		ld bc,$003f

fs_fssok	ld a,c
		ld hl,$0080				;find appropriate cluster size (in h)
fs_fcls		add hl,hl
		cp h
		jr nc,fs_fcls
	
		exx
		ld hl,bootsector_stub			;copy generic partition boot sector data to sector buffer
		ld de,sector_buffer			;sector buffer will still be clear from ops at start
		ld bc,$3f
		ldir
		exx
	
		ld a,b
		or c
		jr nz,ts_dword
		ld (sector_buffer+$13),de		;set total sectors (word) when < 65536
		jr ts_done

ts_dword	ld (sector_buffer+$20),de    	 	;set total sectors (dword lo) when >65535
		ld (sector_buffer+$22),bc		;set total sectors (dword hi) when >65535

ts_done		ld a,h					;A = cluster size
		ld (sector_buffer+$d),a			;fill in sectors per cluster
		ld hl,0					;becomes 1 if there is a remainder 
ffatsize	srl a
		jr z,gotfats				;divide total sectors by sectors per cluster and 256
		srl c					;to find length of FAT tables
		rr d
		rr e
		jr nc,ffatsize
		ld l,1
		jr ffatsize
gotfats		ld a,e					;if remainder, add 1 to number of sectors in FAT
		or l
		ld e,d
		ld d,c
		jr z,norem
		inc de
norem		ld (sector_buffer+$16),de		;fill in sectors per FAT
		ld (fs_sectors_per_fat),de
		ld de,$aa55
		ld (sector_buffer+$1fe),de		;fill in $55,$AA format ID
		ld de,0
		ld c,d
		call set_lba_and_write_sector		;write boot sector (LBA zero)
		ret c

		ld de,(sector_buffer+$e)		;DE = reserved sectors before fat
		call fs_clear_sector_buffer		;initial FAT entry is FF,F8,FF,FF
		ld hl,$fff8
		ld (sector_buffer),hl
		ld l,h
		ld (sector_buffer+2),hl
		ld c,0					;write fat 1 (@ "reserved_sectors") 
		call set_lba_and_write_sector
		ret c
		
		ld hl,(fs_sectors_per_fat)	
		add hl,de
		ex de,hl
		call set_lba_and_write_sector 		;write fat 2 (@reserved_sectors + sectors_per_fat)
		ret c	
		
		push de				;make root dir sector
		call fs_clear_sector_buffer
		ld hl,fs_sought_filename
		ld de,sector_buffer
		ld bc,11
		ldir
		ld a,8
		ld (de),a				;volume label
		ld a,$21
		ld (sector_buffer+$18),a		;set date to 1 JAN 1980
		
		pop hl	
		ld de,(fs_sectors_per_fat)		;write 1st root dir entry
		add hl,de
		ex de,hl
		ld c,0
		call set_lba_and_write_sector
		ret c	

		xor a					;no error on return 
		ret
		


set_lba_and_write_sector

		push bc
		ld b,0
		ld (sector_lba0),de			;set sector required = C:DE 
		ld (sector_lba2),bc			
		pop bc
		call fs_write_sector
		ret
		
	
;---------------------------------------------------------------------------------------------


fs_get_partition_info

; Set A to partition: $00 to $03
; On return: If A = $00, HL = Address of requested partition table entry
;            If A = $2e, A partition table is not present at sector 0
;            If A = $13, Disk format is bad 
;            If carry flag set, there was a hardware error


		ld (partition_temp),a
		
		ld hl,0					; read sector zero
		ld (sector_lba2),hl	
		ld (sector_lba0),hl
		call fs_read_sector
		ret c

		call fs_check_fat_sig			; sector 0 must always have the FAT marker
		jr nz,formbad

		call check_fat16_id			; if 36-3a = "FAT16" this is disk has no MBR
		jr c,at_pbs				; assume there's a single parition at sector 0
		
		ld a,(sector_buffer+$1c2)		; assuming this is then an MBR, get the partition ID code 
		and 4					; bit 2 should be set for FAT16
		jr z,formbad	
		ld a,(partition_temp)
		rlca
		rlca
		rlca
		rlca
		ld e,a
		ld d,0
		ld hl,sector_buffer+$1be
		add hl,de				; hl = address of partition table entry
		xor a
		ret
		
at_pbs		ld a,$2e				; return code $2e no partition info (MBR) on this device
		or a
		ret



check_fat16_id
		
		ld hl,sector_buffer+$36			; carry set if 36-3a = FAT16
		ld de,fat16_txt			
		ld b,5
		call os_compare_strings
		ret
	
;----------------------------------------------------------------------------------------------


fs_check_fat_sig

		ld hl,(sector_buffer+$1fe)		; check FAT signature @ $1FE in sector buffer 
		ld de,$aa55
		xor a
		sbc hl,de
		ret



formbad		ld a,$13				; error code $13 - incompatible format			
		or a
		ret

;---------------------------------------------------------------------------------------------


fs_check_disk_format

; ensures disk is FAT16, sets up constants..
	
		push bc
		push de
		push hl
		call go_checkf
		pop hl
		pop de
		pop bc
		ret
	
go_checkf	call fs_read_partition_bootsector
		ret c
		or a
		ret nz
		
		call fs_check_fat_sig			; must have a FAT signature at $1FE
		jr nz,formbad		

		call check_fat16_id			; must be FAT16
		jr nc,formbad

		ld hl,(sector_buffer+$0b)		; get sector size
		ld de,512				; must be 512 bytes for this code
		xor a
		sbc hl,de
		jr nz,formbad

		
form_ok		ld a,(sector_buffer+$0d)		; get number of sectors in each cluster
		ld (fs_cluster_size),a
		sla a
		ld (fs_bytes_per_cluster+1),a
					
		ld hl,(sector_buffer+$0e)		; get 'sectors before FAT'
		ld (fs_fat1_position),hl		; set FAT1 position
		ld de,(sector_buffer+$16)		; get sectors per FAT
		ld (fs_sectors_per_fat),de
		add hl,de
		ld (fs_fat2_position),hl		; set FAT2 position
		add hl,de
		ld (fs_root_dir_position),hl 		; set location of root dir
		ld hl,(sector_buffer+$11)		; get max root directory ENTRIES
		ld a,h
		or l
		jr z,formbad				; FAT32 puts $0000 here
		add hl,hl				; (IE: 32 bytes each, 16 per sector)
		add hl,hl
		add hl,hl
		add hl,hl
		xor a
		ld l,h
		ld h,a
		ld (fs_root_dir_sectors),hl		; set number of sectors used for root dir (max_root_entries / 32)				 
		ld de,(fs_root_dir_position)
		add hl,de				
		ex de,hl				; de = sectors between partition start and beginning of file data area
		
		ld bc,(sector_buffer+$22)		; this the MSW of the 32 bit total sectors (0 if sectors < 65536)		
		ld hl,(sector_buffer+$13)		; this is the 16 bit version
		ld a,h					; is 16 bit version 0?
		or l
		jr nz,got_tsfbs
		ld hl,(sector_buffer+$20)		; if so get the LSW of the 32 bit version in DE
got_tsfbs	xor a					; calculate max clusters available for file data
		sbc hl,de				; subtract the amount of sectors up to the file data area
		jr nc,nomxcb
		dec c
nomxcb		ld a,(fs_cluster_size)
fmaxcl		srl a
		jr z,got_cmaxc				;divide remaining sectors by sectors-per-cluster
		srl c				
		rr h
		rr l
		jr fmaxcl
got_cmaxc	push hl				;if max clusters > $ffef, truncate to $fff0
		ld de,$fff0
		xor a
		sbc hl,de
		jr c,cmaxok
		pop hl
		push de
cmaxok		pop hl
		ld (fs_max_data_clusters),hl
		xor a
		ret
		
	
;---------------------------------------------------------------------------------------------
	
fs_read_partition_bootsector
				
		call fs_calc_volume_offset		; reads the current volume's partition boot sector into the sector buffer	
		ld hl,volume_mount_list
		add hl,de
		ld a,(hl)
		or a					; is volume present according to mount list?
		jr nz,fs_volpre
		ld a,$0e				; error $0e = "volume not mounted"
		or a
		ret

fs_volpre	ld de,8					; get first sector of partition
		add hl,de
		ld de,sector_lba0
		ld bc,4
		ldir
		call fs_read_sector
		ret	
	
;---------------------------------------------------------------------------------------------

fs_calc_free_space

;returns free space in KB in HL:DE

		ld de,(fs_max_data_clusters)
		inc de
		inc de					;compensate for first two FAT entries always being ffff fff8
		push de
		pop ix

		xor a
cfs_lp2		ld (fs_working_sector),a
		ld hl,(fs_fat1_position)
		call set_abs_lba_and_read_sector
		ret c
	
		ld hl,sector_buffer
		ld b,0
cfs_lp1		ld a,(hl)
		inc hl
		or (hl)
		inc hl
		jr z,cfs_ddcc
		dec ix					;reduce free cluster count if fat entry in use
cfs_ddcc	dec de
		ld a,d
		or e
		jr z,cfs_ok				;max cluster count depleted?
		djnz cfs_lp1
		ld a,(fs_working_sector)
		inc a
		jr cfs_lp2
		
cfs_ok		push ix				;convert free clusters ix to KB free in hl:de
		pop de
		ld hl,0
		ld a,(fs_cluster_size)
cltoslp		srl a
		jr z,cltosok
		sla e
		rl d
		rl l
		jr cltoslp	
cltosok		srl l
		rr d
		rr e
		xor a
		ret

;---------------------------------------------------------------------------------------------


fs_change_dir_command

; INPUT: HL = directory name ascii (zero/space terminate)


		call fs_find_filename			; returns with start of 32 byte entry in IX
		ret c					; quit on hardware error
		cp 2
		jr nz,founddir
		ld a,$23					
		or a					; clear carry and zeroflag
		ret

founddir	xor a					; clear carry
		ld a,$04				; prep error code $04 - not a directory
		bit 4,(ix+$0b)
		ret z
		ld e,(ix+$1a)
		ld d,(ix+$1b)				; de = starting cluster of dir
		call fs_update_dir_block
		xor a
		ret


;----------------------------------------------------------------------------------------------
	
	
fs_goto_root_dir_command

		push de
		ld de,0
		call fs_update_dir_block
		xor a					; no error return
		pop de
		ret

;----------------------------------------------------------------------------------------------
	
	
fs_parent_dir_command

		call fs_test_dir_cluster
		jr nz,pdnaroot
		ld a,$0a				;error $0a = already at root block
		or a
		ret

pdnaroot	ld hl,$2e2e				;make filename = "..         "
		ld (fs_sought_filename),hl		;(cant use normal filename copier due to dots)
		ld hl,fs_sought_filename+2		
		ld a,32
		ld bc,9
		call os_bchl_memfill
		jr fs_change_dir_command
	
		
;------------------------------------------------------------------------------------------------

		
fs_open_file_command

; INPUT: HL = directory name ascii (zero/space terminate)
; OUTPUT: DE = start cluster of file, others are internal vars (file pointer reset to zero etc)


		call fs_find_filename			; set fs_filename ascii string before calling!
		ret c					; h/w error?
		ret nz					; file not found
						
		ld a,$06				; prep error $06 - not a file
		bit 4,(ix+$0b)
		ret nz
		
		ld e,(ix+$1a)		
		ld d,(ix+$1b)
		ld (fs_file_start_cluster),de		; set file's start cluster
		push de
		
		call set_and_test_filelength		; default load length = file length
		xor a
		ld (fs_filepointer_valid),a		; invalidate filepointer
		ld l,a
		ld h,a					; (dont care if filesize is zero here)
		ld (fs_file_pointer),hl			; default file offset = 0
		ld (fs_file_pointer+2),hl
		
		ld (fs_z80_bank),a			; by default load bank is 0
		ld h,$50				; by default load to $5000 
		ld (fs_z80_address),hl		
		
		pop de					; DE returns start cluster
		ret

	
;===================================================================================================================

fs_read_data_command		

; FS_OPEN_FILE_COMMAND must be called first (and if desired load location, bank, file pointer and length
; can be modified. If no changes are made prior to this call, an entire file from the start will be
; loaded to $5000 - bank 0)


		call prep_bank	
		call fs_load
		push af
		call os_getbank
		ld (fs_z80_bank),a			;update the bank
		call os_restorebank
		pop af
		ret

fs_load		call test_bytes_to_go
		jr nz,fs_btrok
fs_fliz		ld a,$07				; error $07 - requested transfer length is zero
		or a
		ret
 
fs_btrok	ld bc,(fs_sector_pos_cnt)		; Set BC in case of a load continuation
		ld a,(fs_filepointer_valid)		; if the file pointer has been externally changed, we need
		or a					; to seek again from start of file.
		jr nz,btgnzero				; otherwise jump back into the main load routine

seek_strt	ld a,1
		ld (fs_filepointer_valid),a
		ld hl,(fs_file_start_cluster)		; put working cluster at first cluster of file
		ld (fs_file_working_cluster),hl		; routine affects working register copy only

		ld de,(fs_file_pointer+2)		; move into file - sub bytes_per_cluster and advance
		ld hl,(fs_file_pointer)			; a cluster if no carry 
fs_fpblp	ld bc,(fs_bytes_per_cluster)
		xor a
		sbc hl,bc
		jr nc,fs_fpgnb
		dec de
		ld a,d
		and e
		inc a
		jr z,fs_fpgbo
fs_fpgnb	push hl				
		call next_cluster
		jr nc,fs_ghok
		pop hl
		ret
fs_ghok		call fs_compare_hl_fff8
		pop hl
		jp nc,fs_fpbad
		jr fs_fpblp

fs_fpgbo	add hl,bc				; HL = cluster's *byte* offset
		ld c,h
		srl c					; c = sectors into cluster	
		ld a,(fs_cluster_size)
		sub c
		ld b,a					; b = number of sectors to read
		ld a,h
		and $01
		ld h,a
		ld (fs_in_sector_offset),hl		; sector offset from where data is to be read
		call get_new_file_sector		; read in first sector of file
		ret c
		
;-----------------------------------------------------------------------------------------------------------------

fs_read_loop


btgnzero	ld de,(fs_file_pointer)			; If file_pointer => actual_file_length (we know bytes_to_go > 0)	
		ld hl,(fs_file_length)			; then return EOF error
		scf
		sbc hl,de
		ld de,(fs_file_pointer+2)
		ld hl,(fs_file_length+2)
		sbc hl,de
		jp c,fs_fpbad				; show ERROR $1B: Data beyond EOF requested

not_eof		push bc				; stash sector pos / countdown
		ld de,(fs_in_sector_offset)
		ld hl,512
		xor a
		sbc hl,de
		ld b,h
		ld c,l					; bc = number of bytes to end of sector
		
		ld hl,sector_buffer			
		add hl,de				; add in_sector_offset to sector base
		
		ld de,(fs_z80_address)			; get dest address for file bytes


; HL = source address in sector buffer
; DE = dest address in Z80 address space
; BC = transfer bytes (to end of sector buffer)


; Are there more bytes to the end of the sector (BC) than the desired transfer size?

		push hl				; protect HL source address 
		push de				; protect DE dest address
		ld hl,(fs_bytes_to_go)	
		xor a
		sbc hl,bc				; if (BC) bytes to end of sector > bytes_to_go
		ld de,0					; then set BC to bytes_to_go
		ld hl,(fs_bytes_to_go+2)
		sbc hl,de
		jr nc,ftlen_ok1			
		ld bc,(fs_bytes_to_go)			; reduce bytes_to_go
	
	

; Is this proposed transfer size (BC) + File_pointer > the whole file length?

ftlen_ok1	push bc				; protect original transfer length
		ld hl,(fs_file_pointer)
		ld de,(fs_file_pointer+2)
		add hl,bc
		jr nc,fpncarry
		inc de					; DE:HL = file pointer + BC

fpncarry	ld bc,(fs_file_length)		
		scf
		sbc hl,bc
		ex de,hl
		ld bc,(fs_file_length+2)
		sbc hl,bc
		ex de,hl				; DE:HL = (file pointer + BC) - (ACTUAL file_length + 1)
		jr c,ftlen_ok2
		ld hl,(fs_file_length)			; if exceeds file length replace value in BC with
		ld bc,(fs_file_pointer)			; (ACTUAL file_length - file_pointer)
		xor a
		sbc hl,bc
		pop bc					; level the stack (throw away original BC)
		ld b,h
		ld c,l				
		jr ftlen_ok3
	
ftlen_ok2	pop bc		
ftlen_ok3	pop de					; restore dest address
		pop hl					; restore source address


				
ftlen_ok4	push hl
		ld hl,(fs_file_pointer)			; add transfer_size (bc) to file_pointer
		add hl,bc
		ld (fs_file_pointer),hl
		jr nc,fp_nocar
		ld hl,(fs_file_pointer+2)
		inc hl
		ld (fs_file_pointer+2),hl

fp_nocar	ld hl,(fs_bytes_to_go)			; subtract transfer size (bc) from bytes_to_go  
		xor a
		sbc hl,bc
		ld (fs_bytes_to_go),hl
		jr nc,btg_nocar
		ld hl,(fs_bytes_to_go+2)
		dec hl
		ld (fs_bytes_to_go+2),hl
btg_nocar	pop hl					; restore source address
	
	
	
	
; Will the transfer overflow from Z80 dest address $ffff?

		xor a					;A = 0 = not a split LDIR operation
		push de				;Protect DE (Z80 dest address)
		ex de,hl			 
		add hl,bc				;Add transfer length to dest address: Will it cause an $FFFF->$0000 overflow?
		push hl
		pop ix					;IX = bytes remaining after the split for bank change (if relevant)
		ex de,hl
		pop de					;Restore original dest address to DE
		jr nc,fs_nowrap				;If not BC is unchanged = single LDIR operation
		xor a
		sub e			
		ld c,a
		sbc a,a
		sub d
		ld b,a					;BC truncated to "bytes to end of RAM" for first LDIR
		ld a,1					;A = 1, Split LDIR operation
fs_nowrap			

	

; Do the transfer - if split by a bank increment, do in two LDIRs

		ldir					;do main transfer
		or a
		jr z,fs_btfnobi				;was the block transfer split by dest addr overflow?
	
		ld de,$8000		
		call os_incbank				;loop around to $8000, next bank
		jr z,fs_memok				;if bank in range, all OK
		push ix
		pop bc					;if more bytes left in this sector transfer, show out of memory error
		ld a,b
		or c
		jr nz,fs_merr
		call test_bytes_to_go			;if bytes left to go from file = 0, dont show error
		jr z,fs_nomerr			
fs_merr		ld a,$08				;otherwise return with error code $08 - out of memory	
		or a				
fs_nomerr	pop bc
		ret

fs_memok	push ix				;Get remaining bytes (may be zero, but must allow mem/bank to be adjusted anyway)
		pop bc
		ld a,b					;if BC = 0, no more bytes to transfer from this sector
		or c
		jr z,fs_btfnobi
		ldir					;continue for remaining bytes
	
	
fs_btfnobi
	
		ld (fs_z80_address),de			;update working destination address
						
		ld de,sector_buffer			;update "in-sector offset" =  (HL-Sector_buffer) && $01ff
		xor a
		sbc hl,de
		ld a,h
		and 1
		ld h,a				
		ld (fs_in_sector_offset),hl		
		pop bc					; retrieve sector-in-cluster offset / sector countdown
		or l					; if the LDIR ops ended at start of a new sector 
		jr nz,nonewsreq				; read in the following sector

		call get_next_file_sector
		ret c
		ret nz

nonewsreq	call test_bytes_to_go			; is bytes_to_go = 0?
		jp nz,fs_read_loop
		ld (fs_sector_pos_cnt),bc		; if so, store sector count (BC) for any following sequential read
		xor a					; and exit: OK.. Else loop around for read data follow-up.
		ret

;---------------------------------------------------------------------------------------------------------------------------


get_next_file_sector

; Set BC to sector pos/count

		inc c					; next sector pos
		dec b					; dec sector count
		jr nz,get_new_file_sector		; do we need to move to new cluster?
		
		call next_cluster
		ret c	
		call fs_compare_hl_fff8			; if the continuation cluster >= $fff8, its the EOF
		jp c,fs_nfbok			

		call test_bytes_to_go			; that's OK if we're at the end of the file transfer req anyway
		ret z 
fs_fpbad	ld a,$1b				; ERROR $1B: Data beyond EOF requested
		or a
		ret					; if not, return EOF error
	
fs_nfbok	ld c,0					; following clusters have zero sector offset		
		ld a,(fs_cluster_size)	
		ld b,a					; read full cluster of sectors

get_new_file_sector

		ld a,c					; read a sector of file to sector buffer
		ld hl,(fs_file_working_cluster) 	
		call set_clo_lba_and_read_sector	
		ret
					
		
next_cluster	ld hl,(fs_file_working_cluster)	
		call get_fat_entry_for_cluster		; get location of the next cluster in this file's chain
		ret c					; h/w error?
		ld (fs_file_working_cluster),hl
		ret 	
		
	
				
;===========================================================================================================================


fs_make_dir_command		
	
		call fs_find_filename			;does this file/dir name already exist?
		ret c
		cp $02
		jr z,mdirfnde
		xor a					
		ld a,$09				;error 9: "filename already exists"
		or a					;clear carry/zero flag
		ret

mdirfnde	call fs_find_free_cluster		;check for free space of disk
		ret c					;hardware error?
		ret nz					;disk full?
				
		ld hl,(fs_free_cluster)
		ld (fs_new_file_cluster),hl

		call fs_find_free_dir_entry		;look for a free entry in current dir table
		ret c					;hardware error?
		ret nz					;error $03 = (root) dir table is full / $01 = disk is full

		push ix				;copy filename to dir entry (first 11 bytes) 
		pop de
		ld hl,fs_sought_filename
		ld bc,11
		ldir
		xor a					;clear rest of dir entry (remaining 21 bytes)
		ld b,21
clrdiren	ld (de),a
		inc de
		djnz clrdiren
		ld (ix+$0b),$10				;set attribute byte, $10 = subdirectory
		ld (ix+$18),$21				;set date: Jan 1 1980
		ld de,(fs_new_file_cluster)
		ld (ix+$1a),e				;set cluster of new dir
		ld (ix+$1b),d
		call fs_write_sector			;rewrite the current sector
		ret c					;hardware error?
	
		call fs_clear_sector_buffer
		ld hl,$202e				;make the standard "." and ".." sub-directories
		ld (sector_buffer),hl			;in first sector of new directory	
		ld h,l
		ld (sector_buffer+$20),hl
		ld a,$10
		ld (sector_buffer+$0b),a
		ld (sector_buffer+$2b),a
		ld de,(fs_new_file_cluster)		; "." entry's cluster
		ld (sector_buffer+$1a),de
		call fs_get_dir_block			; ".." entry's cluster
		ld (sector_buffer+$3a),de
		ld a,$21
		ld (sector_buffer+$18),a		;set date: Jan 1 1980		
		ld (sector_buffer+$38),a		;set date: Jan 1 1980
		dec a
		ld ix,sector_buffer			
		ld b,9				
mndelp		ld (ix+$02),a				;fill remaining filename data with spaces			
		ld (ix+$22),a			
		inc ix				
		djnz mndelp			
		
		ld hl,(fs_new_file_cluster)		;write to first sector of the new dir cluster
		xor a
		call set_clo_lba_and_write_sector
		ret c					;hardware error?

		call fs_clear_sector_buffer		;now fill rest of cluster with zeroes	
		xor a
wroslp		inc a
		ld (fs_working_sector),a
		ld hl,fs_cluster_size
		cp (hl)
		jr z,allsclr
		ld hl,(fs_new_file_cluster)
		call set_clo_lba_and_write_sector
		ret c
		ld a,(fs_working_sector)
		jr wroslp

allsclr		ld hl,(fs_new_file_cluster)		;mark cluster 'in use / no continuation'
		ld de,$ffff
		call update_fat_entry_for_cluster
		xor a
		ret



;------------------------------------------------------------------------------------------------

fs_delete_dir_command

		call fs_find_filename			;does filename exist in current dir?
		ret c
		jr z,ddc_gotd
		ld a,$23				;change file not found to dir not found
		or a
		ret
	
ddc_gotd	bit 4,(ix+$0b)				;is it really a directory?
		jr nz,okdeldir
		ld a,$04				;error $04 - not a dir
		or a
		ret
	
okdeldir	ld (fs_fname_in_sector_addr),ix		;store position in sector where filename was found
		call backup_sector_lba
		ld l,(ix+$1a)				;hl = starting cluster of dir
		ld h,(ix+$1b)
	
fs_ddecl	ld a,(fs_cluster_size)
		ld b,a					;check that this dir is empty
		ld c,0			
fs_cne2 	ld a,c
		call set_clo_lba_and_read_sector
		ret c					;hardware error?
	
		push bc
		ld b,16					;entries per sector count
		ld ix,sector_buffer
		ld de,$20
fs_cne1		ld a,(ix)
		or a
		jr z,fs_chnde
		cp $e5
		jr z,fs_chnde
		cp "."
		jr z,fs_chnde
		pop bc
		xor a					
		ld a,$05				;a = error 5, cant delete directory - its not empty.
		or a					;clear carry/zero flag
		ret

fs_chnde	add ix,de
		djnz fs_cne1
		pop bc
		inc c
		djnz fs_cne2

		call get_fat_entry_for_cluster		;cluster is empty, any more clusters in dir chain?
		ret c
		call fs_compare_hl_fff8
		jr c,fs_ddecl

dir_empty	call restore_sector_lba			; sector where filename was found
		call fs_read_sector
		ret c					; hardware error?
		ld hl,(fs_fname_in_sector_addr)		; position in sector where filename was found
fs_delco	ld (hl),$e5				; mark entry deleted and re-write current sector
		call fs_write_sector
		ret c

		push hl
		pop ix
		ld l,(ix+$1a)
		ld h,(ix+$1b)
		ld (fs_working_cluster),hl
		ld a,h					; if the start cluster is $0000, then the file
		or l					; was created only and has no associated clusters
		ret z					; to free up in the FAT.
	
clrfatlp	ld hl,(fs_working_cluster)
		call get_fat_entry_for_cluster
		ret c
		ex de,hl
	
		ld hl,(fs_working_cluster)
		ld (fs_working_cluster),de
		ld de,0
		call update_fat_entry_for_cluster	;clear cluster allocation
		ret c
		
		call fs_compare_hl_fff8			;last cluster in chain?
		jr c,clrfatlp
		xor a
		ret


;------------------------------------------------------------------------------------------------

fs_create_file_command

; Note: As per FAT standard, creating a file (0 bytes) does not use a FAT entry
; only a directory entry (FAT is only updated when data is added)

		call fs_find_filename			;does this file/dir name already exist?
		ret c
		cp $02
		jr z,mfilefnde
		ld a,$09				;error 9: "filename already exists"
		or a					;clear carry/zero flag
		ret

mfilefnde	call fs_find_free_dir_entry		;look for a free entry in current dir table
		ret c					;hardware error?
		ret nz					;error $03 = (root) dir table is full / $01 = disk is full

		push ix				;copy filename to dir entry (first 11 bytes) 
		pop de
		ld hl,fs_sought_filename
		ld bc,11
		ldir
		xor a					;clear rest of dir entry (remaining 21 bytes)
		ld b,21
clrfnen		ld (de),a
		inc de
		djnz clrfnen
		ld (ix+$18),$21				;set date: Jan 1 1980
		call fs_write_sector			;rewrite the current sector
		ret c					;hardware error?
		xor a
		ret					;return A=0, carry clear = All OK.


;---------------------------------------------------------------------------------------------

fs_write_bytes_to_file_command
	
; ********************************************************************
; * set up fs_file_length (of new data), fs_filename, fs_z80_address *
; * and z80_bank before calling                                      *
; ********************************************************************


		call prep_bank
		call fs_append
		push af
		call os_restorebank
		pop af
		ret


fs_append	call backup_and_test_filelength
		jp z,fs_fliz				;if append data length is zero, return with error	
	 
		call fs_find_filename			;look for this file within current directory
		ret c					;quit on h/w error
		cp 2				
		jr z,fs_wfnfq				;if error 2 ("file not found") then quit
		bit 4,(ix+$0b)				;test dir/file attribute bit
		jr z,fs_oknad				;if zero, its a file: OK to proceed
		ld a,$06				;else error $06 - not a file
fs_wfnfq	or a					;clear carry/zero flag
		ret

fs_oknad	call backup_sector_lba
		ld (fs_fname_in_sector_addr),ix
		
		call get_filelength			;get existing filesize in hl:de
		ld (fs_existing_file_length),de
		ld (fs_existing_file_length+2),hl
		ld c,l
		ld b,h
		ld iy,(fs_file_length)			;add length of append data to existing filelength
		ld hl,(fs_file_length+2)
		add iy,de
		adc hl,bc
		ld (ix+$1e),l
		ld (ix+$1f),h
		push iy
		pop hl
		ld (ix+$1c),l
		ld (ix+$1d),h
		jr nc,nfsizeok
		ld a,$07				;error code $07 - filesize > $ffffffff
		or a
		ret

nfsizeok	ld e,(ix+$1a)				;de = first cluster of file (will be 0 if existing filesize = 0)
		ld d,(ix+$1b)
		ld (fs_file_working_cluster),de		
		call fs_write_sector			;rewrite the current sector containing directory entry 
		ret c
		ld a,d
		or e
		jr nz,apenclch	
	
		call fs_find_free_cluster		;look for a fresh cluster for file data as original file length was zero
		ret c
		ret nz
		ld hl,(fs_free_cluster)
		ld (fs_file_working_cluster),hl
		ld de,$ffff
		call update_fat_entry_for_cluster	;mark new cluster as used 
		ret c

		call restore_sector_lba			;re-read the sector with the filename in it
		call fs_read_sector
		ret c
		ld ix,(fs_fname_in_sector_addr)		;update the start cluster entry
		ld de,(fs_file_working_cluster)	
		ld (ix+$1a),e
		ld (ix+$1b),d
		call fs_write_sector			;rewrite sector 
		ret c
	
		
apenclch	ld hl,(fs_file_working_cluster)		;move along cluster chain, looking for final cluster
		call get_fat_entry_for_cluster
		ret c
		call fs_compare_hl_fff8
		jr nc,atlclif
		ld (fs_file_working_cluster),hl
		ld a,(fs_cluster_size)
		sla a
		ld b,a
		ld c,0
		ld hl,(fs_existing_file_length)		;subtract a cluster's length from original file length
		xor a
		sbc hl,bc
		ld (fs_existing_file_length),hl
		jr nc,apenclch
		ld bc,(fs_existing_file_length+2)	;upper word adjust not strictly necessary..
		dec bc
		ld (fs_existing_file_length+2),bc
		jr apenclch

atlclif		ld bc,(fs_existing_file_length)
		srl b				
		ld c,b					;c = sectors into this cluster
		ld a,(fs_cluster_size)
		sub c
		ld b,a					;b = remaining sectors in cluster
		jr z,fs_sfncl				;if b = 0, continuation is at end of cluster, new cluster req'd
		
		ld hl,(fs_file_working_cluster)
		ld a,c
		call set_clo_lba_and_read_sector
		ret c
		push bc				;store sector and count
		
		ld de,(fs_existing_file_length)
		ld a,d
		and 1
		ld d,a					;DE = $0 to $1FF, file continuation offset in sector
		ld hl,512
		xor a
		sbc hl,de
		ld b,h
		ld c,l					;BC = remaining bytes in sector
		ld hl,sector_buffer
		add hl,de
		ex de,hl				;DE = destination in sector buffer
		ld a,h			
		or l
		jr nz,fs_dcsb				;If at byte 0 of sector buffer: clear buffer
fs_dbfil	call fs_clear_sector_buffer
fs_dcsb		ld hl,(fs_z80_address)			;HL = source of data to appended
fs_cbsb		ldi					;copy source byte to sector buffer
		call filelength_countdown
		or a
		jr z,fs_lbof				;all bytes written?
		ld a,h					;check if source address has wrapped around to 0
		or l
		jr nz,fs_sadok
		ld h,$80				;set source address addr = $8000 and inc bank
		call os_incbank
		or a					;0 = mem in range ok
		jr z,fs_sadok
		pop bc
		or a					;quit with inc_bank error in A if bank too high
		ret
fs_sadok	ld a,b					;last byte of sector?
		or c
		jr nz,fs_cbsb			

		ld (fs_z80_address),hl			;update the source address count register
		pop bc					;retrieve the sector postition and count
		ld a,c
		ld hl,(fs_file_working_cluster)	
		call set_clo_lba_and_write_sector	;write out this sector
		ret c					;quit on h/w error
		inc c					;inc sector count
		dec b
		jr z,fs_sfncl				;any more sectors in this cluster?	
fs_sfns		push bc				
		ld bc,512				;byte count max = full sector
		ld de,sector_buffer			;no offset from start of sector buffer
		jr fs_dbfil				;loop back and do next sector of cluster
			
fs_sfncl	call fs_find_free_cluster		;new block required
		ret c					;h/w error?
		ret nz					;quit if disk is full
		ld hl,(fs_file_working_cluster)
		ld de,(fs_free_cluster)
		call update_fat_entry_for_cluster	;current cluster points to new cluster
		ret c
		ld hl,(fs_free_cluster)
		ld (fs_file_working_cluster),hl		;current file cluster becomes the new cluster	
		ld de,$ffff
		call update_fat_entry_for_cluster	;mark new cluster as used / no continue (yet)
		ret c
		ld a,(fs_cluster_size)
		ld b,a					;sectors remaining in cluster (full quota)
		ld c,0					;sector position (at start)
		jr fs_sfns				;loop to block data fill
	
fs_lbof		pop bc
		ld a,c					;last sector updated, so write it out
		ld hl,(fs_file_working_cluster)		
		call set_clo_lba_and_write_sector	
		ret c
		xor a					;A=0, carry clear = all done OK
		ret


;---------------------------------------------------------------------------------------------

fs_erase_file_command


		call fs_find_filename			;does filename exist in current dir?
		ret c
		ret nz
		
		bit 4,(ix+$0b)				;is it a file (and not a directory)?
		jr z,okdelf
		ld a,$06				;error $06 - not a file
		or a
		ret
		
okdelf		push ix
		pop hl
		jp fs_delco				;use same code as dir delete to clear FAT etc
			

;---------------------------------------------------------------------------------------------


fs_rename_command

		call fs_find_filename			;does a file/dir already exist with that name?
		ret c					;h/w error?
		cp 2			
		jr z,fs_nfnok				;if error = 2 (file not found), its OK to proceed
		
		ld a,9					;error 9: "filename already exists"
		or a
		ret

fs_nfnok	ld hl,fs_sought_filename		;stash replacement filename for now
		ld de,fs_filename_buffer
		ld bc,11
		ldir
		ld hl,fs_alt_filename			;get existing filename
		ld de,fs_sought_filename
		ld bc,11
		ldir
		call fs_find_filename			;does it exist?
		ret c
		ret nz					;file/dir not found - return with error
		
		push ix
		pop de
		ld hl,fs_filename_buffer	 	
		ld bc,11
		ldir					;overwrite original filename
		call fs_write_sector			;re-write relevent dir sector
		ret c
		xor a
		ret
	

;-----------------------------------------------------------------------------------------------------------------


fs_goto_first_dir_entry

		call fs_get_dir_block
		ld (fs_dir_entry_cluster),de
		xor a
		ld (fs_dir_entry_sector),a		; 0 to cluster size
		ld d,a
		ld e,a
		ld (fs_dir_entry_line_offset),de	; 0 to 480 incl, step 32. (continues into get_entry...)
		


fs_get_dir_entry

; No input parameters.
;
; Returns HL    = Location of null terminated filename string
;         IX:IY = Length of file (if applicable)
;         B     = File flag (1 = directory, 0 = file)
;         A     = Error code 0 = all OK. $24 = Reached end of directory.
;         Carry = Set if hardware error encountered (priority over A)


		ld a,(fs_dir_entry_sector)		
		ld c,a
		ld hl,(fs_dir_entry_cluster)		; HL = cluster, A = Sector offset. 
		call cluster_and_offset_to_lba

		ld a,h					; check special case for FAT16 root directory...
		or l					; if working cluster = 0, we're in the root 
		jr nz,nr_read				; dir so set up LBA directly
		ld hl,(fs_root_dir_position)		
		ld a,c
		call set_absolute_lba
	
		
nr_read		call fs_read_sector			;read the sector
		ret c					;exit upon hardware error
	
		ld de,(fs_dir_entry_line_offset)
ds_inloop	ld ix,sector_buffer
		add ix,de
		ld a,(ix)
		or a					;dir line empty?
		jp z,endofdir		
		cp 0e5h					;dir entry deleted?
		jr z,fs_dir_entry_free	
		cp 05h					;special code = same as $e5
		jr z,fs_dir_entry_free	
		bit 3,(ix+0bh)				;if this entry is a volume lable (or LF entry) ignore it
		jr z,fs_dir_entry_in_use		

fs_dir_entry_free

		ex de,hl
		ld de,32
		add hl,de
		ex de,hl
		bit 1,d
		jr z,ds_inloop
		jr ds_newsec

fs_dir_entry_in_use

		ld (fs_dir_entry_line_offset),de
	
		ld hl,output_line			; clear_output_line
		ld b,OS_window_cols
fs_clrol 	ld (hl),32
		inc hl
		djnz fs_clrol 
	
		push ix
		pop hl
		ld b,8					;8 chars in FAT16 filename
		ld de,output_line
dcopyn		ld a,(hl)
		cp " "					;skip if a space
		jr z,digchar
		ld (de),a
		inc de
digchar		inc hl
		djnz dcopyn
		ld a,(hl)				;if the extension starts with a space dont
		cp " "					;bother with it
		jr z,dirnoex
		ld a,"."				;put a dot
		ld (de),a
		inc de	
		ld bc,3					;copy 3 char extension			
		ldir
dirnoex		xor a 
		ld (de),a				;null terminate the filename
	
		ld b,a
		bit 4,(ix+$b)				;is this entry a file?
		jr z,fs_fniaf		
		inc b					;on return, B = 1 if dir, 0 if file	
fs_fniaf	ld l,(ix+$1e)				;on return IX:IY = filesize
		ld h,(ix+$1f)
		ld e,(ix+$1c)
		ld d,(ix+$1d)
		push hl
		pop ix
		push de
		pop iy
		ld hl,output_line			;on return, HL = location of filename string
		xor a
		ret
	

fs_goto_next_dir_entry

		ld de,32
		ld hl,(fs_dir_entry_line_offset)
		add hl,de
		ld (fs_dir_entry_line_offset),hl
		bit 1,h
		jp z,fs_get_dir_entry

ds_newsec	ld hl,0				
		ld (fs_dir_entry_line_offset),hl	;line offset reset to 0

		ld hl,fs_dir_entry_sector
		inc (hl)				;next sector

		ld de,(fs_dir_entry_cluster)
		ld a,d
		or e					;are we in the root dir?
		jr nz,nonroot2
		ld a,(fs_root_dir_sectors)
		cp (hl)
		jr z,endofdir			
		jp fs_get_dir_entry
							; a = $24, end of dir
nonroot2	ld a,(fs_cluster_size)		
		cp (hl)					;last sector in cluster?
		jp nz,fs_get_dir_entry
		ld (hl),0				;sector offset reset to 0
		ld hl,(fs_dir_entry_cluster)
		call get_fat_entry_for_cluster
		ld (fs_dir_entry_cluster),hl
		ld de,$fff8				;any more clusters in this chain?
		xor a
		sbc hl,de
		jp c,fs_get_dir_entry
	
endofdir	ld a,$24
		or a					; a = $24, end of dir
		ret	
	
;-----------------------------------------------------------------------------------------------

fs_get_volume_label


; On return HL = volume label


		ld hl,(fs_root_dir_position)
		xor a
		call set_abs_lba_and_read_sector
		ret c
		ld b,16					; sixteen 32 byte entries per sector
		ld hl,sector_buffer+$b
		ld de,32
find_vl		ld a,(hl)
		cp $8
		jr z,got_vlabel				; assume volume label is in first sector
		add hl,de				; of root dir. If not, get label from partition sector
		djnz find_vl
		call fs_read_partition_bootsector	
		ret c
		or a
		ret nz
		ld hl,sector_buffer+$2b+$b
	
got_vlabel

		push hl
	
		ld b,11
fndlablp1	dec hl
		ld a,(hl)
		cp 32
		jr nz,glabch	
		djnz fndlablp1
glabch		inc hl
		xor a
		ld (hl),a

		pop hl					; null terminate volume label
		ld de,$b
		sbc hl,de
		xor a
		ret
	

	
;---------------------------------------------------------------------------------------------
; Internal subroutines
;---------------------------------------------------------------------------------------------

fs_compare_hl_fff8

;INPUT HL = value to compare with fff8
;OUTPUT CARRY set if < $fff8, ZERO FLAG set if = $fff8
	
	
		push hl
		push de
		ld de,$fff8			
		or a					;clear carry flag
		sbc hl,de
		pop de
		pop hl
		ret

;---------------------------------------------------------------------------------------------
	
	
prep_bank	call os_cachebank			; bank preserving header
		ld a,(fs_z80_bank)		
		ld de,(fs_z80_address)	
		bit 7,d					; if file starts < $8000, start at bank 0
		jr nz,fs_addrhi
		xor a	
fs_addrhi	call os_forcebank		
		ret
	

;---------------------------------------------------------------------------------------------


fs_find_free_cluster
	
		ld ix,0					;cluster entry counter
		ld de,(fs_fat1_position)		;fat sector start	
		xor a				
fs_ffcl2	ld (fs_working_sector),a	
		push de
		pop hl
		ld a,(fs_working_sector)
		call set_abs_lba_and_read_sector
		ret c
		ld hl,sector_buffer
		ld b,0
fs_ffcl1	ld a,(hl)				; scan the fat entry table for at $0000 entry
		inc hl
		or (hl)
		inc hl
		jr z,fs_gotfc
		inc ix
		djnz fs_ffcl1
	
		ld hl,(fs_sectors_per_fat)
		ld a,(fs_working_sector)		;next sector of fat
		inc a				
		cp l		
		jr nz,fs_ffcl2				;stop if end of fat (assumes FAT < 256 sectors)
fs_dfull	xor a					;clear carry flag
		inc a					;error a = $01: disk is full (zero flag not set)
		ret

fs_gotfc	push ix				;cluster numbers > $ffef cannot be used 
		pop hl					;so if free cluster > $ffef disk is full
		dec hl					;
		dec hl					;hl=hl-2 as first two FAT entries are non-zero
		ld de,(fs_max_data_clusters)
		xor a
		sbc hl,de
		jr nc,fs_dfull

		ld (fs_free_cluster),ix
		xor a
		ret
		
	
;-----------------------------------------------------------------------------------------------
	
	
fs_find_free_dir_entry


; OUTPUT IX start of 32 byte dir entry in sector buffer


		call fs_get_dir_block			; get current directory in DE
		ex de,hl
ffenxtclu	ld (fs_file_working_cluster),hl
		xor a
		ld (fs_working_sector),a

ffenxtsec	ld hl,(fs_root_dir_position)		; initially set up LBA for a root dir scan
		ld a,(fs_working_sector)
		call set_absolute_lba
		
		call fs_test_dir_cluster			; if not actually in root...
		jr z,at_rootd
		ld hl,(fs_file_working_cluster)		; ...set up LBA for current cluster
		ld a,(fs_working_sector)
		call cluster_and_offset_to_lba
		
at_rootd	call fs_read_sector
		ret c
		ld b,16					; sixteen 32 byte entries per sector
		ld de,32
		ld ix,sector_buffer
scdirfe		ld a,(ix)				; first byte must be $00 or $e5 to be usable
		or a
		jr z,got_fde
		cp $e5
		jr z,got_fde
		add ix,de				; move to next filename entry in dir
		djnz scdirfe				; all entries in this sector scanned?
		
		ld hl,fs_working_sector			; move to next sector of cluster
		inc (hl)
		
		call fs_test_dir_cluster			; are we scanning the root dir?
		jr nz,ffenotroo
		ld a,(fs_root_dir_sectors)		; reached last sector of root dir?
		cp (hl)					; LSB only: Assumes < 256 sectors used for root dir
		jr nz,ffenxtsec
fenotfnd	ld a,$03				; error code $03 - (root) dir table is full
		or a					; clear carry/zero flag
		ret

ffenotroo	ld a,(fs_cluster_size)			; reached last sector of dir cluster?
		cp (hl)
		jr nz,ffenxtsec
		ld hl,(fs_file_working_cluster)		; yes, so..		
		call get_fat_entry_for_cluster		; does this cluster have a continuation entry in the FAT?		
		ret c
		call fs_compare_hl_fff8			; if < $FFF8 set the base cluster to the continuation word 
		jr c,ffenxtclu

		call fs_find_free_cluster		; need to add a fresh cluster to this chain
		ret c					; h/w error?
		ret nz					; disk full?
		ld de,(fs_free_cluster)
		ld hl,(fs_file_working_cluster)	 	
		call update_fat_entry_for_cluster	; update cluster entry in FAT table
		ret c
		ex de,hl				; new cluster -> HL
		ld de,$ffff
		call update_fat_entry_for_cluster	; set new cluster in use / continuation marker = STOP
		ret c

		ld hl,(fs_free_cluster)			; when adding a new cluster to a non-root directory
		call fs_clear_cluster			; list chain, it is necessary to clear it of any previous data	
		ret c
		ld hl,(fs_free_cluster)			; Note: This is referring to the (parent) dir list cluster,
		jp ffenxtclu				; not the new directory cluster itself

got_fde		xor a
		ret
			

;-----------------------------------------------------------------------------------------------

fs_clear_cluster

;INPUT HL = cluster to clear

		ld (fs_working_cluster),hl

		call fs_clear_sector_buffer
		
		xor a				
		ld (fs_working_sector),a			
wipeclulp	ld a,(fs_working_sector)		
		ld hl,(fs_working_cluster)		
		call set_clo_lba_and_write_sector
		ret c
		ld hl,fs_working_sector
		inc (hl)
		ld a,(fs_cluster_size)
		cp (hl)
		jr nz,wipeclulp
		xor a
		ret



fs_clear_sector_buffer

		push hl
		push bc
		ld hl,sector_buffer			
		ld bc,512						
		call os_bchl_memclear	
		pop bc
		pop hl
		ret
		

	
;-----------------------------------------------------------------------------------------------
	
fs_find_filename

		xor a

fs_search	
	
		ld (fs_search_type),a

; OUTPUT IX start of 32 byte dir entry

		call fs_get_dir_block
ffnnxtclu	ld (fs_file_working_cluster),de
		xor a
		ld (fs_working_sector),a

ffnnxtsec	ld hl,(fs_root_dir_position)		; initially set up LBA for a root dir scan
		ld a,(fs_working_sector)
		call set_absolute_lba
		
		call fs_test_dir_cluster		; if not actually in root....
		jr z,at_rootd2
		ld hl,(fs_file_working_cluster)		; ....set up LBA for current cluster	
		ld a,(fs_working_sector)
		call cluster_and_offset_to_lba	
	
at_rootd2	call fs_read_sector
		ret c
		ld c,16					; sixteen 32 byte entries per sector
		ld ix,sector_buffer
ndirentr	push ix
		pop de
		ld a,(fs_search_type)
		or a
		jr z,fs_ststr

		ld a,(ix)				; ensure dir entry is valid (IE: 1st filename
		cp $80					; char is betweeen $20 and $80)
		jr nc,fnnotsame
		cp $20
		jr c,fnnotsame
		ld de,(fs_stash_dir_block)		; search type 1 = find cluster reference
		ld a,(ix+$1a)
		cp e
		jr nz,fnnotsame
		ld a,(ix+$1b)
		cp d
		jr z,fs_found
		jr fnnotsame
		
fs_ststr	ld iy,fs_sought_filename		; search type = 0 find filename string
		ld b,11					; 8+3 chars to compare, filename and extension
cmpfnlp		ld a,(de)				; will have been padded with spaces so a single
		call os_uppercasify			; run on all 11 characters is fine
		ld l,a
		ld a,(iy)
		call os_uppercasify
		cp l				
		jr nz,fnnotsame
		inc iy
		inc de
		djnz cmpfnlp
fs_found	xor a					; found filename: return with zero flag set
		ret

fnnotsame	ld de,32				; move to next filename entry in dir
		add ix,de
		dec c
		jr nz,ndirentr				; all entries in this sector scanned?
		
		ld hl,fs_working_sector			; move to next sector
		inc (hl)
		
		call fs_test_dir_cluster		; are we scanning the root dir?
		jr nz,notrootdir
		ld a,(fs_root_dir_sectors)		; reached last sector of root dir?
		cp (hl)					; LSB only: Assumes < 256 sectors used for root dir
		jp nz,ffnnxtsec
fnnotfnd	ld a,$02				; error code $02 - filename not found
		or a
		ret


notrootdir	ld a,(fs_cluster_size)			; reached last sector of dir cluster?
		cp (hl)
		jp nz,ffnnxtsec
		
		ld hl,(fs_file_working_cluster)		
		call get_fat_entry_for_cluster
		ret c
		call fs_compare_hl_fff8			; does this cluster have a continuation entry in the FAT?
		jr nc,fnnotfnd				; if hl > $FFF7 there's no continuation - stop scanning 
		ex de,hl				; put hl in DE for instruction at loop point
		jp ffnnxtclu				; set base cluster = the continuation word just found
		

;----------------------------------------------------------------------------------------------

fs_hl_to_alt_filename

		ld de,fs_alt_filename
		jr hltofngo


fs_hl_to_filename

;INPUT: HL = address of filename (null / space termimated)
;OUTPUT HL = address of first character after filename
;        C = number of characters in filename

		ld de,fs_sought_filename
hltofngo	call fs_clear_filename			; this preserves DE
		push de			
		pop ix					; stash filename address for extension
	
		ld c,0
		ld b,8
csfnlp2		ld a,(hl)				; now copy filename, upto 8 characters
		or a
		ret z					; is char a zero?
		cp 32
		ret z					; is char a space?
		cp $2f
		ret z					; is char a fwd slash?
		cp $5c
		ret z					; is char a back slash?
		cp "."
		jr z,dofn_ext				; is char a dot?
		call os_uppercasify
		ld (de),a
		inc de
		inc hl
		inc c					; inc source character count
		djnz csfnlp2				; allow 8 filename chars
find_ext	ld a,(hl)
		cp "."					; ninth char should be a dot
		jr z,dofn_ext	
		cp " "					; if space, zero or forward slash, no extension
		ret z
		cp $2f
		ret z
		or a
		ret z
		inc hl
		jr find_ext
		
dofn_ext	inc hl					; skip "." in source filename
		ld b,3				
fnextlp		ld a,(hl)				; copy 3 filename extension chars
		or a
		ret z					; end if space or zero
		cp 32
		ret z
		call os_uppercasify
		ld (ix+8),a
		inc ix
		inc hl
		inc c
		djnz fnextlp
		ret
	
;----------------------------------------------------------------------------------------------


get_fat_entry_for_cluster

; INPUT: HL = cluster in question, OUTPUT: HL = cluster's FAT table entry

		push bc
		push de
		ld c,l
		ld a,h
		ld hl,(fs_fat1_position)
		call set_abs_lba_and_read_sector
		jr c,hwerr
		push ix
		ld ix,sector_buffer
		ld b,0
		add ix,bc
		add ix,bc
		ld l,(ix)
		ld h,(ix+1)
		pop ix
hwerr		pop de
		pop bc
		ret


;----------------------------------------------------------------------------------------------


update_fat_entry_for_cluster

; INPUT: HL = cluster in question
;        DE = new value to put in FAT tables

		push bc
		push hl
		ld c,l
		ld a,h
		ld hl,(fs_fat1_position)		;update FAT 1
		call fat_upd
		jr c,fup_end

		pop hl
		push hl
		ld a,h
		ld hl,(fs_fat2_position)		;update FAT 2
		call fat_upd
fup_end		pop hl
		pop bc
		ret


fat_upd		call set_abs_lba_and_read_sector
		jr c,ufehwerr
		ld b,0
		ld hl,sector_buffer
		add hl,bc
		add hl,bc
		ld (hl),e
		inc hl
		ld (hl),d
		call fs_write_sector
ufehwerr	ret
	
	

;-----------------------------------------------------------------------------------------------

set_and_test_filelength

		push hl
		push de
		call get_filelength
		ld (fs_file_length),de
		ld (fs_file_length+2),hl
backupfl	ld (fs_bytes_to_go),de
		ld (fs_bytes_to_go+2),hl
		ld a,h					
		or l
		or d
		or e
		pop de
		pop hl
		ret


get_filelength

		ld e,(ix+$1c)
		ld d,(ix+$1d)
		ld l,(ix+$1e)				;get filelength in hl:de
		ld h,(ix+$1f)
		ret

		
backup_and_test_filelength

		push hl
		push de
		ld de,(fs_file_length)
		ld hl,(fs_file_length+2)
		jr backupfl
	
;-----------------------------------------------------------------------------------------------

filelength_countdown

		push hl				;count down number of bytes to transfer
		push bc

		ld b,4
		ld hl,fs_bytes_to_go
		ld a,$ff
flcdlp		dec (hl)
		cp (hl)
		jr nz,fs_cdnu
		inc hl
		djnz flcdlp
	
fs_cdnu		ld b,4
		ld hl,fs_file_pointer			;advance the file pointer at the same time
fpinclp		inc (hl)
		jr nz,fs_fpino
		inc hl
		djnz fpinclp
	
fs_fpino	ld hl,(fs_bytes_to_go)			;countdown = 0?
		ld a,h
		or l
		ld hl,(fs_bytes_to_go+2)
		or h
		or l
		pop bc
		pop hl
		ret

	
;-----------------------------------------------------------------------------------------------

	
test_bytes_to_go
	
		push hl
		ld hl,(fs_bytes_to_go)			; is file transfer count now zero?
		ld a,h
		or l
		ld hl,(fs_bytes_to_go+2)
		or h
		or l
		pop hl
		ret
	
	
;-----------------------------------------------------------------------------------------------

fs_get_current_dir_name

;returns current dir name - location at HL

		call fs_test_dir_cluster		; get the current dir block
		jr nz,fs_dnnr
		ld hl,volume_txt			; if at root ($0000), return "volx:/"
		ld a,(current_volume)
		add a,$30
		ld (volume_txt+3),a
		xor a
		ret
		
fs_dnnr		ld (fs_stash_dir_block),de
		call fs_parent_dir_command		; go up a directory
		ret c
		or a
		ret nz
		ld a,1
		call fs_search				; and look for the forward reference to the original cluster
		ret c
		ret nz
		
fs_gdbn		push ix
		pop hl
		ld b,11					;null terminate dir name string (in sector buffer)
ntdirn		ld a,(hl)
		cp " "
		jr z,rdirfsp
		inc hl
rdirnsp		djnz ntdirn
	
rdirfsp		ld (hl),0
		push ix
		ld de,(fs_stash_dir_block)
		call fs_update_dir_block		; go back to original directory
		pop hl	
		xor a					; HL = current dir name
		ret

;----------------------------------------------------------------------------------------------


fs_get_dir_block


		push af				;returns current volume's dir cluster in DE  
		push hl			
		call fs_get_dir_cluster_address
		ld e,(hl)
		inc hl
		ld d,(hl)
dclopdone	pop hl
		pop af
		ret
		



fs_update_dir_block

		push af				;updates current volume's dir cluster from DE
		push hl			
		push de			
		call fs_get_dir_cluster_address	
		pop de
		ld (hl),e
		inc hl
		ld (hl),d
		jr dclopdone



fs_test_dir_cluster
	
		call fs_get_dir_block			;gets dir cluster in DE and sets ZF if its zero (root)
		ld a,d
		or e
		ret
		
;----------------------------------------------------------------------------------------------


fs_clear_filename

		push de				;fills string at DE with 12 spaces
		push bc
		ld b,12
		ld a," "
clrfnlp		ld (de),a
		inc de
		djnz clrfnlp
		pop bc
		pop de
		ret
	
;----------------------------------------------------------------------------------------------


cluster_and_offset_to_lba

; INPUT: HL = cluster, A = sector offset, OUTPUT: Internal LBA address updated

		push bc
		push de
		push hl
		push ix
		dec hl					; offset back by two clusters as there
		dec hl					; are no $0000 or $0001 clusters
		ex de,hl
		ld hl,(fs_root_dir_position)
		ld bc,(fs_root_dir_sectors)
		add hl,bc				; hl = start of data area
		ld c,a
		ld b,0
		add hl,bc				; add sector offset
		ld c,l
		ld b,h					; BC = sector offset + LBA of start of data area

		ex de,hl				; HL = cluster
		ld de,0					; DE = LBA MSB
		ld a,(fs_cluster_size)
caotllp		srl a
		jr z,clusdone
		add hl,hl				; DE:HL * 2
		rl e
		rl d
		jr caotllp

clusdone	add hl,bc				; add sector offset + data area offset to cluster LBA
		jr nc,caotlnc
		inc de					; DE:HL = LBA before partition offset

caotlnc		ld ix,sector_lba0
		push de				; add on volume's partition offset
		push hl
		call fs_calc_volume_offset
		ld hl,volume_mount_list+8
		add hl,de
		ld e,(hl)
		inc hl
		ld d,(hl)				; DE = offset from MBR for partition LSW
		inc hl
		ld c,(hl)
		inc hl
		ld b,(hl)				; BC = offset from MBR for partion MSW
		pop hl
		add hl,de
		ld (ix),l				; update LBA low word		
		ld (ix+1),h
		pop hl
		adc hl,bc
		ld (ix+2),l				; update LBA high word
		ld (ix+3),h
		
		pop ix
		pop hl
		pop de
		pop bc
		ret
		

;-----------------------------------------------------------------------------------------------

set_absolute_lba

; set A to sector offset

		push bc				; this takes a 16 bit "offset from sector 0 lba"
		push de				; address in HL, adds on an 8 bit offset in A
		push hl				; then adds on the 32bit partition offset
		push ix				; relevant to the volume, then sets the LBA registers
		ld c,a
		ld b,0
		ld d,b
		ld e,b
		add hl,bc
		jr nc,caotlnc		
		inc e
		jr caotlnc		
		

set_abs_lba_and_read_sector

		call set_absolute_lba
		jp fs_read_sector
	
;-----------------------------------------------------------------------------------------------


backup_sector_lba

		push bc
		push de
		push hl
		ld hl,sector_lba0
		ld de,fs_backed_up_sector_lba0
lbabur		ld bc,4
		ldir
		pop hl
		pop de
		pop bc
		ret


restore_sector_lba

		push bc
		push de
		push hl
		ld hl,fs_backed_up_sector_lba0
		ld de,sector_lba0
		jr lbabur	
			
;-----------------------------------------------------------------------------------------------

set_clo_lba_and_read_sector

		call cluster_and_offset_to_lba
		
fs_read_sector

;		call log_read
	
		push bc
		push de
		push hl
		push ix
		push iy
		ld c,$08				; offset to "read_sector" routine in driver
		call sector_access_redirect
secaccend	pop iy
		pop ix
		pop hl
		pop de
		pop bc
		ret z					; if ZF set on return, operation completed without error
		scf
		ret					; otherwise CF set and A = error code




set_clo_lba_and_write_sector

		call cluster_and_offset_to_lba
	
fs_write_sector	
	
;		call log_write

		push bc
		push de
		push hl
		push ix
		push iy
		ld c,$0b			;offset of "write_sector" routine in driver
		call sector_access_redirect
		jr secaccend




sector_access_redirect

		ld hl,sector_buffer
		ld (sector_buffer_loc),hl
		ld a,(current_driver)	;selects sector h/w code to run based on the currently selected device type
		call locate_driver_base	;current device is updated by change_volume routine (or forced..)
		ex de,hl
		ld b,0
		add hl,bc			;HL = address of required routine
		jp (hl)

;--------------------------------------------------------------------------------------
	
bootsector_stub

		db  $EB,$3C,$90,$4D,$53,$44,$4F,$53,$35,$2E,$30,$00,$02,$00,$40,$00 
		db  $02,$00,$02,$00,$00,$F8,$F2,$00,$3F,$00,$FF,$00,$00,$00,$00,$00 
		db  $00,$00,$00,$00,$00,$00,$29,$C4,$E6,$36,$98,$4E,$4F,$20,$4E,$41 
		db  $4D,$45,$20,$20,$20,$20,$46,$41,$54,$31,$36,$20,$20,$20,$C3    

volume_txt	db "VOLx:/",0

;-----------------------------------------------------------------------------------------------

fs_cluster_size			db 0
fs_bytes_per_cluster		dw 0
fs_fat1_position		dw 0	;offset from partition base
fs_fat2_position		dw 0	;offset from partition base
fs_root_dir_position		dw 0	;offset from partition base
fs_root_dir_sectors		dw 0

fs_sectors_per_fat		dw 0
fs_max_data_clusters		dw 0

fs_sought_filename		ds 12,0
fs_alt_filename			ds 12,0
fs_filename_buffer		ds 12,0

fs_filepointer_valid		db 0	;Do not change the order from here..
fs_file_pointer			dw 0,0	;
fs_file_length			dw 0,0	;
fs_bytes_to_go			dw 0,0	;
fs_file_start_cluster		dw 0	;
fs_file_working_cluster		dw 0	;
fs_z80_address			dw 0	;
fs_z80_bank			db 0	;..to here. FLOS v584+ relies on it.

fs_in_sector_offset		dw 0
fs_working_sector		db 0

fs_working_cluster		dw 0
fs_free_cluster			dw 0
fs_new_file_cluster		dw 0

fs_existing_file_length 	dw 0,0

fs_backed_up_sector_lba0	db 0,0,0,0
fs_fname_in_sector_addr		dw 0

fs_dir_entry_cluster		dw 0
fs_dir_entry_line_offset	dw 0
fs_dir_entry_sector		db 0

fs_sector_pos_cnt		dw 0

fs_stash_dir_block	 	dw 0
fs_search_type			db 0


;----------------------------------------------------------------------------------------------

