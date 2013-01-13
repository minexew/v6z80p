;-----------------------------------------------------------------------------------------
; tests audio loop flags with IRQ - mulitple channels
;
;---Standard header for OSCA and FLOS  -----------------------------------------------------------------------

include "equates\kernal_jump_table.asm"
include "equates\OSCA_hardware_equates.asm"
include "equates\system_equates.asm"

	
		org $5000	

		xor a
		out (audchan0_loc_hi),a		;all test samples are in first 64KB of system RAM
		out (audchan1_loc_hi),a
		out (audchan2_loc_hi),a
		out (audchan3_loc_hi),a

;-------------------------------------------------------------------------------------
; Set up Audio IRQ
;--------------------------------------------------------------------------------------

		di
		ld hl,(irq_vector)
		ld (original_irq),hl
		ld hl,audio_irq_routine
		ld (irq_vector),hl
		ld a,%00010000		
		out (sys_irq_enable),a		;allow audio IRQ (only)
		ei
		
;-------------------------------------------------------------------------------------
		
		ld hl,test_txt1
		call kjt_print_string

;-------------------------------------------------------------------------------------
; Play sample(s)
;-------------------------------------------------------------------------------------


		call wait_dma			;wait for post-audio DMA time
		
		ld hl,$f0f
		ld (palette),hl
		
		ld a,%00000000
		out (sys_audio_enable),a	;stop audio channels

		ld ix,one_data
		ld c,audchan0_loc		;set up channel 0 location/length/period/volume
		call setup_chan

		ld ix,two_data
		ld c,audchan1_loc		;set up channel 1 location/length/period/volume
		call setup_chan

		ld ix,thr_data
		ld c,audchan2_loc		;set up channel 2 location/length/period/volume
		call setup_chan

		ld ix,fou_data
		ld c,audchan3_loc		;set up channel 3 location/length/period/volume
		call setup_chan
		
		call wait_dma			;wait for post-audio DMA time
		ld a,%00001111			;enable channel(s) playback
		out (sys_audio_enable),a
		
		ld a,%11110000
		out (sys_clear_irq_flags),a	;clear audio loop flags



		ld b,0
wloop		call kjt_wait_vrt		;wait in a loop for 10 seconds
		call kjt_wait_vrt
		djnz wloop
			
		call wait_dma
		ld a,%00000000
		out (sys_audio_enable),a	;stop all channels playback	
		
		di
		ld hl,(original_irq)
		ld (irq_vector),hl
		ld a,%00000011		
		out (sys_irq_enable),a		;enable keyboard and mouse irqs
		ei
		xor a			
		ret				;and exit

;-------------------------------------------------------------------------------------
	

audio_irq_routine

		push af
		in a,(sys_audio_enable)

			
		bit 4,a
		call nz,chan0looped
		bit 5,a
		call nz,chan1looped
		bit 6,a
		call nz,chan2looped
		bit 7,a
		call nz,chan3looped
		
		pop af
		ei
		reti
	


chan0looped

		push af
		push bc
		push de
		push hl
		push ix
		push iy			
		ld hl,ch0txt
		call kjt_print_string
		ld a,%00010000			;clear channel 0 irq flag
		out (sys_clear_irq_flags),a
		pop iy
		pop ix
		pop hl
		pop de
		pop bc
		pop af
		ret
	
	
chan1looped
	
		push af
		push bc
		push de
		push hl
		push ix
		push iy			
		ld hl,ch1txt
		call kjt_print_string
		ld a,%00100000			;clear channel 1 irq flag
		out (sys_clear_irq_flags),a
		pop iy
		pop ix
		pop hl
		pop de
		pop bc
		pop af
		ret

	

chan2looped
	
		push af
		push bc
		push de
		push hl
		push ix
		push iy			
		ld hl,ch2txt
		call kjt_print_string
		ld a,%01000000			;clear channel 2 irq flag
		out (sys_clear_irq_flags),a
		pop iy
		pop ix
		pop hl
		pop de
		pop bc
		pop af
		ret


		
chan3looped
	
		push af
		push bc
		push de
		push hl
		push ix
		push iy			
		ld hl,ch3txt
		call kjt_print_string
		ld a,%10000000			;clear channel 3 irq flag
		out (sys_clear_irq_flags),a
		pop iy
		pop ix
		pop hl
		pop de
		pop bc
		pop af
		ret

			

	
;-------------------------------------------------------------------------------------


no_loop		ld b,$ff			;msb of location / 2
		ld a,$f0			;lsb of location / 2
		out (c),a			
		inc c
		ld b,$00			;msb of length
		ld a,$01			;lsb of length
		out (c),a
		ret
	
	

;-------------------------------------------------------------------------------------

wait_dma	in a,(sys_vreg_read)		;wait for LSB for scanline count to change
		and $40
		ld b,a
loop2		in a,(sys_vreg_read)
		and $40
		cp b
		jr z,loop2
		ret

;-------------------------------------------------------------------------------------

setup_chan

;set c to channel base port address
;set ix to address of sound data_structure

		ld a,(ix+0)		;lsb of location / 2
		ld b,(ix+1)		;msb of location / 2
		out (c),a			
		inc c
		ld a,(ix+2)		;lsb of length
		ld b,(ix+3)		;msb of length
		out (c),a
		inc c
		ld a,(ix+4)		;lsb of sample rate
		ld b,(ix+5)		;msb of sample rate
		out (c),a
		inc c
		ld a,(ix+6)		;volume
		out (c),a
		ret
	
	
setup_chan_loop

;set c to channel base port address
;set ix to address of sound data_structure

		ld a,(ix+0)		;lsb of location / 2
		ld b,(ix+1)		;msb of location / 2
		out (c),a			
		inc c
		ld a,(ix+2)		;lsb of length
		ld b,(ix+3)		;msb of length
		out (c),a
		ret
	

;-------------------------------------------------------------------------------------

pause_long
				
		ld b,0				 ;wait approx 1 second
twait2		ld a,%00000100
		out (sys_clear_irq_flags),a	; clear timer overflow flag
twait1		in a,(sys_irq_ps2_flags)	; wait for overflow flag to become set
		bit 2,a			
		jr z,twait1
		djnz twait2			; loop 256 times
		ret
	
	
;--------------------------------------------------------------------------------------

test_txt1	db "Audio Test - starting playback",11,0

;--------------------------------------------------------------------------------------


one_data	dw one_samp/2,$0812,2000,$40		;location/2, length/2, period, volume
two_data	dw two_samp/2,$0974,2000,$40
thr_data	dw three_samp/2,$0967,2000,$40
fou_data	dw four_samp/2,$08c5,2000,$40

;---------------------------------------------------------------------------------------

	org ($+1) & $fffe

one_samp	incbin "FLOS_based_programs\tests\osca675_features\data\one.raw"
two_samp	incbin "FLOS_based_programs\tests\osca675_features\data\two.raw"
three_samp	incbin "FLOS_based_programs\tests\osca675_features\data\three.raw"
four_samp	incbin "FLOS_based_programs\tests\osca675_features\data\four.raw"

;-------------------------------------------------------------------------------------

original_irq	dw 0

;--------------------------------------------------------------------------------------

ch0txt	db "Audio Channel 0 has looped",11,0

ch1txt	db "Audio Channel 1 has looped",11,0

ch2txt	db "Audio Channel 2 has looped",11,0

ch3txt	db "Audio Channel 3 has looped",11,0

;----------------------------------------------------------------------------------------
