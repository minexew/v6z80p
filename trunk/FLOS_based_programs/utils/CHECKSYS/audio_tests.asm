
audio_tests	call kjt_clear_screen
		
		ld hl,audio_menu_txt
		call kjt_print_string
		
wait_aud_menu	call kjt_wait_key_press
		cp $76
		jr nz,not_aud_quit
		xor a
		ret
		
not_aud_quit	ld a,b
		cp "1"
		jp z,test_panning
		jr wait_aud_menu



test_panning	call kjt_clear_screen
		call do_panning_test
		xor a
		out (sys_audio_enable),a
		jr audio_tests
		

		
;-------------------------------------------------------------------------------------

audio_menu_txt

		db "Audio Test Menu",11,11,"Press:",11,11

		db "1. Panning test",11,11			

		db "ESC - Quit to main menu",11,11,0
		

;-------------------------------------------------------------------------------------

do_panning_test
		
		ld a,0					;put simple sample at $08000-$0ffff
		call kjt_set_bank
		ld hl,0
		ld ($8000),hl
		ld hl,$8002
mksamp		ld (hl),$7f
		inc hl
		ld (hl),$80
		inc hl
		bit 7,h
		jr nz,mksamp
		
		xor a
		out (audchan0_loc_hi),a			
		out (audchan1_loc_hi),a	
		out (audchan2_loc_hi),a	
		out (audchan3_loc_hi),a	
		
		ld hl,left_panning_txt
		call kjt_print_string
		ld a,$f0
		call play_channels
		
		ld hl,right_panning_txt
		call kjt_print_string
		ld a,$0f
		call play_channels
		
		ld hl,both_panning_txt
		call kjt_print_string
		ld a,$ff
		call play_channels
		
		ld hl,stereo_panning_txt
		call kjt_print_string
		ld a,$5a
		call play_channels
		ret

		
play_channels	out (sys_audio_panning),a
		
		ld b,4
		ld d,1

sndlp1		push bc
		push de
		call play_sound
		call pause_1_second
		pop de
		pop bc
		
		sla d
		djnz sndlp1
		ret
		

play_sound	ld a,4
		sub b
		add a,$30
		ld (channel_txt),a
		
		push af
		push bc
		push de
		push hl
		
		ld hl,playing_txt
		call kjt_print_string
			
		pop hl
		pop de
		pop bc
		pop af
	
		call dma_wait
		
		ld a,d
		cpl
		ld e,a
		in a,(sys_audio_enable)	
		and e		
		out (sys_audio_enable),a		;stop channel 0 playback
	
		ld a,4
		sub b
		sla a
		sla a
		add a,audchan0_loc
		ld c,a

		ld hl,$4000
		call set_audreg				;location
		
		inc c
		ld hl,$80
		call set_audreg				;length
		
		inc c
		ld a,b
		sla a
		sla a
		sla a
		sla a
		add a,$80
		ld h,a
		ld l,0
		call set_audreg				;period
		
		inc c
		ld a,$40
		out (c),a				;vol
		
		call dma_wait
		
		in a,(sys_audio_enable)	
		or d
		out (sys_audio_enable),a		;start channel 0 playback
		
		call dma_wait	
		
		ld a,4
		sub b
		sla a
		sla a
		add a,audchan0_loc+1
		ld c,a
		ld hl,1
		call set_audreg				;rewrite length = 1
		ret


set_audreg	push bc
		ld b,h			
		out (c),l				;loc	
		pop bc
		ret

		
;-------------------------------------------------------------------------------------
		
dma_wait	push bc
		in a,(sys_vreg_read)			;wait for the beginning of a scan line 
		and $40					;(ie: after audio DMA) This is so that all the
		ld b,a					;audio registers are cleanly initialized
dma_loop	in a,(sys_vreg_read)	
		and $40
		cp b
		jr z,dma_loop
		pop bc
		ret

;-------------------------------------------------------------------------------------


left_panning_txt	

		db 11,"Chans 0-3 => Left side",11,11,0

right_panning_txt	

		db 11,"Chans 0-3 => Right side",11,11,0

both_panning_txt	

		db 11,"Chans 0-3 => both sides",11,11,0

stereo_panning_txt	

		db 11,"Chans 0+2 => left side",11
		db "Chans 1+3 => Right side",11,11,0
		

playing_txt	db "Playing channel: "
channel_txt	db "x",11,0


;-------------------------------------------------------------------------------------
