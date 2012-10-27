; SDHC test 1

;---Standard header for OSCA and FLOS ----------------------------------------

include "kernal_jump_table.asm"
include "osca_hardware_equates.asm"
include "system_equates.asm"

	org $5000
	
;-----------------------------------------------------------------------------


my_sector_buffer equ $7000


	call sd_initialize
	jr nc,bad
	call sd_get_id
	jr c,good
	
bad	ld hl,bad_txt
	call kjt_hex_byte_to_ascii
	ld hl,bad_txt
	call kjt_print_string
	xor a
	ret
	
	
good	push hl
	ld hl,ok_txt
	call kjt_print_string
	pop hl
	call kjt_print_string
	xor a
	ret
	

ok_txt	db "All OK. ID String:",11,0

bad_txt	db "00 <- Error",11,0

hello_txt	db 11,11,"*** Made it this far ***",11,11,0

getid_txt	db 11,11,"Getting ID",11,11,0

;-----------------------------------------------------------------------------


my_sector_lba0 	db 0
my_sector_lba1 	db 0
my_sector_lba2 	db 0
my_sector_lba3 	db 0

sd_card_info	db 0



;--------------------------------------------------------------------------------------------------
; Low level Z80 MMC/SDC card access routines - Phil Ruston '08-'11
;--------------------------------------------------------------------------------------------------
;
; V1.10 - SDHC support added
;
; Limitations:
; ------------
; Does not check for  block size
; Somewhat arbitary timimg..
;
;--------------------------------------------------------------------------------------------------

; Key Routines:      Input Registers             Output Registers
; -------------      ---------------             ----------------
; mmc_get_id	no arguments required        	BC:DE = Capacity in sectors, HL = ID ASCII string, A = error code
; mmc_read_sector	my_sector_lba0-3		Carry Flag / A = error code
; mmc_write_sector	my_sector_lba0-3    	Carry Flag / A = error code
;
; (Assume all other registers are trashed.)
;
; Routines respond with Carry flag set if operation was OK, else A =

sd_error_spi_mode_failed		equ $01

sd_error_mmc_init_failed		equ $10
sd_error_sd_init_failed		equ $11
sd_error_sdhc_init_failed		equ $12

sd_error_vrange_bad			equ $20
sd_error_check_pattern_bad		equ $21
sd_error_illegal_command		equ $22
mmc_error_bad_command_response	equ $23
mmc_error_data_token_timeout		equ $24
mmc_error_write_timeout		equ $25
mmc_error_write_failed		equ $26
sd_error_id_failed			equ $27


CMD1	equ $40 + 1
CMD9	equ $40 + 9
CMD10	equ $40 + 10
ACMD41	equ $40 + 41
CMD55	equ $40 + 55
CMD58	equ $40 + 58



; Variables required:
; -------------------
;
; "my_sector_buffer" - 512 bytes
;
; "my_sector_lba0" - LBA of desired sector LSB
; "my_sector_lba1" 
; "my_sector_lba2"
; "my_sector_lba3" - LBA of desired sector MSB
;
; "sd_card_info" - Bit [4]    = CCS (block mode access) 
;                  Bits [3:0] = Card type: 0=MMC, 1=SD, 2=SDHC


;--------------------------------------------------------------------------------------------------

sd_initialize

	
	call sd_init_main
	jr c,sd_inok
	call mmc_power_off			; if init failed shut down the SPI port
	ret

sd_inok	call mmc_spi_port_fast		; on initializtion success -  switch to fast clock 
sd_done	call sd_deselect_card
	ret
	
	
		
sd_init_main

	xor a				; Clear card info start
	ld (sd_card_info),a			

	call mmc_power_off			; Switch off power to the card (SPI clock slow, /CS is low but should be irrelevent)
	
	ld b,128				; wait approx 0.5 seconds
mmc_powod	call mmc_wait_4ms
	djnz mmc_powod			
		
	call mmc_power_on			; Switch card power back on (SPI clock slow, /CS high - de-selected)
		
	ld b,10				; send 80 clocks to ensure card has stabilized
mmc_ecilp	call mmc_send_eight_clocks
	djnz mmc_ecilp
	
	call sd_select_card			; Set Card's /CS line active (low)
	
	ld hl,CMD0_string			; Send Reset Command CMD0 ($40,$00,$00,$00,$00,$95)
	call sd_send_command_string		; When /CS is low on receipt of CMD0, card enters SPI mode 
	call mmc_get_byte			; skip nCR
	call mmc_wait_ncr			; wait for valid response..			
	cp $01				; command response should be $01 ("In idle mode")
	jr z,sd_spi_mode_ok
	
	ld a,sd_error_spi_mode_failed
	or a
	ret		


; ---- CARD IS IN IDLE MODE -----------------------------------------------------------------------------------


