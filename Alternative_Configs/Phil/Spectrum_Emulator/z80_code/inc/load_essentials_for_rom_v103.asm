;---------------------------------------------------------------------------------------------------
; Simplified Z80 FAT16 File System code v1.03 [With Spectrum 128 equates]
; Reduced (but not optimized) to the essentials for loading whole file into
; a single 64KB page  / changing dirs
;
; V1.03 - Removed FAT16 dir list routines (not used by ROM)
;       - Removed SD card CSD/CID parsing code (not used by ROM)
;
; Main Routines:
; --------------
; fs_check_format (Call this once before any disk operations)
; fs_load_file (INPUT: HL = required filename, DE = load address)
; fs_change_dir (INPUTS: HL = required subdir name)
; fs_parent_dir
; fs_root_dir
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


error_handler

	jr c,sdchwerr
	or a
	ret

sdchwerr

	ld a,$ff
	or a
	ret
	
;-----------------------------------------------------------------------------------------------------


check_format
	
	ld hl,0					; get FAT16 parameters etc. If zero flag is not
	ld (sector_lba2),hl			; set on return this is not a valid FAT16 disk.
	

retry_fbs

	ld (sector_lba0),hl
	call sdc_read_sector			; read sector zero
	ret c					; quit on hardware error

	ld hl,(fs_sector_buffer+$1fe)		; check signature @ $1FE (applies to MBR and boot sector)
	ld de,$aa55
	xor a
	sbc hl,de
	jr z,diskid_ok			

formbad	ld a,1					; error code $1 - not FAT16			
	ret

diskid_ok

	ld a,(fs_sector_buffer+$3a)		; for FAT16, char at $36 should be "6"
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
	ld (fs_fat1_loc_lba),hl			; set FAT1 position
	ld de,(fs_sector_buffer+$16)		; get sectors per FAT
	add hl,de				; HL = FAT2 position
	add hl,de				; HL = Root Dir loc
	ld (fs_root_dir_loc_lba),hl 		; set location of root dir
	ld hl,(fs_sector_buffer+$11)		; get max root directory ENTRIES
	ld a,h
	or l
	jr z,test_mbr				; FAT32 puts $0000 here
	add hl,hl				; (IE: 32 bytes each, 16 per sector)
	add hl,hl
	add hl,hl
	add hl,hl
	xor a
	ld l,h
	ld h,a
	ld (fs_root_dir_sectors),hl		; set number of sectors used for root dir (max_root_entries / 32)				 
	jr disk_ok			
		
test_mbr
	ld a,(fs_sector_buffer+$1c2)		; get partition ID code (assuming this is MBR)
	and 4
	jp z,formbad				; bit 2 should be set for FAT16
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

pdnaroot
	ld hl,fs_filename			;make filename = "..         "
	ld (hl),"."				;(cant use normal filename copier due to dots)
	inc hl
	ld (hl),"."
	ld b,10
pdclp	inc hl
	ld (hl)," "
	djnz pdclp
	call fs_find_fn_skip
	jr fs_cdskip
	

change_dir

	call fs_find_filename			; returns with start of 32 byte entry in IX
fs_cdskip
	ret c					; quit on hardware error
	cp 2
	jr nz,founddir
	xor a					; clear carry
	ld a,$23				; return file not found error: A = $23
	ret
founddir
	xor a					; clear carry
	ld a,$04				; prep error code A=$04: not a directory
	bit 4,(ix+$0b)
	ret z
	ld e,(ix+$1a)
	ld d,(ix+$1b)				; de = starting cluster of dir
	ld (fs_directory_cluster),de
	xor a
	ret


;------------------------------------------------------------------------------------------------


load_file

		
	ld (fs_z80_working_address),de		; set load address
	
	call fs_find_filename		
	ret c					; h/w error?
	ret nz					; file not found
					
	ld a,$06				; prep error $06 - not a file
	bit 4,(ix+$0b)
	ret nz
	
	ld l,(ix+$1a)		
	ld h,(ix+$1b)
	ld (fs_file_working_cluster),hl		; set file's start cluster

	ld e,(ix+$1c)
	ld d,(ix+$1d)
	ld l,(ix+$1e)				; set filelength
	ld h,(ix+$1f)
	ld (fs_file_length_working),de
	ld (fs_file_length_working+2),hl
	ld a,h					
	or l
	or d
	or e
	jr nz,fs_flnc				; is it > 0?
	ld a,$07
	ret
	
