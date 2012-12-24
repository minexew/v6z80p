
;----------------------------------------------------------------------------------------------------
; SysRAM locations: $05000-$0FFFF = main program
;                   $10000-$17FFF = tune dir list
;                   $18000-$7ffff = music module
;----------------------------------------------------------------------------------------------------
;
; Format of tune dir list:
;
;	db $ff
;	db " ",0			;must have two fake entries so first entry can reach selection
;	db " ",0
;	
;	db "fname1.mod",0		
;	db "fname2.mod",0
;	db "fname3.mod",0		;etc etc
;	
;	db " ",0			;must have two fake entries so last entry can reach selection
;	db " ",0
;	db $ff
;
;----------------------------------------------------------------------------------------------------------

init_tune_menu	ld de,menu_bitmap_loc_lo			; dest = a:de
		ld a,menu_bitmap_loc_hi
		ld bc,$8000					; number of bytes = bc
		call clear_vram		
		
		ld hl,menu_font					; put font in VRAM for blitter access
		ld bc,$1000
		ld de,menu_font_loc_lo		
		ld a,menu_font_loc_hi				; a:de = dest in VRAM
		call copy_to_vram

		call get_module_list
		ld hl,mod_path_bad_txt
		ret nz
		ld a,(mods_avail)
		or a
		jr nz,got_mods
		ld hl,no_mods_txt
		inc a
		ret
		
got_mods	call find_default_tune				;try to load prefered starting module
		call draw_init_tune_menu
		ld c,2						
		call get_filename				;if default tune not present, load first tune
		
got_dt		call load_tune
		xor a
		ret
		
;---------------------------------------------------------------------------------------------------------

mod_list   equ $8000					;mod list is at $10000 in system RAM
mlist      equ mod_list+1

get_module_list
	
		ld a,2					; set upper 32kb page where mod list was loaded	
		out (sys_mem_select),a
		call read_mods_dir
		push af
		xor a
		out (sys_mem_select),a
		pop af
		ret



find_default_tune
		
		ld a,2					
		out (sys_mem_select),a			; set upper 32kb page where mod list was loaded			
		
		ld hl,mlist
		ld (fn_pointer),hl

fdt_loop	ld de,default_tune_fn			; positions the menu index at appropriate point for the required
		ld b,13					; default tune
		call kjt_compare_strings
		jr c,fdt_gdt
		
fdt_notdt	ld a,(hl)
		inc hl
		or a
		jr nz,fdt_notdt
			
fdt_fnt		ld a,(hl)
		cp $ff
		jr nz,fdt_loop
		xor a
		out (sys_mem_select),a
		inc a					;ZF not set on return = didnt find default tune
		ret
		
fdt_gdt		ld (fn_pointer),hl
		call move_to_prev_filename
		call move_to_prev_filename
		
fdt_done	xor a
		out (sys_mem_select),a
		ret

		


draw_init_tune_menu

		
		ld a,1
fmllp		ld (menu_line),a			;set up inital menu
		dec a
		ld c,a
		call get_filename
		ld a,b
		or a
		jr z,fmlend
		push hl
		pop ix
		call draw_fn_line
		ld a,(menu_line)
		inc a
		cp 6
		jr nz,fmllp
fmlend		ret



read_mods_dir	xor a
		ld (mods_avail),a
		
		ld hl,tune_path_txt
		call kjt_parse_path
		ret nz
		
		call kjt_dir_list_first_entry
		ret nz

		ex de,hl
		ld hl,mod_list				;start mod list with $ff," ",0," ",0
		ld (hl),$ff
		inc hl
		ld (hl)," "
		inc hl
		ld (hl),0
		inc hl
		ld (hl)," "
		inc hl
		ld (hl),0
		inc hl
		ex de,hl
			
mlistlp		bit 0,b					;is entry a dir?
		jr nz,skpen
		push hl
		ld a,"."				;does entry end in ".mod"?
		ld bc,9
		cpir
		jr z,gotdot
enbad		pop hl
		jr skpen

gotdot		ld a,(hl)
		cp "M"
		jr nz,enbad
		inc hl
		ld a,(hl)
		cp "O"
		jr nz,enbad
		inc hl
		ld a,(hl)
		cp "D"
		jr nz,enbad
		pop hl

cpfnlp		ld a,(hl)				;copy filename to mod list
		ld (de),a
		inc hl
		inc de
		or a
		jr nz,cpfnlp
		ld a,1
		ld (mods_avail),a

skpen		push de
		call kjt_dir_list_next_entry
		pop de
		jr z,mlistlp
		cp $24					;end of dir?
		ret nz
		ex de,hl
		ld (hl)," "				;end mod list with " ",0," ",0,$ff
		inc hl
		ld (hl),0
		inc hl
		ld (hl)," "
		inc hl
		ld (hl),0
		inc hl
		ld (hl),$ff
		ret
		
		
tune_path_txt	db "/tunes/pt_mods",0
		ds 40,0 
		
mods_avail	db 0
	
;------------------------------------------------------------------------------

