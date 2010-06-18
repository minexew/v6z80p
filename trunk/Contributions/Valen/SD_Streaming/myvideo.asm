
VIDEO_STREAM_WIDTH              equ 64
VIDEO_STREAM_HEIGHT             equ 64
VIDEO_STREAM_SECTORS_PER_VIDEOFRAME  equ 9      ; 1 sector of palette data + 8 sectors of img data
VIDEO_OFFSET_FOR_VSTREAM        equ $0     ; where to draw video stream (linear address 0 - FFFF)

VIDEO_BUFFER_PITCH              equ 128    ; video buffer width

; how much lines of video in one sector (must be integer value!)
LINES_PER_SECTOR                equ 512/VIDEO_STREAM_WIDTH

; we use 2 video pages, for shadow and active video buffers. each by 128 KB
VIDEO_FETCH_ADDR                equ $0200  ; ($20000 / $100)
VIDEO_BANK_NUMBER_OFFS          equ $10    ; ($20000 / $2000)


proccess_video_file
        call get_current_addr_of_shadow_snd_buff; do we need to omit this frame (in 60Hz mode)
        ret nc                                  ; not_need_sector_read_in_this_frame (this happens each 6th frame in 60Hz mode)


;      	ld hl,$00f
;        call mark_frame_time


        ld b,2                                          ; read 2 sectors from SD card
read_next_sector_of_videofile
        push bc
                                                        ; calc a color value
        ld hl,0        
        ld l,b
        rrc l
        rrc l
        call mark_frame_time

        ld hl,struct__stream_file_video1                ; hl = struct
        call StreamedFile__compute_LBA_sector_address
        call mmc_read_sector                            ; read sector (512 byte)      

;        jr c,ok_read_mmc_sector_read1
;        jp 0
;ok_read_mmc_sector_read1
;	call set_palette_based_on_carry
                                                        ; check for palette data
        call is_current_sector_contain_palette          ; cf is 1, if yes
        push af
        call c,  copy_readed_palette_data_to_buffer
        pop af
        call nc, copy_readed_video_data_to_video_memory_zoom2x

        call inc_counter_of_readed_sectors__videostream
        pop bc
        djnz read_next_sector_of_videofile

      	ld hl,$000
        call mark_frame_time

        ret



; zoom 2x
; Draw each source pixel twice in dest line and double each source line.
copy_readed_video_data_to_video_memory_zoom2x
        call kjt_page_in_video
	ld hl,sector_buffer             ; hl = source address

        ld b,LINES_PER_SECTOR           ; how much lines of video in one sector
next_line2
        push bc

        ld b,2          ; double each source video line in frame
next_line3
        push bc
        push hl
        call proccess_video_banking
                        ; de = offset in video bank
        push hl
        ld hl,video_base
        add hl,de
        ex de,hl        ; de = video address
        pop hl

	REPT VIDEO_STREAM_WIDTH
	ldi             ; copy one byte
        dec hl          ; decr source pointer 
        ldi             ; copy the same byte again
        ENDM

        call advance_dest_offset_of_videomem
        pop hl
        pop bc
        dec b
        jp nz,next_line3

        ld bc,VIDEO_STREAM_WIDTH
        add hl,bc                       ; hl = next source line address

        call advance_line_counter
        pop bc
        dec b
        jp nz,next_line2
	call kjt_page_out_video
        ret


advance_dest_offset_of_videomem
        push hl

        ld ix,dest_video_offset
        ld l,(ix)
        ld h,(ix+1)                     ; hl = dest video address

        ld bc, VIDEO_BUFFER_PITCH      ; pitch
        add hl,bc

        ld ix,dest_video_offset
        ld (ix),l
        ld (ix+1),h

        pop hl
        ret        

; Out: DE = offset in video bank
proccess_video_banking
        push hl

        ld ix,dest_video_offset
        ld e,(ix)
        ld d,(ix+1)                     ; de = dest video address

                        ; calc offset in video bank
        push de
        ld a,d
        and %00011111
        ld d,a          ; de = de AND 1fff

                        ; calc video bank number
        pop hl
        REPT 13
        srl h
        rr l
        ENDM            ; hl = hl / 8KB
        
                        ; calc video bank number, according to current active video buffer
        ld a,(video_bank_number_offset)
	add a,l
        

	ld (vreg_vidpage),a    ; set video bank number

        pop hl
        ret

advance_line_counter
        ld a,(count_video_lines_was_copied)
        inc a
        cp VIDEO_STREAM_HEIGHT
        jr nz,not_last_line1    ; is entire video frame was copied ?
