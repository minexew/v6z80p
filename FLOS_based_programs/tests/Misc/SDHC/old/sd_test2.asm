; SDHC test 2

;---Standard header for OSCA and FLOS ----------------------------------------

include "kernal_jump_table.asm"
include "osca_hardware_equates.asm"
include "system_equates.asm"

	org $5000
	
;-----------------------------------------------------------------------------


my_sector_buffer equ $7000


	call sd_initialize
	jr c,good
	
bad	ld hl,bad_txt
	call kjt_hex_byte_to_ascii
	ld hl,bad_txt
	call kjt_print_string
	xor a
	ret
	
	
good	push hl
	ld hl,cap_txt
	ld a,c
	call kjt_hex_byte_to_ascii
	push de
	ld a,d
	call kjt_hex_byte_to_ascii
	pop de
	ld a,e
	call kjt_hex_byte_to_ascii
	

	ld hl,ok_txt
	call kjt_print_string
	pop hl
	call kjt_print_string
	xor a
	ret
	

ok_txt	db "Init OK. Capacity $"
cap_txt	db "xxyyzz",11,"ID String:",11,0
bad_txt	db "00 <- Error",11,0

;-----------------------------------------------------------------------------


my_sector_lba0 	db 0
my_sector_lba1 	db 0
my_sector_lba2 	db 0
my_sector_lba3 	db 0

sd_card_info	db 0



;--------------------------------------------------------------------------------------------------
; Low level Z80 MMC/SDC/SDHC card access routines - Phil Ruston '08-'11
;--------------------------------------------------------------------------------------------------
;
; V1.10 - SDHC support added
;
; Limitations:
; ------------
; Does not check for block size
; Somewhat arbitrary timimg due to quirk of my SD interface ("D_out" not pulled up)


;--------------------------------------------------------------------------------------------------
; Key Routines:      Input Parameters             Output Registers
; -------------      ----------------             ----------------
; sd_initialize	no arguments required        	BC:DE = Capacity in sectors, HL = ID ASCII string
; sd_read_sector	[sector_lba0-3]		Carry Flag / A = error code
; sd_write_sector	[sector_lba0-3]    		Carry Flag / A = error code
;
; (Assume all other registers are trashed.)
;--------------------------------------------------------------------------------------------------

; Routines respond with Carry flag set if operation was OK, Otherwise A = Error code:

; $01 - SPI mode failed	 
; $10 - mmc init failed	
; $11 - sd init failed	
; $12 - sdhc init failed	
; $13 - voltage range bad	
; $14 - check pattern bad
; $20 - illegal command
; $21 - bad command response
; $22 - data token timeout
; $23 - write timeout
; $24 - write failed
;
;---------------------------------------------------------------------------------------------------
;
; Variables required:
; -------------------
;
; "my_sector_buffer" - 512 bytes
;
; "my_sector_lba0" 	 - LBA of desired sector LSB
; "my_sector_lba1" 
; "my_sector_lba2"
; "my_sector_lba3" 	 - LBA of desired sector MSB
;
; "sd_card_info"     -  Bit [4]    = CCS (block mode access) 
;                  	    Bits [3:0] = Card type: 0=MMC, 1=SD, 2=SDHC


;--------------------------------------------------------------------------------------------------
; SD Card INITIALIZE code begins...
;--------------------------------------------------------------------------------------------------

CMD1	equ $40 + 1
CMD9	equ $40 + 9
CMD10	equ $40 + 10
CMD13	equ $40 + 13
CMD17	equ $40 + 17
CMD24	equ $40 + 24
ACMD41	equ $40 + 41
CMD55	equ $40 + 55
CMD58	equ $40 + 58

sd_error_spi_mode_failed	equ $01

sd_error_mmc_init_failed	equ $10
sd_error_sd_init_failed	equ $11
sd_error_sdhc_init_failed	equ $12
sd_error_vrange_bad		equ $13
sd_error_check_pattern_bad	equ $14

sd_error_illegal_command	equ $20
sd_error_bad_command_response	equ $21
sd_error_data_token_timeout	equ $22
sd_error_write_timeout	equ $23
sd_error_write_failed	equ $24

;--------------------------------------------------------------------------------------------------

sd_initialize

	
	call sd_init_main
	jr c,sd_inok
	call sd_power_off			; if init failed shut down the SPI port
	ret

sd_inok	call sd_spi_port_fast		; on initializtion success -  switch to fast clock 

	call sd_read_cid			; and read CID/CSD
	jr nc,sd_done
	push hl
	call sd_read_csd
	pop hl

sd_done	call sd_deselect_card		; routines always deselect card on return
	ret


