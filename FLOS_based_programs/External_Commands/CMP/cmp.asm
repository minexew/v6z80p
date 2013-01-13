;-----------------------------------------------------------------------
; CMP.EXE - Compare memory command. V1.01
;-----------------------------------------------------------------------

; CMP [#] source end target [bank]

;======================================================================================
; Standard equates for OSCA and FLOS
;======================================================================================

include "equates\kernal_jump_table.asm"
include "equates\osca_hardware_equates.asm"
include "equates\system_equates.asm"

;--------------------------------------------------------------------------------------
; Header code - Force program load location and test FLOS version.
;--------------------------------------------------------------------------------------

my_location	equ $f000
my_bank		equ $0e
include 	"flos_based_programs\code_library\program_header\inc\force_load_location.asm"

required_flos	equ $603
include 	"flos_based_programs\code_library\program_header\inc\test_flos_version.asm"

;--------------------------------------------------------------------------------------

max_bank	equ $0e
window_rows	equ 25
	
		call kjt_get_flos_bank		; default banks are both those currently selected by FLOS
		ld (cmp_src_bank),a
		ld (cmp_target_bank),a

		ld a,(hl)
		cp '#'				; check for # = silent running
		jr nz,not_sr
		ld a,1
		ld (silent),a
fnd_nsp2	inc hl
		ld a,(hl)
		or a
		jp z,bad_args
		cp " "
		jr z,fnd_nsp2

not_sr		call kjt_ascii_to_hex_word	; get start address
		cp $0c
		jp z,bad_args
		cp $1f
		jp z,show_usage			; if no args, show usage
		ld (cmp_start_address),de
		
		call kjt_ascii_to_hex_word	; get end addr
		cp $0c
		jp z,bad_args
		cp $1f
		jp z,no_end_addr
		ld (cmp_end_address),de		
		
		call kjt_ascii_to_hex_word	; get target addr
		cp $0c
		jp z,bad_args
		cp $1f
		jp z,missing_args
		ld (cmp_target_address),de		

		call kjt_ascii_to_hex_word	; get specific target bank
		cp $0c
		jp z,bad_args
		cp $1f
		jp z,no_bank
		ld a,e
		ld (cmp_target_bank),a		


no_bank		ld a,(cmp_target_bank)
		cp max_bank+1			; is bank valid?
		jp nc,bad_bank
		
		ld hl,(cmp_start_address)	; is memory range valid?
		ld de,(cmp_end_address)
		scf
		sbc hl,de
		jp nc,bad_range
		ex de,hl			; de = byte count
		
		ld a,(cmp_src_bank)
		ld b,a
		ld hl,(cmp_start_address)
		exx
		ld a,(cmp_target_bank)
		ld b,a
		ld hl,(cmp_target_address)
		exx
		
		xor a
		ld (different_flag),a
		ld (line_count),a
		
cmp_loop	call kjt_read_baddr		;get source byte A= (b:hl)
		inc hl
		ld c,a
		exx
		call kjt_read_baddr		;get target byte A= (b:hl)
		inc hl
		exx
		cp c
		jp z,same_val
		
		ld (mmv_b),a			;store mismatch values
		ld a,c
		ld (mmv_a),a
		
		dec hl
		ld (mma_a),hl
		inc hl
		exx
		dec hl
		ld (mma_b),hl
		inc hl
		exx
		
		ld a,1
		ld (different_flag),a

		ld a,(silent)			;dont print anything if in silent running mode
		or a
		jp nz,same_val
		
		push bc
		push de
		push hl
		ld hl,line_count		;screen filled with difference lines already?
		inc (hl)
		ld a,(hl)
		cp window_rows-1
		jr nz,show_more
		ld (hl),0
		ld hl,more_txt
		call kjt_print_string		;prompt for more
		call kjt_wait_key_press
		ld a,b
		cp "y"
		jr z,show_more
		pop hl
		pop de
		pop bc
		ld hl,dmore_txt
		call kjt_print_string
		ld a,$2d			;aborted error code
		or a
		ret
		
				
show_more	ld a,(cmp_src_bank)		;populate mismatch string
		ld hl,mm_b0_hex
		call kjt_hex_byte_to_ascii
		ld a,(cmp_target_bank)
		ld hl,mm_b1_hex
		call kjt_hex_byte_to_ascii	;banks
		
		ld a,(mmv_a)
		ld hl,mm_v0_hex
		call kjt_hex_byte_to_ascii
		ld a,(mmv_b)
		ld hl,mm_v1_hex
		call kjt_hex_byte_to_ascii	;values

		ld a,(mma_a+1)
		ld hl,mm_a0_hex
		call kjt_hex_byte_to_ascii
		ld a,(mma_a)
		ld hl,mm_a0_hex+2
		call kjt_hex_byte_to_ascii
		
		ld a,(mma_b+1)
		ld hl,mm_a1_hex
		call kjt_hex_byte_to_ascii
		ld a,(mma_b)
		ld hl,mm_a1_hex+2
		call kjt_hex_byte_to_ascii

		ld hl,mismatch_txt
		call kjt_print_string
		
		pop hl
		pop de
		pop bc
		
same_val	inc de
		ld a,d
		or e
		jp nz,cmp_loop
		
		ld a,(different_flag)
		or a
		jr nz,werediff
		
		ld hl,same_txt
		call cond_print_string
		xor a
		ret
		
werediff	ld hl,diff_txt
		call cond_print_string
		ld a,$80			;return error code $80 if different
		or a
		ret
		

;-------------------------------------------------------------------------------------------

			
show_usage

		ld hl,usage_txt
		call kjt_print_string
		xor a
		ret
		
		
bad_args	ld a,$12
		or a
		ret



bad_range	ld a,$1e
		or a
		ret
		

no_end_addr

		ld a,$1c
		or a
		ret

missing_args

		ld a,$1f
		or a
		ret


bad_bank	ld a,$21
		or a
		ret

;------------------------------------------------------------------------------------------------

cond_print_string

		ld a,(silent)
		or a
		ret nz
		call kjt_print_string
		ret
		
;-----------------------------------------------------------------------------------------------------

usage_txt	db 11,"CMP.FLX (V1.01) - Compares memory.",11,11

		db "Syntax:"
		db "CMP [#] Start End Target [bank]",11,11

		db "The source bank is always the currently",11
		db "selected FLOS bank. The target bank is",11
		db "the same as the source unless specified.",11,0

more_txt	db "Show more? (y/n)",13,0
dmore_txt	db "                ",13,0

same_txt	db "Done - Memory ranges are identical.",11,0
diff_txt	db "Done.",11,0

mismatch_txt	db "B:"
mm_b0_hex	db "xx A:"
mm_a0_hex	db "xxxx = "
mm_v0_hex	db "xx / B:"
mm_b1_hex	db "xx A:"
mm_a1_hex	db "xxxx = "
mm_v1_hex	db "xx",11,0

;-----------------------------------------------------------------------------------------------------

args_pointer		dw 0

different_flag		db 0
line_count		db 0
	
cmp_start_address	dw 0
cmp_end_address		dw 0
cmp_src_bank		db 0

cmp_target_address	dw 0
cmp_target_bank		db 0

mma_a			dw 0
mma_b			dw 0
mmv_a			db 0
mmv_b			db 0

silent			db 0

;-----------------------------------------------------------------------------------------------------
	