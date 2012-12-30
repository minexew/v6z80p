
; Tests linecop - wait for same line twice in succession

;---Standard header for OSCA and FLOS  -----------------------------------------------------------------------

include "equates\kernal_jump_table.asm"
include "equates\OSCA_hardware_equates.asm"
include "equates\system_equates.asm"

	org $5000

;--------------------------------------------------------------------------------------------------------------

		ld a,0				; linecop program is at A:HL
		ld hl,linecop_prog
		set 0,l				; enable line cop (bit 0 of vreg_linecop_lo)
		ld (linecop_addr0),hl		; set h/w location of line cop list
		or $80				; bit 7 must be set when writing to linecop_addr2
		ld (linecop_addr2),a
		xor a				; and quit
		ret
	
;----------------------------------------------------------------------------------------------------------------------------------------------------

; Linecop mnemonics and their opcodes..

lc_wr        equ $0000		; Write Register
lc_wril      equ $2000		; Write Register & Inc Line (then wait)
lc_wrir      equ $4000		; Write Register & Inc Reg
lc_wrilir    equ $6000		; Write Register & Inc Reg & Inc Line (then wait)
lc_sr        equ $8000		; Select Register
lc_wl	     equ $c000		; Wait Line

;------------------------------------------------------------------------------------------------------------------------------------------------------

		org $6000		;line cop programs must start on even address

linecop_prog	dw lc_sr+$000
		dw lc_wr+$00		;border = black
		
		dw lc_wl+$080		;wait for line 
				
		dw lc_wl+$080		;wait for same line 

		dw lc_wr,$0f
			
		dw lc_wl+$1ff		;wait for line $1ff (end of list)
		

;---------------------------------------------------------------------------------------------------------
