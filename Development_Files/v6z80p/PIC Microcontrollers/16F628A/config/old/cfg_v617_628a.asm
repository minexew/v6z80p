; ------------------------------------------------------------------------------
; PIC 16F628A SPI serial EEPROM Reader / Spartan II FGPA configurator for V6Z80P
; ------------------------------------------------------------------------------
; By Phil Ruston '08-'09
; Version : V6.17 for V6Z80P
;
; v6.17 - Read slot command and Read EEPROM ID command added
;
; v6.16 - Emergency slot reset. If JTAG jumper is installed whilst in JTAG config mode
; the slot is reset to 20000,40000,60000 in sequence. Power off when the yellow led
; come on after desired slot number indicated by red led flashes.
;
; This program clocks out configuration data bits from a 25XXX series SPI SERIAL EEPROM to configure
; FPGA. Afterwards, it accepts commands from the FPGA to perform tasks such as reprogram
; the EEPROM, send data to the FPGA from the EEPROM (either to reconfigure it or simply read
; bytes) 

; On power up PIC waits for "fpga_init" pin to be high before FPGA config transmission starts*.
; PIC's "FPGA_clock" pin drives FPGA "CCLK" to latch in (rising edge) data bits from the
; EEPROM'S data_out pin during config. Config data is transmitted in byte-sized packets, MSB first.
; One byte is transmitted every 19 (approx) PIC cycles. EG: At 16Mhz the transfer rate is 210KB/Sec
; When all bytes have been sent the PIC checks "FPGA DONE", if it is low the FPGA did not start
; so the status LED flashes once then PGM line pulses low and the programming cycle repeats.
; Once all bytes have been sent and FPGA has started up correctly, Status LED 1 is switched on.
; At this point the PIC listens for commands on the "FPGA clock in" (RA5) and "FPGA INIT" (RB1)
; lines. The PIC does not have a direct data *OUT* line to the FPGA - not without changing
; the port direction at least - data bits come direct from EEPROM. However error/busy status
; can be tested at the FPGA by reading the "PIC clock out" status. If the PIC is holding it high
; the host can take the appropriate action.

; * If JTAG override jumper is on (manual programming), status LED 1 flashes fast until DONE line is
; high then stays lit, the PIC then waits for commands as normal.

; External hardware:
; ------------------
; PIC uses external 16MHz system clock source
;
;                  16F627/8A
;		 	       .---_----.
;   FPGA CLK <- A2 |1     18| A1 -> SPI CLK
;  JTAG_mode -> A3 |2     17| A0 -> SPI CS
;   SPI D_OUT-> A4 |3     16| <- Sys clock 16MHz
; FPGA Clk in-> A5 |4     15| A6 -> SPI D_IN 
;			   GND |5     14| + 3.3V
;  FPGA PGM	 <- B0 |6     13| B7 -> PIC CLK OUT
;  FPGA INIT -> B1 |7     12| B6 -> n/u
;  FPGA DONE -> B2 |8     11| B5 -> n/u
;      LED 1 <- B3 |9     10| B4 -> LED 2
;			       |________|
;
; FPGA's INIT and DONE lines should be pulled to Vcc via 3.3K resistors (whether used
; or not). Decouple PIC with 0.1uf cap across Vcc and GND. Connect status LEDs via a 1K resistor.
;
;             SPI 25XXX EEPROM
;		 	    .---_----.
;          /CS  |1      8| Vcc +3.3V              
;         D_OUT |2      7| /HOLD           
;            WP |3      6| CLK IN     
;		    GND |4      5| DATA IN     
;               |________|
;
; Note: Tie "/HOLD" and "WP" to Vcc.
; Connect /CS to Vcc via 10K resistor (to ensure good start-up, as per datasheet)
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

; * Programming mode must be enabled first
; # The 64KB EEPROM block in which the bytes are to be located must be erased prior to programming new data

;--- GENERIC HEADER AND CLOCK OPTIONS ----------------------------------------------------------------------

	list      p=16f628A            ; list directive to define processor
	list	r=decimal

	#include <p16f628A.inc>        ; processor specific variable definitions

	#define skipifzero        btfss STATUS,Z        
	#define skipifnotzero     btfsc STATUS,Z
	#define skipifcarry       btfss STATUS,C        
	#define skipifnotcarry    btfsc STATUS,C
	
	__CONFIG _CP_OFF & _WDT_OFF & _BODEN_OFF & _PWRTE_ON & _EXTCLK_OSC & _MCLRE_OFF & _LVP_OFF


