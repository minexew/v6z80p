;----------------------------------------------------------------------------------------------
; Simplified Z80 FAT16 File System LOAD ONLY routines - by Phil @ Retroleum
;----------------------------------------------------------------------------------------------
;
; Note: Single Z80 address space (no banking) - Address wraps around to $c000 for Spectrum 128
;       Call "sdc_init" and "fat16_check_format" before any other routine
;
;----------------------------------------------------------------------------------------------
;
; Return codes:
;
; ZF set = OK else...
;
;	      A = $ff - Hardware error
;
;		$02 - file not found
;                   $04 - directory requested is actually a file
;                   $06 - not a file
;		$07 - file length is zero
;		$0a - already at root directory
;                   $0b - directory not found
;		$0e - invalid filename
;		$13 - unknown/incorrect disk format
;		$1b - requested bytes beyond EOF
;		$23 - directory not found		     
;                   $24 - end of directory list

;-----------------------------------------------------------------------------------------------
; Main routines called by external programs
;-----------------------------------------------------------------------------------------------

sdc_init

	call mmc_init_card
	ld a,0				;dont affect carry flag
	ccf
	jr error_handler
		

fat16_check_format
	
	call fs_check_disk_format
	jr error_handler
	

fat16_open_file

; INPUT HL/DE = filename / load address

	ld (fs_z80_address),de
	call fs_hl_to_filename
	call fs_open_file_command
	jr error_handler


fat16_set_load_length

; INPUT HL:DE = set load length

	ld (fs_file_length_temp),de	
	ld (fs_file_length_temp+2),hl
	xor a
	ret


fat16_set_file_pointer

; INPUT HL:DE = seek position

	ld (fs_file_pointer),de
	ld (fs_file_pointer+2),hl
	xor a
	ld (fs_filepointer_valid),a	; invalidate filepointer
	ret
	

fat16_read_data

; open_file must be called first

	call fs_read_data_command
	jr error_handler


fat16_root_dir
	
	call fs_goto_root_dir_command
	ret


fat16_change_dir

; INPUT HL = filename

	call fs_hl_to_filename
	call fs_change_dir_command
	jr error_handler


fat16_parent_dir
	
	call fs_parent_dir_command
	jr error_handler


fat16_goto_first_dir_entry
	
	call fs_goto_first_dir_entry
	jr error_handler


fat16_get_dir_entry
	
	call fs_get_dir_entry
	jr error_handler	


fat16_goto_next_dir_entry
	
	call fs_goto_next_dir_entry


error_handler

	jr c,sdchwerr
	or a
	ret
sdchwerr	ld a,$ff
	or a
	ret


;-----------------------------------------------------------------------------------------------


fs_check_disk_format

	xor a				; read sector zero
	ld h,a
	ld l,a
	ld (sector_lba2),a
retry_fbs	ld (sector_lba0),hl
	call fs_read_sector
	ret c				; quit on hardware error

	ld hl,(fs_sector_buffer+$1fe)		; check signature @ $1FE (applies to MBR and boot sector)
	ld de,$aa55
	xor a
	sbc hl,de
	jr z,diskid_ok			
formbad	xor a
	ld a,$13				; error code $13 - incompatible format			
	ret


diskid_ok	ld a,(fs_sector_buffer+$3a)		; must be FAT16, char at $36 should be "6"
	cp $36
	jr nz,test_mbr

	ld hl,(fs_sector_buffer+$0b)		; get sector size
	ld de,512				; must be 512 bytes for this code
	xor a
	sbc hl,de
	jr nz,test_mbr

		