fs_flnc	ld a,(fs_cluster_size)		
	ld b,a
	ld c,0
fs_flns	ld a,c				
	ld hl,(fs_file_working_cluster) 
	call cluster_and_offset_to_lba
	call sdc_read_sector			;read first sector of file
	ret c					;h/w error?

	push bc				;stash sector pos / countdown
	ld bc,512				;bv = number of bytes to read from sector
	ld hl,fs_sector_buffer			;sector base
	ld de,(fs_z80_working_address)		;dest address for file bytes

fs_cblp	ldi					;(hl)->(de), inc hl, inc de, dec bc
	call file_length_countdown
	jr z,fs_bdld				;if zero flag set = last byte
fs_dadok
	ld a,b					;last byte of sector?
	or c
	jr nz,fs_cblp

	ld (fs_z80_working_address),de		;update destination address
	pop bc					;retrive sector offset / sector countdown
	inc c					;next sector
	djnz fs_flns				;loop until all sectors in cluster read

	ld hl,(fs_file_working_cluster)		;get location of the next cluster in this file's chain
	call get_fat_entry_for_cluster
	ld (fs_file_working_cluster),hl
	call fs_compare_hl_fff8
	jr nc,fs_fpbad			
fs_nfbok
	jr fs_flnc		


fs_bdld	pop bc				
	xor a					; op completed ok: a = 0, carry = 0
	ret

fs_flerr
	pop bc
fs_fpbad
	ld a,3				
	ret			
			
;---------------------------------------------------------------------------------------------
; Internal subroutines
;---------------------------------------------------------------------------------------------

fs_hl_to_filename

;INPUT: HL = address of filename (null / space termimated)

	ld de,fs_filename
hltofngo
	push de
	ld a,32
	ld b,12
csfnlp1	ld (de),a				; first, fill filename array with spaces
	inc de
	djnz csfnlp1
	pop de
	push de			
	pop ix					; stash filename address for extension
	
	ld c,0
	ld b,8
csfnlp2	ld a,(hl)				; now copy filename, upto 8 characters
	or a
	ret z					; is char a zero?
	cp 32
	ret z					; is char a space?
	cp "."
	jr z,dofn_ext				; is char a dot?
	ld (de),a
	inc de
	inc hl
	inc c					; inc source character count
	djnz csfnlp2				; allow 8 filename chars
find_ext
	ld a,(hl)
	cp "."					; ninth char should be a dot
	jr z,dofn_ext	
	cp " "					; if space or zero, no extension
	ret z
	or a
	ret z
	inc hl
	jr find_ext
	
dofn_ext
	inc hl					; skip "." in source filename
	ld b,3				
fnextlp	ld a,(hl)				; copy 3 filename extension chars
	or a
	ret z					; end if space or zero
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
ffnnxtclu
	ld (fs_file_working_cluster),de
	xor a
	ld (fs_working_sector),a

ffnnxtsec
	ld hl,(fs_root_dir_loc_lba)		; initially set up LBA for a root dir scan
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
	ld hl,(fs_file_working_cluster)		; ....set up LBA for current cluster	
	ld a,(fs_working_sector)
	call cluster_and_offset_to_lba	
	
at_rootd2
	call sdc_read_sector
	ret c
	ld c,16					; sixteen 32 byte entries per sector
	ld ix,fs_sector_buffer
ndirentr
	push ix
	pop de
	ld iy,fs_filename
	ld b,11					; 8+3 chars to compare, filename and extension
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
	xor a					; found filename: return with zero flag set
	ret