sd_spi_mode_ok


	ld hl,CMD8_string			; send CMD8 ($48,$00,$00,$01,$aa,$87) to test for SDHC card
	call sd_send_command_string
	call mmc_get_byte
	call mmc_wait_ncr
	cp $01
	jr nz,sd_sdc_init			; r1 response, if not $01: illegal command: not an SDHC card

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
sdhc_iwl	push bc				
	ld a,CMD55			; First send CMD55 ($77 00 00 00 00 01) 
	call sd_send_command_null_args
	call mmc_get_byte			; nCR
	call mmc_get_byte			; R1 Command response
	
	ld hl,ACMD41HCS_string		; Now send ACMD41 with HCS bit set ($69 $40 $00 $00 $00 $01)
	call sd_send_command_string
	call mmc_get_byte			; nCR

	pop bc
	call mmc_wait_ncr			; wait for valid response..	
	bit 2,a				; check bit 2, if set = illegal command
	jp nz,sd_error_illegal_command			
	or a
	jr z,sdhc_init_ok			; when response is $00, card is ready for use
	dec bc
	ld a,b
	or c
	jr nz,sdhc_iwl
	
	ld a,sd_error_sdhc_init_failed
	or a
	ret
	
sdhc_init_ok


;------ SDHC CARD IS INITIALIZED --------------------------------------------------------------------------------------

	
	ld a,CMD58			; send CMD58 - read OCR
	call sd_send_command_null_args
	call mmc_get_byte			; nCR
	
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

	
;-------- NOT AN SDHC CARD ----------------------------------------------------------------------------------------------

sd_sdc_init

	ld hl,hello_txt
	call kjt_print_string


	ld bc,8000			; Send SD card init
sd_iwl	push bc				
	ld a,CMD55			; First send CMD55 ($77 00 00 00 00 01) 
	call sd_send_command_null_args
	call mmc_get_byte			; nCR
	call mmc_get_byte			; Command response
	
	ld a,ACMD41			; Now send ACMD41 ($69 00 00 00 00 01)
	call sd_send_command_null_args
	call mmc_get_byte			; nCR

	pop bc
	call mmc_wait_ncr			; wait for valid response..	
	bit 2,a				
	jr nz,sd_mmc_init			; check bit 2, if set = illegal command - try MMC init
	or a
	jr nz,sd_nrdy			; when response is $00, card is ready for use
	ld a,1
	ld (sd_card_info),a			; set card type to 1:SD (byte access mode)
	scf				; carry flag set: all ok	
	ret
	
sd_nrdy	dec bc
	ld a,b
	or c
	jr nz,sd_iwl
	
	ld a,sd_error_sd_init_failed
	or a
	ret
	

;-------- NOT AN SDHC OR SD CARD ---------------------------------------------------------------------------------


sd_mmc_init

	ld hl,hello_txt
	call kjt_print_string


	ld bc,8000			; Send MMC card init and wait for card to initialize
mmc_iwl	push bc
	ld a,CMD1
	call sd_send_command_null_args	; send CMD1 ($41 00 00 00 00 01) 
	pop bc
	call mmc_wait_ncr			; wait for valid response..	
	or a				; command response is $00 when card is ready for use
	jr nz,mmc_nrdy			; Return if ready, card type is default MMC (byte access mode)
	scf				; carry flag set: all ok	
	ret
mmc_nrdy	dec bc
	ld a,b
	or c
	jr nz,mmc_iwl
	
	ld a,sd_error_mmc_init_failed
	or a
	ret
	

;-----------------------------------------------------------------------------------------------------------------

sd_get_id

; reads CSD and CID into sector buffer and creates string containing ASCII device ID.
; and returns device capacity (number of 512 byte sectors) 

; Return registers
; ----------------
;   HL = Pointer to device ID string 
; C:DE = Capacity (number of sectors)

	ld hl,getid_txt
	call kjt_print_string

	call sd_select_card
	call sd_id_main
	jp sd_done
	

sd_id_fail

	ld a,sd_error_id_failed
	or a
	ret
	
		
sd_id_main
	
	ld a,CMD9				; send "read CSD" command: 49 00 00 00 00 01 to read card info
	call sd_send_command_null_args
	call mmc_wait_ncr			; wait for valid response..	 
	or a				; command response should be $00
	jr nz,sd_id_fail
	call mmc_wait_data_token		; wait for the data token
	or a
	jr nz,sd_id_fail
	ld b,18				; read the card info to sector buffer (16 bytes + 2 CRC)
	call sd_read_bytes_to_sector_buffer	

	ld a,CMD10			; send "read CID" $4a 00 00 00 00 00 command for more card data
	call sd_send_command_null_args
	call mmc_wait_ncr			; wait for valid response..	 
	or a				; command response should be $00
	jr nz,sd_id_fail
	call mmc_wait_data_token		; wait for the data token
	or a
	jr nz,sd_id_fail
	ld hl,my_sector_buffer+16		
	ld b,18
	call sd_read_bytes			; read to sector buffer + 16 (16 bytes + 2 CRC)

	
	ld hl,my_sector_buffer+$13		; Build name / version / serial number of card as ASCII string
	ld de,my_sector_buffer+$20
	ld bc,5
	ld a,(sd_card_info)
	and $f
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
	
	

	ld ix,my_sector_buffer			; compute card's capacity
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
	
	ld hl,my_sector_buffer+$20		; Drive (hardware) name string at HL

	xor a
	scf
	ret


