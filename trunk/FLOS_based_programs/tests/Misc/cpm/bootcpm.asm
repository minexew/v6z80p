; CPM emulator V 0.0; May 15, 2010 
; CPM BDOS to FLOS translator
; This program resides in the upper 4k pages and intercepts all BDOS calls
; and translates them to FLOS calls
; This means that only well behaving CP-M programs will run without risk
; it is planned to make a BIOS jump table and fill in the calls as far as possible
; First task of the program is to switch out bank 0 and set up page 0
; After that every call to BDOS requires switching in FLOS to deal with the call

		

include 	"symbol_list.symbol"
include	"kernal_jump_table.asm"


		

	org	05000h	;FLOS program
	jp	init
opening1:	db	"L1-Setting up for CPM3",13,10,0
setup_done:
	db	"L1-Setup ready",13,10,0
fout:	db	"L1-File niet gevonden",13,10,0
filenaam	db	"startcpm.exe",0

init:	ld	hl,opening1
	call	kjt_print_string	;signal on V6Z80P screen
	ld	hl,opening1
	call	print_serial_string
	in	a,(sys_mem_select)
	ld	hl,sys_mem_byte
	ld	(hl),a
	and	0fh
	out	(sys_mem_select),a	;switch off video & sprite memory
; load startcpm.exe
	ld	hl,filenaam
	call	kjt_find_file
	jr	nz,error
	call	kjt_set_load_length
	ld	hl,0f000h
	ld	b,0
	call	kjt_force_load
	call	kjt_wait_key_press
	call	0f000h		;now jump to cp-m in high memory
	ld	a,(sys_mem_byte)
	out	(sys_mem_select),a
	ld	a,(sys_low_page)
	and	%11110000		; bank 1
	out	(sys_low_page),a	;FLOS accessible
	ld	hl,setup_done
	call	print_serial_string
	ret

error:	ld	hl,fout
	call	kjt_print_string
	ret
sys_mem_byte	ds	1

BDOS	ret	;entry point for BDOS calls

BIOS	ret	;entry point for BIOS calls
		
;-----------------------------------------------------------------		
print_serial_string
	ld	a,(hl)
	or	a
	ret	z
	call	kjt_serial_tx_byte
	inc	hl
	jr	print_serial_string
;-----------------------------------------------------------------		
		end
