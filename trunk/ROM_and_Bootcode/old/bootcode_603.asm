;-------------------------------------------------------------------------------------------------
; OSCA Boot code v6.03
;------------------------------------------------------------------------------------------------
;
; These 2046 bytes of code (+CRC word) are downloaded from the FPGA config EEPROM into RAM at
; $800-$fff by the Z80 ROM code in the FPGA, then executed. This boot code initializes the
; keyboard and loads an operating system from MMC/SC card, EEPROM or via serial download
; using the PC Serial Link app. If F1,F2 is F3 is pressed the FPGA will reconfigure from slot
; 1,2,3 respectively.
;
;-------------------------------------------------------------------------------------------------

include "OSCA_hardware_equates.asm"
include "system_equates.asm"

;--------------------------------------------------------------------------------------------------
	org bootcode_location
;--------------------------------------------------------------------------------------------------


	ld a,%00000111
	out (sys_clear_irq_flags),a		; clear all irqs at start
	ld a,%00000001
	out (sys_mem_select),a		; upper bank bits = 001
	
	ld hl,$0fff
	ld (palette+2),hl			; Text colour = white
	
	ld hl,welcome_txt			; Power-on text
	rst $10				; Print string

	rst $08				; Get hardware version
	rst $10				; Print string
	
	call reset_keyboard			; Reset the keyboard - scancode set 2 etc.
	jr nc,keyb_ok			; if carry flag is set there's a keyboard error
	ld hl,kb_error_txt			; advise of keyboard error
	rst $10

;-------------------------------------------------------------------------------------------------------
	
keyb_ok	ld hl,scanning_txt		
	rst $10				; Show "Looking For OS" text

	
;---------Abort drive OS boot? -------------------------------------------------------------------------

	call pause_1_second			; allow user time to press ESC before checking drives

	in a,(sys_irq_ps2_flags)		; keyboard irq?
	bit 0,a				
	jr z,go_drive_boot	
	in a,(sys_keyboard_data)			 
	ld b,1
	cp $05				; F1 pressed? Set reconfig base to slot 1 and restart
	jr z,go_cfg1
	cp $06				; F2 pressed? Set reconfig base to slot 2 and restart
	jr z,go_cfg2
	cp $04				; F3 pressed? Set reconfig base to slot 3 and restart
	jr z,go_cfg3			
	cp $76				; If ESC key was pressed skip drive-based OS boot		
	jr nz,go_drive_boot			; and boot from serial port download instead
	ld hl,skipped_txt
	rst $10
	jp serial_boot	

go_cfg3	inc b	
go_cfg2	inc b
go_cfg1	ld a,b
	sla a
	ld (cfg_msb),a
	ld hl,reconfig_sequence		; tell PIC to set reconfig base (not permanently) and restart
	ld b,7
cfg_dlp	ld a,(hl)
	call send_byte_to_pic
	inc hl
	djnz cfg_dlp
	
	call pause_1_second			; the FPGA should have restarted by this point

go_drive_boot


;-------- Check for MMC/SD Card ------------------------------------------------------------------------

	call mmc_init_card			; Is there an SD/MMC card attached?
	jr nc,no_mmc_card			; carry is set if initialized OK	
	
	ld hl,drives_present
	set 2,(hl)			; Set bit 2 - SD card present
	
	call mmc_read_sector		; Is there an OS on this card?
	jr nc,no_mmc_card			; If carry not set = hardware error
	call check_os_sector
	jr nz,no_mmc_card
	ld a,3
	ld (boot_drive),a			; Mark card as boot device (type 3)
	ld hl,(OS_location+8)
	ld (os_size),hl
	ld hl,os_card_txt			; Say loading "OS from SD card"
	rst $10
	jr found_os
	
no_mmc_card


;---------Check for OS on EEPROM at $800 ------------------------------------------------------------


	call eeprom_read_sector		; Is there an OS on the eeprom? (Sector 4 onwards)
	jr nc,no_eeprom_os
	call check_os_sector
	jr nz,no_eeprom_os
	ld a,4
	ld (boot_drive),a
	ld hl,(OS_location+8)
	ld (os_size),hl
	ld hl,os_eeprom_txt			; Say loading "OS from EEPROM"
	rst $10
	jr found_os
		
no_eeprom_os


