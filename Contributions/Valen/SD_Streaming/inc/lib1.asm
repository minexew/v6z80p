mark_frame_time
;        ret
;	ld (palette),hl
;        ld b,0
;
	in a,(sys_keyboard_data)
	cp $12 ; left shift
        jr z, ttt1      
        ld hl,0
ttt1

        ld a,(live_palette)
        and 1
        or 2    
        ld (vreg_palette_ctrl),a        ; select write palette same as live palette


	ld (palette),hl
        ;                       ; re-setup palette
        xor 1
        ld (vreg_palette_ctrl),a        ; select write palette 

        ret
; 

; clear first 256KB of video mem
clear_video_memory
        call kjt_page_in_video

        ld b,32         ; 32 banks by 8KB
next_vidmem_bank1
        push bc

        ld a,b
        dec a                   ; calc video bank number, based on loop counter
	ld (vreg_vidpage),a     ; set video bank number
        
        xor a
        ld hl,video_base
        ld (hl),a

        ld e,l
        ld d,h
        inc de
        ld bc, $2000 - 1
        ldir

        pop bc
        djnz next_vidmem_bank1


        call kjt_page_out_video
        ret


;-----------------------------------------------------------------------------------------------------------
; Check V6Z80P hardware revision is appropriate for code
;-----------------------------------------------------------------------------------------------------------
; Out: CF = 1, check is ok
;      CF = 0, check failed
check_V6Z80P_hardware_revision
	call kjt_get_version
	ld hl,req_hw_version-1
	xor a
	sbc hl,de
	jr c,hw_vers_ok
	
	ld hl,bad_hw_vers
	call kjt_print_string
	xor a
	ret
hw_vers_ok
        scf
        ret

bad_hw_vers

	db 11,"Program requires hardware version v638+",11,11,0