;-----Defaults ----------------------------------------------------------------------------------------

fpga_config_length 	equ 130012	 				; Length of FPGA's .bin config file (see PIC EEPROM RAM for location) 

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

slot				EQU 	0x3a

;--------------------------------------------------------------------------------------------

pic_eeprom_addr		EQU		0x70

;---  Project constants --------------------------------------------------------------------

spi_cs				equ	0	;out				 Port A bit assignments
spi_clock			equ 1	;out
fpga_cclk			equ 2	;out				 
jtag_mode 		 	equ 3	;in
spi_data_out		equ 4   ;in
fpga_clock_in		equ 5	;in
spi_data_in			equ 6   ;out

fpga_program  		equ 0   ;out				 Port B bit assignments
fpga_init			equ 1	;in 
fpga_done     		equ 2	;in
status_led_1		equ 3	;out
status_led_2		equ 4	;out
pic_clock_out		equ 7	;out

spi_write_page_cmd	equ 0x02
spi_read_cmd		equ 0x03
spi_read_status_cmd	equ 0x05
spi_write_en_cmd	equ 0x06
spi_erase_cmd		equ 0xd8
spi_id_cmd			equ 0xab

;*********************************************************************************************

	ORG     0x000      			 							; processor reset vector

			goto init_code    								; go to beginning of program

	ORG     0x004       									; interrupt vector location

			retfie            								; return from interrupt

;---------- INITIALIZE PIC FOR THIS PROJECT ----------------------------------------------------------

init_code	movlw b'00000111'		
			movwf CMCON										; use digital mode for PORTA (disable comparitors)
			banksel TRISA
			movlw b'00111000'								; set data direction for port A
			movwf TRISA
			movlw b'00000110'								; set data direction for port B
			movwf TRISB
			banksel PORTA

;------------------------------------------------------------------------------------------------------

			movlw 0											; get default values for FPGA config location
			call pic_eeprom_read
			movwf config_base_low
			movlw 1										
			call pic_eeprom_read
			movwf config_base_med
			movlw 2											
			call pic_eeprom_read
			movwf config_base_high

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

;--------------------------------------------------------------------------------------------------
;---------- Main SPI -> FPGA config code ----------------------------------------------------------
;--------------------------------------------------------------------------------------------------

configure_fpga

			clrf allow_program									; PIC/EEPROM programming disabled by default

			movlw  (1<<spi_cs)									; deselect the SPI EEPROM (set its /CS = high)
			movwf PORTA
			movlw (1<<fpga_program)								; set FPGA program lines inactive
			movwf PORTB											

			call short_pause

;-----------IS JTAG JUMPER ON? ----------------------------------------------------------------------

check_jtag	btfsc PORTA,jtag_mode								; JTAG or EEPROM config?
			goto go_configure

wait_jtag	movlw 0xf8
			movwf temp2
			clrf temp1
chk_done	btfss PORTB,fpga_done								
			goto done_low
			incfsz temp1,f										; resample "done" - ensure it is permanently high
			goto chk_done
			incfsz temp2,f
			goto chk_done
			goto wait_command			

done_low	movlw (1<<fpga_program)+(1<<status_led_1)			; set pic clock out high = busy
			movwf PORTB											; flash LED when waiting for JTAG config
			call short_pause_esc_if_done
			movlw (1<<fpga_program)
			movwf PORTB
			call short_pause_esc_if_done

chkjtag2	btfss PORTA,jtag_mode								; has jumper been installed whilst in JTAG mode?
			goto check_jtag										; If so, go to emergency slot reset mode

;---------- Emergency slot reset mode -------------------------------------------------------------------------

slot_loop	rrf slot_cycle,w									; flash the red led "SLOT" number of times
			andlw 3
			movwf temp4