;--------------------------------------------------------------------------------------------------
		
sd_read_sector

	call sd_read_sector_main
	jr sd_done

;--------------------------------------------------------------------------------------------------
	
sd_write_sector

	call sd_write_sector_main
	jr sd_done
	
;--------------------------------------------------------------------------------------------------
	

sd_init_main

	xor a				; Clear card info start
	ld (sd_card_info),a			

	call sd_power_off			; Switch off power to the card (SPI clock slow, /CS is low but should be irrelevent)
	
	ld b,128				; wait approx 0.5 seconds
sd_powod	call sd_wait_4ms
	djnz sd_powod			
		
	call sd_power_on			; Switch card power back on (SPI clock slow, /CS high - de-selected)
		
	ld b,10				; send 80 clocks to ensure card has stabilized
sd_ecilp	call sd_send_eight_clocks
	djnz sd_ecilp
	
	ld hl,CMD0_string			; Send Reset Command CMD0 ($40,$00,$00,$00,$00,$95)
	call sd_send_command_string		; (When /CS is low on receipt of CMD0, card enters SPI mode) 
	cp $01				; Command Response should be $01 ("In idle mode")
	jr z,sd_spi_mode_ok
	
	ld a,sd_error_spi_mode_failed
	or a
	ret		


; ---- CARD IS IN IDLE MODE -----------------------------------------------------------------------------------


sd_spi_mode_ok


	ld hl,CMD8_string			; send CMD8 ($48,$00,$00,$01,$aa,$87) to test for SDHC card
	call sd_send_command_string
	cp $01
	jr nz,sd_sdc_init			; if R1 response is not $01: illegal command: not an SDHC card

	ld b,4
	call sd_read_bytes_to_sector_buffer	; get r7 response (4 bytes)
	ld a,1
	inc hl
	inc hl
	cp (hl)				; we need $01,$aa in response bytes 2 and 3  
	jr z,sd_vrok
	ld a,sd_error_vrange_bad
	or a
	ret				

sd_vrok	ld a,$aa
	inc hl
	cp (hl)
	jr z,sd_check_pattern_ok
	ld a,sd_error_check_pattern_bad
	or a
	ret
	
sd_check_pattern_ok


;------ SDHC CARD CAN WORK AT 2.7v - 3.6v ----------------------------------------------------------------------
	

	ld bc,8000			; Send SDHC card init

sdhc_iwl	ld a,CMD55			; First send CMD55 ($77 00 00 00 00 01) 
	call sd_send_command_null_args
	
	ld hl,ACMD41HCS_string		; Now send ACMD41 with HCS bit set ($69 $40 $00 $00 $00 $01)
	call sd_send_command_string
	jr z,sdhc_init_ok			; when response is $00, card is ready for use	
	bit 2,a
	jr nz,sdhc_if			; if Command Response = "Illegal command", quit
	
	dec bc
	ld a,b
	or c
	jr nz,sdhc_iwl
	
sdhc_if	ld a,sd_error_sdhc_init_failed	; if $00 isn't received, fail
	or a
	ret
	
sdhc_init_ok


;------ SDHC CARD IS INITIALIZED --------------------------------------------------------------------------------------

	
	ld a,CMD58			; send CMD58 - read OCR
	call sd_send_command_null_args
		
	ld b,4				; read in OCR
	call sd_read_bytes_to_sector_buffer
	ld a,(hl)
	and $40				; test CCS bit
	rrca
	rrca 
	or %00000010				
	ld (sd_card_info),a			; bit4: Block mode access, bit 0:3 card type (0:MMC,1:SD,2:SDHC)
	scf				; carry flag set: all OK
	ret

	
;-------- NOT AN SDHC CARD, TRY SD INIT ---------------------------------------------------------------------------------

sd_sdc_init

	ld bc,8000			; Send SD card init

sd_iwl	ld a,CMD55			; First send CMD55 ($77 00 00 00 00 01) 
	call sd_send_command_null_args

	ld a,ACMD41			; Now send ACMD41 ($69 00 00 00 00 01)
	call sd_send_command_null_args
	jr z,sd_rdy			; when response is $00, card is ready for use
	
	bit 2,a				
	jr nz,sd_mmc_init			; check command response bit 2, if set = illegal command - try MMC init
				
	dec bc
	ld a,b
	or c
	jr nz,sd_iwl
	
	ld a,sd_error_sd_init_failed		; if $00 isn't received, fail
	or a
	ret
	
sd_rdy	ld a,1
	ld (sd_card_info),a			; set card type to 1:SD (byte access mode)
	scf				; carry flag set: all ok	
	ret	


