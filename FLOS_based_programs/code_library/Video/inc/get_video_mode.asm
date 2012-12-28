;----------------------------------------------------------------------------------------------- 
; Returns video mode in A.. 0=PAL, 1=NTSC, 2=VGA 50, 3=VGA 60
 
get_video_mode
		push bc
	        ld b,0                                            
	
		ld a,(vreg_read)                        ;60 Hz?
		bit 5,a
		jr z,not_60hz
		set 0,b

not_60hz	in a,(sys_hw_flags)                     ;VGA jumper on?
		bit 5,a
		jr z,not_vga
		set 1,b

not_vga  	ld a,b			                 ;0=PAL, 1=NTSC, 2=VGA 50, 3=VGA 60
		pop bc
		or a
		ret
		
;-----------------------------------------------------------------------------------------------