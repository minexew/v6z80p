
video_tests	call kjt_clear_screen
		
		ld hl,video_test_menu1
		call kjt_print_string		
		
wait_vt_menu	call kjt_wait_key_press
		cp $76
		jr nz,not_vt_quit
		xor a
		ret
		
not_vt_quit	ld a,b
		cp "1"
		jr z,test_palette
		cp "2"
		jr z,test_sprite_def
		cp "3"
		jr z,test_char_blit
		cp "4"
		jr z,test_blitter
		jr wait_vt_menu
		
test_palette	call do_palette_test
		jr video_tests
		
test_sprite_def	call do_sprite_def_test
		jr video_tests

test_char_blit	call do_char_blit_test
		jr video_tests

test_blitter	call do_blitter_test
		jr video_tests
		
;------------------------------------------------------------------------------------

video_test_menu1

		db "Video Test Menu",11,11

		db "Press:",11,11
		db "1. RGB colour test",11
		db "2. Sprite test",11
		db "3. Plot char test",11
		db "4. Blitter test",11,11
		
		db "ESC - quit to main menu",11,11,0
		

;-------------------------------------------------------------------------------------

do_palette_test
		call kjt_clear_screen

		ld hl,colours1
		ld de,palette+(17*2)
		ld bc,16
		ldir
		
		ld c,$10
		ld hl,colour_txt
rgblp		ld a,(hl)
		or a
		jr z,rgbdone
		ld a,c
		call kjt_set_pen
		call kjt_print_string
		ld a,c
		add a,$10
		ld c,a
		jr rgblp
		
rgbdone		ld a,7
		call kjt_set_pen
		call press_any_key
		call kjt_flos_display
		xor a
		ret

colours1	dw $000,$00f,$f00,$f0f,$0f0,$0ff,$ff0,$fff

colour_txt	db "   BLACK  ",11,0
		db "   BLUE   ",11,0
		db "    RED   ",11,0
		db "  MAGENTA ",11,0
		db "   GREEN  ",11,0
		db "   CYAN   ",11,0
		db "  YELLOW  ",11,0
		db "   WHITE  ",11,11,0
		db 0
		
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
; Sprite RAM test (visual only)
;-------------------------------------------------------------------------------------
		
do_sprite_def_test

		ld hl,sprite_registers			;zero all sprite regs
		ld bc,512
sprclrlp	ld (hl),0
		inc hl
		dec bc
		ld a,b
		or c
		jr nz,sprclrlp
		
		ld de,0					;wipe all sprite defs at start
		ld a,0
clsp1		ld hl,blank_sprite
		ld bc,256
		push af
		push de
		call upload_to_sprite_ram
		pop de
		pop af
		inc d
		jr nz,clsp1
		inc a
		cp 2
		jr nz,clsp1
		
		xor a
		ld (sp_pass),a
		
		ld hl,sp_colours
		ld de,palette+(248*2)
		ld bc,16
		ldir					;set colour used in test sprite to white
		ld a,1
		ld (vreg_sprctrl),a                     ;enable sprites - most basic mode
		call run_sp_test
		xor a					;disable sprites
		ld (vreg_sprctrl),a  	
		ret
		
run_sp_test	ld de,0					;move the test sprite def though all 512 sprite definitions
		ld hl,spsmg1_txt
		call test_spr
		ret z
		
		ld de,128
		ld hl,spsmg2_txt
		call test_spr
		ret z
		
		ld de,256
		ld hl,spsmg3_txt
		call test_spr
		ret z
		
		ld de,384
		ld hl,spsmg4_txt
		call test_spr
		ret z
		
		ld a,(sp_pass)
		inc a
		ld (sp_pass),a
		jr run_sp_test

test_spr	push de
		push hl
		call kjt_clear_screen
		pop hl
		call kjt_print_string
		pop de
		call position_sprites
		xor a
		ld (sp_timer),a
		ld (sp_def_pos),de
		ld hl,0
		ld (sp_def_step),hl
		
		ld a,(sp_pass)				;set colour of sprite
		and 7
		add a,248
		ld hl,test_sprite
		ld b,0
fslp1		ld (hl),a
		inc hl
		djnz fslp1
		
		ld hl,painted_txt
		call kjt_print_string
		ld a,(sp_pass)
		and 7
		ld hl,sp_col_text
		ld bc,end_sp_col_text
		cpir
		call kjt_print_string
		

