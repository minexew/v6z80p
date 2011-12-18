; boot.exe command - reconfigs the FPGA v1.01

;---Standard header for OSCA and FLOS ----------------------------------------

include "kernal_jump_table.asm"
include "OSCA_hardware_equates.asm"
include "system_equates.asm"

;----------------------------------------------------------------------------------------------------
; As this is an external command, load program high in memory to help avoid overwriting user programs
;----------------------------------------------------------------------------------------------------

my_location	equ $8000
my_bank		equ $0c

	org my_location	; desired load address
	
load_loc	db $ed,$00	; header ID (Invalid, safe Z80 instruction)
	jr exec_addr	; jump over remaining header data
	dw load_loc	; location file should load to
	db my_bank	; upper bank the file should load to
	db 0		; no truncating required

exec_addr	

;-------------------------------------------------------------------------------------------------
; Test FLOS version 
;-------------------------------------------------------------------------------------------------

required_flos equ $568

	push hl
	di			; temp disable interrupts so stack cannot be corrupted
	call kjt_get_version
true_loc	exx
	ld ix,0		
	add ix,sp			; get SP in IX
	ld l,(ix-2)		; HL = PC of true_loc from stack
	ld h,(ix-1)
	ei
	exx
	ld de,required_flos
	xor a
	sbc hl,de
	pop hl
	jr nc,flos_ok
	exx
	push hl			;show FLOS version required
	ld de,old_fth-true_loc
	add hl,de			;when testing location references must be PC-relative
	ld de,required_flos		
	ld a,d
	call kjt_hex_byte_to_ascii
	ld a,e
	call kjt_hex_byte_to_ascii
	pop hl
	ld de,old_flos_txt-true_loc
	add hl,de	
	call kjt_print_string
	xor a
	ret

old_flos_txt

        db "Error: Requires FLOS version $"
old_fth db "xxxx+",11,11,0

flos_ok

;------------------------------------------------------------------------------------------------
; Actual program starts here..
;------------------------------------------------------------------------------------------------

;-------- CONSTANTS ----------------------------------------------------------

data_buffer 	equ $8000 ; Dont change this

req_hw_version	equ $600

;-----------------------------------------------------------------------------------------------	
;  Look for argument
;-----------------------------------------------------------------------------------------------	
	
fnd_param	ld a,(hl)				;scan arguments string for filename
    	or a    
    	jp z,no_param
    	cp " "          
    	jr nz,param_ok
skp_spc 	inc hl
    	jr fnd_param
no_param	ld hl,showuse_txt
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
