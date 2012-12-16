; ----------------------------------------------------------------------------------
; Simple routine to fill video RAM (up to 65536 bytes)
;
; Limitations:
; ------------
;
; * Can only write 65536 bytes
; * Not fast at all! Does not use blitter or even optimal Z80 code.
; 
; Usage:
; ------
; Set:
;
; A:DE = Flat dest address in video RAM 0-$7ffff
; BC = Number of bytes to copy (note: 0 = 65536 bytes)
; L  = Byte with which to fill video RAM
;
; Call: "clear_vram" to write all zeroes
;       "fill_vram" to write contents of L
;----------------------------------------------------------------------------------

clear_vram	ld l,0

fill_vram	ld a,l
		ld hl,fvr_fill_byte
		ld (hl),a
		
		push de
		sla d
		rla
		sla d
		rla
		sla d
		rla
		pop de
		
		ld ix,fvr_vram_page
		ld (ix),a
		
		call kjt_page_in_video		
		
fvr_fvrb	ld a,d
		and %00011111
		or  %00100000
		ld d,a
		ld a,(ix)
		ld (vreg_vidpage),a
		
fvr_fvrlp	ldi					;16
		dec hl					;6
		jp po,fvr_end				;10
		bit 6,d					;8
		jp z,fvr_fvrlp				;10
		inc (ix)				;23
		jp fvr_fvrb				;10
		
fvr_end		call kjt_page_out_video
		ret

fvr_fill_byte	db 0

fvr_vram_page	db 0

;----------------------------------------------------------------------------------
	