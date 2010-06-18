;----------------------------------------------------------------------------------------------
; Simplified Z80 FAT16 File System code by Phil @ Retroleum
; Reduced to the essentials required to load a file called
; "********.OSF" from root directory.
;----------------------------------------------------------------------------------------------

find_os_file_fat16

; Set "fs_z80_working_address" to load location before calling

; Output Carry set = Hardware error
;        Zero flag set = OK, else A = error code $1= Not FAT16, $2=File not found, $3= EOF encountered

	xor a				; first, check disk format. 
	ld h,a
	ld l,a
	ld (sector_lba2),a
retry_fbs	ld (sector_lba0),hl
	call sdc_read_sector		; read sector zero
	ret c				; quit on hardware error

	ld hl,(sector_buffer+$1fe)		; check signature @ $1FE (applies to MBR and boot sector)
	ld de,$aa55
	xor a
	sbc hl,de
	jr z,diskid_ok			
formbad	ld a,1				; error code $1 - not FAT16			
	or a
	ret

diskid_ok	ld a,(sector_buffer+$3a)		; for FAT16, char at $36 should be "6"
	cp $36
	jr nz,test_mbr

	ld hl,(sector_buffer+$0b)		; get sector size
	ld de,512				; must be 512 bytes for this code
	xor a
	sbc hl,de
	jr nz,test_mbr
		
form_ok	ld a,(sector_buffer+$0d)		; get number of sectors in each cluster
	ld (fs_cluster_size),a
	ld hl,(sector_lba0)			; get start LBA of partition
	ld de,(sector_buffer+$0e)		; get 'sectors before FAT'
	add hl,de
	ld (fs_fat1_loc_lba),hl		; set FAT1 position
	ld de,(sector_buffer+$16)		; get sectors per FAT
	add hl,de				; HL = FAT2 position
	add hl,de				; HL = Root Dir loc
	ld (fs_root_dir_loc_lba),hl 		; set location of root dir
	ld hl,(sector_buffer+$11)		; get max root directory ENTRIES
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
	jr read_file			
		
test_mbr	ld a,(sector_buffer+$1c2)		; get partition ID code (assuming this is MBR)
	and 4
	jp z,formbad			; bit 2 should be set for FAT16
	ld hl,(sector_lba0)			; have we already changed the LBA from 0?
	ld a,h
	or l
	jp nz,formbad			
	ld hl,(sector_buffer+$1c6)		; update LBA base location and retry
	jp retry_fbs
	
read_file	xor a				; find_os_file must be called first!!
	ld (fs_working_sector),a		; find_filename
ffnnxtsec	ld hl,(fs_root_dir_loc_lba)		; set up LBA for a root dir scan
	ld b,0
	ld a,(fs_working_sector)
	ld c,a
	add hl,bc
	ld (sector_lba0),hl			; sector low bytes
	xor a
	ld (sector_lba2),a			; sector MSB = 0
	call sdc_read_sector
	ret c

	ld b,16				; sixteen 32 byte entries per sector
	ld ix,sector_buffer
ndirentr	ld a,$e5
	cp (ix)
	jr z,fnnotsame			; ignore dir entry if file deleted	
	ld a,"O"
	cp (ix+8)
	jr nz,fnnotsame
	ld a,"S"
	cp (ix+9)
	jr nz,fnnotsame
	ld a,"F"
	cp (ix+10)
	jr z,fnsame
fnnotsame	ld de,32				; move to next filename entry in dir
	add ix,de
	djnz ndirentr			; all entries in this sector scanned?
	
	ld hl,fs_working_sector		; move to next sector
	inc (hl)
	ld a,(fs_root_dir_sectors)		; reached last sector of root dir?
	cp (hl)				; LSB only: Assumes < 256 sectors used for root dir
	jr nz,ffnnxtsec
fnnotfnd	ld a,$02				; error code $02 - filename not found / zero file length
	or a
	ret

fnsame	bit 4,(ix+$0b)			; make sure entry is actually a file - abort if a dir
	jr nz,fnnotfnd
	
	ld l,(ix+$1a)		
	ld h,(ix+$1b)
	ld (fs_file_working_cluster),hl	; set file's start cluster
	ld e,(ix+$1c)
	ld d,(ix+$1d)
	ld l,(ix+$1e)			
	ld h,(ix+$1f)