form_ok	ld a,(fs_sector_buffer+$0d)		; get number of sectors in each cluster
	ld (fs_cluster_size),a
	sla a
	ld (fs_bytes_per_cluster+1),a
	ld hl,(sector_lba0)			; get start LBA of partition
	ld de,(fs_sector_buffer+$0e)		; get 'sectors before FAT'
	add hl,de
	ld (fs_fat1_loc_lba),hl		; set FAT1 position
	ld de,(fs_sector_buffer+$16)		; get sectors per FAT
	add hl,de
	ld (fs_fat2_loc_lba),hl		; set FAT2 position
	add hl,de
	ld (fs_root_dir_loc_lba),hl 		; set location of root dir
	ld hl,(fs_sector_buffer+$11)		; get max root directory ENTRIES
	ld a,h
	or l
	jr z,test_mbr			; FAT32 puts $0000 here
	add hl,hl				; (IE: 32 bytes each, 16 per sector)
	add hl,hl
	add hl,hl
	add hl,hl
	xor a
	ld l,h
	ld h,a
	ld (fs_root_dir_sectors),hl		; set number of sectors used for root dir (max_root_entries / 32)				 
	ld de,(fs_root_dir_loc_lba)
	add hl,de				
	ex de,hl				; de = LBA of file data area
	
	ld bc,(fs_sector_buffer+$22)		; this the MSW of the 32 bit total sectors (0 if sectors < 65536)		
	ld hl,(fs_sector_buffer+$13)		; this is the 16 bit version
	ld a,h				; is 16 bit version 0?
	or l
	jr nz,got_tsfbs
	ld hl,(fs_sector_buffer+$20)		; if so get the LSW of the 32 bit version in DE
got_tsfbs xor a				; calculate max clusters available for file data
	sbc hl,de				; subtract the amount of sectors up to the file data area
	jr nc,nomxcb
	dec c
nomxcb	ld a,(fs_cluster_size)
fmaxcl	srl a
	jr z,got_cmaxc			;divide remaining sectors by sectors-per-cluster
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
cmaxok	pop hl
	ld (fs_max_data_clusters),hl
	jr fs_goto_root_dir_command
			

test_mbr	ld a,(fs_sector_buffer+$1c2)		; get partition ID code (assuming this is MBR)
	and 4
	jp z,formbad			; bit 2 should be set for FAT16
	ld hl,(sector_lba0)			; have we already changed the LBA from 0?
	ld a,h
	or l
	jp nz,formbad			
	ld hl,(fs_sector_buffer+$1c6)		; update LBA base location and retry
	jp retry_fbs
	
;---------------------------------------------------------------------------------------------


fs_change_dir_command

; INPUT: HL = directory name ascii (zero/space terminate)


	call fs_find_filename		; returns with start of 32 byte entry in IX
fs_cdskip	ret c				; quit on hardware error
	cp 2
	jr nz,founddir
	xor a				; clear carry
	ld a,$23
	ret
founddir	xor a				; clear carry
	ld a,$04				; prep error code $04 - not a directory
	bit 4,(ix+$0b)
	ret z
	ld e,(ix+$1a)
	ld d,(ix+$1b)			; de = starting cluster of dir
	ld (fs_directory_cluster),de 
	xor a
	ret


;----------------------------------------------------------------------------------------------
	
	
fs_goto_root_dir_command

	push de
	ld de,0
	ld (fs_directory_cluster),de 
	pop de
	xor a
	ret

;----------------------------------------------------------------------------------------------
	
	
fs_parent_dir_command

	ld de,(fs_directory_cluster) 
	ld a,d
	or e
	jr nz,pdnaroot
	ld a,$0a				;error $0a = already at root block
	ret
pdnaroot	ld hl,fs_sought_filename		;make filename = "..         "
	ld (hl),"."			;(cant use normal filename copier due to dots)
	inc hl
	ld (hl),"."
	ld b,10
pdclp	inc hl
	ld (hl)," "
	djnz pdclp
	call fs_find_filename
	jr fs_cdskip
		
;------------------------------------------------------------------------------------------------

		
fs_open_file_command

	call fs_find_filename		; set fs_filename ascii string before calling!
	ret c				; h/w error?
	ret nz				; file not found
					
	ld a,$06				; prep error $06 - not a file
	bit 4,(ix+$0b)
	ret nz
	
	ld l,(ix+$1a)		
	ld h,(ix+$1b)
	ld (fs_file_start_cluster),hl		; set file's start cluster

	call set_and_test_filelength		; default load length = file length
	xor a
	ld (fs_filepointer_valid),a		; invalidate filepointer
	ld l,a
	ld h,a				; (dont care if filesize is zero here)
	ld (fs_file_pointer),hl		; default file offset = 0
	ld (fs_file_pointer+2),hl
	ret
	
