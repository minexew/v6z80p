;---Standard header for OSCA and FLOS ----------------------------------------

include "kernal_jump_table.asm"
include "OSCA_hardware_equates.asm"
include "system_equates.asm"

	org $5000


;-------- CONSTANTS ----------------------------------------------------------

slot_number	equ 2

data_buffer 	equ $8000 ; Dont change this

req_hw_version	equ $600

;--------------------------------------------------------------------------
; Check hardware revision is appropriate for code
;--------------------------------------------------------------------------

	call kjt_get_version
	ld hl,req_hw_version-1
	xor a
	sbc hl,de
	jr c,hw_vers_ok
	
	ld hl,bad_hw_vers
	call kjt_print_string
	xor a
	ret
	
bad_hw_vers

	db 11,"Program requires hardware version v600+",11,11,0
	
hw_vers_ok

;--------------------------------------------------------------------------------
; Check FLOS version
;-------------------------------------------------------------------------------

	call kjt_get_version		
	ld de,$544
	xor a
	sbc hl,de
	jr nc,flos_ok
	
	ld hl,old_flos_txt
	call kjt_print_string
	xor a
	ret

old_flos_txt

	db "Program requires FLOS v544+",11,11,0

flos_ok	


;-------- INIT -----------------------------------------------------------------

	xor a	
	out (sys_timer),a		; set timer - 256 overflows per irq

;-------- MAIN LOOP -----------------------------------------------------------

	ld d,0				; wait a second 
op2wait	in a,(sys_irq_ps2_flags)		 
	and 4
	jr z,op2wait	
	out (sys_clear_irq_flags),a		 
	dec d				
	jr nz,op2wait					


	ld a,$88			; send "set config base" command
	call send_byte_to_pic
	ld a,$b8
	call send_byte_to_pic
	ld a,$00			
	call send_byte_to_pic	; send address low
	ld a,$00		
	call send_byte_to_pic	; send address mid
	ld a,slot_number
	sla a
	call send_byte_to_pic	; send address high

	ld a,$88			; send reconfigure command
	call send_byte_to_pic
	ld a,$a1
	call send_byte_to_pic
loop
	jp loop


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