s2_ledfl	call long_pause
			bsf PORTB,status_led_2								
			call long_pause
			bcf PORTB,status_led_2			
			decfsz temp4,f
			goto s2_ledfl
			call long_pause

			clrf pic_eeprom_addr								; write the slot number	to PIC flashram
			movlw 0											
			call pic_eeprom_write							
			incf pic_eeprom_addr,f								
			movlw 0
			call pic_eeprom_write
			incf pic_eeprom_addr,f
			movf slot_cycle,w
			call pic_eeprom_write

			bsf PORTB,status_led_1								; wait about 4 seconds. status led on 
			movlw 16
			movwf temp4
eswlp		call long_pause
			decfsz temp4,f
			goto eswlp
			bcf PORTB,status_led_1

			incf slot_cycle,f									; next slot.. 2,4,6
			incf slot_cycle,f
			btfss slot_cycle,3									; if slot = 8, stop
			goto slot_loop
			
stop_here	goto stop_here

;----------- Configure FPGA - Slave Serial mode via PIC and EEPROM --------------------------------------------

go_configure

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

;---------- Send sequential read command to SPI EEPROM --------------------------------------------

			clrf PORTA											; Bring SPI EEPROM /CS = Low (new instruction)

			movlw spi_read_cmd									; send read data command ($03) to SPI EEPROM 
			call send_byte_to_eeprom						

			movf config_base_high,w								; send 24 bit start address to SPI EEPROM, MSB first	
			call send_byte_to_eeprom
			movf config_base_med,w
			call send_byte_to_eeprom
			movf config_base_low,w		
			call send_byte_to_eeprom

;---------- Read the data from EEPROM and Config FPGA with a fast read loop -----------------------------------------------------------------------------

			movlw (1<<spi_clock)+(1<<fpga_cclk)

read_loop	movwf PORTA											;fpga latches bit 7
			CLRF PORTA											;spi eeprom shifts out bit 6
			movwf PORTA											;fpga latches bit 6		
			CLRF PORTA											;spi eeprom shifts out bit 5	
			movwf PORTA											;fpga latches bit 5
			CLRF PORTA											;spi eeprom shifts out bit 4
			movwf PORTA											;fpga latches bit 4
			CLRF PORTA											;spi eeprom shifts out bit 3
			movwf PORTA											;fpga latches bit 3
			CLRF PORTA											;spi eeprom shifts out bit 2
			movwf PORTA											;fpga latches bit 2
			CLRF PORTA											;spi eeprom shifts out bit 1
			movwf PORTA											;fpga latches bit 1
			CLRF PORTA											;spi eeprom shifts out bit 0
			movwf PORTA											;fpga latches bit 0
			CLRF PORTA											;spi eeprom shifts out bit 7

			incfsz bytecount_l,f								; count bytes sent - loop if more to go
			goto read_loop					
			incfsz bytecount_m,f			
			goto read_loop					
			incfsz bytecount_h,f
			goto read_loop

;---------- Check configured -----------------------------------------------------------------------------------------

			call vshort_pause

			btfsc PORTB,fpga_done								; All bytes sent - Check that the FPGA started up 
			goto fpga_done_hi									; (Its "DONE" line should be high now)

			movlw  (1<<spi_cs)									; If not, deselect the SPI EEPROM (set its /CS = high)
			movwf PORTA											; flash the LED once and re-try							
			bsf PORTB,status_led_1								
			call long_pause
			bcf PORTB,status_led_1
			call long_pause
			call long_pause
  			goto configure_fpga				

fpga_done_hi

			movlw  (1<<spi_cs)									; deselect the SPI EEPROM (set its /CS = high)
			movwf PORTA
			
			call vshort_pause

;--------------------------------------------------------------------------------------------------------------------			
;----------- Post config actions ------------------------------------------------------------------------------------
;--------------------------------------------------------------------------------------------------------------------

wait_command

			movlw (1<<fpga_program)+(1<<status_led_1)			; LED 1 ON = FPGA configured, PIC waiting for command..	
			btfsc allow_program,0
			iorlw (1<<status_led_2)								; LED 2 ON if EEPROM programming is enabled
			movwf PORTB

wait_cmd_lp	call get_byte_from_fpga								; all commands must begin with $88
			xorlw 0x88
			skipifzero
			goto wait_cmd_lp

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
			goto send_chip_id

			movf received_byte,w
			xorlw 0x76
			skipifnotzero
			goto send_active_slot

			goto wait_cmd_lp

