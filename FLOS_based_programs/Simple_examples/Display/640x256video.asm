
;  Sets up a 640x256x16 pixel display (81920 bytes)  
;  Fills with individual pixels (using a SLOW put_pixel routine)
;
; ** Hi-Res Mode Works on TV-out only! **
; (Source tab width=8)

;---Standard header for OSCA and FLOS ----------------------------------------

include "equates\kernal_jump_table.asm"
include "equates\OSCA_hardware_equates.asm"
include "equates\system_equates.asm"


	org $5000


;-------- Set up hi-res display window-----------------------------------------


start	ld a,0
	ld (vreg_rasthi),a		; select y window reg
	ld a,$2e
	ld (vreg_window),a		; set y window size/position (256 lines)
	ld a,%00000100
	ld (vreg_rasthi),a		; select x window reg
	ld a,$8c
	ld (vreg_window),a		; set x window size/position (320 pixels)

	ld ix,bitplane0a_loc		; Set display window address to VRAM: 0
	ld hl,0					
	ld a,0 
	ld (ix),l			
	ld (ix+1),h		
	ld (ix+2),a		

	xor a			
	ld (bitplane_modulo),a		; no vram data_fetch modulo is required


	ld a,%10000000
	ld (vreg_vidctrl),a		; Set bitmap mode (bit 0 = 0) + chunky pixel mode (bit 7 = 1)	

	ld a,%00001000
	ld (vreg_ext_vidctrl),a		; Enable hi-res mode
	

;-------------------------------------------------------------------------------


	ld hl,colours
	ld de,palette			; Write 16 colours to palette
	ld bc,32
	ldir


;-----------------------------------------------------------------------------------
; Demonstration - fill display pixel by pixel
;-----------------------------------------------------------------------------------


	ld ix,y_offset_list		; precalculate a y-offset look-up table
	ld hl,0				; (could use the OSCA maths assist unit instead)
	ld b,0
	ld de,320/2			; use half values so result fits in a 16 bit word
mk_tab	ld (ix),l
	ld (ix+1),h
	inc ix
	inc ix
	add hl,de
	djnz mk_tab
		

;----------------------------------------------------------------------------------

	ld de,0				;default x coordinate (0-639) 
	ld (x_coord),de		
	ld a,0				;default y coordinate (0-255)
	ld (y_coord),a		
	ld a,1
	ld (pixel_colour),a		;default pixel colour


fill_loop	
	
	call hires_put_pixel		;plot the pixel
	
	ld hl,(x_coord)			;x=x+1 (move to next pixel across..)
	inc hl
	ld (x_coord),hl
	ld de,640
	xor a
	sbc hl,de
	jr nz,adv_done
	ld hl,0
	ld (x_coord),hl
	ld a,(y_coord)			;y=y+1 (next line down..)
	inc a
	ld (y_coord),a
	jr nz,adv_done
	ld a,(pixel_colour)		;change colour when reached bottom of display
	inc a
	ld (pixel_colour),a


adv_done
		
	call kjt_get_key		; check keyboard buffer, get scancode in A
	cp $76				; check scancode and
	jr nz,fill_loop			; loop if ESC key not pressed

	ld a,$ff			; restart FLOS on exit
	ret


;----------------------------------------------------------------------------------


hires_put_pixel

; plot a pixel at (x_coord), (y_coord) in colour (pixel_colour)
; For clarity, no attempt has been made to optimize this


	in a,(sys_mem_select)	
	or $40
	out (sys_mem_select),a		; page in video RAM

	ld a,(y_coord)		
	ld l,a
	ld h,0
	add hl,hl
	ld de,y_offset_list
	add hl,de			;find location of VRAM y_offset list entry relevant to this line
	ld a,(hl)
	inc hl
	ld h,(hl)
	ld l,a
	xor a
	add hl,hl			;double the offset entry as it contains half-values	
	adc a,0			
		
	ld de,(x_coord)			;divide x coord by 2 as there are two pixels at each byte location
	ld c,0				;c = left (0), right (1) nybble select
	srl d
	rr e
	rr c
	add hl,de			;hl = address in VRAM where pixel is to go [15:0]
	adc a,0				;a  = address in VRAM where pixel is to go [16]			

	ld b,h				;convert linear address to 8KB page and offset 0-8191 byte offset
	sla b
	rl a
	sla b
	rl a
	sla b
	rl a
	ld (vreg_vidpage),a		;select relevant 8KB video page
	ld a,h				;adjust pixel location to position of VRAM window in Z80 space ($2000-$3FFF)
	and $1f
	or $20
	ld h,a				;adjust 
	
	bit 7,c
	jr nz,repl_right_pixel
	
	ld a,(pixel_colour)
	rrca
	rrca
	rrca
	rrca
	and $f0				;only colours 0-15 can be used
	ld b,a
	ld a,(hl)			;read existing byte
	and $0f				;mask off (protect) the right side pixel
	or b	
	ld (hl),a			;write new byte
	jr pixel_done
	
repl_right_pixel
	
	ld a,(pixel_colour)
	and $0f
	ld b,a
	ld a,(hl)			;read existing byte
	and $f0				;mask off (protext) the ledt side pixel
	or b
	ld (hl),a			;write new bytes

pixel_done
	
	in a,(sys_mem_select)		; page in video RAM
	and $bf
	out (sys_mem_select),a
	ret
	

;-----------------------------------------------------------------------------------

x_coord		dw 0
y_coord		db 0
pixel_colour	db 0

;------------------------------------------------------------------------------------

colours	dw $000,$00f,$f00,$f0f,$0f0,$0ff,$ff0,$fff,$008,$800,$808,$080,$088,$880,$888

y_offset_list

	ds 512,0
	
	