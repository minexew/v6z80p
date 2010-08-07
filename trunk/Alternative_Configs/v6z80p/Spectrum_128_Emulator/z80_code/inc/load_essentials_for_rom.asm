;---------------------------------------------------------------------------------------------------
; Simplified (non-FLOS) Z80 FAT16 File System code by Phil @ Retroleum v1.02 [With Spectrum 128 equates]
; Reduced (but not optimized) to the essentials for loading whole file into
; a single 64KB page  / changing dirs / listing dirs
;
; V1.02 - fixed recursive call bug in dir listing routines
;
; Main Routines:
; --------------
; fs_check_format (Call this once before any disk operations)
; fs_load_file (INPUT: HL = required filename, DE = load address)
; fs_change_dir (INPUTS: HL = required subdir name)
; fs_parent_dir
; fs_root_dir

; For listing directory contents:
; -------------------------------
; fs_goto_first_dir_entry
; fs_get_dir_entry (OUTPUTS: HL = ASCII Filename, IX:IY = File Length, B = 1 if a directory)
; fs_goto_next_dir_entry
;
; OUTPUTS (All routines):  Zero Flag set: All OK, else error code in A ($FF = h/w error)
;
;-------------------------------------------------------------------------------------------------


fs_check_format
	
	call check_format
	jr error_handler
	

fs_load_file
	
	call load_file
	jr error_handler


fs_change_dir
	
	call change_dir
	jr error_handler


fs_parent_dir
	
	call parent_dir
	jr error_handler


fs_get_dir_entry
	
	call get_dir_entry
	jr error_handler	


fs_goto_next_dir_entry
	
	call goto_next_dir_entry

error_handler

	jr c,sdchwerr
	or a
	ret
sdchwerr	ld a,$ff
	or a
	ret
	
;-----------------------------------------------------------------------------------------------------


check_format
	
	call mmc_init_card			
	ccf
	ret c
	
	xor a				; get FAT16 parameters etc. If zero flag is not
	ld h,a				; set on return this is not a valid FAT16 disk.
	ld l,a
	ld (sector_lba2),a
retry_fbs	ld (sector_lba0),hl
	call sdc_read_sector		; read sector zero
	ret c				; quit on hardware error

	ld hl,(fs_sector_buffer+$1fe)		; check signature @ $1FE (applies to MBR and boot sector)
	ld de,$aa55
	xor a
	sbc hl,de
	jr z,diskid_ok			
formbad	ld a,1				; error code $1 - not FAT16			
	ret

diskid_ok	ld a,(fs_sector_buffer+$3a)		; for FAT16, char at $36 should be "6"
	cp $36
	jr nz,test_mbr

	ld hl,(fs_sector_buffer+$0b)		; get sector size
	ld de,512				; must be 512 bytes for this code
	xor a
	sbc hl,de
	jr nz,test_mbr
		
form_ok	ld a,(fs_sector_buffer+$0d)		; get number of sectors in each cluster
	ld (fs_cluster_size),a
	ld hl,(sector_lba0)			; get start LBA of partition
	ld de,(fs_sector_buffer+$0e)		; get 'sectors before FAT'
	add hl,de
	ld (fs_fat1_loc_lba),hl		; set FAT1 position
	ld de,(fs_sector_buffer+$16)		; get sectors per FAT
	add hl,de				; HL = FAT2 position
	add hl,de				; HL = Root Dir loc
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
	jr disk_ok			
		
test_mbr	ld a,(fs_sector_buffer+$1c2)		; get partition ID code (assuming this is MBR)
	and 4
	jp z,formbad			; bit 2 should be set for FAT16
	ld hl,(sector_lba0)			; have we already changed the LBA from 0?
	ld a,h
	or l
	jp nz,formbad			
	ld hl,(fs_sector_buffer+$1c6)		; update LBA base location and retry
	jp retry_fbs
	
disk_ok	call fs_root_dir
	ret

;---------------------------------------------------------------------------------------------
	
	
fs_root_dir

	push de
	ld de,0
	ld (fs_directory_cluster),de 
	pop de
	xor a
	ret
	
	
	

parent_dir

	ld de,(fs_directory_cluster)
	ld a,d
	or e
	jr nz,pdnaroot
	ld a,$0a				;error A = $0a = already at root block
	ret

pdnaroot	ld hl,fs_filename			;make filename = "..         "
	ld (hl),"."			;(cant use normal filename copier due to dots)
	inc hl
	ld (hl),"."
	ld b,10
pdclp	inc hl
	ld (hl)," "
	djnz pdclp
	call fs_find_fn_skip
	jr fs_cdskip
	

change_dir

	call fs_find_filename		; returns with start of 32 byte entry in IX
