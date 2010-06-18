;-----------------------------------------------------------------------------------------
; tests audio loop flags - init and wait/reload should count 1,2,3,4 on channel 0
; border changes colour when waiting for loop
; This requires OSCA 642+
;-----------------------------------------------------------------------------------------

;---Standard header for OSCA and FLOS ----------------------------------------

include "kernal_jump_table.asm"
include "OSCA_hardware_equates.asm"
include "system_equates.asm"

;-----------------------------------------------------------------------------------------
	org $5000		
;-----------------------------------------------------------------------------------------


	ld a,%00010000
	out (sys_mem_select),a	;use alt write page
	
	ld a,%00000100
	out (sys_alt_write_page),a	;page in audio ram - first bank of 32kb
	call clear_ram
	ld hl,one_samp		;source address of sample
	ld de,$8000		;
	ld bc,4132		;length of sample
	ldir			;copy sample

	ld a,%00000101
	out (sys_alt_write_page),a	;page in audio ram - 2nd bank of 32kb
	call clear_ram
	ld hl,two_samp		;source address of sample
	ld de,$8000		;
	ld bc,4840		;length of sample
	ldir			;copy sample

	ld a,%00000110
	out (sys_alt_write_page),a	;page in audio ram - 3rd bank of 32kb
	call clear_ram
	ld hl,three_samp		;source address of sample
	ld de,$8000		;
	ld bc,4814		;length of sample
	ldir			;copy sample

	ld a,%00000111
	out (sys_alt_write_page),a	;page in audio ram - 4th bank of 32kb
	call clear_ram
	ld hl,four_samp		;source address of sample
	ld de,$8000		;
	ld bc,4490		;length of sample
	ldir			;copy sample

	ld a,%00000000
	out (sys_mem_select),a	;use same write page as read

;-------------------------------------------------------------------------------------
	
	ld hl,test_txt1
	call kjt_print_string

	call wait_dma		;wait for post-audio DMA time
	ld a,%00000000
	out (sys_audio_enable),a	;req stop channel 0 playback
	ld ix,one_data
	ld c,audchan0_loc		;set up channel sample
	call setup_chan
	
	call wait_dma		;wait for post-audio DMA time
	ld a,%00000001		;req start channel 0 playback
	out (sys_audio_enable),a
	ld a,%00010000
	out (sys_clear_irq_flags),a	;clear sample loop flag for chan 0
	ld ix,two_data
	ld c,audchan0_loc		;set up channel new loc/len
	call setup_chan_loop

	ld hl,$f00
	ld (palette),hl

wait1	in a,(sys_audio_enable)	;wait for sample to loop (length = 0, reloaded loc/len)
	bit 4,a			;ie: end of "one!"
	jr z,wait1
	ld a,%00010000
	out (sys_clear_irq_flags),a	;clear sample loop flag - chan 0
	ld ix,thr_data
	ld c,audchan0_loc		;set up channel new loc/len
	call setup_chan_loop

	ld hl,$0f0
	ld (palette),hl

wait2	in a,(sys_audio_enable)	;wait for sample to loop (length = 0, reloaded loc/len)
	bit 4,a			;ie end of "two!"
	jr z,wait2
	ld a,%00010000
	out (sys_clear_irq_flags),a	;clear sample loop flag - chan 0
	ld ix,fou_data
	ld c,audchan0_loc		;set up channel new loc/len 
	call setup_chan_loop

	ld hl,$f0f
	ld (palette),hl

wait3	in a,(sys_audio_enable)	;wait for sample to loop (length = 0, reloaded loc/len)
	bit 4,a			;ie end of "three!"
	jr z,wait3
	ld a,%00010000
	out (sys_clear_irq_flags),a	;clear sample loop flag - chan 0
		
	ld hl,$ff0
	ld (palette),hl

wait4	in a,(sys_audio_enable)	;wait for sample to loop (length = 0, reloaded loc/len)
	bit 4,a			;ie end of "four!"
	jr z,wait4

	ld a,%00000000		;exit - audio channels disabled
	out (sys_audio_enable),a
	ld hl,$00f
	ld (palette),hl
	xor a
	ret


;-------------------------------------------------------------------------------------


no_loop	ld b,$ff			;msb of location / 2
	ld a,$f0			;lsb of location / 2
	out (c),a			
	inc c
	ld b,$00			;msb of length
	ld a,$01			;lsb of length
	out (c),a
	ret
	
	
;-------------------------------------------------------------------------------------

clear_ram	ld hl,$8000
clrramlp	ld (hl),0
	inc hl
	ld a,h
	or l
	jr nz,clrramlp
	ret


;-------------------------------------------------------------------------------------

wait_dma	ld a,(vreg_read)
	and $40
	ld b,a
loop2	ld a,(vreg_read)
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
				
	ld b,0			;wait approx 1 second
twait2	ld a,%00000100
	out (sys_clear_irq_flags),a	;clear timer overflow flag
twait1	in a,(sys_irq_ps2_flags)	;wait for overflow flag to become set
	bit 2,a			
	jr z,twait1
	djnz twait2		;loop 256 times
	ret
	
	
;--------------------------------------------------------------------------------------

test_txt1		db "Audio Test - starting playback",11,0

;--------------------------------------------------------------------------------------


one_data	dw $0000,$0812,2000,$40	;location/2, length/2, period, volume
two_data	dw $4000,$0974,2000,$40
thr_data	dw $8000,$0967,2000,$40
fou_data	dw $c000,$08c5,2000,$40

;---------------------------------------------------------------------------------------

one_samp		incbin "one.raw"
two_samp		incbin "two.raw"
three_samp	incbin "three.raw"
four_samp		incbin "four.raw"

;-------------------------------------------------------------------------------------