init_menu_scroll_up
	
		ld hl,scroll_up_count			;IE: move down menu list
		ld a,(scroll_down_count)
		or (hl)					;dont do anything if already scrolling
		ret nz
		
		ld a,6					
		ld (menu_line),a
		dec a
		ld c,a
		call get_filename			;if at last line of menu, do not init scroll
		ld a,b
		or a
		ret z
		
nfnok		push hl
		pop ix
		call draw_fn_line
		ld a,8
		ld (scroll_up_count),a
		call move_to_next_filename
		ret
	
	
init_menu_scroll_down
	
		ld hl,scroll_up_count			;IE: Move up menu list
		ld a,(scroll_down_count)
		or (hl)					;dont do anything if already scrolling
		ret nz
		
		call move_to_prev_filename
		ld a,b
		or a
		ret z					;if at top line of menu, do not init scroll
		
		ld a,0
		ld (menu_line),a
		ld c,0
		call get_filename
		push hl
		pop ix
		call draw_fn_line
		ld a,8
		ld (scroll_down_count),a
		ret

;---------------------------------------------------------------------------------------------------------

do_menu_scrolling

		ld a,(scroll_up_count)
		or a
		jr z,tsdown
		dec a
		ld (scroll_up_count),a
		call do_scroll_up
		ret

tsdown		ld a,(scroll_down_count)
		or a
		ret z
		dec a
		ld (scroll_down_count),a
		call do_scroll_down
		ret

;---------------------------------------------------------------------------------------------------------

menu_font_width		equ 8

draw_fn_line

; set IX to filename location
; assumes line is blank (previous data scrolled out)

		call wait_blit				; make sure blitter isnt working

		ld a,menu_font_loc_hi			; set blit parameters
		ld (blit_src_msb),a				
		ld a,menu_bitmap_loc_hi
		ld (blit_dst_msb),a
		
		ld a,$00
		ld (blit_src_mod),a				
		ld a,7
		ld (blit_height),a			
			
		ld hl,bitmap_width
		ld de,menu_font_width
		xor a
		sbc hl,de
		ld a,l					; dest modulo lower bits
		ld (blit_dst_mod),a				
		ld a,h					; dest modulo upper bits
		rlca
		rlca
		and %00001100
		or  %01000000	
		ld (blit_misc),a
		
		ld a,(fn_length)			; plot new filename chars
		dec a
		ld b,a
		rlca
		rlca
		ld c,a
		ld a,bitmap_width/2
		sub c
		ld l,a
		ld h,0
		call add_menu_line_addr
		ld (char_dest),hl

fn_draw_charlp	
	
		ld a,(ix)
		sub 32
		inc ix
		ld l,0
		srl a
		rr l
		srl a
		rr l
		ld h,a
		ld de,menu_font_loc_lo
		add hl,de
		ld (blit_src_loc),hl
		
		ld hl,(char_dest)
		ld (blit_dst_loc),hl

		call wait_blit
		
		ld a,7
		ld (blit_width),a				; set width = 8 bytes, start blit			 
			
		ld hl,(char_dest)				
		ld de,8
		add hl,de
		ld (char_dest),hl
		
		djnz fn_draw_charlp
		
		call wait_blit
		ret


wait_blit	in a,(sys_vreg_read)		
		and $10 			
		jr nz,wait_blit
		ret
		
		
	
add_menu_line_addr
	
		ld a,(menu_line)
		or a 
		jr z,gotmla
		ld de,8*bitmap_width
clmlad		add hl,de
		dec a
		jr nz,clmlad
		
gotmla		ld de,menu_bitmap_loc_lo
		add hl,de
		ret
	
	
;------------------------------------------------------------------------------------------------------------------

do_scroll_up
		call wait_blit

		ld a,menu_bitmap_loc_hi					;common blit parameters for scroll
		ld (blit_src_msb),a				
		ld (blit_dst_msb),a
		
		ld hl,bitmap_width					
		ld de,12*menu_font_width
		xor a
		sbc hl,de
		ld a,l							;dest modulo lower bits
		ld (blit_dst_mod),a				
		ld (blit_src_mod),a
		ld a,h							;dest modulo upper bits
		rlca
		rlca
		and %00001100
		or  %01000000	
		ld l,a
		ld a,h
		and %00000011
		or l
		ld (blit_misc),a

		ld a,48-1						;scroll 6*8 lines
		ld (blit_height),a			

		ld hl,menu_bitmap_loc_lo+(bitmap_width*8)+(bitmap_width/2)-(6*8)			
		ld (blit_dst_loc),hl
		ld de,bitmap_width
		add hl,de
		ld (blit_src_loc),hl
		
		ld a,0+(12*8)-1
		ld (blit_width),a					;start blit

		call wait_blit
		ret



