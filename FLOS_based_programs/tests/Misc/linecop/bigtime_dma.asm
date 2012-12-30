
; Tests linecop - major DMA use on one line

;---Standard header for OSCA and FLOS  -----------------------------------------------------------------------

include "equates\kernal_jump_table.asm"
include "equates\OSCA_hardware_equates.asm"
include "equates\system_equates.asm"

	org $5000

;--------------------------------------------------------------------------------------------------------------

	ld de,linecop_prog
	set 0,e				; enable line cop (bit 0 of vreg_linecop_lo)
	ld (vreg_linecop_lo),de		; set h/w location of line cop list

	XOR A
	RET
	
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

linecop_prog	dw lc_wl+$080		;wait for line 
		dw lc_sr+$000		;set register 0
		
	REPT 1000
		
		dw lc_sr+$000		;set register 0
		
	ENDM
		
			
		dw $c1ff		;wait for line $1ff (end of list)
		

;---------------------------------------------------------------------------------------------------------