fs_cdskip	ret c				; quit on hardware error
	cp 2
	jr nz,founddir
	xor a				; clear carry
	ld a,$23				; return file not found error: A = $23
	ret
founddir	xor a				; clear carry
	ld a,$04				; prep error code A=$04: not a directory
	bit 4,(ix+$0b)
	ret z
	ld e,(ix+$1a)
	ld d,(ix+$1b)			; de = starting cluster of dir
	ld (fs_directory_cluster),de
	xor a
	ret


;------------------------------------------------------------------------------------------------


load_file

		
	ld (fs_z80_working_address),de	; set load address
	
	call fs_find_filename		
	ret c				; h/w error?
	ret nz				; file not found
					
	ld a,$06				; prep error $06 - not a file
	bit 4,(ix+$0b)
	ret nz
	
	ld l,(ix+$1a)		
	ld h,(ix+$1b)
	ld (fs_file_working_cluster),hl	; set file's start cluster

	ld e,(ix+$1c)
	ld d,(ix+$1d)
	ld l,(ix+$1e)			; set filelength
	ld h,(ix+$1f)
	ld (fs_file_length_working),de
	ld (fs_file_length_working+2),hl
	ld a,h					
	or l
	or d
	or e
	jr nz,fs_flnc			; is it > 0?
	ld a,$07
	ret
	
fs_flnc	ld a,(fs_cluster_size)		
	ld b,a
	ld c,0
fs_flns	ld a,c				
	ld hl,(fs_file_working_cluster) 
	call cluster_and_offset_to_lba
	call sdc_read_sector		;read first sector of file
	ret c				;h/w error?

	push bc				;stash sector pos / countdown
	ld bc,512				;bv = number of bytes to read from sector
	ld hl,fs_sector_buffer			;sector base
	ld de,(fs_z80_working_address)	;dest address for file bytes

fs_cblp	ldi				;(hl)->(de), inc hl, inc de, dec bc
	call file_length_countdown
	jr z,fs_bdld			;if zero flag set = last byte
fs_dadok	ld a,b				;last byte of sector?
	or c
	jr nz,fs_cblp

	ld (fs_z80_working_address),de	;update destination address
	pop bc				;retrive sector offset / sector countdown
	inc c				;next sector
	djnz fs_flns			;loop until all sectors in cluster read

	ld hl,(fs_file_working_cluster)	;get location of the next cluster in this file's chain
	call get_fat_entry_for_cluster
	ld (fs_file_working_cluster),hl
	call fs_compare_hl_fff8
	jr nc,fs_fpbad			
fs_nfbok	jr fs_flnc		


fs_bdld	pop bc				
	xor a				; op completed ok: a = 0, carry = 0
	ret

fs_flerr	pop bc
fs_fpbad	ld a,3				
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



get_dir_entry

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
	
nr_read	call sdc_read_sector		;read the sector
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

	ld de,fs_filename			;clear filename string
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
	ld hl,fs_filename			;on return, HL = location of filename string
	xor a
	ret
	

fs_fadp	call goto_next_dir_entry
	jp z,get_dir_entry
	ret
	



goto_next_dir_entry

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
endofdir	ld a,$24				; a = $24, end of dir
	ret	
nonroot2	ld a,(fs_cluster_size)		
	cp (hl)				;last sector in cluster?
	jr nz,ndlok
	ld (hl),0				;sector offset reset to 0
	ld hl,(fs_dir_entry_cluster)
	call get_fat_entry_for_cluster
	ld (fs_dir_entry_cluster),hl
	call fs_compare_hl_fff8		;any more clusters in this chain?
	jr nc,endofdir
		
ndlok	xor a
	ret
	
	
;---------------------------------------------------------------------------------------------
; Internal subroutines
;---------------------------------------------------------------------------------------------

fs_hl_to_filename

;INPUT: HL = address of filename (null / space termimated)

	ld de,fs_filename
hltofngo	push de
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


;------------------------------------------------------------------------------------------------------


fs_find_filename

; INPUT  HL: ASCII filename string
; OUTPUT IX: Start of 32 byte dir entry 
	
	call fs_hl_to_filename

fs_find_fn_skip
	
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
	
	ld de,(fs_directory_cluster)		; if not actually in root....
	ld a,d
	or e
	jr z,at_rootd2
	ld hl,(fs_file_working_cluster)	; ....set up LBA for current cluster	
	ld a,(fs_working_sector)
	call cluster_and_offset_to_lba	
	
at_rootd2	call sdc_read_sector
	ret c
	ld c,16				; sixteen 32 byte entries per sector
	ld ix,fs_sector_buffer
ndirentr	push ix
	pop de
	ld iy,fs_filename
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
	
	ld de,(fs_directory_cluster)		; are we scanning the root dir?
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
	call sdc_read_sector
	jr c,gfc_hwerr
	push ix
	ld ix,fs_sector_buffer
	add ix,bc
	add ix,bc
	ld l,(ix)
	ld h,(ix+1)
	pop ix
