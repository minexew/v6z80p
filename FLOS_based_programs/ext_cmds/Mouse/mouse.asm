;-----------------------------------------------------------------------------------------------
; "MOUSE.EXE" = Test for mouse and activate OS pointer v1.02
;-----------------------------------------------------------------------------------------------

;---Standard header for OSCA and FLOS ----------------------------------------------------------

include "kernal_jump_table.asm"
include "osca_hardware_equates.asm"
include "system_equates.asm"

;----------------------------------------------------------------------------------------------------
; As this is an external command, load program high in memory to help avoid overwriting user programs
;----------------------------------------------------------------------------------------------------

my_location	equ $8000
my_bank		equ $0c

	org my_location	; desired load address
	
load_loc	db $ed,$00	; header ID (Invalid, safe Z80 instruction)
	jr exec_addr	; jump over remaining header data
	dw load_loc	; location file should load to
	db my_bank	; upper bank the file should load to
	db 0		; no truncating required

exec_addr	

;-------------------------------------------------------------------------------------------------
; Test FLOS version 
;-------------------------------------------------------------------------------------------------

required_flos equ $568

	push hl
	di			; temp disable interrupts so stack cannot be corrupted
	call kjt_get_version
true_loc	exx
	ld ix,0		
	add ix,sp			; get SP in IX
	ld l,(ix-2)		; HL = PC of true_loc from stack
	ld h,(ix-1)
	ei
	exx
	ld de,required_flos
	xor a
	sbc hl,de
	pop hl
	jr nc,flos_ok
	exx
	push hl			;show FLOS version required
	ld de,old_fth-true_loc
	add hl,de			;when testing location references must be PC-relative
	ld de,required_flos		
	ld a,d
	call kjt_hex_byte_to_ascii
	ld a,e
	call kjt_hex_byte_to_ascii
	pop hl
	ld de,old_flos_txt-true_loc
	add hl,de	
	call kjt_print_string
	xor a
	ret

old_flos_txt

        db "Error: Requires FLOS version $"
old_fth db "xxxx+",11,11,0

flos_ok


;------------------------------------------------------------------------------------------------
; Actual program starts here..
;------------------------------------------------------------------------------------------------

	call init_mouse
	or a
	jr z,minit_ok
	ld hl,no_mouse_txt
	call kjt_print_string
	xor a
	ret
	
minit_ok	in a,(sys_mem_select)
	or %10000000			; copy sprite pointer to last definition block
	out (sys_mem_select),a		; of sprite ram
	ld a,%10011111
	ld (vreg_vidpage),a		
	ld hl,pointer_def
	ld de,$1f00
	ld bc,$100
	ldir
	in a,(sys_mem_select)
	and %01111111
	out (sys_mem_select),a

	ld hl,new_pointer_colours		;copy to live palette
	ld de,palette+(248*2)
	ld bc,8*2
	ldir

	call kjt_get_display_size		;get pointer boundaries
	ld l,c
	ld h,0
	add hl,hl
	add hl,hl
	add hl,hl
	ex de,hl
	ld l,b
	ld h,0
	add hl,hl
	add hl,hl
	add hl,hl
	ld bc,new_pointer_colours
	call kjt_enable_pointer

	ld hl,mouse_enabled_txt
	call kjt_print_string
	xor a
	ret

;-----------------------------------------------------------------------------------------------

mouse_enabled_txt

	db 11,"Mouse detected and enabled",11,11,0
	
no_mouse_txt
	
	db 11,"No mouse detected",11,11,0

;-----------------------------------------------------------------------------------------------
	
init_mouse

; returns A=$00 if mouse initialized ok
;         A=$01 if no mouse found

	ld a,%10000001
	out (sys_irq_enable),a	;disable mouse interrupts
	ld a,%00000010
	out (sys_clear_irq_flags),a	;clear mouse IRQ flag
	
	ld a,$ff			;send "reset" command to mouse
	call write_to_mouse		
	jr c,mouse_timeout
	call wait_2_mouse_bytes	;should be FF,FA (byte seen by input HW when written and ack)
	jr c,mouse_timeout
	call wait_2_mouse_bytes	;should be AA,00 (mouse passed self test and mouse ID)
	
	ld a,$f4			;send "enable data reporting" command to mouse
	call write_to_mouse
	jr c,mouse_timeout
	call wait_2_mouse_bytes	;should be $F4,$FA (as written) and (ack)
	jr c,mouse_timeout
	
	xor a			;A=0, mouse initialized OK
	ret