;------------------------------------------------------------------------------------------------

fs_read_data_command		

;*******************************************
;*** "fs_open_file" must be called first ***
;*******************************************

	ld hl,(fs_file_length_temp)		; check that file length (load length req) > 0
	ld bc,(fs_file_length_temp+2)
	ld a,h
	or l
	or b
	or c
	jr nz,fs_btrok
fs_fliz	xor a				; clear carry flag
	ld a,$07				; error $07 - requested file length is zero
	ret
 
fs_btrok	ld hl,(fs_z80_address)		; set load address 
	ld (fs_z80_working_address),hl	; routine affects working register copy only

	ld hl,(fs_file_length)		; check file pointer position is valid
	ld bc,(fs_file_pointer)		; compare against TOTAL file length (ie: not
	xor a				; the temp working copy, which may be truncated)
	sbc hl,bc
	ld d,h
	ld e,l
	ld hl,(fs_file_length+2)
	ld bc,(fs_file_pointer+2)
	sbc hl,bc
	jr c,fs_fpbad
	jr nz,fs_fpok
	ld a,d
	or e
	jr nz,fs_fpok
fs_fpbad	xor a
	ld a,$1b				;error $1b - requested bytes beyond end of file
	ret



fs_fpok	ld a,(fs_filepointer_valid)		; if the file pointer has been changed, we need
	or a				; to seek again from start of file
	jr z,seek_strt

	ld de,(fs_z80_working_address)	; otherwise restore CPU registers and jump back into
	ld bc,(fs_sector_pos_cnt)		; main load loop
	push bc
	ld bc,(fs_in_sector_offset)
	ld hl,fs_sector_buffer+$200		; Set HL to sector buffer address
	xor a
	sbc hl,bc		
	jr fs_dadok
	

seek_strt	ld a,1
	ld (fs_filepointer_valid),a
	ld hl,(fs_file_start_cluster)		; get original record for working cluster
	ld (fs_file_working_cluster),hl	; routine affects working register copy only

	ld de,(fs_file_pointer+2)		;move into file - sub bytes_per_cluster and advance
	ld hl,(fs_file_pointer)		;a block if no carry 
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
	ld hl,(fs_file_working_cluster)	;get value of next cluster in chain
	call get_fat_entry_for_cluster
	jr nc,fs_ghok			;hardware error?
	pop hl
	ret
fs_ghok	ld (fs_file_working_cluster),hl	;update cluster where desired bytes are located
	pop hl
	jr fs_fpblp

fs_fpgbo	add hl,bc				;HL = cluster's *byte* offset
	ld c,h
	srl c				;c = sectors into cluster	
	ld a,(fs_cluster_size)
	sub c
	ld b,a				;b = number of sectors to read
	ld a,h
	and $01
	ld h,a
	ld (fs_in_sector_offset),hl		;bytes into sector where data is to be read from
	
fs_flns	ld a,c				
	ld hl,(fs_file_working_cluster) 
	call cluster_and_offset_to_lba
	call fs_read_sector			;read first sector of file
	ret c				;h/w error?

	push bc				;stash sector pos / countdown
	ld de,(fs_in_sector_offset)
	ld hl,512
	xor a
	sbc hl,de
	ld b,h
	ld c,l				;bc = number of bytes to read from sector
	ld hl,fs_sector_buffer			;sector base
	add hl,de				;add filepointer offset to sector base
	ld de,(fs_z80_working_address)	;dest address for file bytes
fs_cblp	ldi				;(hl)->(de), inc hl, inc de, dec bc
	call filelength_countdown		;zero flag set on return = last byte
	jr z,fs_bdld
	ld a,d
	or e
	jr nz,fs_dadok
	ld d,$c0				;address wraps around to $c000
