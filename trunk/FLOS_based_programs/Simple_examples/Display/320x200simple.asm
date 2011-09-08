
; Ultra simple OSCA video demonstration: Sets up a 320x200 pixel, single bitplane
; display window in linear bitmap mode. Writes a byte to it each frame to successive
; locations.

;---Standard header for OSCA and FLOS ----------------------------------------

include "kernal_jump_table.asm"
include "OSCA_hardware_equates.asm"
include "system_equates.asm"

	org $5000

;-------- Set up display window------------------------------------------------

start	ld a,0
	ld (vreg_rasthi),a		; select y window reg
	ld a,$5a
	ld (vreg_window),a		; set y window size/position (200 lines)
	ld a,%00000100
	ld (vreg_rasthi),a		; select x window reg
	ld a,$8c
	ld (vreg_window),a		; set x window size/position (320 pixels)
	
	ld a,0
	ld (vreg_yhws_bplcount),a	; set 1 bitplane display
		
	ld a,0
	ld (vreg_vidctrl),a		; set bitmap mode + normal border + video enabled

	ld a,0
	ld (vreg_vidpage),a		; read / writes to VRAM page 0

	ld hl,0
	ld (bitplane0a_loc),hl	; start address of video datafetch for window [15:0]
	ld a,0
	ld (bitplane0a_loc+2),a	; start address of video datafetch for window [18:16]

	
;---------Set up palette -----------------------------------------------------


	ld hl,palette		; background = black, colour 1 = white
	ld (hl),0
	inc hl
	ld (hl),0
	inc hl
	ld (hl),$ff
	inc hl
	ld (hl),$0f


;--------- Write a byte to VRAM and advance location each frame --------------------


v_loop	call kjt_wait_vrt		; wait for last line of display
	
	call kjt_page_in_video	; page video RAM in at $2000-$3fff
	
	ld hl,video_base		; HL = $2000
	ld de,(offset)		
	add hl,de			; add on offset
	ld (hl),$ff		; write 255 to a location in video RAM
	inc de
	ld a,d			; advance offset and keep it within $0-$1fff
	and $1f
	ld d,a
	ld (offset),de
	
	call kjt_page_out_video	; page video RAM out of $2000-$3fff
	
	call kjt_get_key		; check keyboard buffer, get scancode in A
	cp $76			; check scancode and
	jr nz,v_loop		; loop if ESC key not pressed

;-------------------------------------------------------------------------------

	call kjt_flos_display	; restore video registers to FLOS display
	xor a			; quit to OS
	ret

;-----------------------------------------------------------------------------------

offset 	dw 0

;------------------------------------------------------------------------------------