;-------- DID NOT FIND AN OS ------------------------------------------------------------------------

	ld hl,no_os_found_txt		; and prompt for serial download.
	rst $10
	jr serial_boot


;-------- LOAD OS FROM DRIVE ------------------------------------------------------------------------


found_os	ld hl,(os_size)			; length of OS data (inc header)
	ld de,$1ff
	add hl,de
	ld b,h
	srl b				; covert to number of sectors to load
sectld_lp	push bc
	ld a,(boot_drive)			
	cp 3				; use appropriate read_sector code based on boot drive type
	jr nz,not_card
	call mmc_read_sector		; read in a sector direct to destination addr
	jr nxt_sect			
not_card	call eeprom_read_sector
nxt_sect	jr nc,os_load_error			; if carry is clear, there was an error
	ld hl,sector_lba0
	inc (hl)				; advance to next sector
	ld hl,load_address+1		
	inc (hl)				; advance load address by 512 bytes
	inc (hl)	
	pop bc
	djnz sectld_lp			; any more sectors to load?


;-------- TEST THE CRC CHECKSUM OF THE OS CODE LOADED (FROM CARD/EEPROM) --------------------------

do_chksum	ld hl,(os_size)			; get filelength
	ld de,16
	xor a
	sbc hl,de
	ex de,hl				; DE = file length - 16 (CRC doesnt include first 16 bytes)
		
	ld hl,OS_location+$10
	exx
	ld hl,$ffff			; initial CRC value
	exx
mchkslp	ld a,(hl)
	call crc_calc
	inc hl
	dec de
	ld a,d
	or e
	jr nz,mchkslp
	
	exx				; get final CRC value in HL 
	ld de,(OS_location+$c)		; get checksum word from header
	sbc hl,de				; compare (carry flag will be 0 from prior OR instruction)
	jr nz,bootfail1			; if not same: bad checksum			


;-------- START UP THE OS ----------------------------------------------------------------------
	
start_os	ld hl,starting_txt
	rst $10
	
	call pause_1_second
	
	ld a,%00000001
	out (sys_clear_irq_flags),a		; clear keyboard irq flag before starting 
	xor a
	out (sys_mem_select),a		; set default upper page to 0

	ld a,(boot_drive)			; pass drive info to OS if required
	ld b,a
	ld a,(drives_present)		
	ld c,a
	xor a
	jp OS_location+$10			; executable OS code starts 16 bytes in		

;-----------------------------------------------------------------------------------------------

os_load_error

	pop bc				; say "OS load failed", pause, then reboot 
bootfail1	ld hl,os_load_error_txt
bootfail2	rst $10
	call pause_1_second
	rst $0	


;-------- DOWNLOAD BOOT CODE FROM SERIAL PORT ----------------------------------------------------

serial_boot	

	xor a
	out (sys_timer),a			; timer to overflow every 0.004 secconds

	in a,(sys_serial_port)		; clear serial buffer flag by reading port
	ld a,1
	out (sys_clear_irq_flags),a		; clear keyboard IRQ
	
	ld hl,serial_txt			; say "awaiting serial download"
	rst $10
	
	ld c,60				; allow upto 60 seconds for first byte to arrive after
	ld b,0				; waiting prompt, then reboot
wait_fsb	in a,(sys_joy_com_flags)		
	bit 6,a
	jr nz,got_fsb
	in a,(sys_irq_ps2_flags)		; pressed a key whilst waiting?
	bit 0,a
	jr z,nkbiwffb
	ld a,1
	out (sys_clear_irq_flags),a
	in a,(sys_keyboard_data)		; was it L-CTRL that was pressed?
	cp $14
	jr nz,not_lctrl
stimeout	ld hl,reboot_txt			; if so, reboot.
	jr bootfail2
not_lctrl	cp $78
	jr nz,not_f11
	ld a,0
	out (sys_baud_rate),a
	ld hl,baud_slow			; if F11 pressed set BAUD to 57600
	jr bootfail2
not_f11	cp $07				; if F12 pressed set BAUD to 115200
	jr nz,wait_fsb
	ld a,1
	out (sys_baud_rate),a
	ld hl,baud_fast
	jr bootfail2

nkbiwffb	and 4				; if bit 2 of status flags = 1, timer has overflowed
	jr z,wait_fsb
	out (sys_clear_irq_flags),a		; clear timer overflow flag
	djnz wait_fsb	
	dec c
	jr nz,wait_fsb
	jr stimeout	
	
