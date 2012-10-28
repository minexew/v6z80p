
; LCD addr - disassembles linecop code (v1.04 By Phil 2012)
; addr = 0 to 7FFFF flat system ram address
;
; Changes in v1.04: Updated for full system RAM Linecop ability of OSCA v673
;
;======================================================================================
; Standard equates for OSCA and FLOS
;======================================================================================

include "equates\kernal_jump_table.asm"
include "equates\osca_hardware_equates.asm"
include "equates\system_equates.asm"

;--------------------------------------------------------------------------------------
; Header code - Force program load location and test FLOS version.
;--------------------------------------------------------------------------------------

my_location	equ $f800
my_bank		equ $0e
include 	"flos_based_programs\code_library\program_header\inc\force_load_location.asm"

required_flos	equ $608
include 	"flos_based_programs\code_library\program_header\inc\test_flos_version.asm"
required_osca	equ $673
include 	"flos_based_programs\code_library\program_header\inc\test_osca_version.asm"

;------------------------------------------------------------------------------------------------
; Actual program starts here..
;------------------------------------------------------------------------------------------------

window_cols	equ 40
window_rows	equ 25

		call kjt_ascii_to_hex32		; convert following ascii to address in DE
		or a
		jr z,lcdgo
		cp $c
		ret z
		ld hl,usage_txt
		call kjt_print_string
		xor a
		ret

addr_bad	ld a,$08
		or a
		ret
		
lcdgo		ld a,b				;check address is <$80000
		or a
		jr nz,addr_bad
		ld a,c
		cp $8
		jr nc,addr_bad
		
		res 0,e				; ensure even address for linecop	
		ld (linecop_pc),de
		ld a,c
		ld (linecop_pc+2),a
		
mainloop	ld hl,output_string		
		ld a,(linecop_pc+2)
		call kjt_hex_byte_to_ascii		
		ld de,(linecop_pc)
		ld a,d
		call kjt_hex_byte_to_ascii	; put address at start of line
		ld a,e
		call kjt_hex_byte_to_ascii
		ld (hl)," "
		inc hl

		push hl			; get linecop data word
		ld hl,(linecop_pc)
		ld a,(linecop_pc+2)
		ld e,a
		call kjt_read_sysram_flat
		ld (lc_word_lsb),a

		ld hl,(linecop_pc)
		inc hl
		ld a,(linecop_pc+2)
		ld e,a
		call kjt_read_sysram_flat
		ld (lc_word_msb),a
		pop hl
		

		ld a,(lc_word_msb)		; decode instruction
		and %11000000
		cp %11000000
		jr nz,notwait			; is it a wait line instruction?
		ld de,wait_txt
		call copy_text
		ld a,(lc_word_msb)
		and 1
		ld (current_line+1),a		; note the current wait line and show it
		ld b,a
		ld a,(lc_word_lsb)
		ld (current_line),a		
		ld c,a
		call three_digit_hex		
		jp nxt_ins

notwait		cp %10000000			; is it a set reg instruction?
		jr nz,not_sreg
		ld de,setr_txt
		call copy_text
		ld a,(lc_word_msb)
		and %00000111			; note the register and show it
		ld (current_reg+1),a
		ld b,a
		ld a,(lc_word_lsb)
		ld (current_reg),a
		ld c,a
		call three_digit_hex
		jp nxt_ins

not_sreg	ld de,write_txt			;must be a write instruction then..
		call copy_text
		ld a,(lc_word_lsb)
		call kjt_hex_byte_to_ascii	;show byte to write
		ld de,arrow_txt
		call copy_text
		ld a,(current_reg+1)		;has the dest register been defined yet?
		cp $ff
		jr nz,regknown			;if not, just show "????"
		ld de,unknown_txt
		call copy_text
		jr chk_adops
regknown	ld b,a
		ld a,(current_reg)
		ld c,a
		call three_digit_hex

chk_adops	ld a,(lc_word_msb)		;any additional ops?
		and %01110000
		jr z,nxt_ins			;skip if none
		ld (hl),11			;show additional commands in brackets underneath write
		inc hl
		ld (hl),0
		ld hl,output_string+1		;skip first zero digit
		call kjt_print_string
		ld a,(line_count)
		inc a
		ld (line_count),a
		ld hl,output_string
		ld de,bracket_txt
		call copy_text

		ld a,(lc_word_msb)
		bit 6,a				;inc reg?
		jr z,no_increg
		ld de,incr_txt
		call copy_text
		ld de,(current_reg)
		ld a,d				;has the reg been set yet?
		cp $ff
		jr z,no_increg
		inc de
		ld (current_reg),de

no_increg	ld a,(lc_word_msb)
		bit 5,a				;inc wait?
		jr z,no_incw
		ld de,wait_txt
		call copy_text
		ld de,(current_line)
		ld a,d				;has the wait line been set yet?
		cp $ff
		jr nz,l_known
		ld de,unknown_txt		;if not show "???"
		call copy_text
		jr line_unk	
l_known		inc de
		ld a,d
		and %111
		ld d,a
		ld (current_line),de
		push de
		pop bc
		call three_digit_hex
line_unk	ld (hl),","
		inc hl
		
no_incw		ld a,(lc_word_msb)
		bit 4,a
		jr z,no_reload
		ld de,relo_txt
		call copy_text

no_reload	dec hl				;close bracket around additional ops
		ld (hl),"]"
		inc hl
		
		
nxt_ins		ld (hl),11
		inc hl
		ld (hl),0
		ld hl,output_string+1		;(+1 to skip first zero)
		call kjt_print_string
		call line_counter	
		jr nz,lcd_end
		
		ld a,(linecop_pc+2)
		ld hl,(linecop_pc)		;next instruction
		ld de,2
		add hl,de
		adc a,0
		ld (linecop_pc),hl
		ld (linecop_pc+2),a		
		jp mainloop
		

lcd_end		ld hl,crcr_txt
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




three_digit_hex
		push de
		push hl
		ld hl,hex_chars_txt
		push bc
		ld a,b
		call kjt_hex_byte_to_ascii	
		pop bc
		ld a,c
		call kjt_hex_byte_to_ascii				
		
		ld de,hex_chars_txt+1
		pop hl
		ex de,hl
		ld bc,3
		ldir
		ex de,hl
		pop de
		ret
		
;---------------------------------------------------------------------------------------------	

linecop_pc	dw $0000
		db $00
		
lc_word_lsb	db $00
lc_word_msb	db $00
current_reg	dw $FFFF
current_line	dw $FFFF

wait_txt	db "WAIT LINE ",0
setr_txt	db "SELECT REG ",0
write_txt	db "WRITE ",0
incr_txt	db "INC REG,",0	
relo_txt	db "RESTART,",0
unknown_txt	db "???",0
arrow_txt	db " -> ",0
more_txt	db 11,"More? (y/n)",13,0
crcr_txt	db 11,0
usage_txt	db 11,"Linecop Disassembler v1.04",11,11,"Usage: LCD addr (0-7FFFE)",11,0
bracket_txt	db "       [",0
line_count	db 0

hex_chars_txt	db 0,0,0,0

output_string	ds window_cols*2,0
	
;============================================================================================

