
; Tests linecop list in first 64KB of system RAM, osca v673

;---Standard header for OSCA and FLOS  -----------------------------------------------------------------------

include "equates\kernal_jump_table.asm"
include "equates\OSCA_hardware_equates.asm"
include "equates\system_equates.asm"

		org $5000

		ld ix,linecop_addr0
		ld de,my_linecop_list
		ld (ix+2),%10000000		; set bits [18:16] of linecop address (bit 7 must be set when writing linecop address)
		ld (ix+1),d			; set bits [15:8] of linecop address
		set 0,e				; set "enable linecop" (bit 0)
		ld (ix+0),e			; set bits [7:1] of list address (and start line cop)
		
;------------------------------------------------------------------------------------------------------------

		call kjt_wait_key_press		; wait for any key

		ld a,0
		ld (linecop_addr0),a		; disable linecop

		xor a				; and quit
		ret

;------------------------------------------------------------------------------------------------------
		
		org ($+1) & $FFFE		; Linecop lists must be aligned to even bytes
			
my_linecop_list	dw $c029			; wait for line $29
		dw $8000			; set register 0 (colour 0 lo)
		dw $0080			; write $88 to register
		dw $8001			; set register 1
		dw $0008			; write $08 to register
		
		dw $c02a			; wait for line $2a
		dw $8000			; set register 0
		dw $0008			; write $00 to register
		dw $8001			; set register 1
		dw $0008			; write $00 to register
		
		dw $c02b			; wait for line $2b
		dw $8000			; set register 0
		dw $0000			; write $00 to register
		dw $8001			; set register 1
		dw $0000			; write $00 to register
		
		dw $c1ff			; wait for line $1ff (end of list)
		
;---------------------------------------------------------------------------------------------------------
