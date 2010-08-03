; -------------------------------------------------------------------------
; PIC 16F628 2 x 6 pin Atari-style parallel joysticks to serial data reader
; --------------------------------------------------------------------------
; By Phil Ruston '08
; Version : V1.04 

; PIC reads port A and B, then emits a 16 bit word serially on data line.
; Data bits are output following detection of a rising edge on READ_CLOCK_IN
; The host should therefore latch each bit on the following clock high edge.
; IE:
;
; HOST......      Latch 0    Latch 1     
;         ____      V_____      V_____
;CLK ____!    !_____!     !_____!     !____
;OUT ------<===BIT 0==><==BIT 1===><==BIT2==>
;
;
; The read clock should be bursts of 16 cycles, followed by a gap of at least
; the same length.
;
; When the clock stays low for more than ~300 microseconds, the data packet send
; is aborted, new joystick values are read from the ports and the data transmission
; begins on the next clock high.
;
; Operating with internal 4MHz oscillator, the read clock frequency should
; be between about 5 KHz and 50 KHz, ideally 31250Hz (16MHz / 512) 

; Port A requires external pull-up resistors, Port B uses the internal PIC pull-ups

; Transmission order: (Joy A) U,D,L,R,F1,F2, 0,0, (Joy B) U,D,L,R,F1,F2, 0,0

; PIC connections:
;
; PORT B
;--------
; 0 - JOY B pin 1 - Up
; 1 - JOY B pin 2 - Down
; 2 - JOY B pin 3 - Left
; 3 - JOY B pin 4 - Right
; 4 - JOY A pin 1 - Up
; 5 - JOY A pin 2 - Down
; 6 - JOY A pin 3 - Left
; 7 - JOY A pin 4 - Right

; PORT A
;--------
; 0 - JOY A pin 6 - Fire 1 
; 1 - JOY A pin 9 - Fire 2
; 6 - JOY B pin 6 - Fire 1
; 7 - JOY B pin 9 - Fire 2

; 2 - Joystick Data out
; 3 - Read Clock In

;--- GENERIC HEADER AND CLOCK OPTIONS -------------------------------------------------------

	list    p=16f628           		; list directive to define processor
	list	r=decimal

	#include <p16f628.inc>        	; processor specific variable definitions

	#define skipifzero        btfss STATUS,Z        
	#define skipifnotzero     btfsc STATUS,Z
	#define skipifcarry       btfss STATUS,C        
	#define skipifnotcarry    btfsc STATUS,C
	
	__CONFIG _CP_OFF & _WDT_OFF & _BODEN_OFF & _PWRTE_ON & _INTRC_OSC_NOCLKOUT & _MCLRE_OFF & _LVP_OFF

;---------------------------------------------------------------------------------------------

wait_for_clock_high macro

		    local wait_clo,clk_is_hi

			movlw 60
			movwf loops	
wait_clo	btfsc PORTA,clock_bit			; wait whilst clock is low 
			goto clk_is_hi					
			decfsz loops,f
			goto wait_clo
			goto read_ports
			
clk_is_hi	btfss PORTA,clock_bit			; clock went high, but double check it..
			goto wait_clo

			endm


wait_for_clock_low macro

			local clk_stl_hi

clk_stl_hi	btfsc PORTA,clock_bit			; wait for clock to go low 
			goto clk_stl_hi
			btfsc PORTA,clock_bit
			goto clk_stl_hi
			
			endm

;----- Project Variables ------------------------------------------------------------------

loops				equ     0x20
porta_data			equ		0x21
portb_data			equ 	0x22

;---  Project constants --------------------------------------------------------------------

data_bit  			equ	2
clock_bit 			equ	3

joy_a_up			equ 4
joy_a_down			equ 5
joy_a_left			equ 6
joy_a_right			equ 7
joy_a_fire1			equ 0
joy_a_fire2			equ 1