got_fsb	ld hl,OS_location
	call s_getblock			; get header block 
	jr c,s_bad			; if carry set, there was an error / checksum was bad
	
	ld hl,receiving_txt			; header block rec'd ok so say "Receiving.."
	rst $10

	call s_goodack			; send "OK" to start the first block transfer
		
	ld hl,OS_location+$10		; HL = Address to load OS to (no header)
	ld de,(OS_location+17)		; Number of blocks to load
	ld a,(OS_location+16)
	or a
	jr z,s_gbloop
	inc de
s_gbloop	call s_getblock
	jr c,s_bad
	call s_goodack			; send "OK" to acknowledge block received OK	
	dec de
	ld a,d
	or e
	jr nz,s_gbloop
	jp start_os			; go!

s_bad	ld de,$5858			; send "XX" ack to host to stop file transfer.
	call send_serial_bytes	
	jp bootfail1			; say "error" and retry


;-------------------------------------------------------------------------------------------
; RESET KEYBOARD ROUTINE 
;-------------------------------------------------------------------------------------------

reset_keyboard

; If on return carry flag is set, keyboard init failed


	ld a,%00010000			; pull clock line low
	out (sys_ps2_joy_control),a

	ld a,240				; wait 256 microseconds
	call set_timer
twait	call test_timer	
	jr z,twait
	
	ld a,%00110000
	out (sys_ps2_joy_control),a		; pull data line low 
	ld a,%00100000
	out (sys_ps2_joy_control),a		; release clock line

	ld e,9				; 8 data bits + 1 parity bit	
kb_byte	call wait_kb_clk_low	
	ret c
	xor a
	out (sys_ps2_joy_control),a		; KB data line = 1 (command = $FF)
	call wait_kb_clk_high
	dec e
	jr nz,kb_byte

	call wait_kb_clk_low
	ret c
	
kwd_lo	in a,(sys_irq_ps2_flags)		; wait for keyboard to pull data low (ack)
	bit 5,a
	jr nz,kwd_lo
	call wait_kb_clk_low
	ret c
	
kwdc_hi	in a,(sys_irq_ps2_flags)		; wait for keyboard to release data and clock
	and %00110000
	cp  %00110000
	jr nz,kwdc_hi

	ld e,3				; read 3 bytes, should be $FF,$FA,$AA
wkb_loop	ld b,0
kb_tcd	xor a
	call set_timer			; clear timer overflow flag
wait_klp	in a,(sys_irq_ps2_flags)		; wait for keyboard IRQ flag to be set
	bit 0,a
	jr nz,kbyte_rdy
	call test_timer			; wait for keyboard IRQ flag to be set
	jr z,wait_klp
	djnz kb_tcd
kb_err	scf				;timed out
	ret

kbyte_rdy	ld a,%00000001
	out (sys_clear_irq_flags),a		; clear kb IRQ
	in a,(sys_keyboard_data)		; read kb data byte
	dec e
	jr nz,wkb_loop
	cp $aa				; last byte should be $aa - KB passed self test
	jr nz,kb_err			
	ret
	

wait_kb_clk_low

	xor a
	ld c,a
	call set_timer			; restart timer - overflows every 4 ms	

kb_bcrs	ld b,4				; clk must be continuously low for a few loops
kb_bnclp	in a,(sys_irq_ps2_flags)
	ld d,a
	call test_timer			; timer carry set?
	jr z,kbtcfl_ok
	inc c				; inc timeout counter
	jr z,kb_err			; if c = 0, op timed out
kbtcfl_ok	bit 4,d
	jr nz,kb_bcrs
	djnz kb_bnclp		
	xor a				; carry clear = op was ok
	ret


wait_kb_clk_high

	
kb_rsc	ld b,4				; clk must be continuously hi for a few loops
kb_dcnt	in a,(sys_irq_ps2_flags)
	bit 4,a
	jr z,kb_rsc			; no timeouts here as disconnected state is high
	djnz kb_dcnt
	ret


;----------------------------------------------------------------------------------------------
; SERIAL CODE
;-----------------------------------------------------------------------------------------------

s_getblock

; loads a block of 256 bytes to HL (L must be 0), and 2 extra bytes for CRC checksum
; carry flag is set on time out CRC error

	ld c,0
	exx
	ld hl,$ffff			; initial CRC checksum value
	exx