do_scroll_down	

		call wait_blit

		ld a,menu_bitmap_loc_hi					;common blit parameters for scroll
		ld (blit_src_msb),a				
		ld (blit_dst_msb),a
		
		ld hl,bitmap_width					
		ld de,12*menu_font_width
		xor a
		sbc hl,de
		ld a,l							;dest modulo lower bits
		ld (blit_dst_mod),a				
		ld (blit_src_mod),a
		ld a,h							;dest modulo upper bits
		rlca
		rlca
		and %00001100
		or  %00000000	
		ld l,a
		ld a,h
		and %00000011
		or l
		ld (blit_misc),a

		ld a,48-1						;scroll 6*8 lines
		ld (blit_height),a			

		ld hl,menu_bitmap_loc_lo+(bitmap_width*46)+(bitmap_width/2)+(6*8)-1			
		ld (blit_src_loc),hl
		ld de,bitmap_width
		add hl,de
		ld (blit_dst_loc),hl
		
		ld a,0+(12*8)-1
		ld (blit_width),a					;start blit
		
		call wait_blit
		ret

;--------------------------------------------------------------------------------------------------------------

move_to_next_filename
	
		ld a,2
		out (sys_mem_select),a
		
next_fn		ld hl,(fn_pointer)			
fnfnlp		ld a,(hl)
		inc hl
		or a
		jr nz,fnfnlp
		ld (fn_pointer),hl
		
		xor a
		out (sys_mem_select),a
		ret
	
	
move_to_prev_filename

		ld a,2
		out (sys_mem_select),a

		ld b,0							;if b=0 on return, no previous filename
		ld hl,(fn_pointer)
		dec hl
		ld a,(hl)
		cp $ff
		jr z,mtpfnx
fpfnlp		dec hl
		inc b
		ld a,(hl)
		cp $ff
		jr z,gotpfn
		or a
		jr nz,fpfnlp
gotpfn		inc hl
		ld (fn_pointer),hl
		ld a,b
		ld (fn_length),a

mtpfnx		xor a
		out (sys_mem_select),a
		ret
		
	
;------------------------------------------------------------------------------

get_filename

; Set C = line offset

get_fn		ld a,2
		out (sys_mem_select),a
		
		ld hl,(fn_pointer)			;if b=0 on return, no more filenames
		ld b,0
		ld a,c
		or a
		jr z,gfnfl
glflp		ld a,(hl)
		inc hl
		or a
		jr nz,glflp
		dec c
		jr nz,glflp
		ld a,(hl)
		cp $ff
		jr z,endmenu
		
gfnfl		push hl
glfnlp		ld a,(hl)
		inc b
		inc hl
		or a
		jr nz,glfnlp
		pop hl
		ld a,b
		ld (fn_length),a
		
		ld de,menu_fn				;copy filename to unpaged RAM
		push de
		push bc
		ld bc,14
		ldir
		pop bc
		pop hl
		
endmenu		xor a
		out (sys_mem_select),a
		ret


;-----------------------------------------------------------------------------------------------------


volume_fade	ld a,(fade)				; is master volume falling?
		or a
		ret z
		ld a,(pt_master_vol)			; fade out volume when new tune selected
		sub 2
		ld (pt_master_vol),a
		ret nz
		xor a
		ld (fade),a
		ld a,1					; volume is zero, set a "load tune" flag
		ld (load_new_tune),a
		ret
				

;-----------------------------------------------------------------------------------------------------

pt_module_loc_lo	equ $8000			; flat cpu address in sysram where module is located
pt_module_loc_hi	equ $01				; module located at $18000

load_tune

; Set HL to filename location

		xor a
		ld (tune_loaded),a
		
		push hl
		pop iy					; IY = location of filename
		ld a,pt_module_loc_hi			; load module to A:HL flat address
		ld hl,pt_module_loc_lo
		call load_flat
		ret nz
                    
		call pt_init
		ret nz
		
		ld a,1
		ld (tune_loaded),a		

		xor a					; ZF set, tune loaded and initialized
		ret


tune_fn_loc		dw 0
tune_loaded		db 0

tune_orig_bank		db 0

;------------------------------------------------------------------------------------------------

default_tune_fn		db "stardust.mod",0

menu_fn			ds 14,0

menu_line		db 0
	
fn_pointer		dw 0

fn_length		db 0

scroll_up_count		db 0

scroll_down_count	db 0

char_dest		dw 0

;-----------------------------------------------------------------------------------------------

	include "flos_based_programs\code_library\protracker_player\inc\osca_modplayer_v515.asm"	
	
	include "flos_based_programs\code_library\maths\inc\flat_to_banked_addr.asm"

;-----------------------------------------------------------------------------------------------

menu_font	incbin "flos_based_programs\demos\selectro\data\8x8font.bin"

selector_palette
		incbin "flos_based_programs\demos\selectro\data\music_selector_palette.bin"

menu_fade_colours

		dw $000,$000,$111,$222,$222,$333,$333,$444,$444,$555,$555,$666,$666,$777,$777,$888,$888
		dw $fff,$fff,$fff,$fff,$fff,$fff,$fff,$fff
		dw $888,$888,$777,$777,$666,$666,$555,$555,$444,$444,$333,$333,$222,$222,$111,$000,$000

mod_path_bad_txt	db "Error reading module dir!",11,11,0

no_mods_txt		db "No .mod files found in dir!",11,11,0
		
;-----------------------------------------------------------------------------------------------
