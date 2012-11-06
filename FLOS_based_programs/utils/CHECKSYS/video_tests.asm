
video_tests	call kjt_clear_screen
		
		ld hl,video_test_menu1
		call kjt_print_string
		
		call show_video_mode		
		
		ld hl,video_test_menu2
		call kjt_print_string
		
wait_vt_menu	call kjt_wait_key_press
		cp $76
		jr nz,not_vt_quit
		xor a
		ret
		
not_vt_quit	ld a,b
		cp "1"
		jr z,test_palette
		jr wait_vt_menu
		
test_palette	call do_palette_test
		jr video_tests


;------------------------------------------------------------------------------------

video_test_menu1

		db "Video Test Menu",11,11,0

video_test_menu2

		db 11,11,"Press:",11,11
		db "1. RGB colour test",11,11				
		db "ESC - quit to main menu",11,11,0
		
;-------------------------------------------------------------------------------------

show_video_mode
		ld hl,vmode_txt
		call kjt_print_string
		
	        ld b,0                                            
		in a,(sys_hw_flags)                     ;VGA jumper on?
		bit 5,a
		jr z,not_vga
		ld b,2
		jr got_mode 
not_vga   	ld a,(vreg_read)                        ;60 Hz?
		bit 5,a
		jr z,got_mode
		ld b,1
got_mode  	ld a,b			                 ;0=PAL, 1=NTSC, 2=VGA
		add a,$10
		ld hl,vid_list
		ld bc,end_vid_list-vid_list
		cpir
		call kjt_print_string
		ret
		
vmode_txt	db "Video mode: ",0

vid_list	db $10,"PAL TV",0
		db $11,"NTSC TV",0
		db $12,"VGA",0
end_vid_list	db "Unknown",0

;-------------------------------------------------------------------------------------

do_palette_test
		call kjt_clear_screen
		
		ld hl,pal_test_txt
		call kjt_print_string

		call kjt_wait_key_press
		
		call setup_256x200
	
		ld hl,colours1			; write palette
		ld de,palette+$1e0
		ld bc,32
		ldir

		di
		ld a,%00100001
		out (sys_mem_select),a		; select direct vram write mode
			
		ld hl,0
		ld c,200
fvramlp2	ld a,h
		rrca
		rrca
		rrca
		rrca
		and $f
		add a,240
		ld b,0
fvramlp1	ld (hl),a
		inc l
		djnz fvramlp1
		inc h
		dec c
		jr nz,fvramlp2
		
		ld a,%00000000
		out (sys_mem_select),a		; deselect direct vram write mode
		ei

paltwx		call kjt_wait_key_press
		cp $76
		jr nz,paltwx
		
		call kjt_flos_display
		xor a
		ret

colours1	dw $000,$00f,$0f0,$0ff,$f00,$f0f,$ff0,$fff
		dw $000,$000,$000,$000,$000,$000,$000,$000

pal_test_txt	db "The following colour bars should",11
		db "appear:",11,11
		db "BLACK",11
		db "BLUE",11
		db "GREEN",11
		db "CYAN",11
		db "RED",11
		db "MAGENTA",11
		db "YELLOW",11
		db "WHITE",11,11
		db "Press any key to start / ESC to exit",11,11,0

;-------------------------------------------------------------------------------------

setup_256x200

		ld a,%00000000			; select y window pos register
		ld (vreg_rasthi),a		; 
		ld a,$5a			; set 200 line display
		ld (vreg_window),a
		ld a,%00000100			; switch to x window pos register
		ld (vreg_rasthi),a		
		ld a,$aa
		ld (vreg_window),a		; set 256 pixels wide window

		ld ix,bitplane0a_loc		;initialize datafetch start address HW pointer.
		ld hl,$0000			;datafetch start address (15:0)
		ld c,0				;data fetch start address (16)
		ld (ix),l
		ld (ix+1),h
		ld (ix+2),c
		
		ld a,%10000000
		ld (vreg_vidctrl),a		; Set bitmap mode (bit 0 = 0) + chunky pixel mode (bit 7 = 1)

		ld a,%00000000
		ld (vreg_vidpage),a		; video page access msb = 0
		ret

		
;-------------------------------------------------------------------------------------