gfc_hwerr	pop de
	pop bc
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

;**************************************************************************************************
;* SIMPLIFIED MMC/SD CARD ROUTINES                                                                *
;**************************************************************************************************

mmc_cs		equ 2	;FPGA output (active low)
mmc_power		equ 3	;FPGA output (active low)


; PORT EQUATES FOR SPECTRUM 128 EMULATOR
; --------------------------------------

sys_sdcard_ctrl1	equ 251
sys_sdcard_ctrl2	equ 252
sys_spi_port	equ 250
sys_hw_flags	equ 254

;----------------------------------------------------------------------------------------------

mmc_init_card

; Initializes card. Returns: Carry = 1 if initialized OK


	ld a,1				; Assume card is SD type at start
	ld (mmc_sdc),a			

	call mmc_power_off			; Switch off power to the card
	
	ld b,128				; wait approx 0.5 seconds
mmc_powod	call wait_4ms
	djnz mmc_powod			
		
	call mmc_power_on			; Switch card power back on

	call mmc_spi_port_slow

	call wait_4ms			; Short delay

	call mmc_deselect_card		
	
	ld b,10				; send 80 clocks to ensure card has stabilized
mmc_ecilp	ld a,$ff
	call mmc_send_byte
	djnz mmc_ecilp
	
	call mmc_select_card		; Set Card's /CS line active (low)
	
	ld a,$40				; Send Reset Command CMD0 ($40,$00,$00,$00,$00,$95)
	ld bc,$9500			; When /CS is low on receipt of CMD0, card enters SPI mode 
	ld de,$0000
	call mmc_send_command		 
	call mmc_get_byte			; skip nCR
	call mmc_wait_ncr			; wait for valid response..			
	cp $01				; command response should be $01 ("In idle mode")
	jp nz,card_init_fail		


	ld bc,8000			; Send SD card init command ACMD41, if illegal try MMC card init
sdc_iwl	push bc				;
	ld a,$77				; CMD55 ($77 00 00 00 00 01) 
	ld bc,$0100
	ld de,$0000
	call mmc_send_command
	call mmc_get_byte			; NCR
	call mmc_get_byte			; Command response

	ld a,$69				; ACMD41 ($69 00 00 00 00 01)
	ld bc,$0100				
	ld de,$0000
	call mmc_send_command		
	call mmc_get_byte
	pop bc
	call mmc_wait_ncr			; wait for valid response..	
	bit 2,a				; check bit 2, if set = illegal command
	jr nz,mmc_init			
	or a
	jr z,mmc_init_done			; when response is $00, card is ready for use
	dec bc
	ld a,b
	or c
	jr nz,sdc_iwl
	jp card_init_fail


mmc_init	xor a
	ld (mmc_sdc),a

	ld bc,8000			; Send MMC card init and wait for card to initialize
mmc_iwl	push bc

	ld a,$41				; send CMD1 ($41 00 00 00 00 01) to test this
	ld bc,$0100				
	ld de,$0000
	call mmc_send_command		; send Initialize command
	pop bc
	call mmc_wait_ncr			; wait for valid response..	
	or a				; command response is $00 when card is ready for use
	jr z,mmc_init_done
	dec bc
	ld a,b
	or c
	jr nz,mmc_iwl
	jr card_init_fail


mmc_init_done

	call mmc_deselect_card

	call mmc_spi_port_fast		; Use 8MHz SPI clock		
	
	scf				; carry set = card initialized 
	ret

;---------------------------------------------------------------------------------------------

card_init_fail

	call mmc_deselect_card
	xor a				; a = 0, init failed
	ret

card_read_fail

	call mmc_deselect_card
	xor a
	inc a				; a =1. read failed
	ret
		
;------------------------------------------------------------------------------------------

mmc_read_sector

	call mmc_select_card

	ld hl,sector_lba0
	ld e,(hl)				; sector number LSB
	inc hl
	ld d,(hl)
	inc hl
	ld c,(hl)
	sla e				; convert sector to byte address
	rl d
	rl c
	ld a,$51				; Send CMD17 read sector command		
	ld b,$01				; A = $51 command byte, B = $01 dummy byte for CRC
	call mmc_send_command		
	call mmc_wait_ncr			; wait for valid response..	 
	or a				; command response should be $00
	jp nz,card_read_fail		
	call mmc_wait_data_token		; wait for the data token
	or a
	jp nz,card_read_fail
	
	ld hl,fs_sector_buffer			; optimized read sector code
	ld c,sys_spi_port
	ld b,0
	ld a,$ff
	out (sys_spi_port),a		; send read clocks for first byte
	nop
	nop
	nop
