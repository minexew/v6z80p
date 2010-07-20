;--------------------------------------------------------------------------------------------------
; SIMPLIFIED MMC/SD CARD ROUTINES
;--------------------------------------------------------------------------------------------------

mmc_cs		equ 2	;FPGA output (active low)
mmc_power		equ 3	;FPGA output (active low)

;----------------------------------------------------------------------------------------------

mmc_init_card

; Initializes card. Returns: Carry = 1 if initialized OK


	ld a,1				; Assume card is SD type at start
	ld (mmc_sdc),a			

	call mmc_power_off			; Switch off power to the card
	
	ld b,128				; wait approx 0.5 seconds
mmc_powod	call pause_4ms
	djnz mmc_powod			
		
	call mmc_power_on			; Switch card power back on

	call mmc_spi_port_slow

	call pause_4ms			; Short delay

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
	
	
;----------------------------------------------------------------------------------------------
