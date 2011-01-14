
;-------------------------------------------------------------------------------------------
; RESET KEYBOARD ROUTINE 
;-------------------------------------------------------------------------------------------

reset_keyboard

keyboard_control equ 254
keyboard_inputs   equ 31


	ld a,%01000000			; pull kb clock line low
	out (keyboard_control),a

	ld bc,151				; wait 256 microseconds
	ld a,(hw_vers+1)
	and $f0
	cp $10
	jr nz,twait
	ld bc,33				; if hw version = $1xxx assume CPU is 3.5MHz
twait	dec bc
	ld a,b
	or c
	jr nz,twait
	
	ld a,%11000000
	out (keyboard_control),a		; pull data line low 
	ld a,%10000000
	out (keyboard_control),a		; release clock line
	call wait_kb_clk_low
	ret c

	ld e,9				; 8 data bits + 1 parity bit	
kb_byte	xor a
	out (keyboard_control),a		; KB data line = 1 (command = $FF)
	call wait_kb_clk_high
	ret c
	call wait_kb_clk_low
	ret c
	dec e
	jr nz,kb_byte

	call wait_kb_data_low		; wait for keyboard to pull data low (ack)
	ret c
	call wait_kb_clk_low		; wait for keyboard to pull clock low
	ret c
	
	ld c,10
	ld hl,0
kwdchilp	in a,(keyboard_inputs)		; wait for keyboard to release data and clock
	and %01100000
	cp  %01100000
	jr nz,wcdhi
	xor a
	ret
wcdhi	inc hl
	ld a,h
	or l
	jr nz,kwdchilp
	dec c
	jr nz,kwdchilp
	scf
	ret
	


wait_kb_clk_low

	ld c,5				; time out msb
	ld hl,0					
kb_wcllp	in a,(keyboard_inputs)
	bit 5,a
	jr nz,wkcl
	xor a
	ret
wkcl	inc hl				; timer
	ld a,h
	or l
	jr nz,kb_wcllp
	dec c				; inc timeout counter
	jr nz,kb_wcllp
	scf
	ret				; if c = 0, op timed out




wait_kb_data_low

	ld c,5				; time out msb
	ld hl,0					
kb_wdllp	in a,(keyboard_inputs)
	bit 6,a
	jr nz,wkdl
	xor a
	ret
wkdl	inc hl				; timer
	ld a,h
	or l
	jr nz,kb_wdllp
	dec c				; inc timeout counter
	jr nz,kb_wdllp
	scf
	ret




wait_kb_clk_high

	ld c,5				; time out msb
	ld hl,0					
kb_wchlp	in a,(keyboard_inputs)
	bit 5,a
	jr z,wkch
	xor a
	ret
wkch	inc hl				; timer
	ld a,h
	or l
	jr nz,kb_wchlp
	dec c				; inc timeout counter
	jr nz,kb_wchlp
	scf
	ret				; if c = 0, op timed out


	
;-------------------------------------------------------------------------------------------------
