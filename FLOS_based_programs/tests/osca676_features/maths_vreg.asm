;-------------------------------------------------------------------------------------------
; tests maths unit access through vreg addresses
;-------------------------------------------------------------------------------------------

;---Standard header for OSCA and FLOS  ------------------------------------------------------

include "equates\kernal_jump_table.asm"
include "equates\OSCA_hardware_equates.asm"
include "equates\system_equates.asm"

;--------------------------------------------------------------------------------------------

		org $5000	
		

		ld hl,mult_table			;fill mult table with some words ($2500 to $24ff
		ld de,$2500				;note: LSB and MSB inc each word)
		ld b,0
lp1		ld (hl),e
		inc hl
		ld (hl),d
		inc hl
		inc e
		inc d
		djnz lp1
		
		
		ld hl,$4000				;set mult_write to 16384 (no scaling)
		ld (mult_write),hl
			
		
		ld hl,$8000				;read data from mult_read and place at $8000-$81ff
		ld b,0					;should be same data as written to mult table
		ld c,0
lp2		ld a,c
		ld (mult_index),a			;set index
		
		ld a,(mult_read)			;get LSB
		ld (hl),a
		inc hl
		ld a,(mult_read+1)			;get MSB
		ld (hl),a
		inc hl
		inc c
		djnz lp2
		
		xor a
		ret
		
		
;----------------------------------------------------------------------------------------
