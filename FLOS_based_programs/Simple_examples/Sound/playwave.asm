; Ultra simple audio example - play a sample once (ie: loops to silent sample data)
; Note: Requires OSCA v672+
; (Source tab width=8)

;---Standard header for OSCA and FLOS ---------------------------------------------------

include "equates\kernal_jump_table.asm"
include "equates\OSCA_hardware_equates.asm"
include "equates\system_equates.asm"


;-----------------------------------------------------------------------------------------
	org $5000		
;-----------------------------------------------------------------------------------------

	ld a,0				;set up address of sample, 0-$7fffe
	ld hl,my_sound
	ld (sample_addr),hl
	ld (sample_addr+2),a
	
	ld hl,end_sound-my_sound	;set up byte length of sample,  0-$1fffe
	ld (sample_length),hl
	ld a,0
	ld (sample_length+2),a
	
	ld hl,$600			;set up playback rate, 0-$ffff
	ld (sample_period),hl
	
	ld a,$40
	ld (sample_volume),a		;set up volume 0-$40

	ld a,0				;set up loop-to address, 0-$7fffe
	ld hl,silent_samp
	ld (sample_loop_addr),hl
	ld (sample_loop_addr+2),a
	
	ld hl,2				;set up loop byte length, 0-$1fffe
	ld (sample_loop_length),hl
	ld a,0
	ld (sample_loop_length+2),a

	call play_sound			;play the sound
	
	xor a
	ret

;-----------------------------------------------------------------------------------------

	org ($+1) & $fffe		;word align the samples

my_sound     incbin "flos_based_programs\simple_examples\sound\data\pop.bin"		;pop sample data (8 bit, signed - no header)
end_sound			

silent_samp db 0,0			;silent sample data

;----------------------------------------------------------------------------------------

sample_addr	db 0,0,0			;all little-endian
sample_length	db 0,0,0
sample_period	dw 0
sample_volume	db 0

sample_loop_addr	db 0,0,0
sample_loop_length	db 0,0,0

;----------------------------------------------------------------------------------------



;----------------------------------------------------------------------------------------
; This routine handles the conversion of byte address/length to word address/length
; and writes to the hardware registers
;----------------------------------------------------------------------------------------

play_sound

	call dma_wait
	
	in a,(sys_audio_enable)	
	and %11111110
	out (sys_audio_enable),a	;stop channel 0 playback

	ld a,(sample_addr+2)
	ld hl,(sample_addr)
	srl a 				;divide location by 2 for WORD location
	rr h
	rr l
	ld b,h			
	ld c,audchan0_loc	
	out (c),l			;write sample WORD address [15:0] to audio port	
	out (audchan0_loc_hi),a		;write sample WORD address [16:17] to audio port
	
	ld a,(sample_length+2)
	ld hl,(sample_length)
	srl a
	rr h
	rr l				;divide length by 2 for length in WORDS
	ld b,h
	ld c,audchan0_len
	out (c),l			;write sample WORD length to port
	
	ld hl,(sample_period)		;period = clock ticks between sample bytes
	ld b,h
	ld c,audchan0_per
	out (c),l			;set sample period to relevant port 
	
	ld a,(sample_volume)
	out (audchan0_vol),a		;write sample volume to port (64 = full volume)

	call dma_wait

	in a,(sys_audio_enable)	
	or %00000001
	out (sys_audio_enable),a	;start channel 0 playback

	
;-----------------------------------------------------------------------------------------
;         Now re-set start/length registers for when sample loops                                     
;-----------------------------------------------------------------------------------------
	
	
	call dma_wait			;allow time for sample to start playing, afterwards it is safe to rewrite loc/len

	ld a,(sample_loop_addr+2)
	ld hl,(sample_loop_addr)
	srl a 				;divide location by 2 for WORD location
	rr h
	rr l
	ld b,h			
	ld c,audchan0_loc	
	out (c),l			;write sample WORD address [15:0] to audio port	
	out (audchan0_loc_hi),a		;write sample WORD address [16:17] to audio port
	
	ld a,(sample_loop_length+2)
	ld hl,(sample_loop_length)
	srl a
	rr h
	rr l				;divide length by 2 for length in WORDS
	ld b,h
	ld c,audchan0_len
	out (c),l			;write sample WORD length to port
	ret
	

;-----------------------------------------------------------------------------------------

dma_wait	in a,(sys_vreg_read)		;wait for the beginning of a scan line 
		and $40				;(ie: after audio DMA) This is so that all the
		ld b,a				;audio registers are cleanly initialized
dma_loop	in a,(sys_vreg_read)
		and $40
		cp b
		jr z,dma_loop
		ret
		
;-----------------------------------------------------------------------------------------
