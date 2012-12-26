
; Test reading of bytes from EEPROM (databurst)


;---Standard header for OSCA and FLOS ----------------------------------------

include "equates\kernal_jump_table.asm"
include "equates\osca_hardware_equates.asm"
include "equates\system_equates.asm"


	org $5000

source		equ $fb00			;address within EEPROM block from which to get bytes
src_block 	equ $03				;block number from which to get bytes

length		equ $0100
len_msb		equ $00				;number of bytes required from EEPROM (minimum = $000001)

dst_bank	equ 0
dest		equ $8000			;where to dump the bytes in RAM

;-----------------------------------------------------------------------------
		di
		push hl			; put page number to read to buffer in DE
		push de
		push bc

		call set_timer			; timer @ 256 * 256 cycles between overflows + restart
dl_bcode	in a,(sys_eeprom_byte)		; clear shift reg count with a read

		ld a,src_block
		ld hl,source			; fill in values for databurst command sequence 
		ld (s_addr),hl
		ld (s_addr+2),a
	
		ld a,len_msb
		ld hl,length			
		ld (s_length),hl
		ld (s_length+2),a
	
		ld hl,databurst_sequence	; send PIC the commands to send data from EEPROM
		ld b,12
init_dblp	ld a,(hl)
		call send_byte_to_pic
		inc hl
		djnz init_dblp

		jp rdgo

		ld a,dst_bank
		call kjt_force_bank
		ld hl,dest			; download loop counts.. 
		ld bc,length			                
		ld e,len_msb
	
nxt_byte	ld a,b
		or c
		or e
		jr z,all_ok

		ld d,0				; D counts timer overflows
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
gbcbyte		xor a			
		out (sys_pic_comms),a		; drop PIC clock line, PIC will then wait for next high 
		in a,(sys_eeprom_byte)		; read byte received, clear bit count
		ld (hl),a				; copy to dest, loop back to wait for next byte
		inc hl
		ld a,h
		or l
		jr nz,same_bnk
		call kjt_inc_bank
		ld h,$80
same_bnk	dec bc
		ld a,b
		and c
		inc a
		jr nz,nxt_byte
		dec e
		jr nxt_byte

all_ok		ld hl,ok_txt
endit		call kjt_print_string
		xor a
		ret

dl_error	ld hl,bad_txt
		jr endit	

;------------------------------------------------------------------------------------------	

send_a_byte_to_pic

;pic_data_input	equ 0	; from FPGA to PIC
;pic_clock_input	equ 1	; from FPGA to PIC

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
psbwlp1		djnz psbwlp1		; keep clock high for 10 microseconds
		
		res pic_clock_input,a
		out (sys_pic_comms),a	; drop clock line
	
		ld b,12
psbwlp2		djnz psbwlp2		; keep clock low for 10 microseconds
	
		dec d
		jr nz,bit_loop
	
		ld b,60			; short wait between bytes ~ 50 microseconds
pdswlp		djnz pdswlp		; allows time for PIC to act on received byte
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

		db $88,$d4		; $88,$d4 = set address
s_addr		db $00,$00,$00		; (low,mid,high)

		db $88,$e2		; $88,$e2 = set length
s_length	db $00,$00,$00		; (low,mid,high)

		db $88,$c9		; $88,$c9 = begin transfer!
	
;------------------------------------------------------------------------------------------
	
ok_txt	db "Data downloaded.",11,11,0
bad_txt	db "Download error!",11,11,0

;------------------------------------------------------------------------------------------

include "FLOS_based_programs\code_library\eeprom\inc\eeprom_routines.asm"

		org $7000
		
page_buffer	ds 256,0
