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

audio_registers equ 0f80000h

			call init_tracker

			ld hl,message_txt						 
			call print_string
			
			ld a,10000000b
			ld.lil (audio_registers+3),a			;build buffer A (disable playback)
			call pause
			
			ld a,00000001b
			ld.lil (audio_registers+3),a			;start audio playback
			call pause

;---------------------------------------------------------------------------------------------------

buf_loop	ld hl,buffer_count						; Every 8 buffer fills, update song parameters
			inc (hl)								; (Approx 47Hz)
			ld a,(hl)
			cp 4
			jr nz,no_pt_update
			ld (hl),0
			call play_tracker
			call update_audio_hardware
			
no_pt_update		


			call wait_buf_req						;wait for build (B) req
			
			ld a,10000011b
			ld.lil (audio_registers+3),a			;build buffer B (enable playback) - clears buf req
			call pause
			
			call wait_buf_req						;wait for build (A) req					

			ld a,10000001b
			ld.lil (audio_registers+3),a			;build buffer A (playback still enabled) - clears buf req
			call pause
			
			ld a,kr_get_key
			call.lil prose_kernal
			cp 076h
			jr nz,buf_loop

;---------------------------------------------------------------------------------------------------

			ld a,0
			ld.lil (audio_registers+3),a			; Disable audio playback

			xor a
			jp.lil prose_return						; switch back to ADL mode and jump to os return handler

;-----------------------------------------------------------------------------------------------

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

buffer_count

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

		