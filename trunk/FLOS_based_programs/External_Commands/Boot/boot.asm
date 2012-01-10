; boot.exe command - reconfigs the FPGA v1.01

;======================================================================================
; Standard equates for OSCA and FLOS
;======================================================================================

include "kernal_jump_table.asm"
include "osca_hardware_equates.asm"
include "system_equates.asm"

;--------------------------------------------------------------------------------------
; Header code - Force program load location and test FLOS version.
;--------------------------------------------------------------------------------------

my_location	equ $f000
my_bank		equ $0e
include 		"force_load_location.asm"

required_flos	equ $594
include 		"test_flos_version.asm"


;------------------------------------------------------------------------------------------------
; Actual program starts here..
;------------------------------------------------------------------------------------------------

;-------- CONSTANTS ----------------------------------------------------------

data_buffer 	equ $8000 ; Dont change this

req_hw_version	equ $600

;-----------------------------------------------------------------------------------------------	
;  Look for argument
;-----------------------------------------------------------------------------------------------	
	
fnd_param	ld a,(hl)				;if args = 0, show use
    	or a    
    	jr nz,param_ok
    
    	ld hl,showuse_txt
	call kjt_print_string
	xor a
	ret
	   
param_ok	call kjt_ascii_to_hex_word
	ld a,d
	or a
	jr nz,badslot
	ld a,e
	or a
	jr z,badslot
	cp $20
	jr nc,badslot
	ld (slot_number),a
	
	ld hl,reconfig_txt
	call kjt_print_string
	
	ld b,244				; wait a second 
op2wait	xor a
	call kjt_timer_wait
	djnz op2wait					

	ld a,$88			; send "set config base" command
	call send_byte_to_pic
	ld a,$b8
	call send_byte_to_pic
	ld a,$00			
	call send_byte_to_pic	; send address low
	ld a,$00		
	call send_byte_to_pic	; send address mid
	ld a,(slot_number)
	sla a
	call send_byte_to_pic	; send address high

	ld a,$88			; send reconfigure command
	call send_byte_to_pic
	ld a,$a1
	call send_byte_to_pic
infloop	jr infloop


badslot	ld hl,badslot_txt
	call kjt_print_string
	xor a
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

;------------------------------------------------------------------------------------------

slot_number	db 0

reconfig_txt	db 11,"Reconfiguring...",0

badslot_txt	db 11, "Invalid slot selection",11,0

showuse_txt	db 11,"USAGE:",11,"BOOT [n] - Reconfig FPGA from slot n",11,0

;-------------------------------------------------------------------------------------------
