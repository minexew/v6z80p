; Test audio output (test hardware in ez80p config EZ80P_037)

;----------------------------------------------------------------------------------------------

ADL_mode		equ 1				; 0 if user program is Z80 mode type, 1 if not
load_location	equ 10000h			; anywhere in system ram

				include	'PROSE_header.asm'

;---------------------------------------------------------------------------------------------
; ADL-mode user program follows..
;---------------------------------------------------------------------------------------------

audio_registers	equ 0f80000h

			ld hl,msg_txt				
			call print_string

			ld ix,audio_registers
			ld b,8
			
chloop		push bc
			push ix
			
			call audio_reg_wait						;wait until hw has read audio registers
			
			ld de,0
			ld (ix),de								;loc
			ld de,43952
			ld (ix+4),de							;len
			ld de,0ffffh
			ld (ix+8),de							;freq constant
			ld de,040h
			ld (ix+12),de							;volume
			ld de,0
			ld (ix+16),de							;loop loc
			ld de,2
			ld (ix+20),de							;loop len
						
			ld a,kr_wait_key
			call.lil prose_kernal
			
			pop ix
			pop bc
			ld de,32								;move to base address of next channel
			add ix,de
			djnz chloop
			
			ld a,0
			ld (audio_registers+3),a				;stop audio playback

			xor a
			jp.lil prose_return						; back to OS

			
print_string

			ld a,kr_print_string			 
			call.lil prose_kernal			 
			ret
		
;-----------------------------------------------------------------------------------------------

audio_reg_wait
				ld a,80h
				ld (hw_palette),a

				ld a,1
				ld (audio_registers+3),a		; enable playback / clear audio register status flag
				ld c,port_hw_flags
wait_audreg		tstio 40h						; wait for audio hardware to finish reading registers
				jr z,wait_audreg
				
				ld a,00h
				ld (hw_palette),a
				
				ret
				
				
;-----------------------------------------------------------------------------------------------

msg_txt

		db 'Sound test..',11
		db 'Please preload ding.snd to $C00000 and press a key play on each channel',11,0

;-----------------------------------------------------------------------------------------------
		
		