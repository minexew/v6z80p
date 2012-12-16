; ----------------------------------------------------------------------------------
; Simple routine to copy from system RAM to video RAM
;
; Limitations:
; ------------
;
; * Source data must fit in continuous Z80 addresses, routine does not handle page swaps for source
; * Could be faster
; 
; Usage:
; ------
; Set:
; HL = Z80 system RAM source address (0-$ffff)
; A:DE = Flat dest address in video RAM 0-$7ffff
; BC = Number of bytes to copy (1-$ffff)
;----------------------------------------------------------------------------------

copy_to_vram	push de
		sla d
		rla
		sla d
		rla
		sla d
		rla
		pop de
		
		ld ix,ctvr_vram_page
		ld (ix),a
		
		call kjt_page_in_video
		
ctvr_utrvb	ld a,d
		and %00011111
		or  %00100000
		ld d,a
		ld a,(ix)
		ld (vreg_vidpage),a
ctvr_utrlp	ldi
		jp po,ctvr_uplrend
		bit 6,d
		jp z,ctvr_utrlp
		inc (ix)
		jr ctvr_utrvb
		
ctvr_uplrend	call kjt_page_out_video
		ret

ctvr_vram_page	db 0
	
;----------------------------------------------------------------------------------
	