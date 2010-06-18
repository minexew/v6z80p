
; Tests: Joystick ports

;---Standard header for OSCA and FLOS ----------------------------------------

include "kernal_jump_table.asm"
include "OSCA_hardware_equates.asm"
include "system_equates.asm"

	org $5000	

;-----------------------------------------------------------------------------------------

; Initialize video hardware

	ld a,0
	ld (vreg_rasthi),a		; select y window reg
	ld a,$5a
	ld (vreg_window),a		; set y window size/position (200 lines)
	ld a,%00000100
	ld (vreg_rasthi),a		; select x window reg
	ld a,$8c
	ld (vreg_window),a		; set x window size/position (320 pixels)
	
	ld a,%01000000
	out (sys_mem_select),a	; page in video ram
	
	ld e,0
	ld a,e
clrabp	ld (vreg_vidpage),a

	ld hl,video_base		; clear all bitplanes
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
	
	ld a,0
	ld (vreg_vidctrl),a		;bitmap mode + normal border + video enabled
	ld a,0
	ld (vreg_xhws),a		;x scroll position = 0

	ld a,7
	ld (vreg_yhws_bplcount),a

	ld ix,bitplane0a_loc	;initialize bitplane pointers.
	ld hl,$0			;first bitplane address (15:0)
	ld c,$0			;first bitplane address msb
	ld de,$2000		;size of bitplane
	ld b,16			;number of registers to do
ibpl_lp	ld (ix),l
	ld (ix+1),h
	ld (ix+2),c
	inc ix
	inc ix
	inc ix
	inc ix
	add hl,de
	jr nc,nobplcr
	set 0,c
nobplcr	djnz ibpl_lp

		
;---------------------------------------------------------------------------------------

; Draw 128x128x8 pic

	ld a,0		
	ld (vid_buffer),a		;software blit writes to bm buffer 0

	ld de,video_base+12+(32*40)	;de = destination address
	ld hl,test_gfx		;source address of graphic
	ld bc,$8010		;b = height / c = width in bytes
	ld a,40-16		;a = destination modulo
	call sw_blit


;-----------------------------------------------------------------------------------------

	ld hl,test_pal		;write palette
	ld de,palette
	ld b,0
pwloop	ld c,(hl)
	inc hl
	ld a,(hl)
	inc hl
	ld (de),a
	inc de
	ld a,c
	ld (de),a
	inc de
	djnz pwloop
		
	ld a,%00000000
	out (sys_mem_select),a	;page out video ram

;--------------------------------------------------------------------------------------------

	di	
	ld hl,my_irq_handler	; set IRQ vector for custom keyboard code 
          ld (irq_vector),hl	  
	ld a,%00000001
	out (sys_clear_irq_flags),a	; clear keyboard irq flag 
	ld a,%10000001		
          out (sys_irq_enable),a	; enable keyboard interrupts
	xor a
	ld (key_directions),a
	ld (esc_keytime),a
	ei
	
;--------------------------------------------------------------------------------------------

wvrtstart	ld a,(vreg_read)		;wait for Vertical Retrace
	and 1
	jr z,wvrtstart
wvrtend	ld a,(vreg_read)
	and 1
	jr nz,wvrtend
	
	ld hl,counter
	inc (hl)
	
	call do_stuff

	ld a,(esc_keytime)
	or a
	jr z,wvrtstart		; loop if SPACE key not pressed
	
	ld a,$ff			; quit
	or a
	ret

	
;-----------------------------------------------------------------------------------------
		
		
do_stuff


	ld hl,palette+(240*2)
	ld b,16
pgrey	ld (hl),$88
	inc hl
	ld (hl),$08
	inc hl
	djnz pgrey
	
	ld hl,palette+(240*2)
	
	ld a,(key_directions)		;read direction bits
	ld b,a
	and %0011
	cp  %0011				;are up and down pressed together?
	jr nz,gotkbv
	bit 7,b				;if so, mask off to give the most recent key press
	jr z,priup
	ld a,b
	and %11100
	or  %00010
	ld b,a
	jr gotkbv
priup	ld a,b
	and %11100
	or  %00001
	ld b,a
gotkbv	ld a,b
	and %1100
	cp  %1100				;are left and right pressed together?
	jr nz,gotkbh
	bit 6,b				;if so, mask off to give the most recent key press
	jr z,prileft
	ld a,b
	and %10011
	or  %01000
	ld b,a
	jr gotkbh
prileft	ld a,b
	and %10011
	or  %00100
	ld b,a
gotkbh

	bit 0,b
	jr z,not_a0
	ld (hl),$0f00

not_a0	inc hl
	inc hl
	bit 1,b
	jr z,not_a1
	ld (hl),$0f00

not_a1	inc hl
	inc hl
	bit 2,b
	jr z,not_a2
	ld (hl),$0f00