fnnotsame
	ld de,32				; move to next filename entry in dir
	add ix,de
	dec c
	jr nz,ndirentr				; all entries in this sector scanned?
	
	ld hl,fs_working_sector			; move to next sector
	inc (hl)
	
	ld de,(fs_directory_cluster)		; are we scanning the root dir?
	ld a,d
	or e
	jr nz,notrootdir
	ld a,(fs_root_dir_sectors)		; reached last sector of root dir?
	cp (hl)					; LSB only: Assumes < 256 sectors used for root dir
	jr nz,ffnnxtsec
fnnotfnd
	ld a,$02				; error code $02 - filename not found
	or a
	ret

notrootdir
	
	ld a,(fs_cluster_size)			; reached last sector of dir cluster?
	cp (hl)
	jr nz,ffnnxtsec
	
	ld hl,(fs_file_working_cluster)		
	call get_fat_entry_for_cluster
	ret c
	
	call fs_compare_hl_fff8			; does this cluster have a continuation entry in the FAT?
	jr nc,fnnotfnd				; if hl > $FFF7 there's no continuation - stop scanning 
	ex de,hl				; put hl in DE for instruction at loop point
	jp ffnnxtclu				; set base cluster = the continuation word just found
	

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
	ld hl,(fs_root_dir_loc_lba)
	ld bc,(fs_root_dir_sectors)
	add hl,bc				; hl = start of data area
	ld c,a
	ld b,0
	add hl,bc				; add sector offset
	ld c,l
	ld b,h					; bc = sector offset + LBA of start of data area
	ex de,hl
	ld e,0					; e = LBA MSB
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
	
doubclus
	sla l					; cluster * 2
	rl h
	rl e
	jr caotllp


;-----------------------------------------------------------------------------------------------


sdc_read_sector

	push bc
	push de
	push hl
	call sd_read_sector
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

;--------------------------------------------------------------------------------------------------
; SIMPLIFIED MMC/SD/SDHC LOW LEVEL CARD ROUTINES
;--------------------------------------------------------------------------------------------------

mmc_cs		equ 2	;FPGA output (active low)
mmc_power	equ 3	;FPGA output (active low)


; PORT EQUATES FOR SPECTRUM 128 EMULATOR
; --------------------------------------

sys_sdcard_ctrl1	equ 251
sys_sdcard_ctrl2	equ 252
sys_spi_port		equ 250
sys_hw_flags		equ 254

;-------------------------------------------------------------------------------------------------

CMD1      equ $40 + 1
CMD9      equ $40 + 9
CMD10     equ $40 + 10
CMD13     equ $40 + 13
CMD17     equ $40 + 17
CMD24     equ $40 + 24
ACMD41    equ $40 + 41
CMD55     equ $40 + 55
CMD58     equ $40 + 58

sd_error_spi_mode_failed      equ $01

sd_error_mmc_init_failed      equ $10
sd_error_sd_init_failed       equ $11
sd_error_sdhc_init_failed     equ $12
sd_error_vrange_bad           equ $13
sd_error_check_pattern_bad    equ $14

sd_error_illegal_command      equ $20
sd_error_bad_command_response equ $21
sd_error_data_token_timeout   equ $22
sd_error_write_timeout        equ $23
sd_error_write_failed         equ $24

;----------------------------------------------------------------------------------------------

sd_initialize

          
          call sd_init_main
          or a                                    ; if non-zero returned in A, there was an error
          jr z,sd_inok
          call sd_power_off                       ; if init failed shut down the SPI port
          scf
	  ret

sd_inok   call sd_spi_port_fast                   ; on initializtion success -  switch to fast clock 

sd_done   call sd_deselect_card                   ; Routines always deselect card on return
          or a                                    ; If A = 0 on SD routine exit, ZF set on return: No error
          ret z
          scf
          ret                                     ; if A <> 0 set carry flag                           

;--------------------------------------------------------------------------------------------------
                    
sd_read_sector

          call sd_read_sector_main
          jr sd_done
          
;--------------------------------------------------------------------------------------------------
          

sd_init_main

          xor a                                   ; Clear card info start
          ld (sd_card_info),a                     

          call sd_power_off                       ; Switch off power to the card (SPI clock slow, /CS is low but should be irrelevent)
          
          ld b,128                                ; wait approx 0.5 seconds
