; only one sound stream can be played at once


SND_CHANNEL_MASK   equ (1 << SND_CHANNEL_NUMBER)
SND_CHANNEL_LOC    equ ($10 + SND_CHANNEL_NUMBER*4)             ; audchan0_loc $10
SND_CHANNEL_LEN    equ SND_CHANNEL_LOC + 1
SND_CHANNEL_PER    equ SND_CHANNEL_LOC + 2
SND_CHANNEL_VOL    equ SND_CHANNEL_LOC + 3

;qqq ld a,SND_CHANNEL_MASK
;ld a,SND_CHANNEL_LOC

; Call this routine every frame , you want to play sound file.
proccess_sound_file
        call play_active_sound_buffer


	ld hl,$000
	ld (palette),hl

        call get_current_addr_of_shadow_snd_buff
        ret nc                                  ; not_need_sector_read_in_this_frame (this happens each 6th frame in 60Hz mode)


	ld hl,$f00
	ld (palette),hl

        ld hl,struct__stream_file_sound1
        call StreamedFile__compute_LBA_sector_address
        call mmc_read_sector
        jr c,ok_read_mmc_sector_read
;        jp 0
ok_read_mmc_sector_read
	call set_palette_based_on_carry
        ;call delay_for_mmc_access
        call copy_readed_sound_data_to_shadow_sound_buffer

        ret


; Call this only in 60Hz video modes
; Out: cf = 1, yes can be omitted
;is_this_frame_can_be_omitted
;        or a
;        ret

;        call is_this_playercall_must_be_proccessed
;        ccf

;        ld a,(counter_all)
;        and $3f
;        or a
;        jr z,skipframe
;        or a
;        ret
;skipframe
;        scf
;        ret


;        ld a,(is_this_frame_can_be_omitted_var)
;        or a
;        jr nz, canbeomitted1
;                        ; cf = 0
;        ret
;canbeomitted1
;        scf             ; cf = 1
;        ret

set_palette_based_on_carry
	ld hl,0
	jr c,all_ok1
	ld hl,$0f0
all_ok1	ld (palette),hl
        ret

delay_for_mmc_access
;        call mmc_wait_4ms
        ld b,156
        djnz $
        ret


copy_readed_sound_data_to_shadow_sound_buffer
	ld a,SYSBANK_FOR_DECODEBUF
	out (sys_mem_select),a		; dest bank (audio bank)

        call get_current_addr_of_shadow_snd_buff        ; hl  =  addr
        push hl
        pop  de                         ; de = dest buffer in audio RAM bank
        ld hl,sector_buffer             ; hl = sector buffer 
        ld bc,512                       ; 
        ldir
        ret


; -- sound buffer routines ---
play_active_sound_buffer
                                                ; set current address of active sound buffer 
        call get_current_addr_of_active_snd_buff        ; hl  =  addr
        ld de,SND_DECODE_BUF                    ; convert regular address to audio hw address
        or a
        sbc hl,de
        srl h                                   ; convert to WORDS
        rr l
        

        ld ix,active_sound                      ; set address of active sound buffer (in WORDS)
        ld (ix),l
        ld (ix+1),h

                                        ; set hw audio regs, to play active sound buffer
        ld bc,active_sound
        call set_hw_period
        call set_hw_volume
        ld bc,active_sound
        call set_hw_loclen

        ret


; redirect call to videomode specific routine
get_current_addr_of_active_snd_buff
        call is_current_videomode_50Hz
        jr c,yeap50Hzvideomode1
        call get_current_addr_of_active_snd_buff__60Hzmode
        ret
yeap50Hzvideomode1
        call get_current_addr_of_active_snd_buff__50Hzmode
        ret


; redirect call to videomode specific routine
get_current_addr_of_shadow_snd_buff
        call is_current_videomode_50Hz
        jr c,yeap50Hzvideomode2
        call get_current_addr_of_shadow_snd_buff__60Hzmode
        ret
yeap50Hzvideomode2
        call get_current_addr_of_shadow_snd_buff__50Hzmode
        ret



; --------------- 50 Hz routines -----------------
; Out: hl, current address of active sound buffer
get_current_addr_of_active_snd_buff__50Hzmode
        ld a,(counter)          ; use global counter to compute address
        and 1
        call get_current_addr_of_snd_buff
        ret

; Out: hl, current address of shadow sound buffer
;      cf = 1, need sector read in this frame
;      cf = 0, no sector read in this frame
get_current_addr_of_shadow_snd_buff__50Hzmode
        ld a,(counter)          ; use global counter to compute address
        and 1
        xor 1                   ;
        call get_current_addr_of_snd_buff
        scf                     ; 
        ret

; In:  a = 0, get addr of buf1
;      a = 1, get addr of buf2
; Out: hl, address of snd buffer
get_current_addr_of_snd_buff
        or a
        ld hl,$8000
        jr z,firstbuf
        ld hl,$8000 + $200
firstbuf
        ret

; --------------- 60 Hz routines -----------------
; Out: hl, current address of active sound buffer
get_current_addr_of_active_snd_buff__60Hzmode
        ld a,(player_frame_counter)     ; use counter [0...5] to compute address
        add a,a
        add a,a                         ; a = a * 4
        ld e,a
        ld d,0                          ; de = offset in table of records
        ld ix,sound_decode_values
        add ix, de

        ld l,(ix+2)                     ; get 2nd WORD in record, it's a address of active buffer
        ld h,(ix+3)
        ret

