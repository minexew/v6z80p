
; Tests linecop - major DMA use on one line

;---Standard header for OSCA and FLOS  -----------------------------------------------------------------------

include "kernal_jump_table.asm"
include "OSCA_hardware_equates.asm"
include "system_equates.asm"

	org $5000


linecop_code	equ $0			; $0000 to $FFFE = $70000 to $7FFFE in sys RAM (must be even)

;--------------------------------------------------------------------------------------------------------------

	ld hl,linecop_data			;fill linecop list with lots of writes 
	ld b,0
lp1	ld (hl),b				;write value
	inc hl
	ld (hl),0				;write command
	inc hl
	djnz lp1
	


	ld a,13				;Bank 13 = $70000 in sys RAM (flat address)
	ld de,linecop_code			
	bit 7,d				;if > $7FFF use bank 14 ($78000 in sys RAM)
	jr z,lowerbank
	inc a
lowerbank	call kjt_forcebank
	set 7,d				; will always be in upper page of Z80 address space
	ld hl,my_linecoplist
	ld bc,end_my_linecoplist-my_linecoplist
	ldir				; copy linecop list to linecop accessible memory

	ld de,linecop_code
	set 0,e				; enable line cop (bit 0 of vreg_linecop_lo)
	ld (vreg_linecop_lo),de		; set h/w location of line cop list
		
;------------------------------------------------------------------------------------------------------------

wvrtstart	ld a,(vreg_read)			;wait for VRT
	and 1
	jr z,wvrtstart
wvrtend	ld a,(vreg_read)
	and 1
	jr nz,wvrtend

	call do_stuff
	
	in a,(sys_keyboard_data)
	cp $76
	jr nz,wvrtstart			; loop if ESC key not pressed
	
	ld a,0
	ld (vreg_linecop_lo),a		; disable linecop
	xor a				; and quit
	ret


;--------------------------------------------------------------------------------------------------------

do_stuff	ret

;------------------------------------------------------------------------------------------------------

counter		db 0

my_linecoplist	dw $c018		;wait for line $18 
		dw $8000		;set register 0
		
linecop_data	ds 512,0		;data to be filled in by init
		
		dw $c019		;wait for line $19
		dw $0000		;write 0 to register 0
		
		dw $c1ff		;wait for line $1ff (end of list)
		
end_my_linecoplist	db 0

;---------------------------------------------------------------------------------------------------------