;------------------------------------------------------------------------------------------------------------------------

send_chip_id

			clrf PORTA											; Bring SPI EEPROM /CS = Low (new instruction)
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
wid_clk_hi	btfsc PORTA,fpga_clock_in							
			goto id_read_lp
			incfsz temp1,f										
			goto wid_clk_hi										
			incfsz temp2,f
			goto wid_clk_hi
			goto id_timeout

id_read_lp	movlw 8											   ; Clock out the byte from EEPROM							
			movwf temp1											
idbit_lp	movlw (1<<fpga_program)+(1<<pic_clock_out)		   ; set clock hi = latch bit
			movwf PORTB
			movlw (1<<fpga_program)			   				   ; return clock low
			movwf PORTB
			movlw (1<<spi_clock)							   ; set SPI EEPROM clock high
			movwf PORTA					
			movlw 0											   ; set SPI EEPROM clock low = EEPROM shifts out a new bit
			movwf PORTA										   
			decfsz temp1,f
			goto idbit_lp

id_timeout	movlw  (1<<spi_cs)									; deselect the SPI EEPROM (set its /CS = high)
			movwf PORTA
			goto wait_command

;------------------------------------------------------------------------------------------------------------------------

send_active_slot

			movlw 2											
			call pic_eeprom_read								; get MSB of config base (slot * 2)
			movwf slot
			movlw 8
			movwf bitcount

sas_bitloop	clrf temp2											; wait clock low
			clrf temp1											; PIC will wait about 0.1 seconds for this before timing out
wasb_clk_lo	btfss PORTA,fpga_clock_in							
			goto was_chi
			incfsz temp1,f										
			goto wasb_clk_lo									
			incfsz temp2,f
			goto wasb_clk_lo
			goto sas_timeout

was_chi		clrf temp2											; wait clock hi
			clrf temp1											; PIC will wait about 0.1 seconds for this before timing out
wasb_clk_hi	btfsc PORTA,fpga_clock_in							
			goto nxtasbit
			incfsz temp1,f										
			goto wasb_clk_hi										
			incfsz temp2,f
			goto wasb_clk_hi
			goto sas_timeout

nxtasbit	movlw (1<<fpga_program)								; present a new bit on RB7 when the clock goes hi
			btfsc slot,7
			movlw (1<<fpga_program)+(1<<pic_clock_out)
			movwf PORTB
			rlf slot,f
			decfsz bitcount,f
			goto sas_bitloop

sas_timeout	movlw (1<<fpga_program)
			movwf PORTB
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

			movlw (1<<fpga_program)+(1<<pic_clock_out)			; set pic clock out high = busy
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

			clrf PORTA											; Bring SPI EEPROM /CS = Low (new instruction)

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
db_clk_hi	btfss PORTA,fpga_clock_in							
			goto db_clk_lo
			incfsz temp1,f										
			goto db_clk_hi										
			incfsz temp2,f
			goto db_clk_hi
			goto db_timeout

db_clk_lo	clrf temp2											; PIC requires clock to be high before sending a byte
			clrf temp1											; PIC will wait about 0.1 seconds for this before timing out
wdb_clk_hi	btfsc PORTA,fpga_clock_in							
			goto rom_read_lp
			incfsz temp1,f										
			goto wdb_clk_hi										
			incfsz temp2,f
			goto wdb_clk_hi
			goto db_timeout

rom_read_lp	movlw 8											   ; Clock out the byte from EEPROM							
			movwf temp1											
rombit_lp	movlw (1<<fpga_program)+(1<<pic_clock_out)		   ; set clock hi = latch bit
			movwf PORTB
			movlw (1<<fpga_program)			   				   ; return clock low
			movwf PORTB
			movlw (1<<spi_clock)							   ; set SPI EEPROM clock high
			movwf PORTA					
			movlw 0											   ; set SPI EEPROM clock low = EEPROM shifts out a new bit
			movwf PORTA										   
			decfsz temp1,f
			goto rombit_lp

			incfsz bytecount_l,f								; count bytes sent - loop if more to go
			goto db_nxt_byte					
			incfsz bytecount_m,f			
			goto db_nxt_byte					
			incfsz bytecount_h,f
			goto db_nxt_byte

