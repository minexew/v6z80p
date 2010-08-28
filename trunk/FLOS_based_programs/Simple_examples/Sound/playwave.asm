; Ultra simple audio example - play a sample, no repeat.

;---Standard header for OSCA and FLOS ---------------------------------------------------

include "kernal_jump_table.asm"
include "OSCA_hardware_equates.asm"
include "system_equates.asm"

;-----------------------------------------------------------------------------------------
	org $5000		
;-----------------------------------------------------------------------------------------

	ld a,4			;put first page of audio RAM
	out (sys_mem_select),a	;(sysRAM $20000-$27fff) at Z80 $8000-$FFFF
	
	ld hl,my_sound		;copy a sound sample to audio RAM
	ld de,$8000		;dest
	ld bc,end_sound-my_sound	;length in bytes		
	ldir			;do the copy

;-----------------------------------------------------------------------------------------
	
	in a,(sys_audio_enable)	
	and %11111110
	out (sys_audio_enable),a	;stop channel 0 playback

;-----------------------------------------------------------------------------------------
;         Set up registers to start the sample playing                                            
;-----------------------------------------------------------------------------------------

	call dma_wait
	
	ld hl,0			;Sample location * WORD POINTER IN SAMPLE RAM* 
	ld b,h			;(EG: 0=$20000,1=$20002)
	ld c,audchan0_loc	
	out (c),l			;write sample address to relevant port
		
	ld hl,0+(no_sound-my_sound)/2	;sample length * IN WORDS *
	ld b,h
	ld c,audchan0_len
	out (c),l			;set sample length to relevant port
	
	ld hl,$600		;period = clock ticks between sample bytes
	ld b,h
	ld c,audchan0_per
	out (c),l			;set sample period to relevant port 
	
	ld a,64
	out (audchan0_vol),a	;set sample volume to relevant port (64 = full volume)

	in a,(sys_audio_enable)	
	or %00000001
	out (sys_audio_enable),a	;start channel 0 playback
	
	
;-----------------------------------------------------------------------------------------
;         Now re-set registers for when sample loops                                         
;-----------------------------------------------------------------------------------------
	
	
	call dma_wait		;allow time for sample to start playing..

	ld hl,0+(no_sound-my_sound)/2	;Sample loop location * WORD POINTER IN SAMPLE RAM* 
	ld b,h			
	ld c,audchan0_loc	
	out (c),l			;write sample address to relevant port
		
	ld hl,1			;sample loop length * IN WORDS *
	ld b,h
	ld c,audchan0_len
	out (c),l			;set sample length to relevant port

	xor a
	ret

;-----------------------------------------------------------------------------------------

dma_wait	in a,(sys_vreg_read)	;wait for the beginning of a scan line 
	and $40			;(ie: after audio DMA) This is so that all the
	ld b,a			;audio registers are cleanly initialized
dma_loop	in a,(sys_vreg_read)
	and $40
	cp b
	jr z,dma_loop
	ret
		
;-----------------------------------------------------------------------------------------

my_sound	incbin "pop.bin"		;pop sample data (8 bit, signed - no header)
no_sound	dw 0			;silence sample data
end_sound 

;-----------------------------------------------------------------------------------------