;-------- NOT AN SDHC OR SD CARD, TRY MMC INIT ---------------------------------------------------------------------------


sd_mmc_init

	ld bc,8000			; Send MMC card init and wait for card to initialize

sdmmc_iwl	ld a,CMD1
	call sd_send_command_null_args	; send CMD1 ($41 00 00 00 00 01) 
	jr nz,sd_mnrdy			; If ZF set, command response = 00: Ready,. Card type is default MMC (byte access mode)
	scf				; carry flag set: all ok	
	ret

sd_mnrdy	dec bc
	ld a,b
	or c
	jr nz,sdmmc_iwl
	
	ld a,sd_error_mmc_init_failed		; if $00 isn't received, fail	
	or a
	ret
	

;-----------------------------------------------------------------------------------------------------------------

; Returns BC:DE = Total capacity of card (in sectors)


sd_read_csd
	
	ld a,CMD9				; send "read CSD" command: 49 00 00 00 00 01 to read card info
	call sd_send_command_null_args
	jp nz,sd_bcr_error			; ZF set if command response = 00

	call sd_wait_data_token		; wait for the data token
	jp nz,sd_dt_timeout	

sd_id_ok	ld b,18				; read the card info to sector buffer (16 bytes + 2 CRC)
	call sd_read_bytes_to_sector_buffer	

	ld ix,my_sector_buffer		; compute card's capacity
	bit 6,(ix)
	jr z,sd_csd_v1

sd_csd_v2	ld l,(ix+9)			; for CSD v2.00
	ld h,(ix+8)
	inc hl
	ld a,10
	ld bc,0
sd_csd2lp	add hl,hl
	rl c
	rl b
	dec a
	jr nz,sd_csd2lp
	ex de,hl				; Return Capacity (number of sectors) in BC:DE
	scf
	ret
	
sd_csd_v1	ld a,(ix+6)			; For CSD v1.00
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
sd_cmsh	sla e
	rl d
	rl l
	rl h
	djnz sd_cmsh			; HL:DE = ("C_MULT"+1) * (2 ^ (C_MULT+2))
	
	ld a,(ix+5)
	and %00001111			; A = "READ_BL_LEN"
	jr z,sd_nbls
	ld b,a
sd_blsh	sla e
	rl d
	rl l
	rl h
	djnz sd_blsh			; Cap (bytes) HL:DE = ("C_MULT"+1) * (2 ^ (C_MULT+2)) * (2^READ_BL_LEN)
	
	ld b,9				; convert number of bytes to numer of sectors
sd_cbsec	srl h
	rr l
	rr d
	rr e
	djnz sd_cbsec

sd_nbls	push hl
	pop bc				; Return Capacity (number of sectors) in BC:DE
	scf
	ret


;----------------------------------------------------------------------------------------------------------------------

sd_read_cid
	
; Returns HL = Pointer to device ID string


	ld a,CMD10			; send "read CID" $4a 00 00 00 00 00 command for more card data
	call sd_send_command_null_args
	jp nz,sd_bcr_error			; ZF set if command response = 00	

	call sd_wait_data_token		; wait for the data token
	jp nz,sd_dt_timeout
		
	ld b,18
	call sd_read_bytes_to_sector_buffer	; read 16 bytes + 2 CRC
	
	ld hl,my_sector_buffer+$03		; Build name / version / serial number of card as ASCII string
	ld de,my_sector_buffer+$20
	ld bc,5
	ld a,(sd_card_info)
	and $f
	jr nz,sd_cn5
	inc bc
sd_cn5	ldir
	push hl
	push de
	ld hl,sd_vnchars
	ld bc,20
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
sd_snulp	ld a,(hl)				; put in 32 bit serial number
	srl a
	srl a
	srl a
	srl a
	add a,$30
	cp $3a
	jr c,sd_hvl1
	add a,$7
sd_hvl1	ld (de),a
	inc de
	ld a,(hl)
	and $f
	add a,$30
	cp $3a
	jr c,sd_hvl2
	add a,$7
sd_hvl2	ld (de),a
	inc de
	inc hl
	djnz sd_snulp
	
	ld hl,my_sector_buffer+$20		; Drive (hardware) name string at HL
	scf
	ret


;--------------------------------------------------------------------------------------------------
; SD Card READ SECTOR code begins...
;--------------------------------------------------------------------------------------------------
	
sd_read_sector_main

; 512 bytes are returned in sector buffer

	call sd_set_sector_addr

	ld a,CMD17			; Send CMD17 read sector command		
	call sd_send_command_current_args
	jr z,sd_rscr_ok			; if ZF set command response is $00	