joy_b_up			equ 0
joy_b_down			equ 1
joy_b_left			equ 2
joy_b_right			equ 3
joy_b_fire1			equ 6
joy_b_fire2			equ 7

;*********************************************************************************************

	ORG     0x000      			 	; processor reset vector

			goto init_code    		; go to beginning of program

	ORG     0x004       			; interrupt vector location

			retfie             		; return from interrupt

;---------- INITIALIZE PIC FOR THIS PROJECT ----------------------------------------------------------

init_code	movlw b'00000111'		
			movwf CMCON				; use digital mode for PORTA (disable comparitors)
			banksel TRISA
			movlw b'11101011'		; set data direction for port A (ra5 = always input/mclr)
			movwf TRISA
			movlw b'11111111'		; set data direction for port B
			movwf TRISB
			movlw b'01111111'
			movwf OPTION_REG		; enable port B pull up resistors
			banksel PORTA

;------------------------------------------------------------------------------------------------------
;---------- Main code ---------------------------------------------------------------------------------
;------------------------------------------------------------------------------------------------------

read_ports	movf PORTA,w
			movwf porta_data
			movf PORTB,w
			movwf portb_data

			wait_for_clock_high
			movlw 0
			btfss portb_data,joy_a_up				; joystick switches pull down the lines
			movlw (1<<data_bit)						; so invert for 1 = direction/button pressed
			movwf PORTA
			wait_for_clock_low

			wait_for_clock_high
			movlw 0
			btfss portb_data,joy_a_down
			movlw (1<<data_bit)
			movwf PORTA	
			wait_for_clock_low
								
			wait_for_clock_high
			movlw 0
			btfss portb_data,joy_a_left
			movlw (1<<data_bit)
			movwf PORTA	
			wait_for_clock_low
	
			wait_for_clock_high
			movlw 0
			btfss portb_data,joy_a_right
			movlw (1<<data_bit)
			movwf PORTA		
			wait_for_clock_low
								
			wait_for_clock_high
			movlw 0
			btfss porta_data,joy_a_fire1
			movlw (1<<data_bit)
			movwf PORTA
			wait_for_clock_low
				
			wait_for_clock_high
			movlw 0
			btfss porta_data,joy_a_fire2
			movlw (1<<data_bit)
			movwf PORTA	
			wait_for_clock_low			

			wait_for_clock_high									;no data on this clock
			clrf PORTA
			wait_for_clock_low

			wait_for_clock_high									;no data on this clock
			clrf PORTA
			wait_for_clock_low

			wait_for_clock_high
			movlw 0
			btfss portb_data,joy_b_up
			movlw (1<<data_bit)
			movwf PORTA
			wait_for_clock_low	
								
			wait_for_clock_high
			movlw 0
			btfss portb_data,joy_b_down
			movlw (1<<data_bit)
			movwf PORTA
			wait_for_clock_low	
								
			wait_for_clock_high
			movlw 0
			btfss portb_data,joy_b_left
			movlw (1<<data_bit)
			movwf PORTA
			wait_for_clock_low	
			
			wait_for_clock_high
			movlw 0
			btfss portb_data,joy_b_right
			movlw (1<<data_bit)
			movwf PORTA
			wait_for_clock_low		
								
			wait_for_clock_high
			movlw 0
			btfss porta_data,joy_b_fire1
			movlw (1<<data_bit)
			movwf PORTA
			wait_for_clock_low
								
			wait_for_clock_high
			movlw 0
			btfss porta_data,joy_b_fire2
			movlw (1<<data_bit)
			movwf PORTA
			wait_for_clock_low	

			wait_for_clock_high									;no data on this clock
			clrf PORTA
			wait_for_clock_low

			wait_for_clock_high									;no data on this clock
			clrf PORTA		
			wait_for_clock_low
			
			goto read_ports


;****************************************************************************************************************

			END                     				  ; directive 'end of program'

