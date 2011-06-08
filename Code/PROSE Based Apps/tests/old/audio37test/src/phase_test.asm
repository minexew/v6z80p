; Test audio output (test hardware in ez80p config EZ80P_037)

;----------------------------------------------------------------------------------------------

ADL_mode		equ 1				; 0 if user program is Z80 mode type, 1 if not
load_location	equ 10000h			; anywhere in system ram

				include	'PROSE_header.asm'

;---------------------------------------------------------------------------------------------
; ADL-mode user program follows..
;---------------------------------------------------------------------------------------------

audio_registers	equ 0f80000h

			ld a,0
			ld (audio_registers+3),a		; stop playback / clear audio register status flag

			
			ld hl,0c00000h					; make simple wave
mainlp2		ld a,07fh
			ld b,2
lp1b		ld (hl),a
			inc hl
			djnz lp1b
			ld b,3
			ld a,80h
lp2b		ld (hl),a
			inc hl
			djnz lp2b
			ld a,h
			cp 0f8h
			jr c,mainlp2
			
			

			ld hl,msg_txt				
			call print_string

			ld ix,audio_registers
			
			call audio_reg_wait						;wait until hw has read audio registers
			
			
			ld de,0
			ld (ix+00h),de							;loc
			ld (ix+04h),de							;len
			ld (ix+08h),de							;freq constant
			ld (ix+0ch),de							;volume
			ld (ix+10h),de							;loop loc
			ld (ix+14h),de							;loop len
	
			
			
			
			
			
			
			
			ld de,0
			ld (ix+00h),de							;loc
			ld (ix+20h),de
			
			ld de,08000h
			ld (ix+04h),de							;len
			ld (ix+24h),de
			
			ld de,01fffh
			ld (ix+08h),de							;freq constant
			ld (ix+28h),de		
			
			ld de,10h
			ld (ix+0ch),de							;volume
			ld de,10h
			ld (ix+2ch),de		
			
			ld de,0
			ld (ix+10h),de							;loop loc
			ld (ix+30h),de							;loop loc

			ld de,8000h
			ld (ix+14h),de							;loop len
			ld (ix+34h),de	
				
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
		
		