;=======================================================================================
;
; SERIAL COPY V2.0
;
; Receives multiple files from serial port, writes them to current disk directory
; No max file length, uses append file feature of FLOS 521
;
;=======================================================================================


;---Standard header for OSCA and OS ----------------------------------------

include "kernal_jump_table.asm"
include "OSCA_hardware_equates.asm"
include "system_equates.asm"

	org $5000

;=======================================================================================

	call kjt_get_version		; check running under FLOS v521+ 
	ld de,$521
	xor a
	sbc hl,de
	jr nc,flos_ok
	ld hl,bad_flos_txt
	call kjt_print_string
	xor a
	ret
	
flos_ok	call kjt_clear_screen
	ld hl,start_text
	call kjt_print_string
	in a,(sys_serial_port)		; flush serial buffer at prog start



wait_file	ld hl,waiting_text
	call kjt_print_string

recwloop	call receive_block
	jr nc,s_gbfhok			; if carry set = there was an error (code in A)
	cp $14				; if its a time out error, just wait again..
	jr nz,s_nfhdr			; after checking for quit via ESC key
	call kjt_get_key			
	cp $76
	jr nz,recwloop	
	xor a				
	ret
s_nfhdr	push af				
	call s_badack			; tell the sender that the header was rejected
	call serial_error
	pop af				; and quit
	or a
	ret

s_gbfhok	ld hl,serial_headertag		; Check to make sure rec'd block is tagged as a header block
	ld de,rx_sector_buffer+20		; check ASCII chars 
	ld b,12
	call kjt_compare_strings	
	jr nc,s_nfhdr
	ld b,256-32			; bytes 32-256 should be zero
	ld hl,rx_sector_buffer+32
s_chdr	ld a,(hl)
	inc hl
	or a
	jr nz,s_nfhdr
	djnz s_chdr

	ld hl,rx_sector_buffer
	ld de,serial_filename		; Convert filename to uppercase	
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

	ld hl,serial_filename		; filename location
	ld ix,$5000			; use default reload location: $5000
	ld b,0				; and load bank 0
	call kjt_create_file		; create the file stub
	jr z,fc_ok			
	push af
	call s_badack
	call save_error			; quit on error
	pop af
	ret
	
fc_ok	ld hl,receiving_text		; say "Receiving [filename]"
	call kjt_print_string
	ld hl,serial_filename
	call kjt_print_string
	ld hl,cr_txt
	call kjt_print_string

	ld de,(rx_sector_buffer+16)
	ld hl,(rx_sector_buffer+18)
	ld (len_lo),de
	ld (len_hi),hl

buff_lp	ld de,(len_lo)			; length of file low
	ld hl,(len_hi)			; length of file high
	ld iy,load_buffer			; $7e00 byte buffer
	ld c,$7e
rx_filelp	call s_goodack			; prompt sender for a file block
	call receive_block			; get block of file data
	jp c,s_nfhdr			; if carry set = there was an error (code in A)
	ld ix,rx_sector_buffer		; copy sector buffer to load buffer
	ld b,0
scopylp	ld a,(ix)
	ld (iy),a
	inc ix
	inc iy
	dec de				; countdown file length
	ld a,e
	and d
	inc a
	jr nz,s_rfmb
	dec hl
s_rfmb	ld a,e				
	or d
	or l
	or h
	jr z,all_bytes_rec			; if zero, last byte
	djnz scopylp			
	dec c				
	jr nz,rx_filelp			; loop to next block of load buffer

	ld (len_lo),de			; reduce length of file
	ld (len_hi),hl
	ld de,$7e00
	ld c,0				; C,DE = File lenth
	ld b,0				; B = bank 0
	ld ix,load_buffer			; IX = source address
	ld hl,serial_filename		; HL = filename
	call kjt_write_bytes_to_file		; write $7e00 bytes max to file
	jr z,buff_lp			
ffb_bad	push af
	call s_badack			; quit on error
	call save_error
	pop af
	ret
	

all_bytes_rec


	push iy
	pop hl
	ld de,load_buffer
	xor a
	sbc hl,de
	ex de,hl
	ld c,0				; C,DE = File length
	ld b,0				; B = bank 0
	ld ix,load_buffer			; IX = source address
	ld hl,serial_filename		; HL = filename
	call kjt_write_bytes_to_file		; write $7e00 bytes max to file
	jr nz,ffb_bad			
	call s_goodack
	ld hl,saved_text
	call kjt_print_string
	jp wait_file
	

serial_error

	ld hl,serial_error_text
	call kjt_print_string
	xor a
	ret

save_error

	ld hl,save_error_text
	call kjt_print_string
	xor a
	ret	
	
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
s_lgb	ld a,1
	call kjt_serial_rx_byte
	jr c,s_gbtoerr			; timed out if carry = 1	
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
	jr c,s_gbtoerr
	ld c,a
	call kjt_serial_rx_byte	
	jr c,s_gbtoerr		
	ld b,a
	
	xor a				; compare checksum
	sbc hl,bc
	jr z,s_gbcsok
	ld a,$0f				;A=$0f : bad checksum
	scf
s_gberr	pop bc
	pop de
	pop hl
	ret

s_gbtoerr ld a,$14				;A=$14 : time out
	scf
	jr s_gberr
	
s_gbcsok	xor a				;A=$00 : all ok
	jr s_gberr

;----------------------------------------------------------------------------------

s_goodack	ld a,"O"				; send "OK" ack to start file TX
	call kjt_serial_tx_byte
	ld a,"K"
	call kjt_serial_tx_byte
	ret

;----------------------------------------------------------------------------------
		
s_badack	ld a,"X"				; send "bad ack" to stop file TX
	call kjt_serial_tx_byte
	ld a,"X"
	call kjt_serial_tx_byte	
	ret

;----------------------------------------------------------------------------------

start_text	db 11,"**************************************",11
		db    "*          Serial copy v2.0          *",11
		db    "* Copies multiple files from serial  *",11
		db    "* link to disk. Hold ESC key to quit *",11 
		db    "**************************************",11,11,0
		
waiting_text	db "Waiting for file..",11,0		

receiving_text	db "Receiving: ",0
saved_text	db "OK, File saved to disk..",11,11,0

cr_txt		db 11,0

serial_error_text	db "Serial error!",11,11,0

save_error_text	db "Save error!",11,11,0

bad_flos_txt	db "Error: Requires FLOS v5.21+",11,11,0

serial_headertag	db "Z80P.FHEADER"		;12 chars

serial_filename   	ds 18,0
len_lo		dw 0
len_hi		dw 0

rx_sector_buffer	ds 256,0
load_buffer	db 0			; Dont put anything after this - $7e00 byte buffer

;------------------------------------------------------------------------------------------------
	