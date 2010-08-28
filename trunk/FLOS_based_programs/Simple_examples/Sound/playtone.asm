; Ultra simple audio example - play a continuous tone

;---Standard header for OSCA and FLOS ---------------------------------------------------

include "kernal_jump_table.asm"
include "OSCA_hardware_equates.asm"
include "system_equates.asm"

;-----------------------------------------------------------------------------------------
	org $5000		
;-----------------------------------------------------------------------------------------

	ld a,4			;put first page of audio RAM
	out (sys_mem_select),a	;(sysRAM $20000-$27fff) at Z80 $8000-$FFFF
	
	ld hl,$7f80		;put 2 byte square wave at $8000
	ld ($8000),hl

;-----------------------------------------------------------------------------------------
	
	in a,(sys_audio_enable)	
	and %11111110
	out (sys_audio_enable),a	;stop channel 0 playback


	in a,(sys_vreg_read)	;wait for the beginning of a scan line 
	and $40			;(ie: after audio DMA) This is so that all the
	ld b,a			;audio registers are cleanly initialized
dma_loop	in a,(sys_vreg_read)
	and $40
	cp b
	jr z,dma_loop
	

	ld hl,0			;Sample location * WORD POINTER IN SAMPLE RAM* 
	ld b,h			;(EG: 0=$20000,1=$20002)
	ld c,audchan0_loc	
	out (c),l			;write sample address to relevant port
		
	ld hl,2			;sample length * IN WORDS *
	ld b,h
	ld c,audchan0_len
	out (c),l			;set sample length to relevant port
	
	ld hl,$8000		;period = clock ticks between sample bytes
	ld b,h
	ld c,audchan0_per
	out (c),l			;set sample period to relevant port 
	
	ld a,64
	out (audchan0_vol),a	;set sample volume to relevant port (64 = full volume)

	
	in a,(sys_audio_enable)	
	or %00000001
	out (sys_audio_enable),a	;start channel 0 playback
	
	xor a
	ret
	
;-----------------------------------------------------------------------------------------
