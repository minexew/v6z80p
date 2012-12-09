
;---------------------------------------------------------------------------------------------------
; "flat_mem_copy"
;
; Copies data within system memory with flat, linear source/dest addresses using LDIRs
;
; IMPORTANT:
; ----------
; Routine must be placed in unpaged memory
; Ensure no interrupt code is in paged memory (or disable the irqs)
; Ensure stack is in unpaged memory
; Routine does NOT check for overflow from $7FFFF or zero-length copy
;
; Set B:HL = source address
; Set C:DE = dest address
; Set A:IX = number of bytes to copy
;
; Trashes all registers except  A' BC' DE' HL' IY
;
;---------------------------------------------------------------------------------------------------

flat_mem_copy	ld (fmc_bytes_remaining),ix
		ld (fmc_bytes_remaining+2),a
		or a
		jr z,fmc_not64k1
		ld ix,$8000			;if number of bytes >= 64KB, do 32KB max in first pass
fmc_not64k1	ld (fmc_bytes_to_copy),ix		
				
		in a,(sys_mem_select)		
		ld (fmc_orig_rd_page),a
		in a,(sys_alt_write_page)
		ld (fmc_orig_wr_page),a
	
		ld a,h				;convert flat address to banked for reads
		rla				
		rl b				;b = upper page selection for reads
		in a,(sys_mem_select)
		and %11110000
		or  %00010000			;enable "alt_write_page" mode
		or b
		out (sys_mem_select),a		
		set 7,h				;using "any page mode" - all sysram locations paged into Z80 $8000-$ffff
		
		ld a,d				;convert flat address to banked for writes
		rla				
		rl c				;c = upper page selection for writes
		in a,(sys_alt_write_page)
		and %11110000
		or  %00100000			;enable any_page_mode (allow first 32KB of SYSRAM to appear at Z80: $8000)
		or c
		out (sys_alt_write_page),a	
		set 7,d				;using "any page mode" - all sysram locations paged into Z80 $8000-$ffff
	
fmc_loop	push hl			;will the transfer be broken by source page wrap?
		ld bc,(fmc_bytes_to_copy)
		dec bc
		add hl,bc
		call c,fmc_mem_wrap
		pop hl
		
		push de			;will the transfer be broken by dest page wrap?
		push hl
		ex de,hl
		ld bc,(fmc_bytes_to_copy)
		dec bc
		add hl,bc
		call c,fmc_mem_wrap
		pop hl
		pop de
		
		ld bc,(fmc_bytes_to_copy)	;do as many bytes as we can before a page needs to be changed
		ldir				;(will never be more than 32KB)
		
		push hl			;subtract transferred bytes from remaining bytes
		push de
		ld hl,(fmc_bytes_remaining)
		ld a,(fmc_bytes_remaining+2)
		ld bc,(fmc_bytes_to_copy)
		or a
		sbc hl,bc
		sbc a,0
		ld (fmc_bytes_remaining),hl
		ld (fmc_bytes_remaining+2),a
		ld d,a
		or h
		or l
		jr nz,fmc_more			;have all bytes been transferred?	
		
		pop de				;all done
		pop hl
		ld (fmc_orig_rd_page),a		;restore original bank settings
		out (sys_mem_select),a		
		ld (fmc_orig_wr_page),a
		out (sys_alt_write_page),a
		ret
			
fmc_more	ld a,d
		or a
		jr z,fmc_not64k2		;if bytes remaining >= 64KB, set next "bytes to copy" = 32KB
		ld hl,$8000	
fmc_not64k2	ld (fmc_bytes_to_copy),hl
		pop de
		pop hl
					
		ld a,h				;has the source address wrapped?
		or l
		jr nz,fmc_nincsb
		in a,(sys_mem_select)
		inc a
		out (sys_mem_select),a
		ld h,$80
		
fmc_nincsb	ld a,d				;has the dest address wrapped?
		or e
		jr nz,fmc_nincdb
		in a,(sys_alt_write_page)
		inc a
		out (sys_alt_write_page),a
		ld d,$80

fmc_nincdb	jr fmc_loop


fmc_mem_wrap	ld b,h				;reduce bytes_to_copy by the amount that will cause a page wrap
		ld c,l
		ld hl,(fmc_bytes_to_copy)
		sbc hl,bc			;carry flag is already set (want to subtract overflow+1)
		ld (fmc_bytes_to_copy),hl
		ret
		

fmc_bytes_to_copy	dw 0
fmc_bytes_remaining	db 0,0,0

fmc_orig_rd_page	db 0
fmc_orig_wr_page	db 0

;---------------------------------------------------------------------------------------------------
	
	