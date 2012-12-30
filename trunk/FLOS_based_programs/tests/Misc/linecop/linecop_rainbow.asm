
; Tests linecop - rainbow colourbars

;---Standard header for OSCA and FLOS  -----------------------------------------------------------------------

include "equates\kernal_jump_table.asm"
include "equates\OSCA_hardware_equates.asm"
include "equates\system_equates.asm"

	org $5000


linecop_code	equ $0			; $0000 to $FFFE = $70000 to $7FFFE in sys RAM (must be even)

;--------------------------------------------------------------------------------------------------------------

		ld de,linecop_prog
		push de			;build rainbow colour bar linecop program from list
		pop ix
		ld (ix+0),$10			;first wait line
		ld (ix+1),$c0
		inc ix
		inc ix
		
		ld b,0				;make a load of set reg, writelo+inc_reg, writehi instructions
		ld hl,rainbow_colours
mcblp		ld (ix+0),$00			;set reg 0
		ld (ix+1),$80
		ld a,(hl)
		ld (ix+2),a			;write colour lo, inc reg
		ld (ix+3),$40
		inc hl
		ld a,(hl)
		ld (ix+4),a			;write colour hi, inc line
		ld (ix+5),$20
		inc hl
		ld de,6
		add ix,de
		djnz mcblp
		ld (ix+0),$ff			;at end of list, wait for $1ff 
		ld (ix+1),$c1		

		ld de,linecop_prog
		set 0,e				; enable line cop (bit 0 of vreg_linecop_lo)
		ld (vreg_linecop_lo),de		; set h/w location of line cop list
		
		xor a				; and quit
		ret


;------------------------------------------------------------------------------------------------------

rainbow_colours	dw $f0f,$f0f,$e0f,$e0f,$d0f,$c0f,$b0f,$a0f,$90f,$80f,$70f,$60f,$50f,$40f,$30f,$30f,$20f,$20f,$10f,$10f,$00f
		dw $00f,$00f,$01f,$01f,$02f,$02f,$03f,$04f,$05f,$06f,$07f,$08f,$09f,$0af,$0bf,$0cf,$0df,$0df,$0ef,$0ef,$0ff
		dw $0ff,$0ff,$0fe,$0fe,$0fd,$0fd,$0fc,$0fb,$0fa,$0f9,$0f8,$0f7,$0f6,$0f5,$0f4,$0f3,$0f2,$0f2,$0f1,$0f1,$0f0
		dw $0f0,$1f0,$1f0,$2f0,$2f0,$3f0,$4f0,$5f0,$6f0,$7f0,$8f0,$9f0,$af0,$bf0,$cf0,$df0,$df0,$ef0,$ef0,$ff0,$ff0
		dw $ff0,$fe0,$fe0,$fd0,$fd0,$fc0,$fb0,$fa0,$f90,$f80,$f70,$f60,$f50,$f40,$f30,$f30,$f20,$f20,$f10,$f10,$f00
		dw $f00,$f00,$f01,$f01,$f02,$f02,$f03,$f04,$f05,$f06,$f07,$f08,$f09,$f0a,$f0b,$f0c,$f0d,$f0d,$f0d,$f0e,$f0e,$f0f,$f0f
		dw $f0f,$f0f,$e0f,$e0f,$d0f,$c0f,$b0f,$a0f,$90f,$80f,$70f,$60f,$50f,$40f,$30f,$30f,$20f,$20f,$10f,$10f,$00f
		dw $00f,$00f,$01f,$01f,$02f,$02f,$03f,$04f,$05f,$06f,$07f,$08f,$09f,$0af,$0bf,$0cf,$0df,$0df,$0ef,$0ef,$0ff
		dw $0ff,$0ff,$0fe,$0fe,$0fd,$0fd,$0fc,$0fb,$0fa,$0f9,$0f8,$0f7,$0f6,$0f5,$0f4,$0f3,$0f2,$0f2,$0f1,$0f1,$0f0
		dw $0f0,$1f0,$1f0,$2f0,$2f0,$3f0,$4f0,$5f0,$6f0,$7f0,$8f0,$9f0,$af0,$bf0,$cf0,$df0,$df0,$ef0,$ef0,$ff0,$ff0
		dw $ff0,$fe0,$fe0,$fd0,$fd0,$fc0,$fb0,$fa0,$f90,$f80,$f70,$f60,$f50,$f40,$f30,$f30,$f20,$f20,$f10,$f10,$f00
		dw $f00,$f00,$f01,$f01,$f02,$f02,$f03,$f04,$f05,$f06,$f07,$f08,$f09,$f0a,$f0b,$f0c,$f0d,$f0d,$f0d,$f0e,$f0e,$f0f,$f0f

;---------------------------------------------------------------------------------------------------------

linecop_prog	db 0