db_timeout	movlw  (1<<spi_cs)									; deselect the SPI EEPROM (set its /CS = high)
			movwf PORTA
			goto wait_command

;=====================================================================================================================

erase_eeprom_block

			btfss allow_program,0								; cannot proceed if host has not sent special code
			goto cant_program									; host should check clock line before sending 3 byte address

			call get_eeprom_address								; read in 3 bytes
			
			movlw (1<<fpga_program)+(1<<pic_clock_out)			; set pic clock out high = busy
			movwf PORTB

			clrf PORTA											; select the EEPROM (/cs = low: new instruction)
			movlw spi_write_en_cmd								; send WRITE ENABLE command
			call send_byte_to_eeprom
			movlw (1<<spi_cs)									; deselect the SPI EEPROM (set its /CS = high: end of instruction)
			movwf PORTA											
			call wait_eeprom_wel								; ensure the WRITE ENABLE LATCH is set

			clrf PORTA											; Bring SPI EEPROM /CS = Low (new instruction)
			movlw spi_erase_cmd									; send erase block command 
			call send_byte_to_eeprom
			call send_eeprom_address							; send the 3 address bytes
			movlw (1<<spi_cs)									; deselect the SPI EEPROM (set its /CS = high)
			movwf PORTA											; this initiates the EEPROM's internal programming operation
			call wait_eeprom_busy								; wait for EEPROMS's block erase to finish
			goto wait_command

cant_program
			
			movlw (1<<fpga_program)+(1<<status_led_2)+(1<<pic_clock_out)		
			movwf PORTB		
			call long_pause										; LED 2 flashes twice to warn not in programming mode
			movlw (1<<fpga_program)+(1<<pic_clock_out)			; PIC clock out line is held high for duration
			movwf PORTB
			call long_pause
			movlw (1<<fpga_program)+(1<<status_led_2)+(1<<pic_clock_out)			
			movwf PORTB
			call long_pause
			movlw (1<<fpga_program)+(1<<pic_clock_out)
			movwf PORTB
			call long_pause
			goto wait_command

;=====================================================================================================================

write_bytes_to_eeprom

			btfss allow_program,0								; cannot proceed if host has not sent special code
			goto cant_program									; host should check clock line before sending 3 byte address/datapacket

			call get_eeprom_address								; get 3 bytes for write address
			movlw 64
			movwf buffer_count									; get 64 bytes to program into EEPROM
			movlw 0xa0											
			movwf FSR											; temporarily store them in PIC RAM $a0-$df
readb_loop	call get_byte_from_fpga
			movwf INDF
			incf FSR,f
			decfsz buffer_count,f
			goto readb_loop

			movlw (1<<fpga_program)+(1<<pic_clock_out)			; set pic clock out high = busy
			movwf PORTB

			clrf PORTA											; select the EEPROM (/cs = low: new instruction)
			movlw spi_write_en_cmd								; send WRITE ENABLE command
			call send_byte_to_eeprom
			movlw  (1<<spi_cs)									; deselect the SPI EEPROM (set its /CS = high: end of instruction)
			movwf PORTA											
			call wait_eeprom_wel								; ensure the WRITE ENABLE LATCH is set

			clrf PORTA											; Bring SPI EEPROM /CS = Low (new instruction)
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

			movlw  (1<<spi_cs)									; deselect the SPI EEPROM (set its /CS = high)
			movwf PORTA											; this initiates the EEPROM's internal programming operation
			call wait_eeprom_busy								; wait for EEPROM's internal write operation to complete
			goto wait_command


;********** Called routines **************************************************************************************

wait_eeprom_wel

			clrf PORTA											; select the EEPROM (/cs = low: new instruction)
			movlw spi_read_status_cmd							; send READ STATUS command
			call send_byte_to_eeprom
wel_loop	call get_byte_from_eeprom							; read status byte from EEPROM
			btfss received_byte,1								; loop until write enable flag (WEL: bit 1) is set
			goto wel_loop
			movlw  (1<<spi_cs)									; deselect the SPI EEPROM (set its /CS = high: end of instruction)
			movwf PORTA
			return

;-------------------------------------------------------------------------------------------------------------------
						
