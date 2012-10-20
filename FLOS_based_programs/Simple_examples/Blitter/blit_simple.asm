
; Basic blit example - copies a rectangular image to the display (moved along
; one pixel every frame)

;---Standard header for OSCA and FLOS --------------------------------------------------------

include "equates\kernal_jump_table.asm"
include "equates\OSCA_hardware_equates.asm"
include "equates\system_equates.asm"

	org $5000
	
;-------- Initialize video --------------------------------------------------------------------


display_width equ 256


		ld a,%00000000			; select y window pos register
		ld (vreg_rasthi),a		; 
		ld a,$5a			; set 200 line display
		ld (vreg_window),a
		ld a,%00000100			; switch to x window pos register
		ld (vreg_rasthi),a			
		ld a,$bb
		ld (vreg_window),a		; set 256 pixels wide window

		ld hl,colours
		ld de,palette			; upload spectrum palette
		ld bc,512
		ldir
		
		ld ix,bitplane0a_loc	 
		ld hl,0				; Set video window start address		
		ld a,0 
set_vaddr	ld (ix),l			;\ 
		ld (ix+1),h			;- Video fetch start address for this frame
		ld (ix+2),a			;/
			
		ld a,%10000000
		ld (vreg_vidctrl),a		; Set bitmap mode (bit 0 = 0) + chunky pixel mode (bit 7 = 1)	

;---------------------------------------------------------------------------------------------------

		call kjt_page_in_video
		
		ld e,0				; clear 16 x 8KB video pages
		ld a,e	
clrabp		ld (vreg_vidpage),a
		ld hl,video_base		
		ld bc,$2000
flp		ld (hl),0
		inc hl
		dec bc
		ld a,b
		or c
		jr nz,flp
		inc e
		ld a,e
		cp 16
		jr nz,clrabp

		ld a,8				;put my object at VRAM $010000
		ld (vreg_vidpage),a
		ld hl,object
		ld de,video_base
		ld bc,colours-object
		ldir
		
		call kjt_page_out_video
		

;----------------------------------------------------------------------------------------------------


main_loop	call kjt_wait_vrt

		call do_blit

		in a,(sys_keyboard_data)
		cp $76
		jr nz,main_loop			;loop if ESC key not pressed
	
		xor a
		ld a,$ff			;quit (restart OS)
		ret


;-------------------------------------------------------------------------------------------
; Use blitter to put object on screen
;-------------------------------------------------------------------------------------------

obj_width 		equ 32
obj_height		equ 28

source_modulo 		equ 0
destination_modulo	equ display_width-obj_width

do_blit

		ld a,$01
		ld hl,$0000			;source object is at VRAM $010000
		ld (blit_src_loc),hl		;set source address
		ld (blit_src_msb),a		;set source address msb
		
		ld a,source_modulo 	
		ld (blit_src_mod),a		;set source modulo

		ld a,$00
		ld hl,(destaddr)		;destination for object is VRAM $000000-$00ffff
		ld (blit_dst_loc),hl		;(moves along one pixel each frame)
		ld (blit_dst_msb),a
		
		ld a,destination_modulo
		ld (blit_dst_mod),a		;set destination video
		
		ld a,%01000000			;set blitter to ascending mode (modulo 
		ld (blit_misc),a		;high bits set to zero, transparency: off)

		ld a,obj_height-1
		ld (blit_height),a		;set height of blit object (in lines)
		ld a,obj_width-1
		ld (blit_width),a		;set width of blit object (in bytes) and start blit
		
		nop				;waste a few cycles to ensure blit has begun
		nop				;before testing busy flag
waitblit	in a,(sys_vreg_read)		
		bit 4,a 			;busy wait for blit to complete
		jr nz,waitblit

		ld hl,(destaddr)		;increase the blit destination address ready
		inc hl				;for next frame
		ld (destaddr),hl
		ret

;-------------------------------------------------------------------------------------------

object		incbin "flos_based_programs\simple_examples\blitter\data\object_32x28.bin"

colours		incbin "flos_based_programs\simple_examples\blitter\data\object_palette.bin"

destaddr	dw 0

;--------------------------------------------------------------------------------------------