;=======================================================================================
; SERIAL LINK DIAG 0.02
;=======================================================================================

;---Standard header for OSCA and OS ----------------------------------------

include "equates\kernal_jump_table.asm"
include "equates\OSCA_hardware_equates.asm"
include "equates\system_equates.asm"

;======================================================================================
; MAIN PROGRAM CODE STARTS HERE
;======================================================================================

rx_sector_buffer equ $ff00

	org $5000
	
start	call kjt_clear_screen
	ld hl,start_text
	call kjt_print_string
	in a,(sys_serial_port)		; flush serial buffer at prog start

	ld hl,baud_lo_text
	ld a,(baud)
	out (sys_baud_rate),a
	or a
	jr z,baudlo
	ld hl,baud_hi_text
baudlo	call kjt_print_string
	
;---------------------------------------------------------------------------------------

mainloop	ld hl,menu_text
	call kjt_print_string

	call kjt_wait_key_press
	cp $76
	jr nz,notquit
	xor a
	ret

notquit	ld a,b
	cp "1"
	jp z,baud_hi
	cp "2"
	jp z,baud_lo
	cp "3"
	jp z,rec_test
	cp "4"
	jp z,rx_byte_test
	cp "5"
	jp z,send_string
	jp mainloop

;---------------------------------------------------------------------------------------
	
baud_hi	ld a,1
	ld (baud),a
	jp start

;---------------------------------------------------------------------------------------


baud_lo	ld a,0
	ld (baud),a
	jp start

;---------------------------------------------------------------------------------------
	
rec_test	ld hl,waiting_text
	call kjt_print_string

recwloop	call receive_block
	jr nc,s_gbfhok			; if carry set = there was an error (code in A)
	cp $14				; if its a time out error, just wait again..
	jr z,recwloop			
	cp $2a				; if its a quit with key error, quit the op
	jr z,mainloop
s_nfhdr	push af				; else its some other serial error..
	call s_badack			; tell the sender that the header was rejected
	pop af				
	ld hl,checksum_text
	cp $0f
	jr goterr
	ld hl,error_byte_text
	call kjt_hex_byte_to_ascii
	ld hl,error_text
goterr	call kjt_print_string
	jp save_data
badheader	ld hl,bad_header_text
	jr goterr

	
s_gbfhok	ld hl,serial_headertag		; Check to make sure rec'd block is tagged as a header block
	ld de,rx_sector_buffer+20		; check ASCII chars 
	ld b,12
	call kjt_compare_strings	
	jr nc,badheader
	ld b,256-32			; bytes 32-256 should be zero
	ld hl,rx_sector_buffer+32
s_chdr	ld a,(hl)
	inc hl
	or a
	jr nz,badheader
	djnz s_chdr

	ld hl,rx_sector_buffer
	ld de,filename			; Convert filename to uppercase	
	ld b,16				; and ensure null terminated
s_tuclp	ld a,(hl)				
	cp $21
	jr c,s_ffhswz	
	cp $61
	jr c,s_notuc
	sub $20
s_notuc	ld (de),a
	inc hl
	inc de
	djnz s_tuclp
	ld b,1
s_ffhswz	xor a
	ld (de),a
	inc de
	djnz s_ffhswz	

	ld hl,receiving_text		; say "Checking receiption of [filename]"
	call kjt_print_string
	ld hl,filename
	call kjt_print_string
	ld hl,cr_text
	call kjt_print_string

	ld hl,(rx_sector_buffer+16)
	ld de,(rx_sector_buffer+18)
buff_lp	ld (len_lo),hl
	ld (len_hi),de
	ld a,d
	or e
	or h
	or l
	jr z,albldone

	call s_goodack			; prompt sender for a file block
	call receive_block			; get block of file data
	jp c,s_nfhdr			; if carry set = there was an error (code in A)

	ld hl,dot_text
	call kjt_print_string

	ld de,(len_hi)			; length of file low
	ld hl,(len_lo)
	ld bc,256
	xor a
	sbc hl,bc
	jr nc,buff_lp
	ex de,hl
	ld bc,1
	xor a
	sbc hl,bc
	ex de,hl
	jr nc,buff_lp

albldone	call s_goodack
	ld hl,ok_text
	call kjt_print_string
	call kjt_wait_key_press
	jp mainloop
	

save_data	
	
	ld a,(calc_crc+1)			; show the CRCs of the last received block
	ld hl,crc_text1
	call kjt_hex_byte_to_ascii
	ld a,(calc_crc)
	call  kjt_hex_byte_to_ascii
	ld a,(rec_crc+1)
	ld hl,crc_text2
	call  kjt_hex_byte_to_ascii
	ld a,(rec_crc)
	call  kjt_hex_byte_to_ascii
	ld hl,crc_text
	call kjt_print_string
	
	ld hl,save_text
	call kjt_print_string
	call kjt_wait_key_press
	ld a,b
	cp "y"
	jp nz,mainloop

	ld hl,save_filename			; filename location
	call kjt_create_file		; create the file stub
	jr z,fc_ok			
	cp $9
	jr nz,ovwr_file			; does file already exist?

	ld hl,overwrite_text		; ask if want to overwrite
	call kjt_print_string
	call kjt_wait_key_press
	cp $35
	jr z,ovwr_file
	ld hl,aborted_text
	call kjt_print_string
	jp mainloop	