;------------------------------------------------------------------------------------------
	
	
mmc_read_sector

;set c:de to sector number to read, 512 bytes returned in sector buffer

	call sd_select_card

	ld hl,my_sector_lba0
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
	
	ld hl,my_sector_buffer			; optimized read sector code
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
;	ld hl,my_sector_buffer			; read 512 bytes into sector buffer - unoptimized
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

	call sd_deselect_card
	xor a
	scf
	ret
	
;---------------------------------------------------------------------------------------------

mmc_write_sector

;set c:de to sector number to write, 512 bytes written from sector buffer

	call sd_select_card

	ld hl,my_sector_lba0
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

	ld hl,my_sector_buffer			; optimized write sector code
	ld c,sys_spi_port
	ld b,$00
mmc_owsl1	nop				; 4 cycles padding time
	outi				; 16 cycles, (HL)->(c), HL+1, B-1
	jp nz,mmc_owsl1			; 10 cycles
mmc_owsl2	nop				; 4 cycles padding time
	outi				; 16 cycles, (HL)->(c), HL+1, B-1
	jp nz,mmc_owsl2			; 10 cycles


;..............................................................................................	
;	ld hl,my_sector_buffer			; write out 512 bytes for sector -unoptimized
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
	call sd_deselect_card		; sector write all OK
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
	
;----------------------------------------------------------------------------------------------

mmc_bcr_error

	ld a,mmc_error_bad_command_response
	or a
	ret
	
;---------------------------------------------------------------------------------------------

mmc_dt_timeout

	ld a,mmc_error_data_token_timeout
	or a
	ret

;----------------------------------------------------------------------------------------------

mmc_write_fail
	
	ld a,mmc_error_write_failed
	or a
	ret

;----------------------------------------------------------------------------------------------

mmc_card_busy_timeout

	ld a,mmc_error_write_timeout
	or a
	ret

;----------------------------------------------------------------------------------------------

mmc_vnchars	db " vx.x SN:00000000      ",0,0,0,0

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

sd_select_card

	push af
	in a,(sys_sdcard_ctrl2)
	res mmc_cs,a
	out (sys_sdcard_ctrl2),a
	pop af
	ret
	
sd_deselect_card

	push af
	in a,(sys_sdcard_ctrl2)
	set mmc_cs,a
	out (sys_sdcard_ctrl2),a
	ld a,$ff				; send 8 clocks to make card de-assert its Dout line
	call mmc_send_byte
	pop af
	ret
	
;---------------------------------------------------------------------------------------------

mmc_power_on

	push af
	in a,(sys_sdcard_ctrl2)		
	res mmc_power,a			; pull power control low: Active - SD card powered up
	set mmc_cs,a			; card deselected by default at power on
	out (sys_sdcard_ctrl2),a
	
	ld a,%01000000			; (6) = 1 FPGA Output enabled, (7) = 0: 250Khz SPI clock
mmc_setsp	out (sys_sdcard_ctrl1),a		
	pop af
	ret
	
	
	
mmc_power_off
	
	push af
	in a,(sys_sdcard_ctrl2)
	set mmc_power,a			; set power control hi: inactive - no power to SD
	res mmc_cs,a			; ensure /CS is low	- no power to this pin		; 			
	out (sys_sdcard_ctrl2),a		
	xor a
	jr mmc_setsp			; disable FPGA SPI data output too



mmc_spi_port_fast
	
	push af
	ld a,%11000000			; (6) = 1 FPGA Output enabled, (7) = 1: 8MHz SPI clock
	jr mmc_setsp
	
;---------------------------------------------------------------------------------------------
	
mmc_wait_4ms

	push af
	call wait_4ms			; use timer routine in main body of FLOS code
	pop af
	ret

;===============================================================================================

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

; new stuff

sd_send_command_null_args

	ld hl,CMD_generic
	ld (hl),a


sd_send_command_string

; set HL = location of 6 byte command string

		
	call mmc_send_eight_clocks		; send 8 clocks first - seems necessary for SD cards..

	ld b,6
sd_sclp	ld a,(hl)
	call mmc_send_byte			; command byte
	inc hl
	djnz sd_sclp
	ret
	

;-----------------------------------------------------------------------------------------------

sd_read_bytes_to_sector_buffer

	ld hl,my_sector_buffer
	
sd_read_bytes

; set HL to dest address for data
; set B to number of bytes required  

	push hl
sd_rblp	call mmc_get_byte
	ld (hl),a
	inc hl
	djnz sd_rblp
	pop hl
	ret
	
;-----------------------------------------------------------------------------------------------

CMD_generic	db $00,$00,$00,$00,$00,$01

CMD0_string	db $40,$00,$00,$00,$00,$95
CMD8_string	db $48,$00,$00,$01,$aa,$87
ACMD41HCS_string	db $69,$40,$00,$00,$00,$01

;-----------------------------------------------------------------------------------------------