s_lgb	call receive_serial_byte
	ret c				; timed out if carry = 1	
	ld (hl),a
	call crc_calc
	inc hl				; hl = next dest address for data bytes
	ld a,h
	or l
	jr nz,samebank
	in a,(sys_mem_select)		; overflow from $FFFF, next bank!
	inc a
	out (sys_mem_select),a
	ld h,$80				; wrap dest addr around to $8000
samebank	dec c
	jr nz,s_lgb
	exx				; hl = calculated CRC

	call receive_serial_byte		; get 2 more bytes - block checksum in bc
	ret c
	ld c,a
	call receive_serial_byte
	ret c		
	ld b,a
	
	xor a				; compare checksum
	sbc hl,bc
	exx				; put address back in HL before exit
	ret z
	scf
	ret

	
;-------------------------------------------------------------------------------------------


crc_calc
	exx
	xor h				; do CRC calculation from A, to 'HL		
	ld h,a				
	ld b,8
rxcrcbyte	add hl,hl
	jr nc,rxcrcnext
	ld a,h
	xor 10h
	ld h,a
	ld a,l
	xor 21h
	ld l,a
rxcrcnext	djnz rxcrcbyte
	exx
	ret

		
;--------------------------------------------------------------------------------------------


s_goodack	push de
	ld de,$4f4b			; send "OK" ack to host
	call send_serial_bytes
	pop de
	ret


;---------------------------------------------------------------------------------------------
		

receive_serial_byte
	
	ld b,0
wait_sb	in a,(sys_joy_com_flags)		; if bit 6 of status flags = 1, byte is in buffer 
	bit 6,a
	jr nz,sbyte_in
	in a,(sys_irq_ps2_flags)
	and 4				; if bit 2 of status flags = 1, timer has overflowed
	jr z,wait_sb
	out (sys_clear_irq_flags),a		; clear timer overflow flag
	djnz wait_sb				
	scf 				; time out after 1 second
	ret
sbyte_in	in a,(sys_serial_port)		; get serial byte in A - this also clears bit 6 of status flags
	or a			
	ret
	
	
;------------------------------------------------------------------------------------------------

send_serial_bytes

; set D to the first byte to send
; and E to the second byte to send

	ld c,2
s_wait	in a,(sys_joy_com_flags)		; ensure no byte is still being transmitted
	bit 7,a
	jr nz,s_wait
	ld a,d
	out (sys_serial_port),a
	ld b,32				; limit send speed (gap between bytes)
ssplim	djnz ssplim
	ld d,e
	dec c
	jr nz,s_wait
	ret
	
	
;------------------------------------------------------------------------------------------------
; TIMER ROUTINES
;------------------------------------------------------------------------------------------------

set_timer

; put timer reload value in A before calling, remember - timer counts upwards!

	out (sys_timer),a			;load and restart timer
	ld a,%00000100
	jr clr_tirq			;clear timer overflow flag

;------------------------------------------------------------------------------------------
	
test_timer

; zero flag is set on return if timer has not overflowed

	in a,(sys_irq_ps2_flags)		;check for timer overflow..
	and 4
	ret z	
clr_tirq	out (sys_clear_irq_flags),a		;clear timer overflow flag
	ret


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
mmc_powod	rst $18
	djnz mmc_powod			
		
	call mmc_power_on			; Switch card power back on

	call mmc_spi_port_slow

	rst $18				; Short delay

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
	
	ld hl,(load_address)		; optimized read sector code
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
; EEPROM sector read routine
;---------------------------------------------------------------------------------------------

eeprom_read_sector

	ld hl,(sector_lba0)
	xor a
	ld de,$1c				; adjust usual OS sector (32+) to first available
	sbc hl,de				; EEPROM sector (4+) 
	add hl,hl
	ld (databurst_sequence+3),hl		; convert LBA sector to byte address in EEPROM
	
	in a,(sys_eeprom_byte)		; At outset, clear the input shift register count with a read
	ld hl,databurst_sequence		; tell PIC to send bytes from EEPROM
	ld b,12
init_dblp	ld a,(hl)
	call send_byte_to_pic
	inc hl
	djnz init_dblp

	ld hl,(load_address)		; destination address
	ld bc,512				; 512 bytes in a sector                 