fs_dadok	ld a,b				;last byte of sector?
	or c
	jr nz,fs_cblp

	ld (fs_in_sector_offset),bc		;byte offset for all following sectors is zero
	ld (fs_z80_working_address),de	;update destination address
	pop bc				;retrive sector offset / sector countdown
	inc c				;next sector
	djnz fs_flns			;loop until all sectors in cluster read

	ld hl,(fs_file_working_cluster)	
	call get_fat_entry_for_cluster	;get location of the next cluster in this file's chain
	ret c				;h/w error?
	ld (fs_file_working_cluster),hl
	call fs_compare_hl_fff8		;if the continuation cluster >= $fff8, its the EOF
	jp nc,fs_fpbad			
fs_nfbok	ld c,0				;following clusters have zero sector offset		
	ld a,(fs_cluster_size)	
	ld b,a				;read full cluster of sectors
	jr fs_flns		

fs_bdld	ld (fs_in_sector_offset),bc		; all requested bytes transferred
	pop bc				; back up regs for any following sequential read
	ld (fs_sector_pos_cnt),bc
	xor a				; op completed ok: a = 0, carry = 0
	ret

fs_flerr	pop bc
	or a				;clears carry flag
	ret			
			
;----------------------------------------------------------------------------------------------

fs_goto_first_dir_entry

	ld de,(fs_directory_cluster) 
	ld (fs_dir_entry_cluster),de
	xor a
	ld (fs_dir_entry_sector),a		; 0 to cluster size
	ld d,a
	ld e,a
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
	ld c,a
	ld hl,(fs_dir_entry_cluster)		; HL = cluster, A = Sector offset. 
	call cluster_and_offset_to_lba

	ld a,h				; check special case for FAT16 root directory...
	or l				; if working cluster = 0, we're in the root 
	jr nz,nr_read			; dir so set up LBA directly
	ld hl,(fs_root_dir_loc_lba)		
	xor a
	ld b,a
	add hl,bc
	ld (sector_lba0),hl
	ld (sector_lba2),a
	
nr_read	call fs_read_sector			;read the sector
	ret c				;exit upon hardware error
	
	ld hl,fs_sector_buffer
	ld bc,(fs_dir_entry_line_offset)
	add hl,bc
	push hl
	pop ix
	ld a,(hl)
	or a				;dir line empty?
	jr z,fs_fadp		
	cp $e5				;dir entry deleted?
	jr z,fs_fadp
	cp $05				;special code = same as $e5
	jr z,fs_fadp
	bit 3,(ix+$b)			;if this entry is a volume lable (or LF entry) ignore it
	jr nz,fs_fadp		

	ld de,fs_sought_filename		;clear filename string
	push de
	ld b,12
	xor a
col_lp	ld (de),a
	inc de
	djnz col_lp	
	pop de
	ld b,8				;8 chars in FAT16 filename
dcopyn	ld a,(hl)
	cp " "				;skip if a space
	jr z,digchar
	ld (de),a
	inc de
digchar	inc hl
	djnz dcopyn
	ld a,(hl)				;if the extension starts with a space dont
	cp " "				;bother with it
	jr z,dirnoex
	ld a,"."				;put a dot
	ld (de),a
	inc de	
	ld bc,3				;copy 3 char extension			
	ldir
dirnoex	xor a 
	ld (de),a				;null terminate the filename
	
	ld b,a
	bit 4,(ix+$b)			;is this entry a file?
	jr z,fs_fniaf		
	inc b				;on return, B = 1 if dir, 0 if file	
fs_fniaf	ld l,(ix+$1e)			;on return IX:IY = filesize
	ld h,(ix+$1f)
	ld e,(ix+$1c)
	ld d,(ix+$1d)
	push hl
	pop ix
	push de
	pop iy
	ld hl,fs_sought_filename		;on return, HL = location of filename string
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
	ld de,(fs_dir_entry_cluster)
	ld a,d
	or e				;are we in the root dir?
	jr nz,nonroot2
	ld a,(fs_root_dir_sectors)
	cp (hl)
	jr nz,ndlok
endofdir	ld a,$24
	or a				; a = $24, end of dir
	ret	
nonroot2	ld a,(fs_cluster_size)		
	cp (hl)				;last sector in cluster?
	jr nz,ndlok
	ld (hl),0				;sector offset reset to 0
	ld hl,(fs_dir_entry_cluster)
	call get_fat_entry_for_cluster
	ld (fs_dir_entry_cluster),hl
	ld de,$fff8			;any more clusters in this chain?
	xor a
	sbc hl,de
	jr nc,endofdir
	
