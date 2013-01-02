
; Simple LineCop Example: Changes a single scanline (border) colour to white
; Requires OSCA v673 or above

;---Standard header for OSCA and FLOS  -----------------------------------------------------------------------

include "equates\kernal_jump_table.asm"
include "equates\OSCA_hardware_equates.asm"
include "equates\system_equates.asm"


	org $5000

;--------------------------------------------------------------------------------------------------------------

	
		ld c,$0 
		ld de,my_linecop_list		; c:de = linecop address in system memory
		
		ld ix,linecop_addr0
		set 7,c 			; bit 7 of MSB must be set for linecop hi
		set 0,e 			; Bit 0 of LSB must be set to enable the linecop system
		ld (ix+2),c			; write linecop addr 23:16
		ld (ix+1),d			; write linecop addr 15:8
		ld (ix+0),e			; write linecop addr 7:0 (and enable)
		
		call kjt_wait_key_press		; wait for any key
		
		xor a
		ld (vreg_linecop_lo),a		; disable linecop
	
		xor a				; back to flos
		ret


;---------------------------------------------------------------------------------------------------------------
; Linecop mnemonics and their opcodes..
;---------------------------------------------------------------------------------------------------------------

lc_wr        equ $0000		; Write Register
lc_wril      equ $2000		; Write Register & Inc Line (then wait)
lc_wrir      equ $4000		; Write Register & Inc Reg
lc_wrilir    equ $6000		; Write Register & Inc Reg & Inc Line (then wait)
lc_sr        equ $8000		; Select Register
lc_wl	     equ $c000		; Wait Line

;------------------------------------------------------------------------------------------------------------------------------------------------------

		org ($+1) & $fffe	; line cop lists must be aligned on even address
		
my_linecop_list	
	
		dw lc_wl+$080		; Wait for line $80
		dw lc_sr+$000		; Select video register $000 (background colour)
		dw lc_wrir+$ff		; Write $ff to colour LSB, increment video register
		dw lc_wril+$ff		; Write $ff to colour MSB, increment wait line (and wait)
		dw lc_sr+$000		; Select video register $000 (background colour)
		dw lc_wrir+$00		; Write $00 to colour LSB, increment video register
		dw lc_wr+$00		; Write $00 to colour MSB
		dw lc_wl+$1ff		; Wait for Line $1FF (End of LineCop program)
		
;---------------------------------------------------------------------------------------------------------