spwtlp1		call kjt_wait_vrt
		call kjt_get_key
		cp $76
		ret z
		ld hl,sp_timer
		inc (hl)
		ld a,(hl)
		cp 2
		jr nz,spwtlp1
		ld (hl),0

		ld hl,(sp_def_pos)		;copy the test sprite to a def block
		ld de,(sp_def_step)
		add hl,de
		ld a,h
		and 1
		ld d,l
		ld e,0
		ld hl,test_sprite		
		ld bc,$100
		call upload_to_sprite_ram

		ld hl,(sp_def_step)
		inc hl
		ld a,l
		cp 128
		jr nz,cspl
		xor a
		inc a
		ret
cspl		ld (sp_def_step),hl
		jr spwtlp1	


spsmg1_txt	db "Sprite definitions $00-$7F",11
		db "(Sprite RAM $00000-$07FFF)",11,0

spsmg2_txt	db "Sprite definitions $80-$FF",11
		db "(Sprite RAM $08000-$0FFFF)",11,0

spsmg3_txt	db "Sprite definitions $100-$17F",11
		db "(Sprite RAM $10000-$17FFF)",11,0

spsmg4_txt	db "Sprite definitions $180-$1FF",11
		db "(Sprite RAM $18000-$1FFFF)",11,0

sp_timer	db 0

sp_def_pos	dw 0
sp_def_step	dw 0
sp_pass		db 0

sp_colours	dw $fff,$f00,$0f0,$00f,$000,$888,$ff0,$0ff

sp_col_text	db 0,"White",0
		db 1,"Red",0
		db 2,"Green",0
		db 3,"Blue",0
		db 4,"Black",0
		db 5,"Grey",0
		db 6,"Yellow",0
		db 7,"Cyan",0
		
end_sp_col_text

painted_txt	db 11,"Blocks should be painted: ",0

;-------------------------------------------------------------------------------------

position_sprites
		
		push de
		
		ld b,16                                 ;update the sprite registers
		ld hl,128+(8*4)                         ;x coord
		          
		ld ix,sprite_registers
spreglp		ld (ix+0),l                             ;set x coord low
		ld (ix+3),e                             ;set def low
		ld a,d
		rlca
		rlca
		and 4
		ld c,a
		ld a,h
		and 1
		or $80
		or c
		ld (ix+1),a                             ;set msbs
		ld (ix+2),$60                           ;set y coord low
          
		ld a,l                                  ;next x coord
		add a,16
		ld l,a
		jr nc,xcomok
		inc h
          
xcomok   	ld a,e                                  ;def + 8
		add a,8
		ld e,a
		jr nc,defmok
		inc d

defmok   	inc ix                                  ;next spr reg
		inc ix
		inc ix
		inc ix
          
		djnz spreglp
		
		pop de
		ret

;-------------------------------------------------------------------------------------

upload_to_sprite_ram
	
		push de
		sla d
		rla
		sla d
		rla
		sla d
		rla
		sla d
		rla
		pop de
		
		ld ix,sprite_page
		ld (ix),a
		
		in a,(sys_mem_select)				;page in VRAM
		or $80
		out (sys_mem_select),a
		
utsrvb		ld a,d
		and %00001111
		or  %00010000
		ld d,a
		ld a,(ix)
		or $80
		ld (vreg_vidpage),a
utsrlp		ldi
		jp po,uplsrend
		bit 5,d
		jp z,utsrlp
		inc (ix)
		jr utsrvb
	
uplsrend	in a,(sys_mem_select)				;page out VRAM
		and $7f
		out (sys_mem_select),a
		ret

sprite_page	db 0	

;-------------------------------------------------------------------------------------

test_sprite	ds 256,0

blank_sprite	ds 256,0

;-------------------------------------------------------------------------------------

do_char_blit_test
		call kjt_clear_screen
		ld hl,charblit_txt
		call kjt_print_string
		
		ld d,0

chbllp3		ld e,d
		ld c,1
chbllp2		ld b,0
chbllp1		ld a,e
		call kjt_plot_char
		inc e
		inc b
		ld a,b
		cp 40
		jr nz,chbllp1
		inc c
		ld a,c
		cp 25
		jr nz,chbllp2
		
		inc d
		
		call kjt_get_key
		cp $76
		jr nz,chbllp3
		xor a
		ret

charblit_txt	db "Plot char test.. Esc to quit.",0

;-------------------------------------------------------------------------------------

do_blitter_test

		call kjt_clear_screen
		ld hl,blit_test_txt
		call kjt_print_string
			
		ld a,$0
		ld (vreg_vidpage),a		; put blit test obs at VRAM $0
		call kjt_page_in_video
		ld hl,object
		ld de,$2000
		ld bc,512
		ldir
		call kjt_page_out_video
			
		ld hl,0
		ld (pass_count),hl
			
