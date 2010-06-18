;---Standard header for OSCA and FLOS ----------------------------------------

include "kernal_jump_table.asm"
include "OSCA_hardware_equates.asm"
include "system_equates.asm"

	org $5000

;-----------------------------------------------------------------------------

length equ 1

;-----------------------------------------------------------------------------

	call set_timer			; timer @ 256 * 256 cycles between overflows + restart
dl_bcode	in a,(sys_eeprom_byte)		; clear shift reg count with a read

	ld hl,databurst_sequence		; send PIC the desired command
	ld b,2
init_dblp	ld a,(hl)
	call send_byte_to_pic
	inc hl
	djnz init_dblp

	ld hl,dest			; download loop.. 
	ld bc,length			;                 
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
	jr dl_error			; if waited about 1 second, timeout
gbcbyte	xor a			
	out (sys_pic_comms),a		; drop PIC clock line, PIC will then wait for next high 
	in a,(sys_eeprom_byte)		; read byte received, clear bit count
	ld (hl),a				; copy to dest, loop back to wait for next byte
	inc hl
	dec bc
	ld a,b
	or c
	jr nz,nxt_byte

all_ok	ld a,(dest)	
	ld hl,text+1
	call kjt_hex_byte_to_ascii
	ld hl,msg_txt
endit	call kjt_print_string
	xor a
	ret

dl_error	ld hl,bad_txt
	jr endit	

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

	
;-------------------------------------------------------------------------------------------

databurst_sequence

	db $88,$53		; $88,$53 = send chip ID byte

dest	db 0

msg_txt	db "EEPROM ID BYTE: ",11
text	db "$xx",11,0

bad_txt	db "Time out error",11,0

;------------------------------------------------------------------------------------------
