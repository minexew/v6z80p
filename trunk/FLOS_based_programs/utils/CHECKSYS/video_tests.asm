
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
		jp z,test_sprite_def
		cp "3"
		jp z,test_char_blit
		jr wait_vt_menu
		
test_palette	call do_palette_test
		jr video_tests
test_sprite_def	call do_sprite_def_test
		jr video_tests
test_char_blit	call do_char_blit_test
		jr video_tests

;------------------------------------------------------------------------------------

video_test_menu1

		db "Video Test Menu",11,11

		db "Press:",11,11
		db "1. RGB colour test",11
		db "2. Sprite test",11
		db "3. Plot char (blit) test",11,11
		
		db "ESC - quit to main menu",11,11,0
		

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