nxt_byte	ld d,0				; D counts timer overflows
	ld a,1<<pic_clock_input		; prompt PIC to send a byte by raising PIC clock line
	out (sys_pic_comms),a
wbc_byte	in a,(sys_hw_flags)			; have 8 bits been received?		
	bit 4,a
	jr nz,gbcbyte
	in a,(sys_irq_ps2_flags)		; check for timer overflow..
	and 4
	jr z,wbc_byte	
	out (sys_clear_irq_flags),a		; clear timer overflow flag
	inc d				; inc count of overflows,
	jr nz,wbc_byte			
	xor a
	ret				; quit with carry clear = h/w error
	
gbcbyte	xor a			
	out (sys_pic_comms),a		; drop PIC clock line, PIC will then wait for next high 
	in a,(sys_eeprom_byte)		; read byte received, clear bit count
	ld (hl),a				; copy to dest, loop back to wait for next byte
	inc hl
	dec bc
	ld a,b
	or c
	jr nz,nxt_byte
	xor a
	scf				; carry set on return = all ok
	ret

;------------------------------------------------------------------------------------------	

send_byte_to_pic

pic_data_input	equ 0	; from FPGA to PIC
pic_clock_input	equ 1	; from FPGA to PIC

; put byte to send in A
; Bit rate ~ 50KHz (Transfer ~ 4.7KBytes/Second)

	push bc
	push de
	ld c,a			
	ld d,8
bit_loop	xor a
	rl c
	jr nc,zero_bit
	set pic_data_input,a
zero_bit	out (sys_pic_comms),a	; present new data bit
	set pic_clock_input,a
	out (sys_pic_comms),a	; raise clock line
	
	ld b,12
psbwlp1	djnz psbwlp1		; keep clock high for 10 microseconds
		
	res pic_clock_input,a
	out (sys_pic_comms),a	; drop clock line
	
	ld b,12
psbwlp2	djnz psbwlp2		; keep clock low for 10 microseconds
	
	dec d
	jr nz,bit_loop

	ld b,60			; short wait between bytes ~ 50 microseconds
pdswlp	djnz pdswlp		; allows time for PIC to act on received byte
	pop de			; (PIC will wait 300 microseconds for next clock high)
	pop bc
	ret			


;-------------------------------------------------------------------------------------------


check_os_sector

	ld hl,OS_location			; check if sector loaded is first OS sector
	ld de,z80_OS_txt			; if so bytes 0-7 will be "Z80P*OS*"
	ld b,8				; zero flag not set on return = no boot code
cmposn	ld a,(de)				 
	cp (hl)
	ret nz				
	inc de
	inc hl
	djnz cmposn
	xor a
	ret	

;-------------------------------------------------------------------------------------------

pause_1_second
				
	ld b,0				; wait approx 1 second
twait1	rst $18				; pauses 4ms
	djnz twait1			; loop 256 times
	ret
	
;------------------------------------------------------------------------------------------
	
	
mmc_sdc		db $00			; 0 = Card is MMC type, 1 = Card is SD type
drives_present	db $00			; Bit 0 =MMC, bit 1 = IDE M, bit 2 = IDE S
boot_drive	db $00			; (1 =IDE master, 2=IDE Slave), 3= MMC/SDcard, 4=EEPROM

sector_lba0	db $20			; keep these 4 bytes in sequence
sector_lba1	db $00
sector_lba2	db $00
sector_lba3	db $00

os_size		dw 0
load_address	dw OS_location

;-------------------------------------------------------------------------------------
	

z80_OS_txt	db "Z80P*OS*"

kb_error_txt	db 11,11,"KEYBOARD ERROR",0
crcr_txt		db 11,11,0

welcome_txt	db "V6Z80P <C> PHIL RUSTON 2008",11,11,"BOOTCODE:V6.03 - OSCA HW:V",0
scanning_txt	db 11,11,"LOOKING FOR OS.. "
		db 11,11,"PRESS ESC TO SKIP, F1-F3 FOR FPGA CFG",11,11,0
