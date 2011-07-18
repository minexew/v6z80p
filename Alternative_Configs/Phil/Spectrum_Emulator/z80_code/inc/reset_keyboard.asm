;-------------------------------------------------------------------------------------------
; RESET KEYBOARD ROUTINE 
;-------------------------------------------------------------------------------------------

reset_keyboard

keyboard_control equ 254
keyboard_inputs   equ 31


	call do_kbrs
	xor a				
	out (keyboard_control),a
	ret
	
do_kbrs

	ld a,%01000000			; pull kb clock line low
	out (keyboard_control),a

	call wait_256_us			; wait 256 microseconds	

	ld a,%11000000			; Border = Black
	out (keyboard_control),a		; pull data line low 
	call kb_pause
	ld a,%10000001			; Border = Blue
	out (keyboard_control),a		; release clock line
	call kb_pause

	call wait_kb_clk_low
	ret c

	ld e,9				; 8 data bits + 1 parity bit	
kb_byte	ld a,%00000010			; Border = RED
	out (keyboard_control),a		; KB data line = 1 (command = $FF)
	call kb_pause
	call wait_kb_clk_high
	ret c
	call kb_pause
	call wait_kb_clk_low
	ret c
	dec e
	jr nz,kb_byte

	ld a,%00000011			; TEST ONLY - border = magenta
	out (keyboard_control),a		; TEST ONLY

	call kb_pause
	call wait_kb_data_low		; wait for keyboard to pull data low (ack)
	ret c

	ld a,%00000100			; TEST ONLY - border = green
	out (keyboard_control),a		; TEST ONLY

	call kb_pause
	call wait_kb_clk_low		; wait for keyboard to pull clock low
	ret c
	call kb_pause
	
	ld a,%00000101			; TEST ONLY - border = cyan
	out (keyboard_control),a		; TEST ONLY
	
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

	ld c,20				; time out msb
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

	ld c,20				; time out msb
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

	ld c,20				; time out msb
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

wait_256_us

	ld bc,155				; 155 loops of 26 cycles + call overhead = ~256uS		
	ld a,(hw_vers+1)
	and $f0
	cp $10
	jr nz,twait
	ld bc,32				; if hw version = $1xxx assume CPU is 3.5MHz
twait	dec bc		
	ld a,b
	or c
	jr nz,twait
	ret

;---------------------------------------------------------------------------------------------------

kb_pause

	ld b,9				; pause about 8 microseconds
	ld a,(hw_vers+1)
	and $f0
	cp $10
	jr nz,kbpwait
	ld b,2				
kbpwait	djnz kbpwait		
	ret

;---------------------------------------------------------------------------------------------------
	