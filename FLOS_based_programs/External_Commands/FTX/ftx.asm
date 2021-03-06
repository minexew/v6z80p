;--------------------------------------------------------------------------------------
; FTX v1.01 - sends a file from SD card to serial port
;
; Changes: V1.01 Changed name, reformatted source to TAB size = 8
;--------------------------------------------------------------------------------------

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

required_flos	equ $607
include 	"flos_based_programs\code_library\program_header\inc\test_flos_version.asm"

;------------------------------------------------------------------------------------------------
; Actual program starts here..
;------------------------------------------------------------------------------------------------

buffer_size equ $800				; must be multiple of 256

;------------------------------------------------------------------------------------------------

max_path_length equ 40

		call save_dir_vol
		call filetx
		call restore_dir_vol
		ret
	
filetx		ld a,(hl)			; examine argument text, if encounter 0 show usage
		or a			
		jp z,show_use
	
		call extract_path_and_filename
		ld hl,path_txt
		call kjt_parse_path		;change dir according to the path part of the string
		ret nz

;-------------------------------------------------------------------------------------------------------
	
		ld hl,filename_txt
		ld de,sh_filename		; copy filename to serial header
		ld b,15
fnclp		ld a,(hl)
		or a
		jr z,fncdone
		cp " "
		jr z,fncdone
		ld (de),a
		inc hl
		inc de
		djnz fnclp
fncdone		xor a
		ld (de),a			; null terminate filename
		
		ld hl,filename_txt		; does filename exist?
		call kjt_find_file
		ret nz
		ld (file_size),iy
		ld (file_size+2),ix
		
		ld ix,serial_header
		call send_serial_block		; send file header and wait to receive "OK" acknowledge
		ret nz
		
		ld hl,sending_txt
		call kjt_print_string
		
;-------------------------------------------------------------------------------------------------------


send_loop	ld ix,0				; reset load length to buffer size (file pointer can be
		ld iy,buffer_size		; automatic since the sector buffer is not being corrupted)
		call kjt_set_load_length
		call clear_load_buffer
		ld hl,load_buffer
		ld b,my_bank
		call kjt_read_from_file
		jr z,fl_ok
		cp $1b				; dont care about EOF
		ret nz
	
fl_ok		ld ix,load_buffer
		ld b,buffer_size/256		; maximum blocks to send from this load_buffer
sloop		push bc
		call send_serial_block		; send a block and wait to receive "OK" acknowledge
		pop bc
		ret nz
		push bc
		ld hl,(file_size)		; subtract 256 bytes from file size
		ld bc,$100
		xor a
		sbc hl,bc
		ld (file_size),hl
		ex de,hl
		ld bc,0
		ld hl,(file_size+2)
		sbc hl,bc
		ld (file_size+2),hl
		pop bc
		jr c,file_sent			; if carry or size, send is complete
		ld a,h
		or l
		or d
		or e
		jr z,file_sent
		djnz sloop
		jr send_loop

	
file_sent	ld hl,ok_txt
		call kjt_print_string
		xor a
		ret
		
	
;======== FLOS protocol RS232 Send File Routines ==================================================


send_serial_block

		push ix
		ld b,0				;sends a 256 byte block (from IX) and its 2 byte checksum
s_sblklp	ld a,(ix)
		call kjt_serial_tx_byte
		inc ix
		djnz s_sblklp
		
		pop de				;retreive start loc of data into DE for CRC compute routine
		ld c,0
		call crc_checksum
		ld a,l
		call kjt_serial_tx_byte
		ld a,h
		call kjt_serial_tx_byte
		

s_waitack	ld a,$c5
		call kjt_serial_rx_byte		; wait to receive "OK" acknowledge
		jr c,ack_bad
		ld b,a
		ld a,$c5
		call kjt_serial_rx_byte
		jr c,ack_bad
		ld c,a
		ld h,"O"
		ld l,"K"
		xor a
		sbc hl,bc			; zero flag set on return if OK received
		ret z
		ld a,$11			; bad ack received  ($11:"comms error")

ack_bad		or a
		ret
		

;--------------------------------------------------------------------------------------------

clear_load_buffer

		ld hl,load_buffer
		ld (hl),0
		push hl
		pop de
		inc de
		ld bc,buffer_size-1
		ldir
		ret


;--------------------------------------------------------------------------------------------

; makes checksum in HL, src addr = DE, length = C bytes

crc_checksum

		ld hl,$ffff		
crcloop		ld a,(de)			
		xor h			
		ld h,a			
		ld b,8
crcbyte		add hl,hl
		jr nc,crcnext
		ld a,h
		xor 10h
		ld h,a
		ld a,l
		xor 21h
		ld l,a
crcnext		djnz crcbyte
		inc de
		dec c
		jr nz,crcloop
		ret


;--------------------------------------------------------------------------------------

show_use	ld hl,usage_txt
		call kjt_print_string
		xor a
		ret

;--------------------------------------------------------------------------------------
		
include "FLOS_based_programs\code_library\string\inc\extract_path_and_filename.asm"

include "FLOS_based_programs\code_library\loading\inc\save_restore_dir_vol.asm"

;--------------------------------------------------------------------------------------

			
;=============================================================================================

usage_txt	db "FTX - V1.02 Send a file from disk",11
		db "using Serial Link protocol.",11,11
		db "Usage: FTX filename",11,0

sending_txt	db "Sending.. ",0				
ok_txt		db "OK",11,0

;---------------------------------------------------------------------------------------------

serial_header	

sh_filename	ds 16,0
file_size	dw 0,0
serial_h_txt	db "Z80P.FHEADER"
remaining	ds $e0,0

;---------------------------------------------------------------------------------------------

load_buffer	db 0

;=============================================================================================
