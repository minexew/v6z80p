; Z80-mode Protracker Player.

;----------------------------------------------------------------------------------------------
; Set these two values to suit user program
;----------------------------------------------------------------------------------------------

ADL_mode		equ 0				; 0 if user program is Z80 mode type, 1 if not
load_location	equ 10000h			; anywhere in system ram

				include	'PROSE_header.asm'

;---------------------------------------------------------------------------------------------
; Z80-mode user program follows..
;---------------------------------------------------------------------------------------------

include "ez80_cpu_equates.asm"

audio_registers equ 0f80000h

			call init_tracker

			ld hl,message_txt						 
			call print_string
			
			ld a,10000000b
			ld.lil (audio_registers+3),a		; build buffer A (disable playback)
			call pause
			
			ld a,00000001b
			ld.lil (audio_registers+3),a		; start audio playback
			call pause

			xor a
			ld (audio_buffer_sel),a					
			
;---------------------------------------------------------------------------------------------------

			ld de,655							; set count to 655 ticks (50Hz)
			ld a,e							
			out0 (TMR0_RR_L),a					; set count value lo
			ld a,d
			out0 (TMR0_RR_H),a					; set count value hi
			ld a,00010011b							
			out0 (TMR0_CTL),a					; enable and start timer 0 (continuous mode)

wait_50hz	in0 a,(TMR0_CTL)					; has timer count looped?			
			bit 7,a
			call nz,do_tracker_update			
		
			in0 a,(port_hw_flags)				; is audio hardware requesting buffer fill?
			bit 6,a
			call nz,do_audio_buffer_fill

			ld a,kr_get_key						; Quit if ESC pressed
			call.lil prose_kernal
			cp 076h
			jr nz,wait_50hz

			ld a,0
			ld.lil (audio_registers+3),a		; Disable audio playback
			xor a
			jp.lil prose_return					; switch back to ADL mode and jump to os return handler

;-----------------------------------------------------------------------------------------------

do_tracker_update

			call play_tracker					; call this routine at 50 Hz
			call update_audio_hardware
			ret
			
;-----------------------------------------------------------------------------------------------

do_audio_buffer_fill

			ld a,(audio_buffer_sel)				; call this routine when buffer fill request flag is set
			xor 1								
			ld (audio_buffer_sel),a				; flip buffer
			sla a
			or a,10000001b
			ld.lil (audio_registers+3),a		; build buffer (enable playback) - clears buf req
			call pause
			ret
			
;---------------------------------------------------------------------------------------------------

print_string

			ld a,kr_print_string			 
			call.lil prose_kernal			 
			ret


waitkey		ld a,kr_wait_key
			call.lil prose_kernal
			ret


pause		ld b,0
lp3			nop
			djnz lp3
			ret


wait_buf_req

			in0 a,(port_hw_flags)
			bit 6,a
			jr z,wait_buf_req
			ret


;-----------------------------------------------------------------------------------------------

audio_buffer_sel

			db 0
			
message_txt

			db 'Initialized song. Playing..',11,0

;-----------------------------------------------------------------------------------------------
		
			include "50Hz_Protracker_Player_v505.asm"
	
			include "Amiga_to_EZ80P_audio.asm"

;-----------------------------------------------------------------------------------------------

ALIGN 2
			include "tune03_pattern.asm"
			
;------------------------------------------------------------------------------------------------

		