sd_powod  call pause_4ms
          djnz sd_powod                           
                    
          call sd_power_on                        ; Switch card power back on (SPI clock slow, /CS high - de-selected)
                    
          ld b,10                                 ; send 80 clocks to ensure card has stabilized
sd_ecilp  call sd_send_eight_clocks
          djnz sd_ecilp
          
          ld hl,CMD0_string                       ; Send Reset Command CMD0 ($40,$00,$00,$00,$00,$95)
          call sd_send_command_string             ; (When /CS is low on receipt of CMD0, card enters SPI mode) 
          cp $01                                  ; Command Response should be $01 ("In idle mode")
          jr z,sd_spi_mode_ok
          
          ld a,sd_error_spi_mode_failed
          ret                 


; ---- CARD IS IN IDLE MODE -----------------------------------------------------------------------------------


sd_spi_mode_ok


          ld hl,CMD8_string                       ; send CMD8 ($48,$00,$00,$01,$aa,$87) to test for SDHC card
          call sd_send_command_string
          cp $01
          jr nz,sd_sdc_init                       ; if R1 response is not $01: illegal command: not an SDHC card

          ld b,4
          call sd_read_bytes_to_sector_buffer     ; get r7 response (4 bytes)
          ld a,1
          inc hl
          inc hl
          cp (hl)                                 ; we need $01,$aa in response bytes 2 and 3  
          jr z,sd_vrok
          ld a,sd_error_vrange_bad
          ret                                     

sd_vrok   ld a,$aa
          inc hl
          cp (hl)
          jr z,sd_check_pattern_ok
          ld a,sd_error_check_pattern_bad
          ret
          
sd_check_pattern_ok


;------ SDHC CARD CAN WORK AT 2.7v - 3.6v ----------------------------------------------------------------------
          

          ld bc,8000                              ; Send SDHC card init

sdhc_iwl  ld a,CMD55                              ; First send CMD55 ($77 00 00 00 00 01) 
          call sd_send_command_null_args
          
          ld hl,ACMD41HCS_string                  ; Now send ACMD41 with HCS bit set ($69 $40 $00 $00 $00 $01)
          call sd_send_command_string
          jr z,sdhc_init_ok                       ; when response is $00, card is ready for use     
          bit 2,a
          jr nz,sdhc_if                           ; if Command Response = "Illegal command", quit
          
          dec bc
          ld a,b
          or c
          jr nz,sdhc_iwl
          
sdhc_if   ld a,sd_error_sdhc_init_failed          ; if $00 isn't received, fail
          ret
          
sdhc_init_ok


;------ SDHC CARD IS INITIALIZED --------------------------------------------------------------------------------------

          
          ld a,CMD58                              ; send CMD58 - read OCR
          call sd_send_command_null_args
                    
          ld b,4                                  ; read in OCR
          call sd_read_bytes_to_sector_buffer
          ld a,(hl)
          and $40                                 ; test CCS bit
          rrca
          rrca 
          or %00000010                                      
          ld (sd_card_info),a                     ; bit4: Block mode access, bit 0:3 card type (0:MMC,1:SD,2:SDHC)
          xor a                                   ; A = 00, all OK
          ret

          
;-------- NOT AN SDHC CARD, TRY SD INIT ---------------------------------------------------------------------------------

sd_sdc_init

          ld bc,8000                              ; Send SD card init

sd_iwl    ld a,CMD55                              ; First send CMD55 ($77 00 00 00 00 01) 
          call sd_send_command_null_args

          ld a,ACMD41                             ; Now send ACMD41 ($69 00 00 00 00 01)
          call sd_send_command_null_args
          jr z,sd_rdy                             ; when response is $00, card is ready for use
          
          bit 2,a                                 
          jr nz,sd_mmc_init                       ; check command response bit 2, if set = illegal command - try MMC init
                                        
          dec bc
          ld a,b
          or c
          jr nz,sd_iwl
          
          ld a,sd_error_sd_init_failed            ; if $00 isn't received, fail
          ret
          
