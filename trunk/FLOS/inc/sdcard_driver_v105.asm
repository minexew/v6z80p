;--------------------------------------------------------------------------------------------------
; Low level Z80 MMC/SDC card access routines - Phil Ruston '08
;--------------------------------------------------------------------------------------------------
;
; V1.05 - Added new driver header for FLOS 564+
;
; V1.04 -  Removed V5Z80P checks, optimized for code size
; V1.03 -  Sector read / write code have optimized 512 byte transfer loops
;
; Limitations:
; ------------
; Currently does not support V2.0 SD cards (IE: SDHC large capacity cards > 2GB)
; Does not check for voltage compatibility or block size
; Somewhat arbitary timimg..
;
;--------------------------------------------------------------------------------------------------

; Key Routines:      Input Registers             Output Registers
; -------------      ---------------             ----------------
; mmc_get_id	no arguments required        	BC:DE = Capacity in sectors, HL = ID ASCII string, A = error code
; mmc_read_sector	sector_LBA0-3		Carry Flag / A = error code
; mmc_write_sector	sector_LBA0-3    		Carry Flag / A = error code
;
; (Assume all other registers are trashed.)
;
; Routines respond with Carry flag set if operation was OK, else A =

mmc_error_bad_init			equ 1
sdc_error_bad_init			equ 2
mmc_error_bad_id			equ 3
mmc_error_bad_command_response	equ 4
mmc_error_data_token_timeout		equ 5
mmc_error_write_timeout		equ 6
mmc_error_write_failed		equ 7

; Variables required:
; -------------------
;
; "sector_buffer" - 512 bytes
;
; "sector_lba0" - LBA of desired sector LSB
; "sector_lba1" 
; "sector_lba2"
; "sector_lba3" - LBA of desired sector MSB
;
; "mmc_sdc" - 1 byte ($00 = card is MMC, $01 = card is SD)


;-------------------------------------------------------------------------------------------------
; STANDARDIZED DRIVER HEADER FOR V6Z80P / FLOS 564+
;-------------------------------------------------------------------------------------------------

sd_card_driver			; label of driver code

	db "SD_CARD",0		; 0 - 7 = desired ASCII name of device type
	
	jp mmc_read_sector		; $8 = jump to read sector routine
	jp mmc_write_sector		; $B = jump to write sector routine
				; $E = init / get hardware ID routine

;--------------------------------------------------------------------------------------------------
; (Mostly) Hardware agnostic section..
;--------------------------------------------------------------------------------------------------

mmc_get_id


; Initializes card, reads CSD and CID into sector buffer and creates string
; containing ASCII device ID. Returns device capacity (number of 512 byte sectors) 

; Returns:
; --------
;   HL = Pointer to device ID string 
; C:DE = Capacity (number of sectors)


	ld a,1				; Assume card is SD type at start
	ld (mmc_sdc),a			

	call mmc_power_off			; Switch off power to the card
	
	ld b,128				; wait approx 0.5 seconds
mmc_powod	call mmc_wait_4ms
	djnz mmc_powod			
		
	call mmc_power_on			; Switch card power back on

	call mmc_spi_port_slow

	call mmc_wait_4ms			; Short delay

	call mmc_deselect_card		
	
	ld b,10				; send 80 clocks to ensure card has stabilized
mmc_ecilp	call mmc_send_eight_clocks
	djnz mmc_ecilp
	
	call mmc_select_card		; Set Card's /CS line active (low)
	
	ld a,$40				; Send Reset Command CMD0 ($40,$00,$00,$00,$00,$95)
	ld bc,$9500			; When /CS is low on receipt of CMD0, card enters SPI mode 
	ld de,$0000
	call mmc_send_command		 
	call mmc_get_byte			; skip nCR
	call mmc_wait_ncr			; wait for valid response..			
	cp $01				; command response should be $01 ("In idle mode")
	jp nz,mmc_init_fail		


	ld bc,8000			; Send SD card init command ACMD41, if illegal try MMC card init
