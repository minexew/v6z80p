; ----------------------------------------------------------------------------------
; Simple routine to copy from system RAM to sprite RAM
;
; Limitations:
; ------------
;
; * Source data must fit in continuous Z80 addresses: Routine does not handle page swaps for source
; * Could be faster
; 
; Usage:
; ------
; Set:
; HL = Z80 system RAM source address (0-$ffff)
; A:DE = Flat dest address in video RAM 0-$1ffff
; BC = Number of bytes to copy (1-$ffff)
;----------------------------------------------------------------------------------

copy_to_sprite_ram

		push de
		sla d
		rla
		sla d
		rla
		sla d
		rla
		sla d
		rla
		pop de
		
		ld ix,ctsr_sprite_page
		ld (ix),a
		
		in a,(sys_mem_select)				;page in sprite RAM
		or $80
		out (sys_mem_select),a
	
ctsr_utsrvb	ld a,d
		and %00001111
		or  %00010000
		ld d,a
		ld a,(ix)
		or $80
		ld (vreg_vidpage),a
ctsr_utsrlp	ldi
		jp po,ctsr_uplsrend
		bit 5,d
		jp z,ctsr_utsrlp
		inc (ix)
		jr ctsr_utsrvb
	
ctsr_uplsrend	in a,(sys_mem_select)				;page out sprite RAM
		and $7f
		out (sys_mem_select),a
		ret

ctsr_sprite_page

		db 0	
	
	
;----------------------------------------------------------------------------------
	