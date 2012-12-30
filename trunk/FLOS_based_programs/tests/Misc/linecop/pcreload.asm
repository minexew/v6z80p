
; Tests linecop - reloads it's own PC, should alternate between 2 lists on alternate frames

;---Standard header for OSCA and FLOS  -----------------------------------------------------------------------

include "equates\kernal_jump_table.asm"
include "equates\OSCA_hardware_equates.asm"
include "equates\system_equates.asm"

	org $5000

;--------------------------------------------------------------------------------------------------------------

		ld a,0				; linecop program is at A:HL
		ld hl,linecop_prog1
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

		org $6000				;line cop programs must start on even address

linecop_prog1	dw lc_sr+palette
		
		dw lc_wl+$080
		dw lc_wr+$00				;border = black
			
		dw lc_wl+$084				;wait for line 
		dw lc_wr,$0f				;border = blue
		
		dw lc_wl+$088				;wait for line
		dw lc_wr,$00				;border = black
	
		dw lc_sr+linecop_addr0			;select linecop location register
		dw lc_wrir+(linecop_prog2&$ff)+1	;bit 0 must be set (linecop enable)
		dw lc_wrir+(linecop_prog2>>8)
		dw lc_wrir+0+$80			;bit 7 must be set
	
		dw lc_wl+$1ff				;wait for line $1ff (end of list)


			
linecop_prog2	dw lc_sr+palette
		
		dw lc_wl+$0a0
		dw lc_wr+$00				;border = black
		
		dw lc_wl+$0a4				;wait for line 
		dw lc_wr,$f0				;border = green
		
		dw lc_wl+$0a8				;wait for line
		dw lc_wr,$00				;border = black
	
		dw lc_sr+linecop_addr0			;select linecop location register
		dw lc_wrir+(linecop_prog1&$ff)+1	;bit 0 must be set (linecop enable)
		dw lc_wrir+(linecop_prog1>>8)
		dw lc_wrir+0+$80			;bit 7 must be set
	
		dw lc_wl+$1ff				;wait for line $1ff (end of list)
			
;---------------------------------------------------------------------------------------------------------