;                               ; yes, reset video offset to start value
        ld ix,dest_video_offset
        ld de,VIDEO_OFFSET_FOR_VSTREAM                 ; de = dest video offset
        ld (ix),e
        ld (ix+1),d

        call flip_screen_double_buffers

        call set_new_palette
        call flip_palette
        
;
        xor a
not_last_line1
        ld (count_video_lines_was_copied),a
        ret


; copy palette data 
copy_readed_palette_data_to_buffer
	ld hl,sector_buffer    ;colours;
	ld de,colours          ; upload palette;
	ld bc,512;
	ldir

        ret

; Out: CF = 1, yes current sector contain palette data 
;      CF = 0, no
is_current_sector_contain_palette
        ld e,0
        ld ix,count_readed_sectors__videostream
        ld l,(ix)
        ld h,(ix+1)     ; e:hl = dividient
        
        ld d,VIDEO_STREAM_SECTORS_PER_VIDEOFRAME          ; divisor
        
        ;Input: E:HL = Dividend, D = Divisor
        ;Output: E:HL = Quotient, A = Remainder
        call div_unsigned_int_24bit_by_8bit

        or a    ; is remainder zero
        jr nz,notzerorem1
        scf
        ret
notzerorem1
        or a
        ret


; inc counter of readed SD sectors for video stream
inc_counter_of_readed_sectors__videostream
        ld ix,count_readed_sectors__videostream
        ld l,(ix)
        ld h,(ix+1)
        inc hl

        ld (ix),l
        ld (ix+1),h
        ret

flip_screen_double_buffers
                                ; flip bank number offset (shadow screen buffer address depends on it)
        ld a,(video_bank_number_offset)
        xor VIDEO_BANK_NUMBER_OFFS
        ld (video_bank_number_offset),a
                                ; flip video fetch address (active screen buffer)
        ld ix,video_fetch_start_address
        ld l,(ix)
        ld h,(ix+1)
        ld de, VIDEO_FETCH_ADDR

        ld a,l  ; byte
        xor e
        ld l,a
        ld a,h  ; byte
        xor d
        ld h,a

        ld (ix),l
        ld (ix+1),h
        ret

flip_palette
        ld a,(live_palette)
        xor 1
        ld (live_palette),a
        ret

; -----------
; must be called at the begining of the frame
setup_palette
        ld a,(live_palette)
        and 1
        ld (vreg_palette_ctrl),a        ; select 'live' palette 

        xor 1
        and 1
        or 2    
        ld (vreg_palette_ctrl),a        ; select write palette 

        ret

; must be called at the begining of the frame
setup_video_fetch_start_address

        ld ix,video_fetch_start_address
        ld l,(ix)
        ld h,(ix+1)

        push hl
        pop de          ; DE = HL

        ld l,0          ; prepare register for call
        ld h,e
        ld a,d
                        ; A:HL = Video window start address		
        call set_video_fetch_start_address
        ret

; In: 
;       A:HL = Video window start address		
;       (HL = low word
;        A = hight byte of three byte value)
set_video_fetch_start_address
	ld ix,bitplane0a_loc	
	ld (ix),l	        ;\ 
	ld (ix+1),h		;- Video fetch start address for this frame
	ld (ix+2),a		;/
        ret



dest_video_address      dw $2000

dest_video_offset               dw VIDEO_OFFSET_FOR_VSTREAM
count_video_lines_was_copied    db 0
count_readed_sectors__videostream       dw 0

; var for palette double buffering
live_palette            db 0

; vars for screen double buffering 
video_fetch_start_address       dw 0    ; byte 1 and 2 of address (byte 0 is always 0)
video_bank_number_offset        db VIDEO_BANK_NUMBER_OFFS  ;


; ------------------------------------------
;2.4 Classic 24-bit / 8-bit Unsigned
;
;Input: E:HL = Dividend, D = Divisor, A = 0
;Output: E:HL = Quotient, A = Remainder
div_unsigned_int_24bit_by_8bit
        ld a,0

        REPT 24
	add	hl,hl		; unroll 24 times
	rl	e		; ...
	rla			; ...
	cp	d		; ...
	jr	c,$+4		; ...
	sub	d		; ...
	inc	l		; ...
        ENDM
        ret


set_new_palette
	ld hl,colours + (16*2);
	ld de,palette + (16*2)		; upload palette;
	ld bc,512 -     (16*2);
	ldir
        ret
