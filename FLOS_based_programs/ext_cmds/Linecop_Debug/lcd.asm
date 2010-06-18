
; LCD addr - disassembles linecop code (v0.01 By Phil '09)
;
; args = 0 to FFFF flat linecop memory area (70000-7ffff system ram)
;
;---Standard header for OSCA and FLOS ----------------------------------------------------------

include "kernal_jump_table.asm"
include "osca_hardware_equates.asm"
include "system_equates.asm"

window_cols	equ 40
window_rows	equ 25

	org $5000

;--------- Test FLOS version ---------------------------------------------------------------------

	push hl
	call kjt_get_version		; check running under FLOS v544+ 
	ld de,$544
	xor a
	sbc hl,de
	jr nc,flos_ok
	ld hl,old_flos_txt
	call kjt_print_string
	pop hl
	xor a
	ret

old_flos_txt

	db "Program requires FLOS v544+",11,11,0
	
;-------- Load and Init -----------------------------------------------------------------------
	
flos_ok	pop hl

	ld de,$5000		; if being run from G command, HL which is normally
	xor a			; the argument string will be $5000..
	sbc hl,de
	jr z,mainloop		; if thats the case use default start address of $0
	
addr_ok	add hl,de
	call kjt_ascii_to_hex_word	; convert following ascii to address in DE
	or a
	jr z,lcdgo
	cp $c
	ret z
	ld hl,usage_txt
	call kjt_print_string
	xor a
	ret
				; quit if ascii is not valid hex
lcdgo	ld a,14			
	bit 7,d			; covert flat 64k range to 8000-ffff + bank
	jr nz,bsok
	set 7,d
	dec a	
bsok	call kjt_forcebank
	res 0,e			; ensure even address for linecop	
	ld (linecop_pc),de
	
	
mainloop	ld hl,output_string		
	ld de,(linecop_pc)
	in a,(sys_mem_select)
	rrca
	and $80
	ld b,a
	ld a,d
	and $7f
	or b
	call kjt_hex_byte_to_ascii	; put address at start of line
	ld a,e
	call kjt_hex_byte_to_ascii
	ld (hl)," "
	inc hl
	push de
	pop ix
	ld a,(ix+1)		; decode instruction
	and %11000000
	cp %11000000
	jr nz,notwait		; is it a wait line instruction?
	ld de,wait_txt
	call copy_text
	ld a,(ix+1)
	and 1
	ld (current_line+1),a
	call kjt_hex_byte_to_ascii	; show the line to wait for
	ld a,(ix)
	ld (current_line),a		; note the current wait line
	call kjt_hex_byte_to_ascii
	jp nxt_ins

notwait	cp %10000000		; is it a set reg instruction?
	jr nz,not_sreg
	ld de,setr_txt
	call copy_text
	ld a,(ix+1)
	and %00111111		; note the register and show it
	ld (current_reg+1),a
	call kjt_hex_byte_to_ascii
	ld a,(ix)
	ld (current_reg),a
	call kjt_hex_byte_to_ascii
	jp nxt_ins

not_sreg	ld de,write_txt		;must be a write instruction then..
	call copy_text
	ld a,(ix)
	call kjt_hex_byte_to_ascii	;show byte to write
	ld de,arrow_txt
	call copy_text
	ld a,(current_reg+1)	;has the dest register been defined yet?
	cp $ff
	jr nz,regknown		;if not, just show "????"
	ld de,unknown_txt
	call copy_text
	jr chk_adops
regknown	call kjt_hex_byte_to_ascii
	ld a,(current_reg)
	call kjt_hex_byte_to_ascii
chk_adops	ld a,(ix+1)		;any additional ops?
	and %01110000
	jr z,nxt_ins		;skip if none
	ld (hl),11		;show additional commands in brackets underneath write
	inc hl
	ld (hl),0
	ld hl,output_string
	call kjt_print_string
	ld a,(line_count)
	inc a
	ld (line_count),a
	ld hl,output_string
	ld de,bracket_txt
	call copy_text

	bit 6,(ix+1)		;inc reg?
	jr z,no_increg
	ld de,incr_txt
	call copy_text
	ld de,(current_reg)
	ld a,d			;has the reg been set yet?
	cp $ff
	jr z,no_increg
	inc de
	ld (current_reg),de

no_increg	bit 5,(ix+1)		;inc wait?
	jr z,no_incw
	ld de,wait_txt
	call copy_text
	ld de,(current_line)
	ld a,d			;has the wait line been set yet?
	cp $ff
	jr nz,l_known
	ld de,unknown_txt		;if not show "????"
	call copy_text
	jr line_unk	
l_known	inc de
	ld (current_line),de
	ld a,(current_line+1)
	call kjt_hex_byte_to_ascii
	ld a,(current_line)
	call kjt_hex_byte_to_ascii
line_unk	ld (hl),","
	inc hl
	
no_incw	bit 4,(ix+1)
	jr z,no_reload
	ld de,relo_txt
	call copy_text

no_reload dec hl			;close bracket around additional ops
	ld (hl),"]"
	inc hl
	
	
nxt_ins	ld (hl),11
	inc hl
	ld (hl),0
	ld hl,output_string
	call kjt_print_string
	call line_counter	
	jr nz,lcd_end
	
	ld hl,(linecop_pc)		;next instruction
	inc hl
	inc hl
	ld a,h
	or a
	jr nz,nbswap
	ld h,$80
	in a,(sys_mem_select)
	xor 1
	out (sys_mem_select),a
nbswap	ld (linecop_pc),hl
	jp mainloop
	

lcd_end	ld hl,crcr_txt
	call kjt_print_string
	xor a
	ret
	
	
	
	
copy_text	ld a,(de)
	or a
	ret z
	ld (hl),a
	inc de
	inc hl
	jr copy_text



line_counter

	ld a,(line_count)
	inc a
	ld (line_count),a
	cp window_rows-4
	jr c,noprompt
	xor a
	ld (line_count),a
	ld hl,more_txt
	call kjt_print_string
	call kjt_wait_key_press
	ld a,b
	cp "y"
	ret

noprompt	xor a
	ret
				
;---------------------------------------------------------------------------------------------	

linecop_pc	dw $0000
current_reg	dw $FFFF
current_line	dw $FFFF

wait_txt		db "WAIT LINE ",0
setr_txt		db "SELECT REG ",0
write_txt		db "WRITE ",0
incr_txt		db "INC REG,",0	
relo_txt		db "RESTART,",0
unknown_txt	db "???",0
arrow_txt		db " -> ",0
more_txt		db 11,"More? (y/n)",13,0
crcr_txt		db 11,0
usage_txt		db "Usage:LCD.EXE LineCop Mem Addr (0-FFFE)",11,0
bracket_txt	db "     [",0
line_count	db 0

output_string	ds window_cols*2,0
	
;============================================================================================