sdc_iwl	push bc				;
	ld a,$77				; CMD55 ($77 00 00 00 00 01) 
	call mmc_send_command_null_args
	call mmc_get_byte			; NCR
	call mmc_get_byte			; Command response
	ld a,$69				; ACMD41 ($69 00 00 00 00 01)
	call mmc_send_command_null_args		
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
	jp sdc_init_fail


mmc_init	xor a				; try MMC card init command
	ld (mmc_sdc),a
	ld bc,8000			; Send MMC card init and wait for card to initialize
mmc_iwl	push bc
	ld a,$41				; send CMD1 ($41 00 00 00 00 01) to test this
	call mmc_send_command_null_args	; send Initialize command
	pop bc
	call mmc_wait_ncr			; wait for valid response..	
	or a				; command response is $00 when card is ready for use
	jr z,mmc_init_done
	dec bc
	ld a,b
	or c
	jr nz,mmc_iwl
	jp mmc_init_fail



mmc_init_done

	ld a,$49				; send "read CSD" command: 49 00 00 00 00 01 to read card info
	call mmc_send_command_null_args
	call mmc_wait_ncr			; wait for valid response..	 
	or a				; command response should be $00
	jp nz,mmc_id_fail
	call mmc_wait_data_token		; wait for the data token
	or a
	jp nz,mmc_id_fail
	ld hl,sector_buffer			; read the card info to sector buffer (16 bytes)
	call mmc_read_id_bytes	

	ld a,$4a				; send "read CID" $4a 00 00 00 00 00 command for more card data
	call mmc_send_command_null_args
	call mmc_wait_ncr			; wait for valid response..	 
	or a				; command response should be $00
	jp nz,mmc_id_fail
	call mmc_wait_data_token		; wait for the data token
	or a
	jp nz,mmc_id_fail
	ld hl,sector_buffer+16		; read in more card data (16 bytes) 
	call mmc_read_id_bytes
	call mmc_deselect_card


mmc_quit	

	ld hl,sector_buffer+$13		; Build name / version / serial number of card as ASCII string
	ld de,sector_buffer+$20
	ld bc,5
	ld a,(mmc_sdc)
	or a
	jr nz,mmc_cn5
	inc bc
mmc_cn5	ldir
	push hl
	push de
	ld hl,mmc_vnchars
	ld bc,26
	ldir
	pop de
	pop hl
	inc de
	inc de
	ld a,(hl)
	srl a
	srl a
	srl a
	srl a
	add a,$30				; put in version digit 1
	ld (de),a
	inc de
	inc de
	ld a,(hl)
	and $f
	add a,$30
	ld (de),a				; put in version digit 2
	inc de
	inc de
	inc de
	inc de
	inc de
	inc hl
	ld b,4
mmc_snulp	ld a,(hl)				; put in 32 bit serial number
	srl a
	srl a
	srl a
	srl a
	add a,$30
	cp $3a
	jr c,mmc_hvl1
	add a,$7
mmc_hvl1	ld (de),a
	inc de
	ld a,(hl)
	and $f
	add a,$30
	cp $3a
	jr c,mmc_hvl2
	add a,$7
mmc_hvl2	ld (de),a
	inc de
	inc hl
	djnz mmc_snulp
	
	

	ld ix,sector_buffer			; compute card's capacity
	ld a,(ix+6)
	and %00000011
	ld d,a
	ld e,(ix+7)
	ld a,(ix+8)
	and %11000000
	sla a
	rl e
	rl d
	sla a
	rl e
	rl d				; DE = 12 bit value: "C_SIZE"
	
	ld a,(ix+9)
	and %00000011
	ld b,a
	ld a,(ix+10)
	and %10000000
	sla a
	rl b				; B = 3 bit value: "C_MULT"
	
	inc b
	inc b
	ld hl,0
mmc_cmsh	sla e
	rl d
	rl l
	rl h
	djnz mmc_cmsh			; HL:DE = ("C_MULT"+1) * (2 ^ (C_MULT+2))
	
	ld a,(ix+5)
	and %00001111			; A = "READ_BL_LEN"
	jr z,mmc_nbls
	ld b,a
