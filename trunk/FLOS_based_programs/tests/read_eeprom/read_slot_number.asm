
;---Standard header for OSCA and FLOS ----------------------------------------

include "kernal_jump_table.asm"
include "OSCA_hardware_equates.asm"
include "system_equates.asm"

	org $5000

;-----------------------------------------------------------------------------

	ld hl,databurst_sequence		; send PIC the desired command
	ld b,2
init_dblp	ld a,(hl)
	call send_byte_to_pic
	inc hl
	djnz init_dblp

	ld hl,dest			; read bits from PIC RB7 
	ld (hl),0
	ld c,8				                 
nxt_bit	sla (hl)
	ld a,1<<pic_clock_input		; prompt PIC to present next bit by raising PIC clock line
	out (sys_pic_comms),a
	ld b,128				; wait a while so PIC can keep up..
pause_lp1	djnz pause_lp1
	xor a				; drop clock line again
	out (sys_pic_comms),a
	in a,(sys_hw_flags)			; read the bit into shifter
	bit 3,a
	jr z,nobit
	set 0,(hl)
nobit	ld b,128
pause_lp2	djnz pause_lp2
	dec c
	jr nz,nxt_bit

	ld a,(hl)	
	srl a
	ld hl,text+1
	call kjt_hex_byte_to_ascii
	ld hl,msg_txt
endit	call kjt_print_string
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

databurst_sequence

	db $88,$76		; $88,$76 = send config base MSB

dest	db 0

msg_txt	db "ACTIVE SLOT: ",11
text	db "$xx",11,0

;------------------------------------------------------------------------------------------
