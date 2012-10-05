;----------------------------------------------------------------------------------------------
; App: "FILEINFO.EXE" - Shows file info (size and load addr, bank if header applied) Also
; sets an environment variable called FSIZ with size  - v1.00 By Phil @ retroleum
;
; Usage: FILEINFO (#) filename
;
; If # is included, the operation produces no visible output, just sets the envar - also
; mutes the normal FLOS error report to a silent code $80 if a file error is encountered.
;
;--------------------------------------------------------------------------------------------


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
include 		"program_header\force_load_location.asm"

required_flos	equ $607
include 		"program_header\test_flos_version.asm"

;--------------------------------------------------------------------------------------

max_path_length equ 40

	call save_dir_vol
	call fileinfo
	call restore_dir_vol
	ret
			
;-------- Parse command line arguments ---------------------------------------------------------
	

fileinfo	
	ld a,(hl)			; If no arguments supplied, show usage.
	or a
	jp z,show_usage

	cp "#"
	jr nz,not_quiet_mode
	ld a,1
	ld (quietly),a
	call next_arg
	jp z,show_usage
		
		
not_quiet_mode

	call extract_path_and_filename
	ld hl,path_txt
	call kjt_parse_path		;change dir according to the path part of the string
	ret nz
			
	ld hl,fsiz_txt		; remove fsiz envar if exists
	call kjt_delete_envar

	ld hl,filename_txt
	call kjt_open_file
	jp nz,ferror
	
	ld (size_data),iy
	ld (size_data+2),ix
	ld hl,size_bytes
	ld a,(size_data+3)
	call kjt_hex_byte_to_ascii
	ld a,(size_data+2)
	call kjt_hex_byte_to_ascii
	ld a,(size_data+1)
	call kjt_hex_byte_to_ascii
	ld a,(size_data+0)
	call kjt_hex_byte_to_ascii
	
	ld ix,0
	ld iy,32
	call kjt_set_load_length
	
	ld hl,load_buffer
	ld b,my_bank
	call kjt_read_from_file
	
	ld a,(quietly)
	or a
	ld hl,output_size
	call z,kjt_print_string
	
	ld hl,fsiz_txt
	ld de,size_data
	call kjt_set_envar
	
	ld ix,load_buffer
	ld a,(ix)
	cp $ed
	jr nz,nolheader
	ld a,(ix+1)
	or a
	jr nz,nolheader
	
	ld a,(ix+5)
	ld hl,load_bytes
	call kjt_hex_byte_to_ascii
	ld a,(ix+4)
	call kjt_hex_byte_to_ascii
	ld a,(ix+6)
	ld hl,bank_bytes
	call kjt_hex_byte_to_ascii
	
	ld a,(quietly)
	or a
	ld hl,load_addr_txt
	call z,kjt_print_string
	xor a
	ret
	
	
nolheader	ld a,(quietly)
	or a
	ld hl,no_header_txt
	call z,kjt_print_string
	xor a
	ret
	

ferror	push af
	ld hl,quietly
	bit 0,(hl)
	jr nz,quiet_err
	pop af				;normal error
	ret
	
quiet_err	pop af
	ld a,$80				;silent error
	or a
	ret
	

;-------------------------------------------------------------------------------------------

next_arg	
	
fnextarg	inc hl
	ld a,(hl)			; locate next arg, ZF is NOT set if found
	or a
	ret z
	cp " "
	jr nz,fnextarg
nxtarg2	inc hl
	ld a,(hl)
	cp " "
	ret nz
	or a
	ret z
	jr nxtarg2

;-------------------------------------------------------------------------------------------
	
	
show_usage

	ld hl,usage_txt
	call kjt_print_string
	xor a
	ret

		
;-------------------------------------------------------------------------------------------

include "string\inc\extract_path_and_filename.asm"

include "loading\inc\save_restore_dir_vol.asm"

;---------------------------------------------------------------------------------------

usage_txt	db "-----------------------------------",11
	db "FILEINFO.EXE - V1.01 By Phil Ruston",11
	db "Shows information about a file",11
	db "Usage:",11
	db "FILEINFO.EXE # filename",11
	db "(include # for silent operation)",11
	db "-----------------------------------",11,0

fsiz_txt		db "FSIZ",0

size_data		ds 4,0
	
output_size	db "Size: $"
size_bytes	db "xxyyzzaa",11,0

no_header_txt	db "No load location header",11,0

load_addr_txt	db "Load addr $"
load_bytes	db "xxyy",11
load_bank		db "Load bank $"
bank_bytes	db "xx",11,0

quietly		db 0

load_buffer	ds 32,0

;-------------------------------------------------------------------------------------------