sd_bcr_error

	ld a,sd_error_bad_command_response
	or a				; carry clear = error!
	ret

sd_rscr_ok
	
	call sd_wait_data_token		; wait for the data token
	jr z,sd_dt_ok			; ZF set if data token reeceived
	
	
sd_dt_timeout

	ld a,sd_error_data_token_timeout
	or a				; carry clear = error!
	ret
	
	
sd_dt_ok	ld hl,my_sector_buffer		; optimized read sector code
	ld c,sys_spi_port
	ld b,0
	ld a,$ff
	out (sys_spi_port),a		; send read clocks for first byte
	nop
	nop
	nop
sd_orsl1	nop				; 4 cycles
	ini				; 16 cycles (c)->(HL), HL+1, B1-1
	out (sys_spi_port),a		; 11 cycles - read clocks (requires 16 cycles)
	jp nz,sd_orsl1			; 10 cycles
sd_orsl2	nop				; 4 cycles
	ini				; 16 cycles (c)->(HL), HL+1, B1-1
	out (sys_spi_port),a		; 11 cycles - read clocks (requires 16 cycles)
	jp nz,sd_orsl2			; 10 cycles
	nop				; allow the 'extra' read clocks to end (cyc byte 1)
	nop
	out (sys_spi_port),a		; 8 more clocks (skip crc byte 2)
	nop
	nop
	nop
	nop

;..................................................................................................	
;	ld b,0				; unoptimized sector read
;	call sd_read_bytes_to_sector_buffer
;	inc h
;	ld b,0
;	call read_bytes
;	call sd_get_byte			; read CRC byte 1
;	call sd_get_byte			; read CRC byte 2
;...................................................................................................

	scf				; carry set: all ok
	ret


;--------------------------------------------------------------------------------------------------
; SD Card WRITE SECTOR code begins...
;--------------------------------------------------------------------------------------------------


sd_write_sector_main
	
	call sd_set_sector_addr

	ld a,CMD24			; Send CMD24 write sector command
	call sd_send_command_current_args		
	jr nz,sd_bcr_error			; if ZF set, command response is $00	
	
	call sd_send_eight_clocks		; wait 8 clocks before proceding	

	ld a,$fe
	call sd_send_byte			; send $FE = packet header code

	ld hl,my_sector_buffer		; optimized write sector code
	ld c,sys_spi_port
	ld b,$00
sd_owsl1	nop				; 4 cycles padding time
	outi				; 16 cycles, (HL)->(c), HL+1, B-1
	jp nz,sd_owsl1			; 10 cycles
sd_owsl2	nop				; 4 cycles padding time
	outi				; 16 cycles, (HL)->(c), HL+1, B-1
	jp nz,sd_owsl2			; 10 cycles


;..............................................................................................	
;	ld hl,my_sector_buffer			; write out 512 bytes for sector -unoptimized
;	ld b,0
;sd_wslp	ld a,(hl)
;	call sd_send_byte
;	inc hl
;	ld a,(hl)
;	call sd_send_byte
;	inc hl
;	djnz sd_wslp
;.............................................................................................	
	
	call sd_send_eight_clocks		; send dummy CRC byte 1 ($ff)
	call sd_send_eight_clocks		; send dummy CRC byte 2 ($ff)
		
	call sd_get_byte			; get packet response
	and $1f
	srl a
	cp $02
	jr nz,sd_wr_ok

sd_write_fail
	
	ld a,sd_error_write_failed
	or a				; carry clear = error!
	ret

sd_wr_ok	ld bc,50000			; read bytes until $ff is received
sd_wcbsy	call sd_get_byte			; until that time, card is busy
	cp $ff
	jr nz,sd_busy
	scf				; carry set = all OK
	ret
	
sd_busy	dec bc
	ld a,b
	or c
	jr nz,sd_wcbsy

sd_card_busy_timeout

	ld a,sd_error_write_timeout
	or a				;carry clear = error!
	ret	

;---------------------------------------------------------------------------------------------


sd_set_sector_addr

	ld bc,(my_sector_lba2)
	ld hl,(my_sector_lba0)		; sector LBA BC:HL -> B,D,E,C
	ld d,c
	ld e,h
	ld c,l
	ld a,(sd_card_info)
	and $10
	jr nz,lbatoargs			; if SDHC card, we use direct sector access
	
	ld a,(my_sector_lba2)		; otherwise need to multiply by 512
	add hl,hl
	adc a,a	
	ex de,hl
	ld b,a
	ld c,0