skipped_txt	db "SKIPPED",0
os_card_txt	db "LOADING OS FROM CARD.. ",0
os_eeprom_txt	db "LOADING OS FROM EEPROM.. ",0
no_os_found_txt	db "NO OS FOUND.",0
serial_txt	db 11,11,"AWAITING SERIAL DATA..",11,11,0
receiving_txt	db "RECEIVING FILE..",11,11,0
starting_txt	db "STARTING..",0
os_load_error_txt	db "LOAD ERROR[",0
not_os_txt	db "NOT AN OS FILE[",0
reboot_txt	db 11,11,"REBOOTING..",0
baud_slow		db "57600 BAUD",0
baud_fast		db "115200 BAUD",0

databurst_sequence	db $88,$d4,$00,$00,$00		; set address ($88,$d4,low,mid,high)
		db $88,$e2,$00,$02,$00		; set length ($88,$e2,low,mid,high)
		db $88,$c9			; begin transfer!

reconfig_sequence	db $88,$b8,$00,$00			; set config base ($88,$b8,x,y,z)
cfg_msb		db $00,$88,$a1			; reconfig now ($88,$a1)


;-------------------------------------------------------------------------------------
; Stack occupies the free space from font to here
;-------------------------------------------------------------------------------------
;
; ...
;
;
;--------------------------------------------------------------------------------------
; Bootloader font
;---------------------------------------------------------------------------------------
		 
		 org bootcode_location+$6d2

		 DB $00,$00,$00,$00,$00,$06,$7C,$38,$FC,$FC,$1E,$FE,$7E,$FE,$7C,$7C
        		 DB $00,$00,$3C,$00,$3C,$7C,$7C,$7C,$FC,$7C,$FC,$FE,$FE,$7C,$E6,$7C
         		 DB $7E,$E6,$E0,$C6,$E6,$7C,$FC,$7C,$FC,$7E,$FE,$E6,$E6,$C6,$C6,$CE
         		 DB $FE,$18,$00,$18,$00,$00,$00,$0E,$CE,$78,$0E,$0E,$3E,$E0,$E0,$06
         		 DB $E6,$CE,$18,$30,$70,$00,$0E,$EE,$E6,$E6,$E6,$E6,$E6,$E0,$E0,$E6
         		 DB $E6,$38,$1C,$EC,$E0,$EE,$F6,$E6,$E6,$E6,$E6,$E0,$38,$E6,$E6,$C6
        		 DB $6C,$CE,$1E,$3C,$00,$18,$00,$00,$00,$1C,$DE,$38,$7E,$3C,$76,$FC
        		 DB $FC,$0C,$7C,$7E,$18,$30,$70,$7E,$0E,$0E,$EE,$E6,$FC,$E0,$E6,$F8
         		 DB $E0,$E0,$E6,$38,$1C,$F8,$E0,$FE,$FE,$E6,$E6,$E6,$E6,$7C,$38,$E6
         		 DB $E6,$C6,$38,$CE,$3C,$3C,$00,$7E,$00,$7E,$00,$38,$F6,$38,$E0,$0E
         		 DB $E6,$0E,$E6,$18,$E6,$0E,$00,$00,$70,$00,$0E,$3C,$EE,$FE,$E6,$E0
         		 DB $E6,$E0,$F8,$EE,$FE,$38,$1C,$EC,$E0,$D6,$FE,$E6,$FC,$E2,$FC,$0E
         		 DB $38,$E6,$E6,$D6,$7C,$7E,$78,$18,$00,$18,$18,$00,$18,$70,$E6,$38
          	 DB $E0,$0E,$FF,$0E,$E6,$38,$E6,$CE,$18,$30,$70,$7E,$0E,$00,$E0,$E6
         		 DB $E6,$E6,$E6,$E0,$E0,$E6,$E6,$38,$DC,$E6,$E0,$C6,$EE,$E6,$E0,$EC
          	 DB $E6,$CE,$38,$E6,$6C,$FE,$EE,$0E,$F0,$00,$00,$18,$30,$00,$18,$E0
         		 DB $7C,$7C,$FE,$FC,$06,$FC,$7C,$38,$7C,$7C,$18,$60,$3C,$00,$3C,$38
          	 DB $7C,$E6,$FC,$7C,$FC,$FE,$E0,$7C,$E6,$7C,$78,$E6,$FE,$C6,$E6,$7C
         		 DB $E0,$76,$E6,$7C,$38,$7C,$38,$6C,$C6,$FC,$FE,$18
         		 
;--------------------------------------------------------------------------------------
; append CRC16 checksum word
;--------------------------------------------------------------------------------------