;
; Selectro - a music player / selector for OSCA/FLOS on the V6Z80P
; by Phil www.retroleum.co.uk 2012 - V1.00 
;
;---Standard header for OSCA and FLOS --------------------------------------------------------------------

include "equates\kernal_jump_table.asm"
include "equates\OSCA_hardware_equates.asm"
include "equates\system_equates.asm"

	org $5000

;---------------------------------------------------------------------------------------------------------

required_osca   equ $674
include         "flos_based_programs\code_library\program_header\inc\test_osca_version.asm"

required_flos	equ $610
include 	"flos_based_programs\code_library\program_header\inc\test_flos_version.asm"

;---------------------------------------------------------------------------------------------------------
; Constants / Locations used by intro
;---------------------------------------------------------------------------------------------------------

bitmap_width		equ 400

menu_font_loc_hi	equ $0
menu_font_loc_lo	equ $0000	; VRAM $00000

logo_bitmap_loc_hi	equ $02
logo_bitmap_loc_lo	equ $0000	; VRAM $20000

scroll_bitmap_loc_hi	equ $03
scroll_bitmap_loc_lo	equ $0000	; VRAM $30000

menu_bitmap_loc_hi	equ $4
menu_bitmap_loc_lo	equ $0000	; VRAM $40000

msel_bitmap_loc_hi	equ $4
msel_bitmap_loc_lo	equ $8000	; VRAM $48000

scroll_font_loc_hi	equ $07
scroll_font_loc_lo	equ $0000	; VRAM $70000

;---------------------------------------------------------------------------------------------------------

		call save_dir_vol				; save and restore directory and volume around demo
		call selectro
		call restore_dir_vol
		ret
			
;-------------- Main Initialization code -------------------------------------------------------------------	
	
selectro	ld a,(hl)					; if no args, use default path for tunes
		or a
		jr z,default_dir
		ld de,tune_path_txt
		ld bc,40
		ldir						; use path from command line
		
default_dir	ld de,logo_bitmap_loc_lo			; clear vram where logo will be placed
		ld a,logo_bitmap_loc_hi 			; vram dest = a:de
		ld bc,$8000					; number of bytes = bc
		call clear_vram		

		ld de,msel_bitmap_loc_lo			; clear vram where selector logo will be placed
		ld a,msel_bitmap_loc_hi 			; vram dest = a:de
		ld bc,$8000					; number of bytes = bc
		call clear_vram	

		ld hl,retrologo					; unpack retroleum logo to vram
		ld de,logo_bitmap_loc_lo
		ld a,logo_bitmap_loc_hi
		ld bc,end_retrologo-retrologo
		call unpack_to_vram

		ld hl,selector_gfx				; unpack selector graphic to vram
		ld de,msel_bitmap_loc_lo
		ld a,msel_bitmap_loc_hi
		ld bc,end_selector_gfx-selector_gfx
		call unpack_to_vram
		
		call init_sine_scroller
		call set_up_starfield_sprites
		call set_up_equalizer_sprites
		
		ld hl,loading_txt
		call kjt_print_string

		call init_tune_menu				
		jp nz,dont_start				; if ZF not set there was an error getting module list

		call kjt_wait_vrt				; for a neat, consistant switch over to demo display
		
		call init_linecop
		
		ld a,%00000011
		ld (vreg_sprctrl),a				; enable sprites, enable interleaved priority mode

		ld a,%00000000					; select y window pos register
		ld (vreg_rasthi),a				 
		ld a,$2c					; set 240 line display
		ld (vreg_window),a
		ld a,%00000100					; switch to x window pos register
		ld (vreg_rasthi),a		
		ld a,$6f
		ld (vreg_window),a				; set 368 pixels wide window

		call set_up_interrupts

;-------------- Idle / Background tasks -------------------------------------------------------------


wait_loop	ld a,(load_new_tune)				; if new tune flag is set, load tune
		or a
		jr z,nonewtune
		ld c,2						
		call get_filename
		call load_tune
		ld a,64						; put volume back to full
		ld (pt_master_vol),a
		xor a
		ld (load_new_tune),a