lbatoargs	ld hl,cmd_generic_args
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

	ld b,0				
sd_wdt	call sd_get_byte			; read until data token ($FE) arrives, ZF set if received
	cp $fe
	ret z
	djnz sd_wdt
	inc b				; didn't get a data token, ZF not set
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



sd_send_command_string

; set HL = location of 6 byte command string
; returns command response in A (ZF set if $00)


	call sd_select_card			; send command always enables card select
			
	call sd_send_eight_clocks		; send 8 clocks first - seems necessary for SD cards..
	
	push bc
	ld b,6
sd_sclp	ld a,(hl)
	call sd_send_byte			; command byte
	inc hl
	djnz sd_sclp
	pop bc
	
	call sd_get_byte			; skip first byte of nCR, a quirk of my SD card interface?
		

sd_wait_valid_response
	
	push bc
	ld b,0
sd_wncrl	call sd_get_byte			; read until Command Response from card 
	bit 7,a				; If bit 7 = 0, it's a valid response
	jr z,sd_gcr
	djnz sd_wncrl
					
sd_gcr	or a				; zero flag set if Command response = 00
	pop bc
	ret
	
	
;-----------------------------------------------------------------------------------------------

sd_read_bytes_to_sector_buffer

	ld hl,my_sector_buffer
	
sd_read_bytes

; set HL to dest address for data
; set B to number of bytes required  

	push hl
sd_rblp	call sd_get_byte
	ld (hl),a
	inc hl
	djnz sd_rblp
	pop hl
	ret
	
;-----------------------------------------------------------------------------------------------

cmd_generic	db $00
cmd_generic_args	db $00,$00,$00,$00
cmd_generic_crc	db $01

CMD0_string	db $40,$00,$00,$00,$00,$95
CMD8_string	db $48,$00,$00,$01,$aa,$87
ACMD41HCS_string	db $69,$40,$00,$00,$00,$01

sd_vnchars	db " vx.x SN:00000000 ",0,0

;===============================================================================================











;---------------------------------------------------------------------------------------------
; V6Z80P Specific Hardware Level Routines v1.10
;---------------------------------------------------------------------------------------------

sd_cs		equ 2	;FPGA output (active low)
sd_power		equ 3	;FPGA output (active low)

;----------------------------------------------------------------------------------------------

sd_send_byte

;Put byte to send to card in A

	out (sys_spi_port),a		; send byte to serializer
	
sd_waitserend

	in a,(sys_hw_flags)			; wait for serialization to end
	bit 6,a
	jr nz,sd_waitserend
	ret

	
;---------------------------------------------------------------------------------------------

sd_get_byte

; Returns byte read from card in A

	ld a,$ff
	out (sys_spi_port),a		; send 8 clocks
	
	call sd_waitserend

	in a,(sys_spi_port)			; read the contents of the shift register
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
	ld a,$ff				; send 8 clocks to make card de-assert its Dout line
	call sd_send_byte
	pop af
	ret
	
;---------------------------------------------------------------------------------------------


sd_power_on

	push af
	in a,(sys_sdcard_ctrl2)		
	res sd_power,a			; pull power control low: Active - SD card powered up
	set sd_cs,a			; card deselected by default at power on
	out (sys_sdcard_ctrl2),a
	
	ld a,%01000000			; (6) = 1 FPGA Output enabled, (7) = 0: 250Khz SPI clock
sd_setsp	out (sys_sdcard_ctrl1),a		
	pop af
	ret
	
	
	
sd_power_off
	
	push af
	in a,(sys_sdcard_ctrl2)
	set sd_power,a			; set power control hi: inactive - no power to SD
	res sd_cs,a			; ensure /CS is low	- no power to this pin		; 			
	out (sys_sdcard_ctrl2),a		
	xor a
	jr sd_setsp			; disable FPGA SPI data output too



sd_spi_port_fast
	
	push af
	ld a,%11000000			; (6) = 1 FPGA Output enabled, (7) = 1: 8MHz SPI clock
	jr sd_setsp


;---------------------------------------------------------------------------------------------







;===============================================================================================


	
sd_wait_4ms

	push af
	call wait_4ms			; use timer routine in main body of FLOS code
	pop af
	ret


wait_4ms	xor a

os_timer_wait

; set a = number of 16 microsecond periods to wait

	neg 			;timer counts up, so invert value
	out (sys_timer),a		
	ld a,%00000100
	out (sys_clear_irq_flags),a	;clear timer overflow flag
twait	in a,(sys_irq_ps2_flags)	;wait for overflow flag to become set
	bit 2,a			
	jr z,twait
	ret	

;===============================================================================================


