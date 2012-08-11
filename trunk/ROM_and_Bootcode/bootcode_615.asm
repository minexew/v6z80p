;----------------------------------
; OSCA Bootcode by Phil Ruston 2011
;----------------------------------

; Changes in V6.15
; ----------------
;
; Added a short delay after EEPROM sector read to make sure PIC has time to return to waiting
; command mode (in case of variability in 20MHz PIC crystal / temperature)
;
; Previous:
; V6.14: Added V1.10 SD card driver for SDHC support.
; 
; --------------------------------------------------------------------------------------------------
;
; This boot code initializes the keyboard and loads an operating system file (*.OSF file)
; from MMC/SD/SDHC card, EEPROM (location $00800+) or via serial download using the PC Serial Link app.

; Bootcode is 3518 bytes max of code/data (+ CRC word). It is downloaded from the FPGA config EEPROM
; (or serially if no bootcode exists) into RAM at $0200-$0FBF by the Z80 ROM code in the FPGA then
; executed (if the CRC word in the last two bytes matches the contents of the file). $0FC0-$0FFF
; is reserved for the stack. Address range $200-$7FF is system RAM when the ROM passes control to
; this routine.

; Keys:
; -----
; F1-F7 - The FPGA will reconfigure from slot 1-7 respectively.
; ESC   - Force serial download (afterwards L-CTRL reboots if required)
; F11   - 57600 BAUD (whilst waiting for serial download)
; F12   - 115200 BAUD (""                             "")

;-------------------------------------------------------------------------------------------------

include "OSCA_hardware_equates.asm"
include "system_equates.asm"


;**************************************************************************************************
	org new_bootcode_location
;**************************************************************************************************


	jp start_boot

;--------------------------------------------------------------------------------------------------

z80_OS_txt	db "Z80P*OS*"

kb_error_txt	db 11,11,"KEYBOARD ERROR",0
crcr_txt		db 11,11,0

welcome_txt	db "V6Z80P BY PHIL RUSTON 2008-2011",11,11,"BOOTCODE:V6.15 - OSCA HW:V",0
scanning_txt	db 11,11,"LOOKING FOR OS.. "
		db 11,11,"PRESS ESC TO SKIP, F1-F7 FOR FPGA CFG",11,11,0
skipped_txt	db "SKIPPED",0
os_card_txt	db "LOADING OS FROM CARD.. ",0
os_eeprom_txt	db "LOADING OS FROM EEPROM.. ",0
no_os_found_txt	db "NO OS FOUND.",0
serial_txt	db 11,11,"AWAITING SERIAL DATA..",11,11,0
receiving_txt	db "RECEIVING FILE..",11,11,0
starting_txt	db "STARTING..",0
os_load_error_txt	db "LOAD ERROR[",0
crc_error_txt	db "CHECKSUM BAD[",0
not_os_txt	db "NOT AN OS FILE[",0
reboot_txt	db 11,11,"REBOOTING..",0
baud_slow		db "57600 BAUD",0
baud_fast		db "115200 BAUD",0

fkey_list		db $83,$0b,$03,$0c,$04,$06,$05	; Function key scancodes F7-to-F1

;--------------------------------------------------------------------------------------------------
	
	include 	"file_load_essentials_fat16.asm"
	include	"serial_load_essentials.asm"

;---------------------------------------------------------------------------------------------
; EEPROM sector read routine
;---------------------------------------------------------------------------------------------

eeprom_read_sector

	ld hl,(sector_lba0)			
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
	
	ld b,0
tlp1	djnz tlp1				; wait a while so PIC is ready for any command that may follow
	
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
zero_bit	out (sys_pic_comms),a		; present new data bit
	set pic_clock_input,a
	out (sys_pic_comms),a		; raise clock line
	
	ld b,12
psbwlp1	djnz psbwlp1			; keep clock high for 10 microseconds
		
	res pic_clock_input,a
	out (sys_pic_comms),a		; drop clock line
	
	ld b,12
psbwlp2	djnz psbwlp2			; keep clock low for 10 microseconds
	
	dec d
	jr nz,bit_loop

	ld b,60				; short wait between bytes ~ 50 microseconds
pdswlp	djnz pdswlp			; allows time for PIC to act on received byte
	pop de				; (PIC will wait 300 microseconds for next clock high)
	pop bc
	ret			


;------------------------------------------------------------------------------------------------

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

;----------------------------------------------------------------------------------------------

pause_1_second
				
	ld b,0				; wait approx 1 second