ndlok	xor a
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
	or a			;clear carry flag
	sbc hl,de
	pop de
	pop hl
	ret


;-----------------------------------------------------------------------------------------------
	
	
fs_find_filename

; OUTPUT IX start of 32 byte dir entry

	ld de,(fs_directory_cluster) 
ffnnxtclu	ld (fs_file_working_cluster),de
	xor a
	ld (fs_working_sector),a

ffnnxtsec	ld hl,(fs_root_dir_loc_lba)		; initially set up LBA for a root dir scan
	ld b,0
	ld a,(fs_working_sector)
	ld c,a
	add hl,bc
	ld (sector_lba0),hl			; sector low bytes
	xor a
	ld (sector_lba2),a			; sector MSB = 0
	
	ld de,(fs_directory_cluster) 		; if not actually in root....
	ld a,d
	or e
	jr z,at_rootd2
	ld hl,(fs_file_working_cluster)	; ....set up LBA for current cluster	
	ld a,(fs_working_sector)
	call cluster_and_offset_to_lba	
	
at_rootd2	call fs_read_sector
	ret c
	ld c,16				; sixteen 32 byte entries per sector
	ld ix,fs_sector_buffer
ndirentr	push ix
	pop de
	ld iy,fs_sought_filename
	ld b,11				; 8+3 chars to compare, filename and extension
cmpfnlp	ld a,(de)				; will have been padded with spaces so a single
	call uppercasify			; run on all 11 characters is fine
	ld l,a
	ld a,(iy)
	call uppercasify
	cp l				
	jr nz,fnnotsame
	inc iy
	inc de
	djnz cmpfnlp
	xor a				; found filename: return with zero flag set
	ret
fnnotsame	ld de,32				; move to next filename entry in dir
	add ix,de
	dec c
	jr nz,ndirentr			; all entries in this sector scanned?
	
	ld hl,fs_working_sector		; move to next sector
	inc (hl)
	
	ld de,(fs_directory_cluster) 		; are we scanning the root dir?
	ld a,d
	or e
	jr nz,notrootdir
	ld a,(fs_root_dir_sectors)		; reached last sector of root dir?
	cp (hl)				; LSB only: Assumes < 256 sectors used for root dir
	jr nz,ffnnxtsec
fnnotfnd	ld a,$02				; error code $02 - filename not found
	or a
	ret

notrootdir
	
	ld a,(fs_cluster_size)		; reached last sector of dir cluster?
	cp (hl)
	jr nz,ffnnxtsec
	
	ld hl,(fs_file_working_cluster)		
	call get_fat_entry_for_cluster
	ret c
	call fs_compare_hl_fff8		; does this cluster have a continuation entry in the FAT?
	jr nc,fnnotfnd			; if hl > $FFF7 there's no continuation - stop scanning 
	ex de,hl				; put hl in DE for instruction at loop point
	jp ffnnxtclu			; set base cluster = the continuation word just found
	

;----------------------------------------------------------------------------------------------

fs_hl_to_filename

;INPUT: HL = address of filename (null / space termimated)
;OUTPUT HL = address of first character after filename
;        C = number of characters in filename


	ld de,fs_sought_filename
	push de
	ld a,32
	ld b,12
csfnlp1	ld (de),a				; first, fill filename array with spaces
	inc de
	djnz csfnlp1
	pop de
	push de			
	pop ix				; stash filename address for extension
	
	ld c,0
	ld b,8
csfnlp2	ld a,(hl)				; now copy filename, upto 8 characters
	or a
	ret z				; is char a zero?
	cp 32
	ret z				; is char a space?
	cp "."
	jr z,dofn_ext			; is char a dot?
	ld (de),a
	inc de
	inc hl
	inc c				; inc source character count
	djnz csfnlp2			; allow 8 filename chars
find_ext	ld a,(hl)
	cp "."				; ninth char should be a dot
	jr z,dofn_ext	
	cp " "				; if space or zero, no extension
	ret z
	or a
	ret z
	inc hl
	jr find_ext
	