mmc_blsh	sla e
	rl d
	rl l
	rl h
	djnz mmc_blsh			; Cap (bytes) HL:DE = ("C_MULT"+1) * (2 ^ (C_MULT+2)) * (2^READ_BL_LEN)
	
	ld b,9				; convert number of bytes to numer of sectors
mmc_cbsec	srl h
	rr l
	rr d
	rr e
	djnz mmc_cbsec

mmc_nbls	push hl
	pop bc				; Return Capacity (number of sectors) in BC:DE
	ld hl,sector_buffer+$20		; Drive (hardware) name string at HL

	call mmc_spi_port_fast		; Use 8MHz SPI clock		
	xor a
	scf
	ret


;------------------------------------------------------------------------------------------

mmc_read_id_bytes

	ld b,16
mmc_csdlp	call mmc_get_byte
	ld (hl),a
	inc hl
	djnz mmc_csdlp
	call mmc_get_byte			; read CRC byte 1 
	call mmc_get_byte			; read CRC byte 2
	ret
	
;------------------------------------------------------------------------------------------
	
	
mmc_read_sector

;set c:de to sector number to read, 512 bytes returned in sector buffer

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
	jp nz,mmc_bcr_error			
	call mmc_wait_data_token		; wait for the data token
	or a
	jp nz,mmc_dt_timeout
	
	ld hl,sector_buffer			; optimized read sector code
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

;..................................................................................................	
;	ld hl,sector_buffer			; read 512 bytes into sector buffer - unoptimized
;	ld b,0
;mmc_rslp	call mmc_get_byte
;	ld (hl),a
;	inc hl
;	call mmc_get_byte
;	ld (hl),a
;	inc hl
;	djnz mmc_rslp
;	call mmc_get_byte			; read CRC byte 1
;	call mmc_get_byte			; read CRC byte 2
;...................................................................................................

	call mmc_deselect_card
	xor a
	scf
	ret
	
;---------------------------------------------------------------------------------------------

mmc_write_sector

;set c:de to sector number to write, 512 bytes written from sector buffer

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
	ld a,$58				; Send CMD24 write sector command
	ld b,$01				; A = $58 command byte, B = $01 dummy byte for CRC
	call mmc_send_command		
	call mmc_wait_ncr			; wait for valid response..	 
	or a				; command response should be $00
	jp nz,mmc_bcr_error			
	
	call mmc_send_eight_clocks		; wait 8 clocks before proceding	

	ld a,$fe
	call mmc_send_byte			; send $FE = packet header code

	ld hl,sector_buffer			; optimized write sector code
	ld c,sys_spi_port
	ld b,$00
mmc_owsl1	nop				; 4 cycles padding time
	outi				; 16 cycles, (HL)->(c), HL+1, B-1
	jp nz,mmc_owsl1			; 10 cycles
mmc_owsl2	nop				; 4 cycles padding time
	outi				; 16 cycles, (HL)->(c), HL+1, B-1
	jp nz,mmc_owsl2			; 10 cycles


;..............................................................................................	
;	ld hl,sector_buffer			; write out 512 bytes for sector -unoptimized
;	ld b,0
;mmc_wslp	ld a,(hl)
;	call mmc_send_byte
;	inc hl
;	ld a,(hl)
;	call mmc_send_byte
;	inc hl
;	djnz mmc_wslp
;.............................................................................................	
	
	call mmc_send_eight_clocks		; send dummy CRC byte 1 ($ff)
	call mmc_send_eight_clocks		; send dummy CRC byte 2 ($ff)
		
	call mmc_get_byte			; get packet response
	and $1f
	srl a
	cp $02
	jp nz,mmc_write_fail

	ld bc,50000			; read bytes until $ff is received
mmc_wcbsy	call mmc_get_byte			; until that time, card is busy
	cp $ff
	jr z,mmc_nbusy
	dec bc
	ld a,b
	or c
	jr nz,mmc_wcbsy
	jp mmc_card_busy_timeout	

mmc_nbusy	ld a,$4d				; Send CMD13: Check the status registers following the write
	ld bc,$0100			
	ld de,$0000
	call mmc_send_command
	call mmc_wait_ncr			; wait for valid response..	
	or a				; "R1" command response should be $00
	jp nz,mmc_write_fail
	call mmc_get_byte			; now get "R2" status code
	or a				; "R2" should also be $00
	jp nz,mmc_write_fail		
	call mmc_deselect_card		; sector write all OK
	xor a
	scf
	ret
	