twait1	call pause_4ms			; pauses 4ms
	djnz twait1			; loop 256 times
	ret

;---------------------------------------------------------------------------------------------------------
	
pause_4ms
	push af
	xor a				; set timer to count 256 x 65536 cycles
	call set_timer
pause_lp	call test_timer
	jr z,pause_lp			
	pop af
	ret
	
	
;------------------------------------------------------------------------------------------------
; SIMPLIFIED TEXT PLOTTING ROUTINE
;------------------------------------------------------------------------------------------------

cursor_pos	equ video_base+$1ffe	; cursor pos variable is held in video memory
bootcode_font	equ video_base+$1e80	; as is the bootcode font


print_string

	ld a,%01000000			; page video memory into $2000-$3fff
	out (sys_mem_select),a		

	ld bc,(cursor_pos)			; prints ascii at current cursor position

prtstrlp	ld a,(hl)				; set hl to start of 0-termimated ascii string
	inc hl	
	or a			
	jr nz,noteos
		
	ld (cursor_pos),bc		
	
	out (sys_mem_select),a		; page video memory OUT of $2000-$3fff (A will be 0)	
	ret
	
noteos	cp 11				; is character a new line code LF+CR? (11)
	jr nz,nolf
	ld b,0
	inc c
	jr prtstrlp

	
nolf	push hl
	push bc
	
	sub $2a				; adjust ascii code to character definition offset
	jr nc,tnc
	xor a
tnc	ld h,0				; b = xpos, c = ypos
	ld l,a
	ld de,bootcode_font			; start of font 
	add hl,de
	push hl
	pop ix				; ix = first addr of char 
	
	ld hl,video_base-(40*8)
	ld de,40*8
	ld a,c
	inc a
ymultlp	add hl,de
	dec a
	jr nz,ymultlp
gotymul	ld d,0
	ld e,b
	add hl,de				; hl = first dest addr		
	
	ld d,0
	ld b,6
pltchlp	ld a,(ix)
	ld (hl),a
	ld e,50				; offset to next line of char
	add ix,de
	ld e,40
	add hl,de
	djnz pltchlp	
	
	pop bc
	pop hl
	inc b
	jr prtstrlp
	

;---------------------------------------------------------------------------------------------------------

get_hw_version

	ld hl,OS_location			; show hardware version (4 digit BCD)
 	push hl
 	ld b,15				; bit number to read
	ld c,sys_hw_flags			; port to read from
	ld d,4
verloop2	ld e,4
	ld (hl),$03			; Decimal ascii base >> 4
verloop1	in a,(c)				; serial data is bit 7
	sla a				; force into carry flag
	rl (hl)				; word ends up in DE
	dec b
	dec e
	jr nz,verloop1			; next bit
	inc hl
	dec d
	jr nz,verloop2
	ld (hl),d				; zero terminate string
	pop hl				; return hardware version string (4 digit BCD)
	ret


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


;=============================================================================================
; MAIN BOOTCODE STARTS HERE
;=============================================================================================

start_boot

	call init_vregs			; using a call allows the routine to be above paged memory
	
	ld a,%01000000			; page video memory in
	out (sys_mem_select),a		
	ld hl,video_base			; clear vram 0-1fff for 1 bitplane display
	xor a
	ld c,32
clr_scr2	ld b,a
	call clear_mem
	dec c
	jr nz,clr_scr2
		
	ld hl,bootloader_font		; copy font to video RAM	
	ld de,video_base+$1e80		; (video page register was cleared above)
	ld bc,300
	ldir
	ld a,1
	out (sys_mem_select),a		; page video memory out, bank select = 1

	xor a
	out (sys_ps2_joy_control),a		; release keyboard / mouse control lines
	out (sys_irq_enable),a		; zero all IRQ enables
	out (sys_audio_enable),a		; disable sound channels
	ld c,$10				; zero ports $10 to $20 inclusive (sound and
	ld b,a				; low_page setting)
	ld l,17
clploop	out (c),a
	inc c
	dec l
	jr nz,clploop	

	call set_timer			; timer @ 256 * 256 cycles between overflows + restart

	jp sector_buffer+$200

	
;*****************************************************************************************************
; THERE CAN BE NO CODE WITHIN $800-$9FF (sector buffer)
; This font data is OK here as it is immediately copied to VRAM before any sector buffer shenanigans
;*****************************************************************************************************

	org sector_buffer
	
bootloader_font

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
         		 
         		 
;************************************************************************************************
	org sector_buffer+$200	; skip $800-$9FF (sector buffer)
