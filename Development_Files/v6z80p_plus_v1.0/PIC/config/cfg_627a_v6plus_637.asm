; --------------------------------------------------------------------------------
; PIC 16F627A SPI serial EEPROM Reader / Spartan II FGPA configurator for V6Z80P+
; --------------------------------------------------------------------------------
;
; By Phil Ruston 2010-2012 for V6Z80P_plus
;
; Latest changes: v6.37
; ---------------------
; JP2 now acted on as if button is connected:
;
;  If held on power up: JTAG MODE. This persists until the button is released and pressed/released again, then: MANUAL SLOT SET MODE.
;  If pressed after config, FPGA is reconfigured from Active Slot (system reset).
; 
; (A jumper can still be used on JP2 as before (it will be ignored after the FPGA is configured via JTAG mode so that it doesn't
;  trigger a system reset)
;
; Test commands commented out (needed the program space)
;
; Previous changes:
; ----------------
;
; 6.36
; ----
; Added ID support for SST25VF016B and SST25VF080B EEPROMs
;
; 6.35
; ----
; Added write / ID support for SST25VF032B EEPROM
; Added Status Register read command
; WEL wait routine now times out
; Block protect bits [5:2] of SR are all cleared and all set around writes for SST chips - these are s/w, not flash on 25VF types.;
; Removed I2C obsolete code
; Couple of bugfixes (timeout routine goto/call problems)
;
; 6.29
; ----
;
; Coms_clock_in and data_in are sampled 7 times and a count incremented each time the pin reads high.
; If the count is 4 or above, the pin is taken to be high
;
; 6.28
; ---
; After 64 bytes are written to the EEPROM, they are (locally) verified (LED flashes 5 times on verify error)
; LED = OFF during EEPROM busy waits (busy waits will now time out, other timing altered)
; Added test commands
;
; ----------------------------------------------------------------------------------------------------------------------
;
;  Pin connections:
;  ----------------
;
;							16F627/8A
;                            ___   __
;		 					|   '-'  |
;		    CONF CCLK <- A2 |1     18| A1 -> SPI (EEPROM) CLK
;   SPI D_IN (EEPROM) <- A3 |2     17| A0 -> SPI (EEPROM) /CS
;		 I2C DATA O/D <- A4 |3     16| XTAL
;PIC-FPGA Comms CLK IN-> A5 |4     15| XTAL
;	 				    GND |5     14| 3.3V
;		   CONF PGM	  <- B0 |6     13| B7 -> PIC-FPGA comms CLK OUT
;		   CONF INIT  -> B1 |7     12| B6 <- JUMPER / SWITCH (JTAG MODE)
;		   CONF DONE  -> B2 |8     11| B5 -> I2C CLOCK
; SPI (EEPROM) D_OUT ->  B3 |9     10| B4 -> I2C ADDRESS + LED
;					        |________|
;
; "CONF INIT" and "CONF DONE" should be pulled to Vcc via 3.3K resistors as per Spartan 2 config specs.
; "I2C DATA" is an Open Drain output (PIC RA4) agreeing with I2C spec, so needs to be pulled up to Vcc via 2.2K resistor.
; Decouple PIC with 0.1uf cap across Vcc and GND.
;
;
;			             SPI 25XXX EEPROM
;					       .---_----.
;			          /CS  |1      8| 3.3V              
;			         D_OUT |2      7| /HOLD           
;			            WP |3      6| CLK IN     
;					   GND |4      5| D_IN     
;			               |________|
;
; Note: Tie "/HOLD" and "WP" to Vcc.
; Connect /CS to Vcc via 10K resistor (to ensure good start-up, as per datasheet)
;
;
; ----------------------------------------------------------------------------------------------------------------------
;
;
; Post configuration commands:
; ----------------------------
;
; $88 + $a1 = Reconfigure + restart FPGA from current config address base
; $88 + $b8 + $low + $middle + $high address bytes = Set config address base
; $88 + $37 + $d8 + $06 = make current FPGA config base address permanent (in PIC's EEPROM)*

; $88 + $c9 = send databurst to FPGA using current databurst base address and length
; $88 + $d4 + $low + $middle + $high address bytes = Set databurst address base
; $88 + $e2 + $low + $middle + $high count bytes = Set databurst length

; $88 + $25 + $fa + $99 = Enable EEPROM programming
; $88 + $1f = Disable EEPROM programming
; $88 + $f5 + $low + $middle + $high address bytes = Erase 64KB block of SPI EEPROM ($middle and $low = 00)*
; $88 + $98 + $low + $middle + $high address bytes + 64 data bytes = Program bytes into SPI EEPROM #*

; $88 + $53 = Request EEPROM sends its ID byte
; $88 + $76 = Request PIC sends current active slot (bit sequence - FPGA provides clock, PIC data out on RB7)
; $88 + $4e = Request PIC sends current firware version

; $88 + $6c = Optional EEPROM ID read if Command $88+$53 is invalid (note: data sent from PIC, not EEPROM)
; $88 + $8f = Request PIC sends the EEPROM's status register

;-------------------------------------------------------------------------------------------------------------------------
; TEST COMMANDS:
; $88 + $FF + 64 data bytes = fill PIC RAM with data bytes
; $88 + $FE = Request PIC sends 64 bytes from its RAM
;-------------------------------------------------------------------------------------------------------------------------

; * Programming mode must be enabled first
; # The 64KB EEPROM block in which the bytes are to be located must be erased prior to programming new data

;
;
;
;--- GENERIC HEADER AND CLOCK OPTIONS ----------------------------------------------------------------------

	list      p=16f627A            ; list directive to define processor
	list	r=decimal

	#include <p16f627A.inc>        ; processor specific variable definitions

	#define skipifzero        btfss STATUS,Z        
	#define skipifnotzero     btfsc STATUS,Z
	#define skipifcarry       btfss STATUS,C        
	#define skipifnotcarry    btfsc STATUS,C
	
	__CONFIG _CP_OFF & _WDT_OFF & _BODEN_OFF & _PWRTE_ON & _HS_OSC & _MCLRE_OFF & _LVP_OFF


;-----Defaults ----------------------------------------------------------------------------------------

firmware_vers		equ 0x37

fpga_config_length 	equ 130012	 				; Length of FPGA's .bin config file (SPARTAN 2 XC2S150)

databurst_address	equ 0x0						; Default location of databurst (ROM code) in SPI EEPROM
databurst_length	equ 2048					; Default length of databurst (ROM code): 2KB

;----- Project Variables -------------------------------------------------------------------------------

temp1				EQU     0x20
temp2				EQU		0x21
temp3				EQU		0x22
bitcount			EQU     0x23
bytecount_h			EQU		0x24
bytecount_m			EQU		0x25
bytecount_l			EQU		0x26

config_base_low		EQU		0x27
config_base_med		EQU		0x28
config_base_high	EQU		0x29

eeprom_address_low	EQU		0x2a
eeprom_address_med	EQU		0x2b
eeprom_address_high	EQU		0x2c

databurst_base_low	EQU		0x2d
databurst_base_med	EQU		0x2e
databurst_base_high	EQU		0x2f
databurst_len_low	EQU     0x30
databurst_len_med	EQU		0x31
databurst_len_high	EQU     0x32

received_byte		EQU		0x33
allow_program		EQU     0x34
time_out			EQU     0x35
buffer_count		EQU     0x36
busy_flash			EQU 	0x37
slot_cycle			EQU     0x38
temp4				EQU     0x39

databyte			EQU 	0x3a

eeprom_id			EQU     0x3b
eeprom_type			EQU		0x3c

busy_flash_low		EQU		0x3d
average				EQU		0x3e
write_count			EQU		0x3f

startup_mode		EQU		0x40		;0 = JTAG, 1 = Normal

;--------------------------------------------------------------------------------------------

pic_eeprom_addr		EQU		0x70

;---  Project constants ---------------------------------------------------------------------

;Port A bit assignments

eeprom_cs			equ	0	;out				 
eeprom_clock		equ 1	;out
fpga_cclk			equ 2	;out				 
eeprom_data_in		equ 3	;out
i2c_data			equ 4   ;out (Open Drain)  (obsolete)
comms_clock_in		equ 5	;in


; Port B bit assignments

fpga_program  		equ 0   ;out				 
fpga_init			equ 1	;in 
fpga_done     		equ 2	;in
eeprom_data_out		equ 3	;in
status_led			equ 4	;out
i2c_clock			equ 5	;out (obsolete)
jumper				equ 6	;in
comms_clock_out		equ 7	;out


; 25-series eeprom commands

spi_write_page_cmd	equ 0x02
spi_read_cmd		equ 0x03
spi_read_status_cmd	equ 0x05
spi_write_en_cmd	equ 0x06
spi_erase_cmd		equ 0xd8
spi_id_cmd			equ 0xab
spi_write_sr_cmd	equ 0x01

; 25vf series eeprom commands

sst_aai_write_cmd	equ 0xad	
sst_wrdi_cmd		equ 0x04


porta_default		equ (1<<eeprom_cs)+(1<<i2c_data)		; EEPROM not selected, I2C data high
portb_default		equ (1<<fpga_program)+(1<<i2c_clock)	; FPGA program high (inactive), I2C clock high

;*****************************************************************************************************

	ORG     0x000      			 							; processor reset vector

			goto init_code    								; go to beginning of program

	ORG     0x004       									; interrupt vector location

			retfie            								; return from interrupt

;---------- INITIALIZE PIC FOR THIS PROJECT ----------------------------------------------------------


init_code	movlw b'00000111'		
			movwf CMCON										; use digital mode for PORTA (disable comparitors)
			banksel TRISA
			movlw b'00100000'								; set data direction for port A
			movwf TRISA
			movlw b'01001110'								; set data direction for port B
			movwf TRISB
			banksel PORTA

			movlw porta_default							
			movwf PORTA
			movlw portb_default								
			movwf PORTB											


;---------------------------------------------------------------------------------------------------------------
			
			call active_slot_to_cfg_base

			movlw databurst_address & 0xff					;set default values for databurst loc/len	
			movwf databurst_base_low
			movlw (databurst_address >> 8) & 0xff
			movwf databurst_base_med
			movlw (databurst_address >> 16) & 0xff					
			movwf databurst_base_high
			movlw (0x1000000-databurst_length) & 0xff		
			movwf  databurst_len_low
			movlw ((0x1000000-databurst_length) >> 8) & 0xff
			movwf databurst_len_med
			movlw ((0x1000000-databurst_length) >> 16) & 0xff
			movwf databurst_len_high

			movlw 2
			movwf slot_cycle

			clrf eeprom_type
			clrf write_count
			clrf startup_mode

;----------------------------------------------------------------------------------------------------------------------------
;   Main SPI -> FPGA config code
;----------------------------------------------------------------------------------------------------------------------------

configure_fpga

			clrf allow_program									; PIC/EEPROM programming disabled by default (software flag)

			movlw porta_default									; deselect the SPI EEPROM (set its /CS = high)
			movwf PORTA
			movlw portb_default									; set FPGA program line inctive / I2C clock high
			movwf PORTB											

			call short_pause

			call get_eeprom_id

;-----------IS JTAG JUMPER ON? ---------------------------------------------------------------------------------------------

			movlw 1
			movwf temp3

check_jtag	btfsc PORTB,jumper									; JTAG or EEPROM config?
			goto go_configure									; if JP2 button is not pressed (pin high) do normal EEPROM config

wait_jtag	movlw 0xf8											; otherwise flash LED until JTAG config complete
			movwf temp2
			clrf temp1
chk_done	btfss PORTB,fpga_done								
			goto done_low
			incfsz temp1,f										; resample "done" - ensure it is permanently high
			goto chk_done
			incfsz temp2,f
			goto chk_done
			goto wait_command									; when JTAG config complete, wait for commands.

done_low	movlw portb_default+(1<<status_led)					; flash LED when waiting for JTAG config			
			movwf PORTB											; LED: on
			call short_pause_esc_if_done
			movlw portb_default									; LED: off
			movwf PORTB				
			call short_pause_esc_if_done

			btfsc temp3,0										; if latch bit set, test for button release otherwise test if button is pressed
			goto chkjtag2	
			btfsc PORTB,jumper									 
			goto wait_jtag										
			call long_pause
wait_jpoff	btfss PORTB,jumper									; button is pressed - wait for it to be released then do manual config
			goto wait_jpoff		
			call short_pause
			goto manslotset

chkjtag2	btfss PORTB,jumper									; has button been released whilst in JTAG config mode?
			goto wait_jtag										 
			clrf temp3											; if so, clear the latch bit 
			goto wait_jtag										


;---------- Manual active slot reset system --------------------------------------------------------------------------------

manslotset	call long_pause
			call long_pause
			call long_pause
			call long_pause

slot_loop	rrf slot_cycle,w									; slots 1-7 can be made active manually. 
			andlw 7
			movwf temp4
s2_ledfl	call long_pause										; flash the LED "SLOT" number of times
			bsf PORTB,status_led								
			call long_pause
			bcf PORTB,status_led			
			decfsz temp4,f
			goto s2_ledfl

			call wait4seconds_bx								; wait 4 seconds, if button pressed quit and go to set slot
			xorlw 1
			skipifnotzero
			goto set_slot								

			incf slot_cycle,f									; EEPROM address MSB = 2,4,6,8,A,C,E
			incf slot_cycle,f
			btfss slot_cycle,4									; if slot count = 8, return to slot 1
			goto slot_loop
			movlw 2
			movwf slot_cycle
			goto slot_loop

set_slot	clrf pic_eeprom_addr								; write the slot number	to PIC flashram
			movlw 0											
			call pic_eeprom_write							
			incf pic_eeprom_addr,f								
			movlw 0
			call pic_eeprom_write
			incf pic_eeprom_addr,f
			movf slot_cycle,w
			call pic_eeprom_write

			bsf PORTB,status_led								; status LED stays on when done (At this point, power off the board)
stop_here	goto stop_here										



wait4seconds_bx

			movlw 20											; wait about 4 seconds - quit early if button pressed (Return 1 in W)
			movwf temp4

p4loop2		movlw 5												; approx 0.25 seconds (20MHz clock)
			movwf temp3
p4loop1		btfss PORTB,jumper									
			retlw 1
			call short_pause
			decfsz temp3,f
			goto p4loop1
			
			decfsz temp4,f
			goto p4loop2
			retlw 0

;----------- Configure FPGA - Slave Serial mode via PIC and EEPROM ----------------------------------------------------------------------

go_configure
			
			bsf startup_mode,0									; set bit 0 = started noramlly (IE: not JTAG)

			bcf PORTB,fpga_program								; force reload config on FPGA
			call short_pause									; IE: pulse "Program" low
			bsf PORTB,fpga_program
			call short_pause

wait_init_1	btfss PORTB,fpga_init								; wait for FPGA to be ready (fpga_init = high)
			goto wait_init_1									; before sending data

			movlw ((0x1000000-fpga_config_length) >> 16) & 0xff					
			movwf  bytecount_h
			movlw ((0x1000000-fpga_config_length) >> 8) & 0xff
			movwf  bytecount_m
			movlw (0x1000000-fpga_config_length) & 0xff			
			movwf  bytecount_l


;---------- Send sequential read command to SPI EEPROM -----------------------------------------------------------------------------------

			movlw porta_default-(1<<eeprom_cs)
			movwf PORTA											; Bring SPI EEPROM /CS = Low (new instruction)

			movlw spi_read_cmd									; send read data command ($03) to SPI EEPROM 
			call send_byte_to_eeprom						

			movf config_base_high,w								; send 24 bit start address to SPI EEPROM, MSB first	
			call send_byte_to_eeprom
			movf config_base_med,w
			call send_byte_to_eeprom
			movf config_base_low,w		
			call send_byte_to_eeprom


;---------- Read the data from EEPROM and configure the FPGA  ------------------------------------------------------------------------------


do_clocks equ (1<<i2c_data)+(1<<eeprom_clock)+(1<<fpga_cclk)
no_clocks equ (1<<i2c_data)


read_loop	movlw do_clocks
			movwf PORTA											;fpga latches bit 7
			movlw no_clocks
			movwf PORTA											;spi eeprom shifts out bit 6

			movlw do_clocks
			movwf PORTA											;fpga latches bit 6
			movlw no_clocks
			movwf PORTA											;spi eeprom shifts out bit 5	

			movlw do_clocks
			movwf PORTA											;fpga latches bit 5	
			movlw no_clocks
			movwf PORTA											;spi eeprom shifts out bit 4

			movlw do_clocks
			movwf PORTA											;fpga latches bit 4							
			movlw no_clocks
			movwf PORTA											;spi eeprom shifts out bit 3

			movlw do_clocks
			movwf PORTA											;fpga latches bit 3
			movlw no_clocks
			movwf PORTA											;spi eeprom shifts out bit 2

			movlw do_clocks
			movwf PORTA											;fpga latches bit 2									
			movlw no_clocks
			movwf PORTA											;spi eeprom shifts out bit 1

			movlw do_clocks
			movwf PORTA											;fpga latches bit 1
			movlw no_clocks
			movwf PORTA											;spi eeprom shifts out bit 0

			movlw do_clocks
			movwf PORTA											;fpga latches bit 0
			movlw no_clocks
			movwf PORTA											;spi eeprom shifts out bit 7

			incfsz bytecount_l,f								;count bytes sent - loop if more to go
			goto read_loop					
			incfsz bytecount_m,f			
			goto read_loop					
			incfsz bytecount_h,f
			goto read_loop

;---------- Check FPGA configured OK -------------------------------------------------------------------------------------------------------------------

			call vshort_pause

			btfsc PORTB,fpga_done								; All bytes sent - Check that the FPGA started up 
			goto fpga_done_hi									; (Its "DONE" line should be high now)

			movlw porta_default									; If not, deselect the SPI EEPROM (set its /CS = high)
			movwf PORTA																	
			bsf PORTB,status_led								; flash the LED once and re-try							
			call long_pause
			bcf PORTB,status_led
			call long_pause
			call long_pause
  			goto configure_fpga				

fpga_done_hi

			movlw porta_default									; deselect the SPI EEPROM (set its /CS = high)
			movwf PORTA
			
			call vshort_pause

;--------------------------------------------------------------------------------------------------------------------			
; After config, wait for commands from CPU (via FPGA)
;--------------------------------------------------------------------------------------------------------------------

wait_command

			movlw portb_default+(1<<status_led)					; LED ON = FPGA configured / PIC waiting for command..	
			movwf PORTB

wait_cmd_lp	call get_byte_from_fpga								; all commands must begin with $88
			xorlw 0x88
			skipifzero
			goto test_reconf_reset

			call get_byte_from_fpga								; next byte is the actual command code
		
			movf received_byte,w
			xorlw 0xa1
			skipifnotzero
			goto configure_fpga

			movf received_byte,w
			xorlw 0xb8
			skipifnotzero
			goto set_config_base_address

			movf received_byte,w
			xorlw 0x37
			skipifnotzero
			goto make_config_base_permanent

			movf received_byte,w
			xorlw 0xc9
			skipifnotzero
			goto send_databurst_to_fpga
			
			movf received_byte,w
			xorlw 0xd4
			skipifnotzero
			goto set_databurst_base_address

			movf received_byte,w
			xorlw 0xe2
			skipifnotzero
			goto set_databurst_length

			movf received_byte,w
			xorlw 0xf5
			skipifnotzero
			goto erase_eeprom_block

			movf received_byte,w
			xorlw 0x98
			skipifnotzero
			goto write_bytes_to_eeprom

			movf received_byte,w
			xorlw 0x25
			skipifnotzero
			goto set_programming_mode

			movf received_byte,w
			xorlw 0x1f
			skipifnotzero
			goto exit_programming_mode

			movf received_byte,w
			xorlw 0x53
			skipifnotzero
			goto send_eeprom_id

			movf received_byte,w
			xorlw 0x76
			skipifnotzero
			goto send_active_slot

			movf received_byte,w
			xorlw 0x4e
			skipifnotzero
			goto send_firmware_vers

			movf received_byte,w
			xorlw 0x6c
			skipifnotzero
			goto sst_send_eeprom_id

			movf received_byte,w
			xorlw 0x8f
			skipifnotzero
			goto send_status_register


;			movf received_byte,w			; a test command
;			xorlw 0xff
;			skipifnotzero
;			goto write_to_pic_ram

;			movf received_byte,w			; a test command
;			xorlw 0xfe
;			skipifnotzero
;			goto read_pic_ram

			goto wait_cmd_lp

;------------------------------------------------------------------------------------------------------------------------

test_reconf_reset

			btfss startup_mode,0								; ignore button status if configured via JTAG (since we want to allow JTAG mode
			goto wait_cmd_lp									; to be activated by a jumper left on as well as using a button)

			clrf temp3											; button pressed (for 256 loops) ?
jptest		btfsc PORTB,jumper
			goto wait_cmd_lp
			incfsz temp3,f
			goto jptest
			
			movlw portb_default									; LED: off
			movwf PORTB				
		
			call long_pause

waitbrel	btfss PORTB,jumper									; wait button released?
			goto waitbrel

		    call long_pause

			call active_slot_to_cfg_base						; reconfigure FPGA from Active slot
			goto go_configure
			
;------------------------------------------------------------------------------------------------------------------------


send_status_register

			call select_eeprom
			movlw spi_read_status_cmd							; send EEPROM "READ STATUS" command
			call send_byte_to_eeprom

			call get_byte_from_eeprom							; read the EEPROM's Status Register
			movwf received_byte
			call deselect_eeprom							   	; deselect the EEPROM (set its /CS = high)

			movf received_byte,w								
			call send_w_to_fpga								    ; send byte to FPGA
			goto wait_command


;------------------------------------------------------------------------------------------------------------------------


send_firmware_vers

			movlw firmware_vers		
			call send_w_to_fpga
			goto wait_command


;------------------------------------------------------------------------------------------------------------------------


send_eeprom_id

			movlw porta_default-(1<<eeprom_cs)
			movwf PORTA											; Bring SPI EEPROM /CS = Low (new instruction)

			movlw spi_id_cmd									
			call send_byte_to_eeprom							; send eeprom ID command ($ab) to SPI EEPROM 											
			movlw 0
			call send_byte_to_eeprom							; send 3 dummy bytes
			movlw 0
			call send_byte_to_eeprom
			movlw 0
			call send_byte_to_eeprom

			clrf temp2											; PIC requires clock to be high before sending each byte
			clrf temp1											; PIC will wait about 0.1 seconds for this before timing out
wid_clk_hi	btfsc PORTA,comms_clock_in							
			goto id_read_lp
			incfsz temp1,f										
			goto wid_clk_hi										
			incfsz temp2,f
			goto wid_clk_hi
			goto id_timeout

id_read_lp	movlw 8											   ; Clock out the byte from EEPROM							
			movwf temp1											
idbit_lp	movlw portb_default+(1<<comms_clock_out)		   ; set clock hi = latch bit
			movwf PORTB
			movlw portb_default				   				   ; return clock low
			movwf PORTB
			movlw (1<<eeprom_clock)+(1<<i2c_data)			   ; set SPI EEPROM clock high
			movwf PORTA					
			movlw (1<<i2c_data)								   ; set SPI EEPROM clock low = EEPROM shifts out a new bit
			movwf PORTA										   
			decfsz temp1,f
			goto idbit_lp

id_timeout	movlw porta_default								   ; deselect the SPI EEPROM (set its /CS = high)
			movwf PORTA
			goto wait_command

;------------------------------------------------------------------------------------------------------------------------

send_active_slot

			movlw 2											
			call pic_eeprom_read								; get MSB of config base (slot * 2)
			call send_w_to_fpga
			goto wait_command


;------------------------------------------------------------------------------------------------------------------------

set_config_base_address

			call get_byte_from_fpga
			movwf config_base_low
			call get_byte_from_fpga
			movwf config_base_med
			call get_byte_from_fpga
			movwf config_base_high
			goto wait_command

;-----------------------------------------------------------------------------------------------------------------------

make_config_base_permanent

			btfss allow_program,0								; cannot proceed if host has not sent special code
			goto cant_program									; host should check clock line before sending 2 cmd bytes

			call get_byte_from_fpga								
			xorlw 0xd8											; op requires code $d8..
			skipifzero
			goto wait_command
			call get_byte_from_fpga
			xorlw 0x06											; ...followed by $06
			skipifzero
			goto wait_command

			movlw portb_default+(1<<comms_clock_out)			; set pic clock out high = busy
			movwf PORTB

			clrf pic_eeprom_addr								; write the received address to PIC's EEPROM memory.	
			movf config_base_low,w								; upon power on, the FPGA will get its config code from
			call pic_eeprom_write								; this address
			incf pic_eeprom_addr,f								
			movf config_base_med,w
			call pic_eeprom_write
			incf pic_eeprom_addr,f
			movf config_base_high,w
			call pic_eeprom_write

			goto wait_command

;------------------------------------------------------------------------------------------------------------------------

set_databurst_base_address

			call get_byte_from_fpga
			movwf databurst_base_low
			call get_byte_from_fpga
			movwf databurst_base_med
			call get_byte_from_fpga
			movwf databurst_base_high
			goto wait_command

;------------------------------------------------------------------------------------------------------------------------

set_databurst_length

			call get_byte_from_fpga
			movwf databurst_len_low
			call get_byte_from_fpga
			movwf databurst_len_med
			call get_byte_from_fpga
			movwf databurst_len_high
			goto wait_command

;------------------------------------------------------------------------------------------------------------------------

set_programming_mode

			call get_byte_from_fpga
			xorlw 0xfa
			skipifzero
			goto wait_command
			call get_byte_from_fpga
			xorlw 0x99
			skipifzero
			goto wait_command
			bsf allow_program,0
			goto wait_command

;------------------------------------------------------------------------------------------------------------------------

exit_programming_mode

			bcf allow_program,0
			goto wait_command

;------------------------------------------------------------------------------------------------------------------------

send_databurst_to_fpga

			clrf bytecount_l									; subtract length from $1000000 for loop
			clrf bytecount_m
			clrf bytecount_h
        	movf databurst_len_low,w 						 	
        	subwf bytecount_l,f    								 
        	movf databurst_len_med,w 							 
        	skipifcarry                            				 
           	incfsz databurst_len_med,w 							 
            subwf bytecount_m,f									 
        	movf databurst_len_high,w    						 
        	skipifcarry
           	incfsz databurst_len_high,w
            subwf bytecount_h,f

			movlw porta_default-(1<<eeprom_cs)
			movwf PORTA											; Bring SPI EEPROM /CS = Low (new instruction)

			movlw spi_read_cmd									; send read data command ($03) to SPI EEPROM 
			call send_byte_to_eeprom						

			movf databurst_base_high,w						    ; send 24 bit start address to SPI EEPROM, MSB first	
			call send_byte_to_eeprom
			movf databurst_base_med,w
			call send_byte_to_eeprom
			movf databurst_base_low,w			
			call send_byte_to_eeprom

			goto db_clk_lo										; dont wait for clock lo for first byte, go straight to wait clock hi

db_nxt_byte	clrf temp2											; wait for clock from CPU to go low again
			clrf temp1	
db_clk_hi	btfss PORTA,comms_clock_in							
			goto db_clk_lo
			incfsz temp1,f										
			goto db_clk_hi										
			incfsz temp2,f
			goto db_clk_hi
			goto db_timeout

db_clk_lo	clrf temp2											; PIC requires clock to be high before sending a byte
			clrf temp1											; PIC will wait about 0.1 seconds for this before timing out
wdb_clk_hi	btfsc PORTA,comms_clock_in							
			goto rom_read_lp
			incfsz temp1,f										
			goto wdb_clk_hi										
			incfsz temp2,f
			goto wdb_clk_hi
			goto db_timeout

rom_read_lp	movlw 8													  ; Clock out the byte from EEPROM							
			movwf temp1											
rombit_lp	movlw portb_default+(1<<comms_clock_out)+(1<<status_led)  ; set clock hi = latch bit
			movwf PORTB
			movlw portb_default				   				  		  ; return clock low
			movwf PORTB
			movlw (1<<eeprom_clock)+(1<<i2c_data)			  		  ; set SPI EEPROM clock high
			movwf PORTA					
			movlw (1<<i2c_data)								          ; set SPI EEPROM clock low = EEPROM shifts out a new bit
			movwf PORTA										   
			decfsz temp1,f
			goto rombit_lp

			incfsz bytecount_l,f								; count bytes sent - loop if more to go
			goto db_nxt_byte					
			incfsz bytecount_m,f			
			goto db_nxt_byte					
			incfsz bytecount_h,f
			goto db_nxt_byte

db_timeout	movlw porta_default									; deselect the SPI EEPROM (set its /CS = high)
			movwf PORTA
			goto wait_command

;=====================================================================================================================

erase_eeprom_block

			btfss allow_program,0								; cannot proceed if host has not sent special code
			goto cant_program									; host should check clock line before sending 3 byte address

			call get_eeprom_address								; read in 3 bytes
			
			movlw portb_default+(1<<comms_clock_out)			; set pic clock out high = busy
			movwf PORTB

			call sst_write_enable								; if EEPROM is SST type, make sure SR bits [5:2] are clear

			movlw porta_default-(1<<eeprom_cs)
			movwf PORTA											; Bring SPI EEPROM /CS = Low (new instruction)
			movlw spi_write_en_cmd								; send WRITE ENABLE command
			call send_byte_to_eeprom
			movlw porta_default									; deselect the SPI EEPROM (set its /CS = high: end of instruction)
			movwf PORTA											
			call wait_eeprom_wel								; ensure the WRITE ENABLE LATCH is set
			btfsc time_out,0
			goto timeout_error			

			movlw porta_default-(1<<eeprom_cs)
			movwf PORTA											; Bring SPI EEPROM /CS = Low (new instruction)
			movlw spi_erase_cmd									; send erase block command 
			call send_byte_to_eeprom
			call send_eeprom_address							; send the 3 address bytes
			movlw porta_default									; deselect the SPI EEPROM (set its /CS = high)
			movwf PORTA											; this initiates the EEPROM's internal programming operation
			call wait_eeprom_busy								; wait for EEPROMS's block erase to finish
			call long_pause
			call sst_write_protect
			goto wait_command

cant_program
			
			movlw portb_default+(1<<comms_clock_out)			; LED flashes twice to warn not in programming mode
			movwf PORTB											; PIC clock out line is held high for duration
			call long_pause												
			movlw portb_default+(1<<status_led)+(1<<comms_clock_out)		
			movwf PORTB
			call long_pause
			movlw portb_default+(1<<comms_clock_out)			
			movwf PORTB
			call long_pause
			movlw portb_default+(1<<status_led)+(1<<comms_clock_out)	
			movwf PORTB
			call long_pause
			goto wait_command


;=====================================================================================================================


write_bytes_to_eeprom

			btfss allow_program,0								; cannot proceed if host has not sent special code
			goto cant_program									; host should check clock line before sending 3 byte address/datapacket

			incf write_count,f									; flash LED 
			movlw portb_default									
			btfsc write_count,1
			movlw portb_default+(1<<status_led)	
			movwf PORTB		

			call get_eeprom_address								; get 3 bytes for write address
			movlw 64
			movwf buffer_count									; get 64 bytes to program into EEPROM
			movlw 0xa0											
			movwf FSR											; temporarily store them in PIC RAM $a0-$df
readb_loop	call get_byte_from_fpga
			btfsc time_out,0
			goto timeout_error
			movwf INDF
			incf FSR,f
			decfsz buffer_count,f
			goto readb_loop

			movlw portb_default+(1<<comms_clock_out)			; set pic clock out high = busy
			btfsc write_count,1
			movlw portb_default+(1<<comms_clock_out)+(1<<status_led)
			movwf PORTB

			btfsc eeprom_type,0									; if EEPROM is SST type switch to appropriate programming code
			goto sst_write_bytes

			movlw porta_default-(1<<eeprom_cs)
			movwf PORTA											; Bring SPI EEPROM /CS = Low (new instruction)
			movlw spi_write_en_cmd								; send WRITE ENABLE command
			call send_byte_to_eeprom
			movlw porta_default									; deselect the SPI EEPROM (set its /CS = high: end of instruction)
			movwf PORTA											
			call wait_eeprom_wel								; ensure the WRITE ENABLE LATCH is set
			btfsc time_out,0
			goto timeout_error

			movlw porta_default-(1<<eeprom_cs)
			movwf PORTA											; Bring SPI EEPROM /CS = Low (new instruction)
			movlw spi_write_page_cmd							; send write page command 
			call send_byte_to_eeprom
			call send_eeprom_address							; send the destination address
			movlw 64
			movwf buffer_count									; write the 64 bytes from PIC RAM to the EEPROM
			movlw 0xa0													
			movwf FSR											; read them from $a0-$bf
writeb_loop	movf INDF,w
			call send_byte_to_eeprom
			incf FSR,f
			decfsz buffer_count,f
			goto writeb_loop

			movlw porta_default									; deselect the SPI EEPROM (set its /CS = high)
			movwf PORTA											; this initiates the EEPROM's internal programming operation
			call wait_eeprom_busy								; wait for EEPROM's internal write operation to complete
			btfsc time_out,0
			goto timeout_error
	
verify		movlw porta_default-(1<<eeprom_cs)					; verify the 64 bytes just written
			movwf PORTA											; Bring SPI EEPROM /CS = Low (new instruction)
			movlw spi_read_cmd									; send read data command ($03) to SPI EEPROM 
			call send_byte_to_eeprom						
			call send_eeprom_address
			movlw 64
			movwf buffer_count									
			movlw 0xa0													
			movwf FSR											
ver_loop	call get_byte_from_eeprom
			movf INDF,w
			xorwf received_byte,w
			skipifzero
			goto ver_error
			incf FSR,f
			decfsz buffer_count,f
			goto ver_loop

			movlw porta_default									; deselect the SPI EEPROM (set its /CS = high)
			movwf PORTA											
			goto wait_command

ver_error	movlw 5												; If the 64 bytes read back do not match those in PIC's memory
			movwf busy_flash									; flash the LED 5 times, keeping the PIC clock out line high
verr_loop	movlw portb_default+(1<<comms_clock_out)			
			movwf PORTB									
			call long_pause												
			movlw portb_default+(1<<status_led)+(1<<comms_clock_out)		
			movwf PORTB
			call long_pause
			decfsz busy_flash,f
			goto verr_loop			
			movlw porta_default									; deselect the SPI EEPROM (set its /CS = high)
			movwf PORTA											
			goto wait_command									; abort operation and go to wait_command

;--------------------------------------------------------------------------------------------------------------

timeout_error

			movlw 10											; If the PIC timed out waiting for data from CPU (FPGA)
			movwf busy_flash									; flash the LED 10 times, keeping the PIC clock out line high

to_loop		movlw portb_default+(1<<comms_clock_out)			
			movwf PORTB									
			call long_pause												
			movlw portb_default+(1<<status_led)+(1<<comms_clock_out)		
			movwf PORTB
			call long_pause
			
			decfsz busy_flash,f
			goto to_loop			
			
			goto wait_command									; abort operation and go to wait_command (dont jump to timeout_error from with a subroutine)


;********** Called routines **************************************************************************************

wait_eeprom_wel

			clrf time_out

			movlw portb_default+(1<<comms_clock_out)			; LED is off whilst waiting (keep PIC clock high)
			movwf PORTB

		    movlw porta_default-(1<<eeprom_cs)
			movwf PORTA											; Bring SPI EEPROM /CS = Low (new instruction)
			movlw spi_read_status_cmd							; send READ STATUS command
			call send_byte_to_eeprom
			
			clrf temp1
			clrf temp2
			movlw 10
			movwf temp3
wel_loop	call get_byte_from_eeprom							; read status byte from EEPROM
			btfsc received_byte,1								; until "WEL" flag (bit 1) is set
			goto wel_set
			incfsz temp1,f
			goto wel_loop
			incfsz temp2,f
			goto wel_loop
			decfsz temp3,f
			goto wel_loop
			bsf time_out,0

wel_set		movlw porta_default									; deselect the SPI EEPROM (set its /CS = high: end of instruction)
			movwf PORTA
			return	

;-------------------------------------------------------------------------------------------------------------------
						
wait_eeprom_busy

			clrf time_out

			movlw portb_default+(1<<comms_clock_out)			; LED is off whilst waiting (keep PIC clock high)
			movwf PORTB											

		    movlw porta_default-(1<<eeprom_cs)
			movwf PORTA											; Bring SPI EEPROM /CS = Low (new instruction)
			movlw spi_read_status_cmd							; send READ STATUS command
			call send_byte_to_eeprom
			
			clrf temp1
			clrf temp2
			movlw 10
			movwf temp3
wip_loop	call get_byte_from_eeprom							; read status byte from EEPROM
			btfss received_byte,0								; until "write in progress busy" flag (BSY: bit 0) is clear
			goto not_busy
			incfsz temp1,f
			goto wip_loop
			incfsz temp2,f
			goto wip_loop
			decfsz temp3,f
			goto wip_loop
busy_error	movlw porta_default									; deselect the SPI EEPROM (set its /CS = high: end of instruction)
			movwf PORTA
			bsf time_out,0
			return	

not_busy	movlw porta_default									; deselect the SPI EEPROM (set its /CS = high: end of instruction)
			movwf PORTA
			return
						
;-------------------------------------------------------------------------------------------------------------------

get_byte_from_eeprom

			clrf received_byte
			movlw 8
			movwf bitcount									
gbfe_loop	bcf STATUS,0										; clear carry flag
			rlf received_byte,f
			btfsc PORTB,eeprom_data_out
			bsf received_byte,0
			movlw (1<<eeprom_clock)+(1<<i2c_data)				; raise the EEPROM clock line
			movwf PORTA
			nop
			nop
			movlw (1<<i2c_data)
			movwf PORTA											; drop EEPROM clock line
			decfsz bitcount,f
			goto gbfe_loop
			movf received_byte,w
			return

;---------------------------------------------------------------------------------------------------------------------

get_eeprom_address

			call get_byte_from_fpga								; get 3 bytes for address
			movwf eeprom_address_low
			call get_byte_from_fpga
			movwf eeprom_address_med
			call get_byte_from_fpga
			movwf eeprom_address_high
			return

;------------------------------------------------------------------------------------------------------------------

get_byte_from_fpga

			movlw 8												; This routine has transmission speed limits
			movwf bitcount										; Minimum speed ~ 2 KHz  
			clrf time_out										; Max recommended speed ~ 100 KHz
			clrf received_byte

next_fcbit	bcf STATUS,0										; clear carry flag
			rlf received_byte,f									; rotate serial register
			clrf temp1	
wait_bffch	call comms_clk_average								; wait for clock high 
			btfsc average,2
			goto gbff_clk_hi
			incfsz temp1,f										; loop 256 times and then time out
			goto wait_bffch										
			bsf time_out,0
			movlw 0xff
			movwf received_byte
			return

gbff_clk_hi	nop													; wait 5 uS after clock goes high before sampling
			nop													; the data pin
			nop
			nop
			nop
			nop
			nop
			nop
			nop
			nop
			nop
			nop
			nop
			nop
			nop
			nop
			nop
			nop
			nop
			nop
			nop
			nop
			nop
			nop
			nop
			call data_in_average
			btfsc average,2										; read bit from FPGA init line
			bsf received_byte,0

			clrf temp1
wait_bffcl	call comms_clk_average	
			btfss average,2										; wait for clock low
			goto gbff_clk_lo
			incfsz temp1,f										; loop 256 times and then time out
			goto wait_bffcl										
			bsf time_out,0
			movlw 0xff
			movwf received_byte
			return
			
gbff_clk_lo	decfsz bitcount,f									; loop for 8 bits
			goto next_fcbit

			movf received_byte,w								; return byte in W
			return


data_in_average

			clrf average
			btfsc PORTB,fpga_init							
			incf average,f
			btfsc PORTB,fpga_init							
			incf average,f
			btfsc PORTB,fpga_init							
			incf average,f
			btfsc PORTB,fpga_init							
			incf average,f
			btfsc PORTB,fpga_init							
			incf average,f
			btfsc PORTB,fpga_init							
			incf average,f
			btfsc PORTB,fpga_init							
			incf average,f
			return

comms_clk_average

			clrf average
			btfsc PORTA,comms_clock_in							
			incf average,f
			btfsc PORTA,comms_clock_in						
			incf average,f
			btfsc PORTA,comms_clock_in						
			incf average,f
			btfsc PORTA,comms_clock_in						
			incf average,f
			btfsc PORTA,comms_clock_in						
			incf average,f
			btfsc PORTA,comms_clock_in							
			incf average,f
			btfsc PORTA,comms_clock_in						
			incf average,f
			return

;------------------------------------------------------------------------------------------------------------------------

send_w_to_fpga

			movwf databyte
			clrf time_out
			movlw 8
			movwf bitcount
			
sas_bitloop	clrf temp2											; wait clock low
			clrf temp1											; PIC will wait about 0.1 seconds for this before timing out
wasb_clk_lo	btfss PORTA,comms_clock_in							
			goto was_chi
			incfsz temp1,f										
			goto wasb_clk_lo									
			incfsz temp2,f
			goto wasb_clk_lo
			goto sas_timeout

was_chi		clrf temp2											; wait clock hi
			clrf temp1											; PIC will wait about 0.1 seconds for this before timing out
wasb_clk_hi	btfsc PORTA,comms_clock_in							
			goto nxtasbit
			incfsz temp1,f										
			goto wasb_clk_hi										
			incfsz temp2,f
			goto wasb_clk_hi
			goto sas_timeout

nxtasbit	movlw portb_default									; present a new bit on RB7 now that the clock is high
			btfsc databyte,7
			movlw portb_default+(1<<comms_clock_out)
			movwf PORTB
			rlf databyte,f
			decfsz bitcount,f
			goto sas_bitloop

			clrf temp2											; wait for clock to return low after final bit presented 
			clrf temp1											; it is at this point the CPU samples RB7
wclklo_exit	btfss PORTA,comms_clock_in							
			goto psb_exit
			incfsz temp1,f										
			goto wclklo_exit								
			incfsz temp2,f
			goto wclklo_exit
			goto sas_timeout

psb_exit	movlw 64											; allow some time for CPU to read the last bit on RB7 before it is
			movwf temp1											; cleared by the subsequent PIC code
psb_xdelay	decfsz temp1,f									
			goto psb_xdelay
			movlw portb_default
			movwf PORTB
			return

sas_timeout	bsf time_out,0
			movlw portb_default
			movwf PORTB
			return

;-------------------------------------------------------------------------------------------------------------------

send_eeprom_address

			movf eeprom_address_high,w							; send 24 bit start address to SPI EEPROM, MSB first	
			call send_byte_to_eeprom
			movf eeprom_address_med,w
			call send_byte_to_eeprom
			movf eeprom_address_low,w			
			call send_byte_to_eeprom
			return

;-------------------------------------------------------------------------------------------------------------------

send_byte_to_eeprom

			movwf temp1											; send byte in W to SPI EEPROM
			movlw 8
			movwf bitcount									
sb_loop		movlw (1<<i2c_data)				
			rlf temp1,f
			skipifnotcarry
			iorlw (1<<eeprom_data_in)							; present data bit to EEPROM
			movwf PORTA
			iorlw (1<<eeprom_clock)								; raise the EEPROM clock line
			movwf PORTA
			xorlw (1<<eeprom_clock)								; drop the EEPROM clock line
			movwf PORTA
			decfsz bitcount,f									; loop to next bit
			goto sb_loop
			return

;----------------------------------------------------------------------------------------------------

pic_eeprom_write

			banksel EEADR	 									;Bank 1
			movwf EEDATA										;put byte to write in W
			movf pic_eeprom_addr,w
			movwf EEADR											;address to write to
			BSF EECON1, WREN 									;Enable write
			MOVLW 0x55 											;
			MOVWF EECON2 										;Write 55h
			MOVLW 0xAA 											;
			MOVWF EECON2 										;Write AAh
			BSF EECON1,WR 										;Set WR bit
wait_epwr	btfsc EECON1,WR										;wait for WR bit to be cleared by HW
			goto wait_epwr	
			BCF EECON1, WREN 									;disable EE writes
			banksel PORTA
			return


pic_eeprom_read

		    banksel EEADR										; bank 1
			MOVWF EEADR 										; Put address to read in W
			BSF EECON1, RD 										; EE Read
			MOVF EEDATA, W 										; W = EEDATA
			banksel PORTA   									; Bank 0
			return

;-----------------------------------------------------------------------------------------------------

long_pause	movlw 5												; approx 0.25 seconds (20MHz clock)
			movwf temp3
lp_loop		call short_pause
			decfsz temp3,f
			goto lp_loop
			return


short_pause	clrf temp2											; approx 0.052 seconds (20MHz clock)									 
			clrf temp1									
swlp1		nop
			incfsz temp1,f			
			goto swlp1			
			incfsz temp2,f			
			goto swlp1
			return


vshort_pause

			clrf temp1											; approx 200 microseconds (20MHz Clock)
vsh_pause	nop
			decfsz temp1,f
			goto vsh_pause
			return


pause_1ms	movlw 5
			movwf temp2											; approx 1 millisecond (20MHz clock)									 
			clrf temp1									
msplp1		nop
			incfsz temp1,f			
			goto msplp1			
			decfsz temp2,f			
			goto msplp1
			return


short_pause_esc_if_done

			movlw 160
			movwf temp2											; approx 0.05 seconds (20MHz clock)									 
			clrf temp1											; quits immediately if done is high
shpeidlp	btfsc PORTB,fpga_done
			return
			incfsz temp1,f			
			goto shpeidlp			
			decfsz temp2,f			
			goto shpeidlp
			return


;------------------------------------------------------------------------------------------------------
; Alternate EEPROM support
;------------------------------------------------------------------------------------------------------


get_eeprom_id

			call select_eeprom
			movlw spi_id_cmd									
			call send_byte_to_eeprom							; send eeprom ID command ($ab) to SPI EEPROM 											
			movlw 0
			call send_byte_to_eeprom							; send 3 dummy bytes
			movlw 0
			call send_byte_to_eeprom
			movlw 0
			call send_byte_to_eeprom

			call get_byte_from_eeprom
			movwf eeprom_id		
			xorlw 0xbf
			skipifzero											; is it an SST chip?
			goto id_done

			call get_byte_from_eeprom							; following byte is device ID
			movwf eeprom_id	
			call sst_device_id_to_cap
			movwf eeprom_id										; if so, set ID as standard 25x type (32MBit)
			movlw 0x01
			movwf eeprom_type									; set eeprom type to SST
			
id_done		call deselect_eeprom
			return


sst_device_id_to_cap
			
			movf eeprom_id,w									;sst25vf16 (16 Mbit)
			xorlw 0x41
			skipifnotzero
			retlw 0x14

			movf eeprom_id,w									;sst25vf32 (32 Mbit)
			xorlw 0x4a
			skipifnotzero
			retlw 0x15

			retlw 0x13											;if neither, default to 25vf080 (8 Mbit)

;------------------------------------------------------------------------------------------------------


sst_send_eeprom_id

			movf eeprom_id,w
			call send_w_to_fpga
			goto wait_command


;------------------------------------------------------------------------------------------------------


sst_write_bytes
			
			call sst_write_enable								; clear SR [5:2] 

			call select_eeprom
			movlw spi_write_en_cmd								; send WRITE ENABLE command
			call send_byte_to_eeprom
			call deselect_eeprom
														
			call select_eeprom
			movlw sst_aai_write_cmd								; send SST style write bytes command 
			call send_byte_to_eeprom

			call send_eeprom_address							; and send the destination address

			movlw 0xa0													
			movwf FSR											; send first two bytes from $a0 and $a1
			movf INDF,w
			call send_byte_to_eeprom							; send byte 0
			incf FSR,f
			movf INDF,w
			call send_byte_to_eeprom							; send byte 1
			incf FSR,f

			call deselect_eeprom								; deselect the SPI EEPROM (set its /CS = high)
										
			call wait_eeprom_busy								; check EEPROM is not busy
			btfsc time_out,0
			goto timeout_error

			movlw 31
			movwf buffer_count									; write the next 31 words from PIC RAM to the EEPROM

sstwr_loop	call select_eeprom
			movlw sst_aai_write_cmd								; send sst write bytes command again - no address this time 
			call send_byte_to_eeprom							

			movf INDF,w
			call send_byte_to_eeprom							; send byte 0
			incf FSR,f
			movf INDF,w
			call send_byte_to_eeprom							; send byte 1
			incf FSR,f

			call deselect_eeprom								

			call wait_eeprom_busy								; check EEPROM busy is clear
			btfsc time_out,0
			goto timeout_error

			decfsz buffer_count,f
			goto sstwr_loop

			call select_eeprom
			movlw sst_wrdi_cmd									; terminate AAI command
			call send_byte_to_eeprom							
			call deselect_eeprom													

			call wait_eeprom_busy								; check EEPROM busy is clear
			btfsc time_out,0
			goto timeout_error

			call sst_write_protect
			goto verify


;------------------------------------------------------------------------------------------------------------------------


sst_write_enable

			btfss eeprom_type,0									; is EEPROM an SST type? If so clear bits 5:2 of SR
			return												; These bits are volatile on SST EEPROMS not flash

			call select_eeprom									; send EEPROM "WRITE ENABLE" command
			movlw spi_write_en_cmd								
			call send_byte_to_eeprom
			call deselect_eeprom

			call select_eeprom									; Bring EEPROM /CS = Low (new instruction)
			movlw spi_write_sr_cmd								; send EEPROM "Write to status register" command 
			call send_byte_to_eeprom
			movlw 0x00											; clear the SR protection bits [5:2] 
			call send_byte_to_eeprom
			call deselect_eeprom								 
			return


;------------------------------------------------------------------------------------------------------------------------


sst_write_protect

			btfss eeprom_type,0									; is EEPROM an SST type? If so set bits 5:2 of SR
			return												; These bits are volatile on SST EEPROMS not flash

			call select_eeprom									; NOTE: THE SR protect bits are VOLATILE on the SST
			movlw spi_write_en_cmd								; send EEPROM "WRITE ENABLE" command
			call send_byte_to_eeprom
			call deselect_eeprom

			call select_eeprom									; Bring EEPROM /CS = Low (new instruction)
			movlw spi_write_sr_cmd								; send EEPROM "Write to status register" command 
			call send_byte_to_eeprom
			movlw 0x3c											; set all block protect bits [5:2] 
			call send_byte_to_eeprom
			call deselect_eeprom								
			return

			
;---------------------------------------------------------------------------------------------------------------------------------

select_eeprom

			movlw porta_default-(1<<eeprom_cs)
			movwf PORTA											; Bring SPI EEPROM /CS = Low (new instruction)
			return


deselect_eeprom

			movlw porta_default									; deselect the SPI EEPROM (set its /CS = high)
			movwf PORTA											
			return


;---------------------------------------------------------------------------------------------------------------------------------

active_slot_to_cfg_base

			movlw 0											; get default values for FPGA config location from PIC's flash RAM
			call pic_eeprom_read
			movwf config_base_low
			movlw 1										
			call pic_eeprom_read
			movwf config_base_med
			movlw 2											
			call pic_eeprom_read
			movwf config_base_high
			return

;------------------------------------------------------------------------------------------------------------------------------
; Test commands
;-------------------------------------------------------------------------------------------------------------------------------
;
;write_to_pic_ram
;
;			movlw 64
;			movwf buffer_count									; get 64 bytes from FPGA - store them in PIC RAM $a0-$df
;			movlw 0xa0											
;			movwf FSR											
;wpr_loop	call get_byte_from_fpga
;			btfsc time_out,0
;			goto timeout_error
;			movwf INDF
;			incf FSR,f
;			decfsz buffer_count,f
;			goto wpr_loop
;			goto wait_command
;
;
;read_pic_ram
;
;			movlw 64
;			movwf buffer_count									; send 64 bytes from PIC ram to FPGA
;			movlw 0xa0											
;			movwf FSR											
;rpr_loop	movf INDF,w
;			call send_w_to_fpga
;			btfsc time_out,0
;			goto timeout_error
;			incf FSR,f
;			decfsz buffer_count,f
;			goto rpr_loop
;			goto wait_command
;

;-----------------------------------------------------------------------------------------------------------------------------
;------ EEPROM DATA ----------------------------------------------------------------------------------------------------------
;-----------------------------------------------------------------------------------------------------------------------------


			ORG 0x2100

    	    DE 0x00,0x00,0x02									; default FPGA config base address low,mid,high
																; 0x20000 ("slot 1")

;*****************************************************************************************************************************

			END                     						  ; directive 'end of program'