mmc_orsl1	nop				; 4 cycles
	ini				; 16 cycles (c)->(HL), HL+1, B1-1
	out (sys_spi_port),a		; 11 cycles - read clocks (requires 16 cycles)
	jp nz,mmc_orsl1			; 10 cycles
mmc_orsl2	nop				; 4 cycles
	ini				; 16 cycles (c)->(HL), HL+1, B1-1
	out (sys_spi_port),a		; 11 cycles - read clocks (requires 16 cycles)
	jp nz,mmc_orsl2			; 10 cycles
	nop				; allow the 'extra' read clocks to end (cyc byte 1)
	nop
	out (sys_spi_port),a		; 8 more clocks (skip crc byte 2)
	nop
	nop
	nop
	nop
	
	call mmc_deselect_card
	xor a
	scf				; carry set = card operation OK 
	ret
	
;---------------------------------------------------------------------------------------------

mmc_send_command

; set A = command, C:DE for sector number, B for CRC

	push af				; send 8 clocks first - seems necessary for SD cards..
	ld a,$ff
	call mmc_send_byte
	pop af

	call mmc_send_byte			; command byte
	ld a,c				; then 4 bytes of address [31:0]
	call mmc_send_byte
	ld a,d
	call mmc_send_byte
	ld a,e
	call mmc_send_byte
	ld a,0
	call mmc_send_byte
	ld a,b				; finally CRC byte
	call mmc_send_byte
	ret

;---------------------------------------------------------------------------------------------

mmc_wait_ncr
	
	push bc
	ld b,0
mmc_wncrl	call mmc_get_byte			; read until valid response from card (skip NCR)
	bit 7,a				; If bit 7 = 0, its a valid response
	jr z,mmc_gcr
	djnz mmc_wncrl
mmc_gcr	pop bc
	ret
	
;---------------------------------------------------------------------------------------------

mmc_wait_data_token

	ld b,0
mmc_wdt	call mmc_get_byte			; read until data token arrives
	cp $fe
	jr z,mmc_gdt
	djnz mmc_wdt
	ld a,1				; didn't get a data token
	ret

mmc_gdt	xor a				; all OK
	ret

;----------------------------------------------------------------------------------------------

mmc_send_byte

;Put byte to send to card in A

	out (sys_spi_port),a		; send byte to serializer
	
mmc_wsb	in a,(sys_hw_flags)			; wait for serialization to end
	bit 6,a
	jr nz,mmc_wsb
	ret

	
;---------------------------------------------------------------------------------------------

mmc_get_byte

; Returns byte read from card in A

	ld a,$ff
	out (sys_spi_port),a		; send 8 clocks

mmc_wrb	in a,(sys_hw_flags)			; wait for serialization to end
	bit 6,a
	jr nz,mmc_wrb

	in a,(sys_spi_port)			; read the contents of the shift register
	ret
	
;---------------------------------------------------------------------------------------------

mmc_select_card

	in a,(sys_sdcard_ctrl2)
	res mmc_cs,a
	out (sys_sdcard_ctrl2),a
	ret
	
mmc_deselect_card

	in a,(sys_sdcard_ctrl2)
	set mmc_cs,a
	out (sys_sdcard_ctrl2),a
	ld a,$ff				; send 8 clocks to make card de-assert its Dout line
	call mmc_send_byte
	ret
	
;---------------------------------------------------------------------------------------------

mmc_power_on

	in a,(sys_sdcard_ctrl2)
	res mmc_power,a
	out (sys_sdcard_ctrl2),a
	ret
	
mmc_power_off
	
	ld a,%00010000			; bit 6 @ 0 = switch off SPI port (force data and clk out low)
	out (sys_sdcard_ctrl1),a		; bit 4 = v5z80p legacy: No affect on v6z80p.

	in a,(sys_sdcard_ctrl2)
	set mmc_power,a			
	res mmc_cs,a			; pull /CS low also (stop all high levels)
	out (sys_sdcard_ctrl2),a		
	ret
	

;----------------------------------------------------------------------------------------------

mmc_spi_port_slow

	ld a,%01000000			; (bit 6) @ 1 = enable SPI outputs, (bit 7) @ 0 = 250Khz
	out (sys_sdcard_ctrl1),a		
	ret

mmc_spi_port_fast
	
	ld a,%11000000			; (bit 6) @ 1 = enable SPI outputs, (bit 7) @ 1 = 8MHz
	out (sys_sdcard_ctrl1),a		
	ret
	
;---------------------------------------------------------------------------------------------

wait_4ms
	push af
	push bc
	ld bc,2461
sdellp	dec bc				;6
	ld a,b				;4
	or c				;4
	jr nz,sdellp			;12
	pop bc
	pop af
	ret
	
;------------------------------------------------------------------------------------------------