;************************************************************************************************

		
	ld a,%00000111
	out (sys_clear_irq_flags),a		; clear all irqs at start

	ld hl,$0fff			; Text colour = white
	ld (palette+2),hl	

	ld hl,welcome_txt			; Power-on text
	call print_string			; Print string

	call get_hw_version			; Get hardware version
	call print_string			; Print string
	
	call reset_keyboard			; Reset the keyboard - scancode set 2 etc.
	jr nc,keyb_ok			; if carry flag is set there's a keyboard error
	ld hl,kb_error_txt			; advise of keyboard error
	call print_string

;-------------------------------------------------------------------------------------------------------
	
keyb_ok	ld hl,scanning_txt		
	call print_string			; Show "Looking For OS" text


;---------Abort drive OS boot? -------------------------------------------------------------------------

chk_keys	call pause_1_second			; allow user time to press ESC before checking drives

	in a,(sys_irq_ps2_flags)		; keyboard irq?
	bit 0,a				
	jr z,go_drive_boot	
	in a,(sys_keyboard_data)			 
	ld hl,fkey_list			; if a Function key F1-F7 is pressed, config from relevant slot
	ld b,7
fklp	cp (hl)
	jr z,go_cfg
	inc hl
	djnz fklp
	cp $76				; If ESC key was pressed skip drive-based OS boot		
	jr nz,go_drive_boot			; and boot from serial port download instead
	ld hl,skipped_txt
	call print_string
	jp serial_boot	

go_cfg	ld a,b
	sla a
	ld (cfg_msb),a
	ld hl,reconfig_sequence		; tell PIC to set reconfig base (not permanently) and restart
	ld b,7
cfg_dlp	ld a,(hl)
	call send_byte_to_pic
	inc hl
	djnz cfg_dlp
	jr chk_keys			; the FPGA should have now restarted

go_drive_boot


;-------- Check for OS on MMC/SD/SDHC Card (*.OSF file) -----------------------------------------------------

	call sd_initialize			; Is there an SD/MMC card attached?
	jr c,no_sd_card_os			; carry is set if error during initialization	
	ld hl,drives_present
	set 2,(hl)			; Set bit 2 - SD card present
	
	call find_os_file_fat16		; look for OSF file on (assumed) FAT16 card
	jr c,no_sd_card_os			; hardware error?
	jr nz,no_sd_card_os			; file not found?
		
load_os_file

	ld a,3
	ld (boot_drive),a			; Mark card as boot device (type 3)
	ld hl,os_card_txt			; Say loading "OS from SD card"
	call print_string

	ld a,1
	out (sys_mem_select),a		; page out video RAM / upper bank bits = 0001
	call load_os_file_fat16
	jp nz,bootfail1			; load error?
	jr do_chksum
	
no_sd_card_os


;---------Check for OS on EEPROM at $800 ------------------------------------------------------------


	ld hl,$4
	ld (sector_lba0),hl			; OS is at EEPROM $800 (sector 4)
	
	call eeprom_read_sector		; Is there an OS on the eeprom?
	jr nc,no_eeprom_os
	call check_os_sector
	jr nz,no_eeprom_os
	ld a,4
	ld (boot_drive),a
	ld hl,os_eeprom_txt			; Say loading "OS from EEPROM"
	call print_string

	ld hl,(OS_location+8)		; length of OS data (excluding header)
	ld de,$20f
	add hl,de
	ld b,h
	srl b				; covert to number of sectors to load
sectld_lp	push bc
	call eeprom_read_sector
nxt_sect	jr nc,os_load_error			; if carry is clear, there was an error
	ld hl,sector_lba0
	inc (hl)				; advance to next sector
	ld hl,load_address+1		
	inc (hl)				; advance load address by 512 bytes
	inc (hl)	
	
	pop bc
	djnz sectld_lp			; any more sectors to load?
	jr do_chksum
		
no_eeprom_os


;-------- DID NOT FIND AN OS ------------------------------------------------------------------------

	ld hl,no_os_found_txt		; and prompt for serial download.
	call print_string
	jr serial_boot


;-------- TEST THE CRC CHECKSUM OF THE OS LOADED (FROM CARD/EEPROM) ---------------------------------

do_chksum	ld a,1
	out (sys_mem_select),a		; ensure we're back at the first bank

	ld de,(OS_location+$8)		; OS length not including header (lo word) 
	ld bc,(OS_location+$a)		; OS length not including header (hi word)			
	ld hl,OS_location+$10		; first address to check
	exx
	ld hl,$ffff			; initial CRC value
	exx