nonewtune	ld a,(esc_pressed)				
		or a
		jr nz,quit_to_flos				; if ESC pressed, quit back to FLOS

		ld a,(fade)					; if ENTER pressed (and not already fading) start fading out tune
		or a
		jr nz,wait_loop
		ld a,(enter_pressed)				
		or a
		jr z,wait_loop
		ld a,1
		ld (fade),a
		ld a,64
		ld (pt_master_vol),a
		jr wait_loop
		

fade		db 0						; 1 = fading out
load_new_tune	db 0



;-------------------------------------------------------------------------------------------------
	

do_every_frame	xor a
		out (sys_mem_select),a
		
		ld hl,frame_count
		inc (hl)
		
		call do_menu_scrolling				
		call update_equalizer_sprites			
		call animate_starfield
		call draw_sine_scroller				
		
		ld a,(tune_loaded)				; don't play tracker code whilst tune is being loaded (or if failed to load)
		or a
		jr z,no_tune
		call osca_play_tracker
		call equalizer_scan
		
no_tune		call volume_fade		
		
		ld a,(up_pressed)				; scroll up through menu?
		or a
		call nz,init_menu_scroll_down

		ld a,(down_pressed)				; scroll down through menu?
		or a
		call nz,init_menu_scroll_up
		
;		call raster_marker				; only for testing

		ret
	
	
;--------------- Return to FLOS --------------------------------------------------------------------


quit_to_flos	di
		ld hl,(flos_irq_vector)
		ld (irq_vector),hl				; restore original FLOS IRQ vector
		xor a
		ld (vreg_rasthi),a				; disable scanline IRQ
		
		call kjt_flos_display	
	
		call osca_silence				; silence sound channels
		xor a		
		ei
		ret



dont_start	call kjt_print_string
		xor a
		ret


;------------------------------------------------------------------------------------------------------
		
raster_marker
		ld hl,$f0f					;used only when testing
		ld (palette),hl
		ld b,0
tlp1		djnz tlp1
		ld hl,000
		ld (palette),hl
		ret

		
;-------- These routines contain bank switching code: keep below $8000! -------------------------------

frame_count	db 0
	
		include "flos_based_programs\demos\selectro\inc\interrupts.asm"
		
		include "flos_based_programs\demos\selectro\inc\tune_selector.asm"		

		include "flos_based_programs\demos\selectro\inc\equalizer.asm"

		
;-------- Not important where these routines are located ------------------------------------------------

		include "flos_based_programs\code_library\loading\inc\load_to_video_ram.asm"

		include "flos_based_programs\code_library\memory\inc\unpack_sprites.asm"
		
		include "flos_based_programs\code_library\memory\inc\unpack_to_vram.asm"

		include "flos_based_programs\code_library\memory\inc\copy_to_video_ram_short.asm"

		include "flos_based_programs\code_library\memory\inc\copy_to_sprite_ram_short.asm"
		
		include "flos_based_programs\code_library\memory\inc\fill_video_ram_short.asm"

		include "flos_based_programs\demos\selectro\inc\sine_scroll_1216.asm"
			
		include "flos_based_programs\demos\selectro\inc\starfield.asm"
		
		include "flos_based_programs\demos\selectro\inc\linecop_stuff.asm"

		include "flos_based_programs\code_library\loading\inc\save_restore_dir_vol.asm"

		include "flos_based_programs\code_library\loading\inc\load_save_flat.asm"
		
;--------------------------------------------------------------------------------------------------

retrologo	incbin "flos_based_programs\demos\selectro\data\retrlogo_packed.bin"
end_retrologo	

logo_palette	incbin "flos_based_programs\demos\selectro\data\retrlogo_palette.bin"

selector_gfx	incbin "flos_based_programs\demos\selectro\data\mussel_packed.bin"
end_selector_gfx

;---------------------------------------------------------------------------------------------------------

loading_txt	db "Loading..",11,11,0

;--------------------------------------------------------------------------------------------------
	