set_flen	ld (fs_file_length_working),de
	ld (fs_file_length_working+2),hl	; set filelength from hl:de
	ld a,h					
	or l
	or d
	or e
	jr z,fnnotfnd			; abort if file length is zero
	xor a
	ret
	

load_os_file_fat16


fs_flnc	ld a,(fs_cluster_size)		; find_os_file must be called first!!
	ld b,a
	ld c,0
fs_flns	ld a,c				
	ld hl,(fs_file_working_cluster) 
	call cluster_and_offset_to_lba
	call sdc_read_sector		;read first sector of file
	ret c				;h/w error?

	push bc				;stash sector pos / countdown
	ld bc,512				;bv = number of bytes to read from sector
	ld hl,sector_buffer			;sector base
	ld de,(fs_z80_working_address)	;dest address for file bytes
fs_cblp	ldi				;(hl)->(de), inc hl, inc de, dec bc
	
	call file_length_countdown
	jr z,fs_bdld			;if zero flag set = last byte

	ld a,d				;check if destination address has wrapped to 0
	or e
	jr nz,fs_dadok
	ld de,$80				;loop around to $8000 and inc bank
	in a,(sys_mem_select)
	and $f
	inc a
	cp $10
	jr z,fs_flerr
	out (sys_mem_select),a

fs_dadok	ld a,b				;last byte of sector?
	or c
	jr nz,fs_cblp
	ld (fs_z80_working_address),de	;update destination address
	pop bc				;retrive sector offset / sector countdown
	inc c				;next sector
	djnz fs_flns			;loop until all sectors in cluster read

	ld hl,(fs_file_working_cluster)	;get location of the next cluster in this file's chain
	ld b,0				
	ld c,l
	ld de,(fs_fat1_loc_lba)
	ld l,h
	ld h,0
	add hl,de
	ld (sector_lba0),hl
	xor a
	ld (sector_lba2),a
	call sdc_read_sector
	ret c
	push ix
	ld ix,sector_buffer
	add ix,bc
	add ix,bc
	ld l,(ix)
	ld h,(ix+1)
	pop ix
	ld (fs_file_working_cluster),hl
	ld de,$fff8			
	xor a				
	sbc hl,de
	jr nc,fs_fpbad			
fs_nfbok	jp fs_flnc		


fs_bdld	pop bc				
	xor a				; op completed ok: a = 0, carry = 0
	ret

fs_flerr	pop bc
fs_fpbad	ld a,3				
	or a
	ret			
			

;---------------------------------------------------------------------------------------------
; Internal subroutines
;---------------------------------------------------------------------------------------------


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


;----------------------------------------------------------------------------------------------
; Simplified Z80 PQFS File System code by Phil @ Retroleum
; Reduced to the essentials required to load a file called
; "*.OSF" from root directory.
;----------------------------------------------------------------------------------------------

find_os_file_pqfs

; Set "fs_z80_working_address" to load location before calling

; Output Carry set = Hardware error
;        Zero flag set = OK, else A = error code $1= Not FAT16, $2=File not found, $3= EOF encountered

	xor a				;read PQFS BAT (block 0, sector 0)
	ld d,a				;check for PQFS signature
	ld e,a
	call pfs_read_sector_new_lba
	ret c				;quit on h/w error
	ld hl,sector_buffer			;first 4 bytes should be "PQFS",$01
	ld de,pfs_pqfs_sig
	ld b,5
pfs_cpqfs	ld a,(de)
	cp (hl)
	jr nz,pfs_not_pqfs
	inc hl
	inc de
	djnz pfs_cpqfs
	jr pqfs_sig_ok
	
pfs_not_pqfs
	
	ld a,1				;error 1 = not PQFS disk
	or a
	ret


pqfs_sig_ok


	ld b,$3f				;find "*.OSF" file in root dir
	ld c,1			
pfs_nfns	ld de,1				;get sector 1 of root block
	ld a,c
	call pfs_read_sector_new_lba
	ret c

	push bc
	ld b,16				;entries per sector count
	ld hl,sector_buffer
pfs_fnls	push hl			
	pop iy				;hl -> iy
	ld e,12
pfnddot	ld a,(iy)				;look for "."
	inc iy
	cp "."
	jr z,pgotext
	dec e
	jr nz,pfnddot
	jr pnxtent