; Out: hl, current address of shadow sound buffer
;      cf = 1, need sector read in this frame
;      cf = 0, no sector read in this frame
get_current_addr_of_shadow_snd_buff__60Hzmode
        ld a,(player_frame_counter)     ; 
        add a,a
        add a,a                         ; a = a * 4
        ld e,a
        ld d,0                          ; de = offset in table 
        ld ix,sound_decode_values
        add ix, de

        ld l,(ix)                       ; get 1st WORD in record, it's a address of shadow buffer
        ld h,(ix+1)

                                        ; if address = $ffff, this mean 'no sector read in current frame'
        push hl
        inc hl                          ; $ffff to $0000
        ld a,l                          ; check if hl = 0
        or h
        pop hl
        jr z, no_sector_read_in_this_frame
        scf
        ret
no_sector_read_in_this_frame        
        or a
        ret



; --- hardware sound routines ---
set_hw_loclen
	push bc
	push bc
	pop ix
	
	ld hl,vreg_read			; wait for display window part of scan line (sound dma done)
xwait1	bit 1,(hl)
	jr nz,xwait1
xwait2	bit 1,(hl)				
	jr z,xwait2
	
	ld a,%00000000			; NOTE!! Include other channel bits other channels in use
	out (sys_audio_enable),a		; Disable channel during loc/len update
	
	ld c,SND_CHANNEL_LOC
	ld a,(ix)				; lsb of WORD location
	ld b,(ix+1)			; msb of WORD location
	out (c),a				; write WORD location to HW reg
	inc c				; move to length reg port
	ld a,(ix+2)			; lsb of length in words
	ld b,(ix+3)			; msb of length in words
	out (c),a				; write WORD length to HW reg		 


	ld hl,vreg_read			 ; wait one scan line (sound dma done)
xwait1b	bit 1,(hl)
	jr nz,xwait1b
xwait2b	bit 1,(hl)				
	jr z,xwait2b

	ld a,SND_CHANNEL_MASK           ; NOTE!! Include other channel bits other channels in use
	out (sys_audio_enable),a		; Restart audio DMA

	ld c,SND_CHANNEL_LOC
	ld a,(ix+6)			; lsb of WORD loop location
	ld b,(ix+7)			; msb of WORD loop location
	out (c),a				; write WORD location to HW reg
	inc c				; move to length reg port
	ld a,(ix+8)			; lsb of loop length in words
	ld b,(ix+9)			; msb of loop length in words
	out (c),a				; write WORD length to HW reg		 

	pop bc
	ret

set_hw_period
        call wait_one_scanline

	push bc	
	push bc
	pop ix
			
	ld c,SND_CHANNEL_PER
	ld a,(ix+5)		; z80 project period value (hi)
	ld b,a
	ld a,(ix+4)		; z80 project period value (lo)
	out (c),a				; write converted period to sample rate port
	pop bc
	ret

set_hw_volume
        call wait_one_scanline

	ld a,$40
fx_fhwv	out (SND_CHANNEL_VOL),a
	ret

wait_one_scanline
	ld hl,vreg_read			 ; wait one scan line (sound dma done)
xwait4b	bit 1,(hl)
	jr nz,xwait4b
xwait5b	bit 1,(hl)				
	jr z,xwait5b
        ret

wait_for_display_window_part_of_scan_line
	ld hl,vreg_read			; wait for display window part of scan line (sound dma done)
xwait6	bit 1,(hl)
	jr nz,xwait6
xwait7	bit 1,(hl)				
	jr z,xwait7
        ret



; active sound buffer 
active_sound
	dw 0		;start location of sample (word offset from start of 128K sample RAM)
                        ; (this value is change every frame)
	dw 512/2	;length of sample (in words)
	dw 625		;16MHz ticks per sample
                        ; 16000000/(50*512) = 625      (25,6KHz)
	dw 0		;restart (looparound) location sample
	dw 2		;restart (looparound) length of sample




; This buffer is used in 60Hz video mode, to recode 50Hz oriented sound stream to 60Hz oriented.
; (freq. 25,6KHz is constant for both 50 and 60Hz modes)
;
; In 50Hz mode, playing of sound stream is much simpler. Each frame active buffer (512 bytes) is playing
; and shadow buffer (512 bytes) is readed from sd/mmc.
;
; offsets in sound buffer (len of buffer 512*5 bytes)
sound_decode_values
;       ---- shadow buffer ---      --- active buffer ---
        dw SND_DECODE_BUF + 0*512, SND_DECODE_BUF + 5*426
        dw SND_DECODE_BUF + 1*512, SND_DECODE_BUF + 0*426
        dw SND_DECODE_BUF + 2*512, SND_DECODE_BUF + 1*426
        dw SND_DECODE_BUF + 3*512, SND_DECODE_BUF + 2*426
        dw SND_DECODE_BUF + 4*512, SND_DECODE_BUF + 3*426
        dw                  $ffff, SND_DECODE_BUF + 4*426