mchkslp	ld a,(hl)
	call crc_calc
	inc hl
	ld a,h
	or l
	jr nz,bank_ok
	ld h,$80
	in a,(sys_mem_select)
	inc a
	and $f
	out (sys_mem_select),a
bank_ok	dec de
	ld a,d
	or e
	jr nz,mchkslp
	dec c
	bit 7,c
	jr z,mchkslp

	exx				; get final CRC value in HL 
	ld de,(OS_location+$c)		; get checksum word from header
	sbc hl,de				; compare (carry flag will be 0 from prior OR instruction)
	ld hl,crc_error_txt
	jr nz,bootfail2			; if not same: bad checksum			


;-------- START UP THE OS ----------------------------------------------------------------------
	
start_os	ld hl,starting_txt
	call print_string
	
	call pause_1_second
	
	ld a,%00000001
	out (sys_clear_irq_flags),a		; clear keyboard irq flag before starting 
	xor a
	out (sys_mem_select),a		; set default upper page to 0
	out (sys_alt_write_page),a		; page in the video registers
	
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
bootfail2	call print_string
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
	call print_string
	
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
	call print_string

	call s_goodack			; send "OK" to start the first block transfer
		
	ld hl,OS_location			; HL = Address to load OS to
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


;-----------------------------------------------------------------------------------------------

init_vregs

	xor a
	out (sys_alt_write_page),a		; writes to go to video registers 

	ld b,a				; (this routine cannot be within $700-$7ff)
	ld hl,spr_registers+$1ff		; clear palette / sprite registers
clrpalsp	ld (hl),a
	dec hl
	ld (hl),a
	dec hl
	djnz clrpalsp
	dec h
	dec h
	jp p,clrpalsp

	ld b,$17
	ld hl,vreg_xhws			; clear video registers - stop before
	call clear_mem			; blitwidth register ($217) 
	ld hl,vreg_xhws+$30			 
	ld b,$50				; continue after linedraw and clear other
	call clear_mem			; registers, bitplanes etc

	ld hl,vreg_window
	ld (hl),$59			; set y window size/position (192 lines)
	ld a,%00000100
	ld (vreg_rasthi),a			; select x window register
	ld (hl),$8c			; set x window size/position (320 pixels)
	
	ld a,%10000000
	out (sys_alt_write_page),a		; writes (and reads) go to RAM below $200-$7FF
	ret

;----------------------------------------------------------------------------------------------

clear_mem	xor a
clrloop	ld (hl),a
	inc hl
	djnz clrloop
	ret
	
;----------------------------------------------------------------------------------------------

	include	"sdcard_essentials_v110.asm"

;----------------------------------------------------------------------------------------------


;=== Keep Variables in unpaged RAM!! ==============================================================

fs_cluster_size		db 0			; FAT16 disk parameters
fs_fat1_loc_lba		dw 0
fs_root_dir_loc_lba		dw 0
fs_root_dir_sectors		dw 0

fs_file_length_working	dw 0,0
fs_file_working_cluster	dw 0
fs_z80_working_address	dw OS_location
fs_working_sector		dw 0

sd_card_info		db $00			; 0 = Card is MMC, 1 = SD, 2 = SDHC
drives_present		db $00			; Bit 0 =MMC, bit 1 = IDE M, bit 2 = IDE S
boot_drive		db $00			; (1 =IDE master, 2=IDE Slave), 3= MMC/SDcard, 4=EEPROM
load_address		dw OS_location

databurst_sequence		db $88,$d4,$00,$00,$00	; set address ($88,$d4,low,mid,high)
			db $88,$e2,$00,$02,$00	; set length ($88,$e2,low,mid,high)
			db $88,$c9		; begin transfer! (this is dynamically updated)

reconfig_sequence		db $88,$b8,$00,$00		; set config base ($88,$b8,x,y,z) 
cfg_msb			db $00,$88,$a1		; reconfig now ($88,$a1) (this is dynamically updated)

sector_lba0 		db 0
sector_lba1		db 0
sector_lba2		db 0
sector_lba3		db 0

cmd_generic		db $00
cmd_generic_args		db $00,$00,$00,$00
cmd_generic_crc		db $01

;**************************************************************************************************
	org new_bootcode_location+$dbe
;**************************************************************************************************
	
crc_value			dw $ffff	; replace this with real CRC16 checksum word (use PC-based app
				; new_bootcode_crc.exe)

;--------------------------------------------------------------------------------------------------