bltstlp		call pause_1_second
		call pause_1_second
		call kjt_get_key
		cp $76
		ret z
		
		call setup_256x200
		
		ld hl,colours2			; write palette
		ld de,palette
		ld bc,256*2
		ldir

		ld a,$20
		ld (vreg_vidpage),a		;draw screen at vram $40000
		ld ix,bitplane0a_loc		
		ld hl,$0000			
		ld c,4				
		ld (ix),l
		ld (ix+1),h
		ld (ix+2),c
		ld a,c
		ld (dest_page),a
		call make_blit_screen
		
		ld a,$30			;draw screen at vram $60000
		ld (vreg_vidpage),a
		ld hl,$0000			
		ld c,6		
		ld (ix),l
		ld (ix+1),h
		ld (ix+2),c
		ld a,c
		ld (dest_page),a
		call make_blit_screen
		
		call kjt_flos_display
		
		ld b,8
		ld c,0				;compare the two blitted screens
blcomp2		ld a,c
		add a,$20
		ld (vreg_vidpage),a
		push bc
		call kjt_page_in_video
		ld hl,$2000
		ld de,$8000
		ld bc,$2000
		ldir
		pop bc
		ld a,c
		add a,$30
		ld (vreg_vidpage),a
		ld hl,$2000
		ld de,$8000
blcomp		ld a,(de)
		cp (hl)
		jr nz,blerr
		inc hl
		inc de
		bit 6,h
		jr z,blcomp
		inc c
		djnz blcomp2
		
		call kjt_page_out_video
		ld hl,(pass_count)
		inc hl
		ld (pass_count),hl
		call show_passes
		call kjt_get_key
		cp $76
		ret z
		jp bltstlp
		
blerr		call kjt_page_out_video
		ld hl,blit_error_txt
		call kjt_print_string
		call press_any_key
		xor a
		inc a
		ret
			

blit_test_txt	db "Blitter Test",11,11
		db "ESC to quit (when FLOS display shows)",11,11,0

blit_error_txt	db 11,"BLITTING ERROR!",11,11
		db "VRAM $40000-$4FFFF and $60000-$6FFFF",11
		db "do not match.",11,11,0



make_blit_screen

		ld hl,(pass_count)
		ld (seed),hl
		
		di
		ld a,%00100000
		out (sys_mem_select),a		; select direct vram write mode (64KB video page)
		ld hl,0				; clear screen
		xor a
clrs1		ld (hl),a
		inc l
		jr nz,clrs1
		inc h
		jr nz,clrs1
		xor a
		out (sys_mem_select),a
		ei
					
		ld bc,0				;draw 65536 randomly positioned bobs
blrand		exx
		call rand16
		ld b,h
		ld c,l
		ld a,b
		xor c
		and 1				;choose randon image
		call blit_trans_16x16
		exx
		inc bc
		ld a,b
		or c
		jr nz,blrand
		ret
		

;-------------------------------------------------------------------------------------------
; Use blitter to put object on screen
;-------------------------------------------------------------------------------------------

display_width		equ 256
obj_width 		equ 16
obj_height		equ 16
source_modulo 		equ 0
destination_modulo	equ display_width-obj_width

blit_trans_16x16
		
		ld h,a
		ld l,0
		ld a,$0				;source objects are at VRAM $0/$100
		ld (blit_src_loc),hl		;set source address
		ld (blit_src_msb),a		;set source address msb
		
		ld a,source_modulo 	
		ld (blit_src_mod),a		;set source modulo

		ld (blit_dst_loc),bc		;coords (on 256x256 display = bc)
		ld a,(dest_page)		;destination page for blit is VRAM $40000 or $60000
		ld (blit_dst_msb),a
		
		ld a,destination_modulo
		ld (blit_dst_mod),a		;set destination modulo
		
		ld a,%11000000			;set blitter to ascending mode (modulo 
		ld (blit_misc),a		;high bits set to zero, transparency: on)

		ld a,obj_height-1
		ld (blit_height),a		;set height of blit object (in lines)
		ld a,obj_width-1
		ld (blit_width),a		;set width of blit object (in bytes) and start blit
		
		nop				;waste a few cycles to ensure blit has begun
		nop				;before testing busy flag
waitblit5	in a,(sys_vreg_read)		
		bit 4,a 			;busy wait for blit to complete
		jr nz,waitblit5
		ret

dest_page	dw 0

;-------------------------------------------------------------------------------------------

object		incbin "FLOS_based_programs\utils\CHECKSYS\data\tiles.bin"

colours2	incbin "FLOS_based_programs\utils\CHECKSYS\data\tiles_palette.bin"

;-------------------------------------------------------------------------------------------