wait_eeprom_busy
		
			clrf PORTA											; select the EEPROM (/cs = low: new instruction)
			movlw spi_read_status_cmd							; send READ STATUS command
			call send_byte_to_eeprom
			clrf temp2
busy_loop	call get_byte_from_eeprom							; read status byte from EEPROM
			btfss received_byte,0								; loop until busy flag (BSY: bit 0) is clear
			goto not_busy
				
			clrf temp1
btloop1		decfsz temp1,f										; wait 192 microseconds
			goto btloop1
			incfsz temp2,f										; inc counter, change LED every 256 overflows
			goto busy_loop
			incf busy_flash,f
			movlw (1<<fpga_program)+(1<<pic_clock_out)			;flash LED2 fast whilst waiting
			btfsc busy_flash,0
			movlw (1<<fpga_program)+(1<<pic_clock_out)+(1<<status_led_2)
			movwf PORTB
			goto busy_loop

not_busy	movlw (1<<spi_cs)									; deselect the SPI EEPROM (set its /CS = high: end of instruction)
			movwf PORTA
			return
										
;-------------------------------------------------------------------------------------------------------------------

get_byte_from_eeprom

			clrf received_byte
			movlw 8
			movwf bitcount									
gbfe_loop	bcf STATUS,0										; clear carry flag
			rlf received_byte,f
			btfsc PORTA,spi_data_out
			bsf received_byte,0
			movlw (1<<spi_clock)								; raise the EEPROM clock line
			movwf PORTA
			clrf PORTA											; drop EEPROM clock line
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
wait_bffch	btfsc PORTA,fpga_clock_in							; wait for clock high
			goto gbff_clk_hi
			incfsz temp1,f										; loop 256 times and then
			goto wait_bffch										; time out
			bsf time_out,0
			movlw 0xff
			movwf received_byte
			return

gbff_clk_hi	btfsc PORTB,fpga_init								; read bit from FPGA init line
			bsf received_byte,0
			
			clrf temp1
wait_bffcl	btfss PORTA,fpga_clock_in							; wait for clock low
			goto gbff_clk_lo
			incfsz temp1,f										; loop 256 times and then
			goto wait_bffcl										; time out
			bsf time_out,0
			movlw 0xff
			movwf received_byte
			return
			
gbff_clk_lo	decfsz bitcount,f									; loop for 8 bits
			goto next_fcbit

			movf received_byte,w								; return byte in W
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
sb_loop		movlw 0				
			rlf temp1,f
			skipifnotcarry
			movlw (1<<spi_data_in)								; present data bit to EEPROM
			movwf PORTA
			iorlw (1<<spi_clock)								; raise the EEPROM clock line
			movwf PORTA
			andlw 0xff-(1<<spi_clock)							; drop the EEPROM clock line
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

long_pause	movlw 5												; approx 0.25 seconds @ 16MHz clock
			movwf temp3
lp_loop		call short_pause
			decfsz temp3,f
			goto lp_loop
			return


short_pause	clrf temp2											; approx 0.05 seconds @ 16MHz clock									 
			clrf temp1									
swlp1		incfsz temp1,f			
			goto swlp1			
			incfsz temp2,f			
			goto swlp1
			return

vshort_pause

			clrf temp1											; approx 200 microseconds
vsh_pause	decfsz temp1,f
			goto vsh_pause
			return


pause_1ms	movlw 6
			movwf temp2											; approx 1 millisecond @ 16MHz clock									 
			clrf temp1									
msplp1		incfsz temp1,f			
			goto msplp1			
			decfsz temp2,f			
			goto msplp1
			return

short_pause_esc_if_done

			movlw 0x80
			movwf temp2											; approx 0.05 seconds @ 16MHz clock									 
			clrf temp1											; escape immediately if done is high
shpeidlp	btfsc PORTB,fpga_done
			return
			incfsz temp1,f			
			goto shpeidlp			
			incfsz temp2,f			
			goto shpeidlp
			return

;------ EEPROM DATA -------------------------------------------------------------------------

			ORG 0x2100

    	    DE 0x00,0x00,0x02									; default FPGA config base address low,mid,high
																; 0x20000 ("slot 1")

;*********************************************************************************************

			END                     						  ; directive 'end of program'