ovwr_file	ld hl,save_filename			;remove existing file
	call kjt_erase_file
	ret nz
	ld hl,save_filename			;create a new file header
	call kjt_create_file		
	ret nz
	
fc_ok	ld c,$0				; C,DE = File length
	ld de,$100
	ld b,0				; B = bank
	ld ix,rx_sector_buffer		; IX = source address
	ld hl,save_filename			; HL = filename
	call kjt_write_bytes_to_file		; write bytes to file
	ret nz			
	ld hl,saved_text
	call kjt_print_string
	jp mainloop
		
	
;-------------------------------------------------------------------------------------------------

receive_block

	push hl
	push de
	push bc
	ld hl,rx_sector_buffer		; load a block of 256 bytes
	ld b,0
	exx
	ld hl,$ffff			; CRC checksum
	exx
s_lgb	ld a,$81
	call kjt_serial_rx_byte
	jr c,s_gberr			; timed out if carry = 1	
	ld (hl),a
	exx
	xor h				; do CRC calculation		
	ld h,a			
	ld b,8
rxcrcbyte	add hl,hl
	jr nc,rxcrcnext
	ld a,h
	xor 10h
	ld h,a
	ld a,l
	xor 21h
	ld l,a
rxcrcnext	djnz rxcrcbyte
	exx
	inc hl
	djnz s_lgb
	exx				; hl = calculated CRC

	call kjt_serial_rx_byte		; get 2 more bytes - block checksum in bc
	jr c,s_gberr
	ld c,a
	call kjt_serial_rx_byte	
	jr c,s_gberr		
	ld b,a
	
	ld (calc_crc),hl
	ld (rec_crc),bc
	xor a				; compare checksum
	sbc hl,bc
	jr z,s_gbcsok
	ld a,$0f				;A=$0f : bad checksum
	scf
s_gberr	pop bc
	pop de
	pop hl
	ret

s_gbcsok	xor a				;A=$00 : all ok
	jr s_gberr

;----------------------------------------------------------------------------------

s_goodack	ld a,"O"				; send "OK" ack to start file 
	call kjt_serial_tx_byte
	ld a,"K"
	call kjt_serial_tx_byte
	ret

		
s_badack	ld a,"X"				; send "bad ack" to stop file 
	call kjt_serial_tx_byte
	ld a,"X"
	call kjt_serial_tx_byte	
	ret

;----------------------------------------------------------------------------------

rx_byte_test

	ld hl,show_bytes_text
	call kjt_print_string
	
rx_loop	ld a,$8a			;wait 10 seconds (quit if ESC pressed)
	call kjt_serial_rx_byte
	jr nc,rx_byte		;if carry clear, received a byte
	cp $2a
	jp z,mainloop
	jr rx_loop
	
rx_byte	ld hl,hex_text+1
	call kjt_hex_byte_to_ascii
	ld hl,hex_text
	call kjt_print_string
	jr rx_loop


;----------------------------------------------------------------------------------

send_string

	ld hl,prompt_txt
	call kjt_print_string

	ld a,40
	call kjt_get_input_string
	or a
	jr z,endss

	ld b,a

comlp	ld a,(hl)
	or a
	jr z,endss
	
	push bc
	push hl
	call kjt_serial_tx_byte
	pop hl
	pop bc
	
	inc hl
	djnz comlp
	
endss	jp start

;----------------------------------------------------------------------------

prompt_txt	db "Enter a string to send and press ENTER",11,11,0

serial_headertag	db "Z80P.FHEADER"		;12 chars

start_text	db "Serial link diagnostic tool v0.01",11,11,0

menu_text		db 11,11,"Press:",11,11
		db "1 - BAUD = 115200",11,"2 - BAUD = 57600",11
		db "3 - Test file transfer - receive",11
		db "4 - Display individual bytes received",11
		db "5 - Send text string to serial port",11,11,0
		db "ESC - quit",11,11,0

waiting_text	db "Waiting for serial file transfer..",11,0
		
baud_lo_text	db "BAUD = 57600",0
baud_hi_text	db "BAUD = 115200",0

baud		db 1

ok_text		db 11,11,"Transfer OK. Press a key.",11,11,0

checksum_text	db "Checksum bad.",11,11,0

save_text		db "Save serial block buffer?",0

save_filename	db "serblock.bin",0

overwrite_text	db "Overwrite existing file?",0

error_text	db "Error code:$"
error_byte_text	db "--",11,11,0

calc_crc		dw 0
rec_crc		dw 0

crc_text		db "Calculated CRC: $"
crc_text1		db "----"
		db " Sent CRC: $"
crc_text2		db "----",11,11,0

saved_text	db 11,11,"Serial block saved (serblock.bin)",11,11,0

bad_header_text	db "Bad header block..",11,11,0

receiving_text	db 11,"Checking reception of:",0

cr_text		db 11,11,0

dot_text		db ".",0

aborted_text	db 11,11,"File was not saved",11,11,0

len_lo		dw 0
len_hi		dw 0

show_bytes_text	db "Bytes received: (ESC to quit)",11,11,0
hex_text		db "$-- ",0

filename		db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0

;------------------------------------------------------------------------------------------------
	