dofn_ext	inc hl				; skip "." in source filename
	ld b,3				
fnextlp	ld a,(hl)				; copy 3 filename extension chars
	or a
	ret z				; end if space or zero
	cp 32
	ret z
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
	ld b,0
	ld c,l
	ld de,(fs_fat1_loc_lba)
	ld l,h
	ld h,0
	add hl,de
	ld (sector_lba0),hl
	xor a
	ld (sector_lba2),a
	call fs_read_sector
	jr c,hwerr
	push ix
	ld ix,fs_sector_buffer
	add ix,bc
	add ix,bc
	ld l,(ix)
	ld h,(ix+1)
	pop ix
hwerr	pop de
	pop bc
	ret


;----------------------------------------------------------------------------------------------


cluster_and_offset_to_lba

; INPUT: HL = cluster, A = sector offset, OUTPUT: Internal LBA address updated

	push bc
	push de
	push hl
	push ix
	dec hl				; offset back by two clusters as there
	dec hl				; are no $0000 or $0001 clusters
	ex de,hl
	ld hl,(fs_root_dir_loc_lba)
	ld bc,(fs_root_dir_sectors)
	add hl,bc				; hl = start of data area
	ld c,a
	ld b,0
	add hl,bc				; add sector offset
	ld c,l
	ld b,h				; bc = sector offset + LBA of start of data area
	ex de,hl
	ld e,0				; e = LBA MSB
	ld ix,sector_lba0
	ld a,(fs_cluster_size)
caotllp	srl a
	jr nz,doubclus
	add hl,bc				; add sector offset to cluster LBA
	jr nc,caotlnc
	inc e
caotlnc	ld (ix),l				; update LBA variable
	ld (ix+1),h
	ld (ix+2),e
caodone	pop ix
	pop hl
	pop de
	pop bc
	ret
	
doubclus	sla l				; cluster * 2
	rl h
	rl e
	jr caotllp

;-----------------------------------------------------------------------------------------------

set_and_test_filelength

	push hl
	push de
	call get_filelength
	ld (fs_file_length),de
	ld (fs_file_length+2),hl
backupfl	ld (fs_file_length_temp),de
	ld (fs_file_length_temp+2),hl
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
	ld l,(ix+$1e)			;get filelength in hl:de
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

;----------------------------------------------------------------------------------------------

uppercasify

; INPUT/OUTPUT A = ascii char to make uppercase

	cp $61			
	ret c
	cp $7b
	ret nc
	sub $20				
	ret	
	
		
;-----------------------------------------------------------------------------------------------

fs_read_sector

	push bc
	push de
	push hl
	push ix
	push iy
	call mmc_read_sector
	pop iy
	pop ix
	pop hl
	pop de
	pop bc
	ccf			;flip carry flag so that 1 = IDE error
	ret			;a = will be ide error reg bits in that case (00 = timeout)


;-----------------------------------------------------------------------------------------------

fs_cluster_size		db 0
fs_bytes_per_cluster	dw 0
fs_fat1_loc_lba		dw 0
fs_fat2_loc_lba		dw 0
fs_root_dir_loc_lba		dw 0
fs_root_dir_sectors		dw 0

fs_sectors_per_fat		dw 0
fs_max_data_clusters	dw 0

fs_sought_filename		ds 12,0

fs_file_pointer		dw 0,0
fs_file_length		dw 0,0
fs_file_length_temp		dw 0,0
fs_file_start_cluster	dw 0
fs_file_working_cluster	dw 0

fs_z80_address		dw 0
fs_z80_working_address	dw 0

fs_in_sector_offset		dw 0
fs_working_sector		db 0

fs_working_cluster		dw 0
fs_free_cluster		dw 0
fs_new_file_cluster		dw 0

fs_backed_up_sector_lba0	db 0,0,0
fs_fname_in_sector_addr	dw 0

fs_dir_entry_cluster	dw 0
fs_dir_entry_line_offset	dw 0
fs_dir_entry_sector		db 0

fs_filepointer_valid	db 0
fs_sector_pos_cnt		dw 0
fs_directory_cluster	dw 0

fs_sector_buffer		ds 512,0

;----------------------------------------------------------------------------------------------
