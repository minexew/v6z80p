; reset mouse on port 2 and test ps2 lifo

;----------------------------------------------------------------------------------------------

ADL_mode		equ 1				; 0 if user program is Z80 mode type, 1 if not
load_location	equ 10000h			; anywhere in system ram

				include	'PROSE_header.asm'

;---------------------------------------------------------------------------------------------
; ADL-mode user program follows..
;---------------------------------------------------------------------------------------------

			ld hl,100ffh
			ld (hl),0

			ld hl,message_txt				; ADL mode program
			ld a,kr_print_string			; desired kernal routine
			call.lil prose_kernal			; call PROSE routine		
	
;			ld de,0ffffh
;			call time_delay
			
			call reset_mouse
			ld hl,ok_txt
			jr nc,kbrsok
			ld hl,bad_txt
kbrsok		ld a,kr_print_string
			call.lil prose_kernal
			xor a
			jp.lil prose_return


org load_location+100h

			ld hl,buffer_empty_txt
			in0 a,(port_ps2_ctrl)
			bit 5,a
			jr z,buffemp
			ld hl,buffer_data_txt
buffemp		ld a,kr_print_string
			call.lil prose_kernal
			xor a
			jp.lil prose_return				; back to OS



org load_location+200h
		
			in0 a,(port_mouse_data)
			call show_byte
			xor a
			jp.lil prose_return				; back to OS


;-----------------------------------------------------------------------------------------------

show_byte

			ld e,a
			ld hl,byte_txt
			ld a,kr_hex_byte_to_ascii
			call.lil prose_kernal
			ld hl,showhex_txt
			ld a,kr_print_string
			call.lil prose_kernal
			ret

;-----------------------------------------------------------------------------------------------

reset_mouse

; Returns with carry flag set if mouse did not initialize

			ld a,01b
			out (port_irq_ctrl),a					;disable mouse interrupts
				
			ld a,0ffh								;send "reset" command to mouse
			call write_to_mouse		
			ret c
			call wait_mouse_byte					;mirror of $FF as written 
			ret c
			call wait_mouse_byte					;response should be $FA : Ack
			ret c
			call wait_mouse_byte					;response should be $AA : Mouse passed self test
			ret c
			call wait_mouse_byte					;response should be $00 : Mouse ID
			ret c

			ld a,0f4h								;send "enable data reporting" command to mouse
			call write_to_mouse
			ret c
			call wait_mouse_byte					;mirror of $F4 as written
			ret c
			call wait_mouse_byte					;response should be $FA : Ack
			ret
			
;-----------------------------------------------------------------------------------------------
				
write_to_mouse

; Put byte to send to mouse in A

			ld c,a								; copy output byte to c
			ld a,0100b							; pull clock line low
			out0 (port_ps2_ctrl),a
			ld de,8
			call time_delay						; wait ~100 microseconds
			ld a,1100b
			out0 (port_ps2_ctrl),a				; pull data line low also
			ld a,1000b
			out0 (port_ps2_ctrl),a				; release clock line
			
			ld d,1								; initial parity count
			ld b,8								; loop for 8 bits of data
mdoloop		call wait_mouse_clk_low	
			ret c
			xor a
			set 3,a
			bit 0,c
			jr z,mdbzero
			res 3,a
			inc d
mdbzero		out0 (port_ps2_ctrl),a				; set data line according to output byte
			call wait_mouse_clk_high
			ret c
			rr c
			djnz mdoloop

			call wait_mouse_clk_low
			ret c
			xor a
			bit 0,d
			jr nz,parone
			set 3,a
parone		out0 (port_ps2_ctrl),a				; set data line according to parity of byte
			call wait_mouse_clk_high
			ret c
			
			call wait_mouse_clk_low
			ret c
			xor a
			out0 (port_ps2_ctrl),a				; release data line

			call wait_mouse_data_low			; wait for mouse to pull data low (ack)
			ret c
			call wait_mouse_clk_low				; wait for mouse to pull clock low
			ret c
				
			call wait_mouse_data_high			; wait for mouse to release data
			ret c
			call wait_mouse_clk_high			; wait for mouse to release clock
			ret 

;-----------------------------------------------------------------------------------------------


wait_mouse_byte

			ld de,8000h
			call set_timeout					; Allow 1 second for mouse response

wait_mloop	in0 a,(port_ps2_ctrl)
			bit 5,a
			jr nz,rec_mbyte
			
			call test_timeout
			jr z,wait_mloop
			scf									; carry flag set = timed out
			ret
			
rec_mbyte	in0 a,(port_mouse_data)				; get byte sent by mouse
			call show_byte						; for testing only!
			xor a
			ld hl,100ffh
			inc (hl)			
			ret
			
;-----------------------------------------------------------------------------------------------

wait_mouse_clk_low

			ld a,4
			jp ps2_test_lo

wait_mouse_data_low
		
			ld a,8
			jp ps2_test_lo	

wait_mouse_clk_high

			ld a,4
			jp ps2_test_hi

wait_mouse_data_high
		
			ld a,8
			jp ps2_test_hi			
			

ps2_test_lo	push bc
			push de
			ld c,a
			ld de,04000h					; allow 0.5 seconds before time out
			call set_timeout
kb_lw		ld b,4							; must be steady for a few loops (noise immunity)
kb_lnlp		call test_timeout				; timer reached zero?
			jr z,kb_lnto
			pop de
			pop bc
			scf								; carry set = timed out
			ret
kb_lnto		in0 a,(port_ps2_ctrl)
			and c
			jr nz,kb_lw
			djnz kb_lnlp		
			pop de
			pop bc
			xor a
			ret								; carry clear = op was ok

			
ps2_test_hi	push bc
			push de
			ld c,a
			ld de,04000h					; allow 0.5 seconds before time out
			call set_timeout
kb_hw		ld b,4							; must be steady for a few loops (noise immunity)
kb_hnlp		call test_timeout				; timer reached zero?
			jr z,kb_hnto
			pop de
			pop bc
			scf								; carry set = timed out
			ret
kb_hnto		in0 a,(port_ps2_ctrl)
			and c
			jr z,kb_hw
			djnz kb_hnlp		
			pop de
			pop bc
			xor a							; carry clear = op was ok
			ret


;-----------------------------------------------------------------------------------------------

purge_mouse	in0 a,(port_ps2_ctrl)
			bit 5,a
			ret z
			in0 a,(port_mouse_data)					;read the mouse port to purge buffer
			jr purge_mouse

;-----------------------------------------------------------------------------------------------

time_delay

			call set_timeout
wait_td		call test_timeout
			jr z,wait_td
			ret
			
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

			in0 a,(TMR0_CTL)								
			bit 7,a
			ret
			
;-----------------------------------------------------------------------------------------------

message_txt

		db 'Resetting mouse on port2',11,11
		db 'G 10100 to read buffer status',11,11
		db 'G 10200 to read a buffer entry',11,11,0

ok_txt	db 'OK..',11,0
bad_txt	db 'Failed..',11,0
		
buffer_empty_txt	db 'Buffer is empty',11,11,0
buffer_data_txt		db 'Buffer contains data',11,11,0

showhex_txt			db 'Buffer byte: $'
byte_txt 			db '--',11,11,0

;-----------------------------------------------------------------------------------------------
		
		