
;  Sets up a 640x512x16 pixel display (163840 bytes)  
;  Fills with individual pixels (using a SLOW put_pixel routine)
;
; ** Hi-Res / Interlace modes work on TV-out only! **


;---Standard header for OSCA and FLOS ----------------------------------------------------------------------------------

include "kernal_jump_table.asm"
include "OSCA_hardware_equates.asm"
include "system_equates.asm"

	org $5000


;-------- Set up hi-res display window----------------------------------------------------------------------------------


start	ld a,0
	ld (vreg_rasthi),a		; select y window reg
	ld a,$2e
	ld (vreg_window),a		; set y window size/position (256 lines)
	ld a,%00000100
	ld (vreg_rasthi),a		; select x window reg
	ld a,$8c
	ld (vreg_window),a		; set x window size/position (320 pixels)

	ld ix,bitplane0a_loc	; Even field pic video address
	ld hl,0					
	ld a,0 
	ld (ix),l			;\ 
	ld (ix+1),h		;- Video fetch start address for odd frame
	ld (ix+2),a		;/
		
	ld ix,bitplane0b_loc	
	ld hl,320		
	ld a,0
	ld (ix),l			;\ 
	ld (ix+1),h		;- Video fetch start address for even frame
	ld (ix+2),a		;/

	ld a,320/2		; divide by 2 as modulo skips *words*
	ld (bitplane_modulo),a	; set modulo to skip alternate lines (so that display in VRAM is continuous)

	ld a,%00001100		; Set hi-res and interlace modes	
	ld (vreg_ext_vidctrl),a	; Note: The LineCop code sets vreg_vidctrl so no there's point setting it here also 


;--------- Copy interlace LineCop instructions to LineCop accessible RAM and start LineCop -------------------------------


linecop_code_loc equ 0
	
	ld a,13			; $70000 (Start of LineCop RAM) = Bank 13
	call kjt_forcebank

	ld hl,my_linecop_code
	ld de,$8000		; upper bank of CPU address space
	ld bc,end_of_my_linecop_code-my_linecop_code
	ldir
		
	ld hl,1			; address in LineCop accessible memory of the LineCop code	
	ld (vreg_linecop_lo),hl	; tell OSCA the location of the LineCop list (bit 0 = enable linecop)

	ld a,0
	call kjt_forcebank


;-------------------------------------------------------------------------------------------------------------------------


	ld hl,colours
	ld de,palette		; Write 16 colours to palette
	ld bc,32
	ldir


;-----------------------------------------------------------------------------------
; Demonstration - fill display pixel by pixel
;-----------------------------------------------------------------------------------


	ld ix,y_offset_list		; precalculate a 512 entry y-offset look-up table
	ld hl,0			; (could use the OSCA maths assist unit instead)
	ld bc,512
	ld de,320/4		; use quarter values so result fits in a 16 bit word
mk_tab	ld (ix),l
	ld (ix+1),h
	inc ix
	inc ix
	add hl,de
	dec bc
	ld a,b
	or c
	jr nz,mk_tab
		

;----------------------------------------------------------------------------------

	ld de,0			;default x coordinate (0-639) 
	ld (x_coord),de		
	ld (y_coord),de		;default y coordinate (0-511)		
	ld a,1
	ld (pixel_colour),a		;default pixel colour


fill_loop	
	
	call hires_put_pixel	;plot the pixel
	
	ld hl,(x_coord)		;x=x+1 (move to next pixel across..)
	inc hl
	ld (x_coord),hl
	ld de,640
	xor a
	sbc hl,de
	jr nz,adv_done

	ld (x_coord),hl
	ld hl,(y_coord)		;y=y+1 (next line down..)
	inc hl
	ld (y_coord),hl
	ld de,512
	xor a
	sbc hl,de
	jr nz,adv_done
	ld (y_coord),hl
	ld a,(pixel_colour)		;change colour when reached bottom of display
	inc a
	ld (pixel_colour),a


adv_done
		
	call kjt_get_key		; check keyboard buffer, get scancode in A
	cp $76			; check scancode and
	jr nz,fill_loop		; loop if ESC key not pressed

quit	ld a,$ff			; restart FLOS on exit
	ret


;----------------------------------------------------------------------------------


hires_put_pixel

; plot a pixel at (x_coord), (y_coord) in colour (pixel_colour)
; For clarity, no attempt has been made to optimize this


	in a,(sys_mem_select)	
	or $40
	out (sys_mem_select),a	; page in video RAM

	ld hl,(y_coord)		
	add hl,hl
	ld de,y_offset_list
	add hl,de			;find location of VRAM y_offset list entry relevant to this line
	ld a,(hl)
	inc hl
	ld h,(hl)
	ld l,a
	xor a
	add hl,hl			;quadruple the offset entry as it contains quarter-values	
	rl a
	add hl,hl
	rl a			
		
	ld de,(x_coord)		;divide x coord by 2 as there are two pixels at each byte location
	ld c,0			;c = left (0), right (1) nybble select
	srl d
	rr e
	rr c
	add hl,de			;hl = address in VRAM where pixel is to go [15:0]
	adc a,0			;a  = address in VRAM where pixel is to go [16]			

	ld b,h			;convert linear address to 8KB page and offset 0-8191 byte offset
	sla b
	rl a
	sla b
	rl a
	sla b
	rl a
	ld (vreg_vidpage),a		;select relevant 8KB video page
	ld a,h			;adjust pixel location to position of VRAM window in Z80 space ($2000-$3FFF)
	and $1f
	or $20
	ld h,a			;adjust 
	
	bit 7,c
	jr nz,repl_right_pixel
	
	ld a,(pixel_colour)
	rrca
	rrca
	rrca
	rrca
	and $f0			;only colours 0-15 can be used
	ld b,a
	ld a,(hl)			;read existing byte
	and $0f			;mask off (protect) the right side pixel
	or b
	ld (hl),a			;write new byte
	jr pixel_done
	
repl_right_pixel
	
	ld a,(pixel_colour)
	and $0f
	ld b,a
	ld a,(hl)			;read existing byte
	and $f0			;mask off (protext) the ledt side pixel
	or b
	ld (hl),a			;write new bytes

pixel_done
	
	in a,(sys_mem_select)	; page in video RAM
	and $bf
	out (sys_mem_select),a
	ret
	

;-----------------------------------------------------------------------------------

x_coord		dw 0
y_coord		dw 0
pixel_colour	db 0

;------------------------------------------------------------------------------------

my_linecop_code	dw $c008		;wait for line 1
		dw $8201		;set register $201 (vreg_vidctrl)
		dw $0080		;write $80 to register (chunky mode using bpl_a pointers)
		dw $820d		;set register $20d (vreg_linecop_lo)
		dw $000d		;write $0d to register (linecop start addr = $c)
		dw $c1ff		;wait for end of frame
				
		dw $c008		;wait for line 1
		dw $8201		;set register $201 (vreg_vidctrl)
		dw $00a0		;write $a0 to register (chunky mode using blp_b pointers)
		dw $820d		;set register $20d (vreg_linecop_lo)
		dw $0001		;write $01 to register (linecop start addr = $0)
		dw $c1ff		;wait for end of frame

end_of_my_linecop_code

;------------------------------------------------------------------------------------

colours	dw $000,$00f,$f00,$f0f,$0f0,$0ff,$ff0,$fff,$008,$800,$808,$080,$088,$880,$888

y_offset_list

	ds 512*2,0
	
