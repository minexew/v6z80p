; Ultra simple "paint object to display with mouse buttons" test program.


;---Standard source header for OSCA and FLOS ------------------------------------------

include "kernal_jump_table.asm"	; essential equates
include "OSCA_hardware_equates.asm"	; ""	""
include "system_equates.asm"		; ""	""

	org $5000

;----------------------------------------------------------------------------------------------

	call kjt_get_mouse_position		; Has mouse driver been enabled?
	jp nz,error
	
	
;-------- Initialize video --------------------------------------------------------------------

display_width equ 256


	ld a,%00000000			; select y window pos register
	ld (vreg_rasthi),a		 
	ld a,$2e				; set 256 line display
	ld (vreg_window),a
	ld a,%00000100			; switch to x window pos register
	ld (vreg_rasthi),a		
	ld a,$bb
	ld (vreg_window),a			; set 256 pixels wide window

	ld ix,bitplane0a_loc	 
	ld hl,0				; Set video window start address		
	ld a,0 
set_vaddr	ld (ix),l				;\ 
	ld (ix+1),h			;- Video fetch start address for this frame
	ld (ix+2),a			;/
		
	ld a,%10000000
	ld (vreg_vidctrl),a			; Set bitmap mode (bit 0 = 0) + chunky pixel mode (bit 7 = 1)	


;--------- Set up source image ------------------------------------------------------------------

	call kjt_page_in_video
	
	ld e,0				; clear 16 x 8KB video pages
	ld a,e	
clrabp	ld (vreg_vidpage),a
	ld hl,video_base		
	ld bc,$2000
flp	ld (hl),0
	inc hl
	dec bc
	ld a,b
	or c
	jr nz,flp
	inc e
	ld a,e
	cp 16
	jr nz,clrabp

	ld a,9				;put painting object at VRAM $012000
	ld (vreg_vidpage),a
	ld hl,object
	ld de,video_base
	ld bc,colours-object
	ldir
	
	ld hl,colours			;set up colour palette
	ld de,palette
	ld bc,256*2
	ldir
		
	call kjt_page_out_video
	
;--------- Set up sprite pointer -----------------------------------------------------------------
	
	ld a,%10000000			; copy sprite pointer to last definition block
	out (sys_mem_select),a		; of sprite ram
	ld a,%10011111
	ld (vreg_vidpage),a		
	ld hl,spr_def
	ld de,$1f00
	ld bc,$100
	ldir
	xor a
	out (sys_mem_select),a

	ld hl,spr_colours			;copy sprite pointer colours to palette
	ld de,palette+(248*2)
	ld bc,8*2
	ldir

	ld a,%00000001
	ld (vreg_sprctrl),a			;enable sprites

	ld hl,$ff
	ld de,$ff
	call kjt_enable_mouse		;set window size for mouse


;---------- Main loop: Do operations required each frame ------------------------------------

loop1	call kjt_wait_vrt			;wait for a new frame

	call update_pointer
	call draw_shape
	
	call kjt_get_key			;quit?
	or a
	jr z,loop1
	xor a
	ld a,$ff				;restart OS
	ret

error	ld hl,error_txt
	call kjt_print_string
	xor a
	ret


;---------------------------------------------------------------------------------------
; Mouse the pointer sprite
;---------------------------------------------------------------------------------------

update_pointer

	call kjt_get_mouse_position		;get mouse location (absolute)
	
	ld (pointer_x),hl			;update sprite register
	ld (pointer_y),de
	ld (mouse_buttons),a	
	push de
	ld de,$af				;add x offset for video window
	add hl,de
	ld ix,spr_registers
	ld (ix),l				;x coord low
	ld b,h
	pop de
	ex de,hl
	ld de,$11				;add y offset for video window
	add hl,de
	ld (ix+2),l			;y coord low
	sla h	
	ld a,$14
	or b
	or h
	ld (ix+1),a
	ld (ix+3),$ff
	ret
	

;-------------------------------------------------------------------------------------------
; Use blitter to put object on screen
;-------------------------------------------------------------------------------------------

obj_width 	equ 16
obj_height	equ 16
source_modulo 	equ 0
destination_modulo	equ display_width-obj_width

draw_shape

	ld a,(mouse_buttons)		;only draw if left/right mouse button is pressed
	and 3
	ret z
	cp 3				;if both are pressed dont draw either
	ret z
	
	dec a				;choose object at $12000 for left mouse
	add a,$20				;and object at $12100 for right mouse
	ld h,a				
	ld l,0	
	ld a,$01				;source object is at VRAM $012000 / $12100
	ld (blit_src_loc),hl		;set source address
	ld (blit_src_msb),a			;set source address msb
	
	ld a,source_modulo 	
	ld (blit_src_mod),a			;set source modulo

	ld a,(pointer_y)			;destination for object is VRAM $000000-$00ffff
	ld h,a
	ld a,(pointer_x)
	ld l,a
	xor a
	ld (blit_dst_loc),hl		;set dest address
	ld (blit_dst_msb),a			;set dest address msb
	
	ld a,destination_modulo
	ld (blit_dst_mod),a			;set destination video
	
	ld a,%11000000			;set blitter to ascending mode (modulo 
	ld (blit_misc),a			;high bits set to zero, transparency: on)

	ld a,obj_height-1
	ld (blit_height),a			;set height of blit object (in lines)
	ld a,obj_width-1
	ld (blit_width),a			;set width of blit object (in bytes) and start blit
	
	nop				;waste a few cycles to ensure blit has begun
	nop				;before testing busy flag
waitblit	in a,(sys_vreg_read)		
	bit 4,a 				;busy wait for blit to complete
	jr nz,waitblit
	ret
	

;--------------------------------------------------------------------------------------

error_txt	db "Mouse driver not installed.",11,11,0

;--------------------------------------------------------------------------------------

spr_colours	incbin "pointer_palette.bin"

spr_def		incbin "pointer_sprite.bin"

object		incbin "objects_chunky.bin"

colours		incbin "objects_palette.bin"

mouse_buttons	db 0

pointer_x		dw 0

pointer_y		dw 0

;------------------------------------------------------------------------------------------------
	