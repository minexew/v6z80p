:Draws a line (in software) using hi-res mode put pixel call.

;---Standard header for OSCA and FLOS ----------------------------------------

include "kernal_jump_table.asm"
include "OSCA_hardware_equates.asm"
include "system_equates.asm"

	org $5000

;-------- INIT DISPLAY -----------------------------------------------------------------------
	
	 ld a,0
 	 ld (vreg_rasthi),a  	; select y window reg
	 ld a,$2e
	 ld (vreg_window),a 	; set y window size/position (256 lines)
	 ld a,%00000100
	 ld (vreg_rasthi),a 	; select x window reg
	 ld a,$8c
	 ld (vreg_window),a  	; set x window size/position (320 pixels)
	 ld ix,bitplane0a_loc 	; Set display window address to VRAM: 0
	 ld hl,0     
	 ld a,0 
	 ld (ix),l   
	 ld (ix+1),h  
	 ld (ix+2),a  
	 xor a   
	 ld (bitplane_modulo),a 	; no vram data_fetch modulo is required
				; a=0 -> planar pixel mode
	 ld a,%10000000
	 ld (vreg_vidctrl),a  	; Set bitmap mode (bit 0 = 0) + chunky pixel mode (bit 7 = 1) 
	 ld a,%00001000
	 ld (vreg_ext_vidctrl),a 	; Enable hi-res mode
 

;------------------------------------------------------------------------------------------------------------------

	call kjt_page_in_video
	
	xor a			; clear first 128KB of VRAM
clrv_lp	ld (vreg_vidpage),a
	ld hl,$2000
	ld (hl),0
	ld de,$2001
	ld bc,$1fff
	ldir
	inc a
	cp 16
	jr nz,clrv_lp
	

;------------------------------------------------------------------------------------------------------------------

	ld b,0			; draw a diagonal line with put pixel routine
	ld hl,0			; x coord
	ld de,0			; y coord
lp1	push hl
	push de
	push bc
	ld a,1			; pixel colour. (bits 4:7 are ignored by plot_pixel routine)
	ex af,af'
	call cplotpixel
	pop bc
	pop de
	pop hl
	inc hl
	inc de
	inc b
	jr nz,lp1
	
	call kjt_page_out_video
		
	call kjt_wait_key_press
	ld a,$ff
	ret
	

;-----------------------------------------------------------------------------------------------------------------

; HIRES PUT PIXEL: hl,de,a'    = (x,y) coordinate of pixel, color
	
cplotpixel:
				 
	push hl
	ld h,0
	ld l,e
	xor a
	add hl,hl
	add hl,hl
	add hl,hl
	add hl,hl
	add hl,hl
	add hl,hl 		; y+*64 
	ld d,e 			; ..+y*256
	ld e,0
	add hl,de
	adc a,0			;a = carry
 
	pop de			;divide x coord by 2 as there are two pixels at each byte location
	ld c,0   			;c = left (0), right (1) nybble select
 	srl d
 	rr e
 	rr c
 	add hl,de   		;hl = address in VRAM where pixel is to go [15:0]
 	adc a,0			;a = carry
 	ld b,h  			;convert linear address to 8KB page and offset 0-8191 byte offset
 	sla b
 	rl a
 	sla b
 	rl a
 	sla b
 	rl a
 	ld (vreg_vidpage),a 	 ;select relevant 8KB video page
 	ld a,h  			 ;adjust pixel location to position of VRAM window in Z80 space ($2000-$3FFF)
 	and $1f
 	or $20
 	ld h,a  			 ;adjust 
 
 	ex af,af'			;pixel colour
	bit 7,c
 	jr z,leftnyb
 	
 	and $0f
 	ld c,a			;do right pixel
 	ld a,(hl)
 	and $f0
 	or c
 	ld (hl),a
 	ret
 	
leftnyb 	rrca			;do left pixel
	rrca
	rrca
	rrca
	and $f0
	ld c,a
	ld a,(hl)
	and $0f
	or c			
   	ld (hl),a
 	ret

;-------------------------------------------------------------------------------------------------------------------

colours	dw $000,$fff,$00f,$0f0,$0ff,$f00,$f0f,$ff0
	dw $888,$8ff,$88f,$f8f,$8ff,$f88,$f8f,$ff8