sd_rdy    ld a,1
          ld (sd_card_info),a                     ; set card type to 1:SD (byte access mode)
          xor a                                   ; A = 0: all ok     
          ret       


;-------- NOT AN SDHC OR SD CARD, TRY MMC INIT ---------------------------------------------------------------------------


sd_mmc_init

          ld bc,8000                              ; Send MMC card init and wait for card to initialize

sdmmc_iwl ld a,CMD1
          call sd_send_command_null_args          ; send CMD1 ($41 00 00 00 00 01) 
          ret z                                   ; If ZF set, command response in A = 00: Ready,. Card type is default MMC (byte access mode)
          
sd_mnrdy  dec bc
          ld a,b
          or c
          jr nz,sdmmc_iwl
          
          ld a,sd_error_mmc_init_failed           ; if $00 isn't received, fail 
          ret
          

;--------------------------------------------------------------------------------------------------
; SD Card READ SECTOR code begins...
;--------------------------------------------------------------------------------------------------
          
sd_read_sector_main

; 512 bytes are returned in sector buffer

          call sd_set_sector_addr

          ld a,CMD17                              ; Send CMD17 read sector command                  
          call sd_send_command_current_args
          jr z,sd_rscr_ok                         ; if ZF set command response is $00     

sd_bcr_error

          ld a,sd_error_bad_command_response
          ret

sd_rscr_ok
          
          call sd_wait_data_token                 ; wait for the data token
          jr z,sd_dt_ok                           ; ZF set if data token reeceived
          
          
sd_dt_timeout

          ld a,sd_error_data_token_timeout
          ret
          
          
sd_dt_ok  ld b,0                                  ; unoptimized sector read
          call sd_read_bytes_to_sector_buffer
          inc h
          ld b,0
          call sd_read_bytes
          call sd_get_byte                        ; read CRC byte 1
          call sd_get_byte                        ; read CRC byte 2

          xor a                                   ; A = 0: all ok
          ret


;---------------------------------------------------------------------------------------------


sd_set_sector_addr

          ld bc,(sector_lba0+2)
          ld hl,(sector_lba0)                     ; sector LBA BC:HL -> B,D,E,C
          ld d,c
          ld e,h
          ld c,l
          ld a,(sd_card_info)
          and $10
          jr nz,lbatoargs                         ; if SDHC card, we use direct sector access
          
          ld a,d                                  ; otherwise need to multiply by 512
          add hl,hl
          adc a,a   
          ex de,hl
          ld b,a
          ld c,0
lbatoargs ld hl,cmd_generic_args
          ld (hl),b
          inc hl
          ld (hl),d
          inc hl
          ld (hl),e
          inc hl
          ld (hl),c
          ret
          
          
;---------------------------------------------------------------------------------------------

sd_wait_data_token

          push bc
          ld bc,8000                                        
sd_wdt    call sd_get_byte                        ; read until data token ($FE) arrives, ZF set if received
          cp $fe
          jr z,sd_gdt
          dec bc
          ld a,b
          or c
          jr nz,sd_wdt
          inc c                                   ; didn't get a data token, ZF not set
sd_gdt    pop bc
          ret

;--------------------------------------------------------------------------------------------

sd_send_eight_clocks

          ld a,$ff
          call sd_send_byte
          ret

;---------------------------------------------------------------------------------------------


sd_send_command_null_args

          ld hl,0
          ld (cmd_generic_args),hl
          ld (cmd_generic_args+2),hl
         
          
sd_send_command_current_args
          
          ld hl,cmd_generic
          ld (hl),a

	  ld a,1
	  ld (cmd_generic_crc),a
          
	  
sd_send_command_string

; set HL = location of 6 byte command string
; returns command response in A (ZF set if $00)


          call sd_select_card                     ; send command always enables card select
                              
          call sd_send_eight_clocks               ; send 8 clocks first - seems necessary for SD cards..
          
          push bc
          ld b,6
