
;-------------------------------------------------------------------------------------------
; RESET KEYBOARD ROUTINE 
;-------------------------------------------------------------------------------------------

reset_keyboard

keyboard_control equ 254
keyboard_inputs   equ 31


	ld a,%01000000			; pull kb clock line low
	out (keyboard_control),a

	ld bc,151				; wait 256 microseconds
twait	dec bc
	ld a,b
	or c
	jr nz,twait
	
	ld a,%11000000
	out (keyboard_control),a		; pull data line low 
	ld a,%10000000
	out (keyboard_control),a		; release clock line

	ld e,9				; 8 data bits + 1 parity bit	
kb_byte	call wait_kb_clk_low	
	ret c
	xor a
	out (keyboard_control),a		; KB data line = 1 (command = $FF)
	call wait_kb_clk_high
	dec e
	jr nz,kb_byte

	call wait_kb_clk_low
	ret c
	
kwd_lo	in a,(keyboard_inputs)		; wait for keyboard to pull data low (ack)
	bit 6,a
	jr nz,kwd_lo
	call wait_kb_clk_low
	ret c
	
kwdc_hi	in a,(keyboard_inputs)		; wait for keyboard to release data and clock
	and %01100000
	cp  %01100000
	jr nz,kwdc_hi
	ret
	


wait_kb_clk_low

	ld c,0				; restart timer
	ld hl,0					

kb_bcrs	ld b,4				; clk must be continuously low for a few loops
kb_bnclp	in a,(keyboard_inputs)
	ld d,a
	inc hl				; timer
	ld a,h
	or l
	jr nz,kbtcfl_ok
	inc c				; inc timeout counter
	jr nz,kbtcfl_ok
	scf
	ret				; if c = 0, op timed out
kbtcfl_ok	bit 5,d
	jr nz,kb_bcrs
	djnz kb_bnclp		
	xor a				; carry clear = op was ok
	ret


wait_kb_clk_high

	
kb_rsc	ld b,4				; clk must be continuously hi for a few loops
kb_dcnt	in a,(keyboard_inputs)
	bit 5,a
	jr z,kb_rsc			; no timeouts here as disconnected state is high
	djnz kb_dcnt
	ret

	
;-------------------------------------------------------------------------------------------------
