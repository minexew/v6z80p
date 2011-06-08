; reset keyboard

;----------------------------------------------------------------------------------------------

ADL_mode		equ 1				; 0 if user program is Z80 mode type, 1 if not
load_location	equ 10000h			; anywhere in system ram

				include	'PROSE_header.asm'

;---------------------------------------------------------------------------------------------
; ADL-mode user program follows..
;---------------------------------------------------------------------------------------------

			ld hl,message_txt				; ADL mode program
			ld a,kr_print_string			; desired kernal routine
			call.lil prose_kernal			; call PROSE routine		
			
			call reset_keyboard
			ld hl,ok_txt
			jr nc,kbrsok
			ld hl,bad_txt

kbrsok		ld a,kr_print_string
			call.lil prose_kernal
			xor a
			jp.lil prose_return				; back to OS

;-------------------------------------------------------------------------------------------
; RESET KEYBOARD ROUTINE 
;-------------------------------------------------------------------------------------------

reset_keyboard

; If on return carry flag is set, keyboard init failed

	
			ld a,0
			out0 (port_irq_ctrl),a			; disable interrupts
			call do_kbrs
			ld a,1
			out0 (port_irq_ctrl),a			; re-enable interrupts
			ret


do_kbrs		ld a,0001b						; pull clock line low
			out0 (port_ps2_ctrl),a

			ld de,8							; wait 250 microseconds
			call set_timeout
wait_to1	call test_timeout
			jr z,wait_to1
						
			ld a,0011b
			out0 (port_ps2_ctrl),a			; pull data line low 
			ld a,0010b
			out0 (port_ps2_ctrl),a			; release clock line

			ld l,9							; 8 data bits + 1 parity bit	
kb_byte		call wait_kb_clk_low	
			ret c
			xor a
			out0 (port_ps2_ctrl),a			; KB data line = 1 (command = $FF)
			call wait_kb_clk_high
			ret c
			dec l
			jr nz,kb_byte

			call wait_kb_clk_low			; wait for keyboard to pull clock low (ack)	
			ret c
			call wait_kb_data_low			; wait for keyboard to pull data low (ack)
			ret c
			call wait_kb_clk_high			; wait for keyboard to release data and clock
			ret c
			call wait_kb_data_high
			ret c

			ld de,0ffffh					; allow 2 seconds for responses
			call set_timeout
			
wsc			in0 a,(port_ps2_ctrl)
			bit 4,a
			jr z,nokbr
			
			in0 e,(port_keyboard_data)
			ld hl,byte_txt
			ld a,kr_hex_byte_to_ascii
			call.lil prose_kernal
			ld hl,byte_txt
			ld a,kr_print_string
			call.lil prose_kernal
			
nokbr		call test_timeout
			jr z,wsc
			xor a
			ret
			


wait_kb_clk_low

			ld c,1
			jr kb_test_lo

wait_kb_data_low
		
			ld c,2

kb_test_lo	ld de,04000h					; allow 0.5 seconds before time out
			call set_timeout
kb_lw		ld b,4							; must be steady for a few loops (noise immunity)
kb_lnlp		call test_timeout				; timer reached zero?
			jr z,kb_lnto
			scf								; carry set = timed out
			ret
kb_lnto		in0 a,(port_ps2_ctrl)
			and c
			jr nz,kb_lw
			djnz kb_lnlp		
			xor a							; carry clear = op was ok
			ret


wait_kb_clk_high

			ld c,1
			jr kb_test_hi

wait_kb_data_high
		
			ld c,2
			
kb_test_hi	ld de,04000h					; allow 0.5 seconds before time out
			call set_timeout
kb_hw		ld b,4							; must be steady for a few loops (noise immunity)
kb_hnlp		call test_timeout				; timer reached zero?
			jr z,kb_hnto
			scf								; carry set = timed out
			ret
kb_hnto		in0 a,(port_ps2_ctrl)
			and c
			jr z,kb_hw
			djnz kb_hnlp		
			xor a							; carry clear = op was ok
			ret


;-----------------------------------------------------------------------------------------------

set_timeout	

			ld a,e							
			out0 (TMR0_RR_L),a				; set count value lo
			ld a,d
			out0 (TMR0_RR_H),a				; set count value hi
			ld a,00000011b							
			out0 (TMR0_CTL),a				; enable and start timer 0 (prescale apparently ignored for RTC)
			in0 a,(TMR0_CTL)				; ensure count complete flag is clear
			ret
			
test_timeout

			in0 a,(TMR0_CTL)				; zero flag not set if timed out				
			bit 7,a
			ret
			
;-----------------------------------------------------------------------------------------------

message_txt

		db 'Resetting keyboard..',11,0

ok_txt	db 'OK..',11,0
bad_txt	db 'Failed..',11,0
		
		
byte_txt db '00 ',11,0


;-----------------------------------------------------------------------------------------------
		
		