sd_sclp   ld a,(hl)
          call sd_send_byte                       ; command byte
          inc hl
          djnz sd_sclp
          pop bc
          
          call sd_send_eight_clocks               ; skip first byte of nCR, a quirk of my SD card interface?
                    

sd_wait_valid_response
          
          push bc
          ld b,0
sd_wncrl  call sd_get_byte                        ; read until Command Response from card 
          bit 7,a                                 ; If bit 7 = 0, it's a valid response
          jr z,sd_gcr
          djnz sd_wncrl
                                                  
sd_gcr    or a                                    ; zero flag set if Command response = 00
          pop bc
          ret
          
          
;-----------------------------------------------------------------------------------------------

sd_read_bytes_to_sector_buffer

          ld hl,fs_sector_buffer
          
sd_read_bytes

; set HL to dest address for data
; set B to number of bytes required  

          push hl
sd_rblp   call sd_get_byte
          ld (hl),a
          inc hl
          djnz sd_rblp
          pop hl
          ret
          
;-----------------------------------------------------------------------------------------------

; This data can be placed in ROM:

CMD0_string         db $40,$00,$00,$00,$00,$95
CMD8_string         db $48,$00,$00,$01,$aa,$87
ACMD41HCS_string    db $69,$40,$00,$00,$00,$01

;===============================================================================================




;---------------------------------------------------------------------------------------------
; V6Z80P Specific Hardware Level Routines v1.10
;---------------------------------------------------------------------------------------------

sd_cs               equ 2     ;FPGA output (active low)
sd_power            equ 3     ;FPGA output (active low)

;----------------------------------------------------------------------------------------------

sd_send_byte

;Put byte to send to card in A

          out (sys_spi_port),a                    ; send byte to serializer
          
sd_waitserend

          in a,(sys_hw_flags)                     ; wait for serialization to end
          bit 6,a
          jr nz,sd_waitserend
          ret

          
;---------------------------------------------------------------------------------------------

sd_get_byte

; Returns byte read from card in A

          ld a,$ff
          out (sys_spi_port),a                    ; send 8 clocks
          
          call sd_waitserend

          in a,(sys_spi_port)                     ; read the contents of the shift register
          ret
          
;---------------------------------------------------------------------------------------------

sd_select_card

          push af
          in a,(sys_sdcard_ctrl2)
          res sd_cs,a
          out (sys_sdcard_ctrl2),a
          pop af
          ret
          
sd_deselect_card

          push af
          in a,(sys_sdcard_ctrl2)
          set sd_cs,a
          out (sys_sdcard_ctrl2),a
                              
          call sd_send_eight_clocks               ; send 8 clocks to make card de-assert its Dout line
          pop af
          ret
          
;---------------------------------------------------------------------------------------------


sd_power_on

          push af
          in a,(sys_sdcard_ctrl2)                 
          res sd_power,a                          ; pull power control low: Active - SD card powered up
          set sd_cs,a                             ; card deselected by default at power on
          out (sys_sdcard_ctrl2),a
          
          ld a,%01000000                          ; (6) = 1 FPGA Output enabled, (7) = 0: 250Khz SPI clock
sd_setsp  out (sys_sdcard_ctrl1),a                
          pop af
          ret
          
          
          
sd_power_off
          
          push af
          in a,(sys_sdcard_ctrl2)
          set sd_power,a                          ; set power control hi: inactive - no power to SD
          res sd_cs,a                             ; ensure /CS is low - no power to this pin                             
          out (sys_sdcard_ctrl2),a                
          xor a
          jr sd_setsp                             ; disable FPGA SPI data output too



sd_spi_port_fast
          
          push af
          ld a,%11000000                          ; (6) = 1 FPGA Output enabled, (7) = 1: 8MHz SPI clock
          jr sd_setsp


;---------------------------------------------------------------------------------------------

pause_4ms
	
	push af				; NOte: only accurate if CPU at 16MHz (full speed)
	push bc
	ld bc,2461
sdellp	dec bc					;6
	ld a,b					;4
	or c					;4
	jr nz,sdellp				;12
	pop bc
	pop af
	ret
	
;---------------------------------------------------------------------------------------------