pgotext	ld a,"O"
	cp (iy)
	jr nz,pnxtent
	ld a,"S"
	cp (iy+1)
	jr nz,pnxtent
	ld a,"F"
	cp (iy+2)
	jr z,pgotosf
pnxtent	ld de,32
	add hl,de
	djnz pfs_fnls			;next entry

	pop bc
	inc c				;next sector
	djnz pfs_nfns
pfs_ffnf	ld a,2				; error 2 = file not found / not a file / file length = 0
	or a				; clears carry flag
	ret

pgotosf	pop bc
	push hl
	pop iy
	bit 0,(iy+$10)			;quit if this is actually a subdir
	jr nz,pfs_ffnf
	ld l,(iy+$12)
	ld h,(iy+$13)
	ld (fs_file_working_cluster),hl
	ld e,(iy+$14)
	ld d,(iy+$15)
	ld l,(iy+$16)
	ld h,(iy+$17)
	jp set_flen
		

load_os_file_pqfs


pfs_ncl	ld b,$3f				;find_os_file_pqfs must be called first!!
	ld c,$01				;read in the file
pfs_flns	ld a,c				;first sector of actual file	
	ld de,(fs_file_working_cluster) 
	call pfs_read_sector_new_lba	
	ret c				;h/w error?

	push bc
	ld bc,512
	ld hl,sector_buffer			;source base
	ld de,(fs_z80_working_address)	;dest address for file bytes
pfs_cblp	ldi
	
	call file_length_countdown
	jr z,pfs_bdld			;if zero flag set = last byte
	
	ld a,d				;check destination address hasnt wrapped to 0
	or e
	jr nz,pfs_dadok
	ld de,$80				;loop around to $8000 and inc bank
	in a,(sys_mem_select)
	and $f
	inc a
	cp $10
	jr z,pfs_flerr
	out (sys_mem_select),a

pfs_dadok	ld a,b				; last byte of sector?
	or c
	jr nz,pfs_cblp
	ld (fs_z80_working_address),de	; update destination address
	pop bc				
	inc c
	djnz pfs_flns			; next sector

	ld de,(fs_file_working_cluster)	; read in header (first sector of block) to find
	xor a				; location of the next block in this file's chain
	call pfs_read_sector_new_lba
	ret c				; h/w error?
	ld de,(sector_buffer+8)		; de = next block location
	ld (fs_file_working_cluster),de
	ld a,d
	or e
	jr z,pfs_fpbad			; next block must not be zero
pfs_nfbok	jr pfs_ncl		

pfs_bdld	pop bc				; op completed ok: a = 0, carry = 0			
	xor a				
	ret

pfs_flerr	pop bc
pfs_fpbad	ld a,3				; end of file encountered
	or a				; clears carry flag
	ret			
			
	
;-----------------------------------------------------------------------------------------------

pfs_read_sector_new_lba

	push ix				; upon call: de = block, a = sector offset
	push de
	push bc
	inc de				; skip first 64 sectors of disk (leave PC MBR etc intact)
	and $3f
	ld b,a				; stash the sector offset for now
	xor a				; a = LSB
	srl d				; multiply de by 64
	rr e	
	rra
	srl d
	rr e
	rra
	or b				; or in the sector offset
	ld ix,sector_lba0			
	ld (ix),a				; put values in registers
	ld (ix+1),e
	ld (ix+2),d
	ld (ix+3),0			; we dont use addresses this high
	pop bc
	pop de
	pop ix


sdc_read_sector

	push bc
	push de
	push hl
	call mmc_read_sector
	ccf				;switch carry flag so set = error
	pop hl
	pop de
	pop bc
	ret


;----------------------------------------------------------------------------------------------
	
file_length_countdown

	push hl				;count down number of bytes to transfer
	push bc
	ld b,4
	ld hl,fs_file_length_working
	ld a,$ff
flcdlp	dec (hl)
	cp (hl)
	jr nz,fs_cdnu
	inc hl
	djnz flcdlp
fs_cdnu	ld hl,(fs_file_length_working)	;countdown = 0?
	ld a,h
	or l
	ld hl,(fs_file_length_working+2)
	or h
	or l
	pop bc
	pop hl
	ret

;----------------------------------------------------------------------------------------------
	
	