not_a2	inc hl
	inc hl
	bit 3,b
	jr z,not_a3
	ld (hl),$0f00

not_a3	inc hl
	inc hl
	bit 4,b
	jr z,not_a4
	ld (hl),$0f00

not_a4	
	ret

	


;-----------------------------------------------------------------------------------------


		
sw_blit	ld ix,blit_vars
	ld (ix),a			;modulo
	ld (ix+1),b		;height
	ld (ix+4),b		;height backup
	ld (ix+2),c		;width
	ld (ix+3),0		;bitplane number
blit_lp2	push de
	ld a,(vid_buffer)
	sla a
	sla a
	sla a
	or (ix+3)
	ld (vreg_vidpage),a
blit_lp1	ld b,0
	ldir
	ld a,(ix)
	add a,e			;add line modulo
	jr nc,nocrmod
	inc d
nocrmod	ld e,a
	ld c,(ix+2)
	dec (ix+1)
	jr nz,blit_lp1
	pop de
	ld a,(ix+4)		;restore height counter
	ld (ix+1),a
	inc (ix+3)		;next bitplane
	ld a,(ix+3)
	cp 8
	jr nz,blit_lp2
	ret
		

;----------------------------------------------------------------------------------------
; Keyboard IRQ routine - highly unoptimized!
;----------------------------------------------------------------------------------------

up_scancode	equ $15
down_scancode	equ $1c
left_scancode	equ $44
right_scancode	equ $4d
fire_scancode	equ $14

; key_directions bits: 0 = up, 1 = down, 2 = left, 3 = right, 4 = fire, 6 = most recent horiz, 7 = most recent vert


my_irq_handler

	push af			; Maskable IRQ jumps here
	in a,(sys_irq_ps2_flags)	; Read irq status flags
	bit 0,a			; keyboard irq set?
	call nz,keyboard_irq_code	; call keyboard irq routine if so
	pop af			
	ei			; re-enable interrupts
	reti			; return to main code
	

keyboard_irq_code

	push af			; treats keyboard as joystick, IE: direction persist until key released
	push hl			
	
	ld hl,key_directions
	in a,(sys_keyboard_data)	; get the keycode
	cp $f0
	jr nz,not_rel		; is it a "key released" prefhl byte
	ld a,1
	ld (key_release),a		; if so, set a flag and take no further action
	jp key_done
	
not_rel	cp up_scancode		; up scancode received?
	jr nz,knotup
	ld a,(key_release)		; was $f0 received previously (key released)?
	or a
	jr z,press_u
	xor a			; this is a key release
	ld (key_release),a
	res 0,(hl)
	jp key_done
press_u	set 0,(hl)		; set up on
	res 7,(hl)		; most recently up
	jp key_done
	
knotup	cp down_scancode
	jr nz,knotdown
	ld a,(key_release)		
	or a
	jr z,press_d
	xor a
	ld (key_release),a
	res 1,(hl)
	jp key_done
press_d	set 1,(hl)
	set 7,(hl)		; most recently down
	jp key_done
	
knotdown	cp left_scancode		; up scancode received?
	jr nz,knotleft
	ld a,(key_release)		; was $f0 received previously (key released)?
	or a
	jr z,press_l
	xor a			; this is a key release
	ld (key_release),a
	res 2,(hl)
	jp key_done
press_l	set 2,(hl)		; set left on
	res 6,(hl)		; most recently left
	jp key_done
	
knotleft	cp right_scancode
	jr nz,knotright
	ld a,(key_release)		
	or a
	jr z,press_r
	xor a
	ld (key_release),a
	res 3,(hl)
	jp key_done
press_r	set 3,(hl)		;set right on
	set 6,(hl)		;most recently right
	jp key_done


knotright	cp fire_scancode
	jr nz,knotfire
	ld a,(key_release)		
	or a
	jr z,press_fir
	xor a
	ld (key_release),a
	res 4,(hl)
	jr key_done
press_fir	set 4,(hl)
	jr key_done


knotfire	cp $76			;ESC key code
	jr nz,key_notesc
	ld a,(key_release)		
	or a
	jr z,press_esc
	xor a
	ld (key_release),a
	ld (esc_keytime),a
	jr key_done
press_esc	ld a,1
	ld (esc_keytime),a
	jr key_done

key_notesc

	xor a
	ld (key_release),a		; for any other key

key_done	ld a,%00000001
	out (sys_clear_irq_flags),a	; clear keyboard interrupt flag
	pop hl
	pop af
	ret

;-------------------------------------------------------------------------------------------


blit_vars		db 0,0,0,0,0,0

vid_buffer	db 0

counter 		db 0

showbuffer 	db 0

;-------------------------------------------------------------------------------------------

test_gfx incbin "joystick_bitplanes.bin"
test_pal incbin "joystick_12bit_palette.bin"

;-------------------------------------------------------------------------------------

key_directions		db 0
esc_keytime		db 0
key_release		db 0