;---------------------------------------------------------------------------------------------

mmc_send_command_null_args

	ld bc,$0100				
	ld de,$0000


mmc_send_command

; set A = command, C:DE for sector number, B for CRC

	push af				
	call mmc_send_eight_clocks		; send 8 clocks first - seems necessary for SD cards..
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

;---------------------------------------------------------------------------------------------

mmc_send_eight_clocks

	ld a,$ff
	call mmc_send_byte
	ret
	
;---------------------------------------------------------------------------------------------

mmc_init_fail

	ld a,mmc_error_bad_init
fail_ret	push af
	call mmc_deselect_card
	pop af
	or a
	ret

;---------------------------------------------------------------------------------------------

sdc_init_fail

	ld a,sdc_error_bad_init
	jr fail_ret
	
	
;---------------------------------------------------------------------------------------------

mmc_id_fail

	ld a,mmc_error_bad_id
	jr fail_ret

;----------------------------------------------------------------------------------------------

mmc_bcr_error

	ld a,mmc_error_bad_command_response
	jr fail_ret
	
;---------------------------------------------------------------------------------------------

mmc_dt_timeout

	ld a,mmc_error_data_token_timeout
	jr fail_ret

;----------------------------------------------------------------------------------------------

mmc_write_fail
	
	ld a,mmc_error_write_failed
	jr fail_ret

;----------------------------------------------------------------------------------------------

mmc_card_busy_timeout

	ld a,mmc_error_write_timeout
	jr fail_ret

;----------------------------------------------------------------------------------------------

mmc_vnchars	db " vx.x SN:00000000      ",0,0,0,0

mmc_sdc		db 0	; 0 = Card is MMC type, 1 = Card is SD type

;===============================================================================================











;---------------------------------------------------------------------------------------------
; VxZ80P Specific Hardware Level Routines v1.01
;---------------------------------------------------------------------------------------------

; Expansion port pins used for V5Z80P (compatible with integrated V6Z80P SDCard interface)

mmc_clock		equ 0	;FPGA output (no effect on V6Z80P - no signal assigned to this bit)
mmc_din		equ 1	;FPGA output (no effect on V6Z80P - ""                          "")
mmc_cs		equ 2	;FPGA output (active low)
mmc_power		equ 3	;FPGA output (active low)

;----------------------------------------------------------------------------------------------

mmc_send_byte

;Put byte to send to card in A

	out (sys_spi_port),a		; send byte to serializer
	
mmc_waitserend

	in a,(sys_hw_flags)			; wait for serialization to end
	bit 6,a
	jr nz,mmc_waitserend
	ret

	
;---------------------------------------------------------------------------------------------

mmc_get_byte

; Returns byte read from card in A

	ld a,$ff
	out (sys_spi_port),a		; send 8 clocks
	
	call mmc_waitserend

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
	
	ld a,%00010000			; switch off SPI port for now. Take direct control
	out (sys_sdcard_ctrl1),a		; of expansion pins		
	in a,(sys_sdcard_ctrl2)
	set mmc_power,a			; only want power control pin high to prevent
	res mmc_cs,a			; current leaking from inputs back around to
	res mmc_clock,a			; card power
	res mmc_din,a			
	out (sys_sdcard_ctrl2),a		
	ret
	

;----------------------------------------------------------------------------------------------

mmc_spi_port_slow

	ld a,%01000000			; (6) = 1 SPI mode, (7) = 0: 250Khz
mmc_setsp	out (sys_sdcard_ctrl1),a		; Forces expansion pins 0+1 = output, 4= input
	ret


mmc_spi_port_fast
	
	ld a,%11000000			; (6) = 1 SPI mode, (7) = 1: 8MHz
	jr mmc_setsp
	
;---------------------------------------------------------------------------------------------
	
mmc_wait_4ms

	push af
	call wait_4ms			; use timer routine in main body of FLOS code
	pop af
	ret

;===============================================================================================
