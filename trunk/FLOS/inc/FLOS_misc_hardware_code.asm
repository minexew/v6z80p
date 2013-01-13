
;-------- Timer functions ----------------------------------------------------------------------------


wait_4ms	xor a

os_timer_wait

; set a = number of 16 microsecond periods to wait

		neg 					; timer counts up, so invert value
		out (sys_timer),a		
		ld a,%00000100
		out (sys_clear_irq_flags),a		; clear timer overflow flag
twait		in a,(sys_irq_ps2_flags)		; wait for overflow flag to become set
		bit 2,a			
		jr z,twait
		ret	


;----------------------------------------------------------------------------------------------------

os_get_version

; Returns hardware version in DE, OS version in HL and PCB version in B

; Before FLOS v610, B was zero on return from this routine. 
; Now: B = 1: V6Z80P, B=2: V6Z80P+, B=3: V6Z80P+1.1

; Also: If C = 0, IX points to data structure:
; $0 = bootcode version (word)
; $2 = device present at boot
; $3 = boot device
 	
		ld b,16					; bit number to read
		ld c,sys_hw_flags			; port to read from
verloop		dec b
		in a,(c)				; serial data is bit 7
		inc b
		sla a					; force into carry flag
		rl e					; word ends up in DE
		rl d 
		djnz verloop				; next bit
		
		ld a,d					; mask off top 4 bits of hardware ID
		ld b,d
		and $f
		ld d,a
		srl b
		srl b
		srl b
		srl b
		
		ld hl,flos_version
		ld c,0
		ld ix,bootcode_version
		ret

;----------------------------------------------------------------------------------------------------

backwards_compatibility
	
		push hl
		push de
		
		ld hl,0
		ld (blit_src_msb),hl			; clear blitter MSB registers - for V5Z80P compatibility 
		
		ld de,(osca_version)			
		ld hl,$671				;if osca >=672 reset audio base registers to $2xxxx
		xor a				
		sbc hl,de
		jr nc,oldosca
		ld a,1			
		out (audchan0_loc_hi),a
		out (audchan1_loc_hi),a
		out (audchan2_loc_hi),a
		out (audchan3_loc_hi),a
		xor a					;also disable the audio, as changing loc_highs could result in noise output
		out (sys_audio_enable),a		;(due to sample_locs now pointing at random bytes)
		
		ld hl,$672				;if osca >=673 set linecop hi bits. IE: LineCop programs @ $7xxxx
		xor a
		sbc hl,de				
		jr nc,oldosca	
		ld a,%10000111
		ld (linecop_addr2),a
	
oldosca		pop de
		pop hl
		ret

;-------------------------------------------------------------------------------------------
		