mouse_timeout

	xor a			;A=1, no mouse detected
	inc a
	ret

wait_2_mouse_bytes

	call wait_mouse_byte
	call wait_mouse_byte
	ret	
	
	
write_to_mouse

; Put byte to send to mouse in A

	ld c,a			; copy output byte to c
	ld d,1			; initial parity count
	ld a,%01000000		; pull clock line low
	out (sys_ps2_joy_control),a
	ld a,7
	call kjt_timer_wait		; wait 100 microseconds
	ld a,%11000000
	out (sys_ps2_joy_control),a	; pull data line low also
	ld a,%10000000
	out (sys_ps2_joy_control),a	; release clock line
	
	ld b,8			; loop for 8 bits of data
mdoloop	call wait_mouse_clk_low	
	ret c
	xor a
	set 7,a
	bit 0,c
	jr z,mdbzero
	res 7,a
	inc d
mdbzero	out (sys_ps2_joy_control),a	; set data line according to output byte
	call wait_mouse_clk_high
	rr c
	djnz mdoloop

	call wait_mouse_clk_low
	ret c
	xor a
	bit 0,d
	jr nz,parone
	set 7,a
parone	out (sys_ps2_joy_control),a	; set data line according to parity of byte
	call wait_mouse_clk_high

	call wait_mouse_clk_low
	ret c
	xor a
	out (sys_ps2_joy_control),a	; release data line

wmdlow	in a,(sys_irq_ps2_flags)	; wait for mouse to pull data low (ack)
	bit 7,a
	jr nz,wmdlow
	call wait_mouse_clk_low	
	ret c
	
wmdchi	in a,(sys_irq_ps2_flags)	; wait for mouse to release data and clock
	and %11000000
	cp %11000000
	jr nz,wmdchi
	xor a
	ret



wait_mouse_clk_low

	push bc
	xor a 			; timer overflows every 4 ms
	ld c,a
	out (sys_timer),a		
	ld a,%00000100
	out (sys_clear_irq_flags),a	; clear timer overflow flag
	
dbcrs1	ld b,8			; clk must be continuously low for a few loops
dbloop1	in a,(sys_irq_ps2_flags)
	ld e,a
	bit 2,e			; timer carry set?
	jr z,mtfl_ok
	ld a,%00000100
	out (sys_clear_irq_flags),a	; clear timer overflow flag
	inc c			; inc timeout counter
	jr nz,mtfl_ok
	pop bc
	scf			; carry flag set = op timed out
	ret
		
mtfl_ok	bit 6,e
	jr nz,dbcrs1
	djnz dbloop1		
	pop bc
	xor a			; carry clear = op was ok
	ret
	

wait_mouse_clk_high

	push bc
dbrs2	ld b,8			; clk must be continuously hi for n cycles
dbloop2	in a,(sys_irq_ps2_flags)
	bit 6,a
	jr z,dbrs2
	djnz dbloop2
	pop bc
	ret
	



wait_mouse_byte

	xor a
	out (sys_timer),a

	ld b,0
mouse_tcd	out (sys_clear_irq_flags),a	; clear timer overflow flag

wait_mlp	in a,(sys_irq_ps2_flags)	; wait for mouse IRQ flag to be set
	bit 1,a
	jr nz,mbyte_rdy
	
	in a,(sys_irq_ps2_flags)
	bit 2,a			; if bit 2 of status flags = 1, timer has overflowed
	jr z,wait_mlp
	djnz mouse_tcd
	scf			; set carry flag = timed out
	ret
	
mbyte_rdy	ld a,%00000010
	out (sys_clear_irq_flags),a	; clear mouse IRQ
	in a,(sys_mouse_data)	; read mouse data byte
	or a			; clear carry flag
	ret


	
;-----------------------------------------------------------------------------------------------

new_pointer_colours	incbin "pointer_palette.bin"

pointer_def	incbin "pointer_sprite.bin"

;------------------------------------------------------------------------------------------------
