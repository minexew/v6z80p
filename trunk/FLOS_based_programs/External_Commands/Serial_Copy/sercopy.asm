;=======================================================================================
;
; SERIAL COPY V2.2 - Receives multiple files from serial port, writes to current disk directory
;
; v2.1 - Prompts to overwrite duplicate file
;      - Loads to $78000 in sys RAM
; v2.2 - Check serial filename for "exit command". Exit to FLOS if command is founded. (Valen)
;
;=======================================================================================

;---Standard header for OSCA and OS ----------------------------------------

include "kernal_jump_table.asm"
include "OSCA_hardware_equates.asm"
include "system_equates.asm"

;======================================================================================
; Program Location File Header:
; FLOS v568+ will use this data to load the program a specific location
; Earlier versions of FLOS will ignore it and load the program to $5000
;======================================================================================

my_location	equ $8000
my_bank		equ $0e


	org my_location	; desired load address
	
load_loc	db $ed,$00	; header ID (Invalid Z80 instruction)
	jr exec_addr	; jump over remaining header data
	dw load_loc	; location file should load to
	db my_bank	; upper bank the file should load to
	db 0		; dont truncate the program load

exec_addr	


;=======================================================================================	
; Location Check:
; As an earlier version of FLOS may have loaded the program, or it has
; simply been loaded into memory somwhere as a binary file we can check to
; see if it is in the desired location before the main code attempts to run.
;=======================================================================================

	push hl		; Tests to see if code is located in the correct place to run
	ld hl,sector_buffer	; use sector buffer location 0 for the test routine
	ld a,(hl)		; preserve the byte that was there
	ld (hl),$c9	; place a RET instruction there	
	call sector_buffer	; Call the RET, PC of true_loc is pushed on stack and returns back here
true_loc	ld (hl),a		; put the preserved byte back where RET was placed
	ld ix,0		
	add ix,sp		; get SP in IX
	ld l,(ix-2)	; HL = PC of true_loc from stack (load_loc + 8 + 11)
	ld h,(ix-1)
	ld de,true_loc-load_loc
	xor a
	sbc hl,de		; HL = actual location that program was loaded to
	push hl
	pop ix		
	ld e,(ix+4)
	ld d,(ix+5)	; DE = address where program is SUPPOSED to be located
	xor a
	sbc hl,de		; are we in the right place?
	pop hl	
	jr z,loc_ok	
	push ix		; No, so show an error message (using relative addressing)
	pop hl
	ld de,locer_txt-load_loc
	add hl,de
	call kjt_print_string
	xor a	
	ret

locer_txt	db "Program cannot run from this location.",11,0	

loc_ok	


;--------- Test FLOS version -----------------------------------------------------------


required_flos equ $578


	push hl
	call kjt_get_version	
	ld de,required_flos 	
	xor a
	sbc hl,de
	pop hl
	jr nc,flos_ok
	ld hl,old_flos_txt
	call kjt_print_string
	ld hl,hex_txt
	push hl
	ld a,d
	call kjt_hex_byte_to_ascii
	ld a,e
	call kjt_hex_byte_to_ascii
	pop hl
	inc hl
	call kjt_print_string
	xor a
	ret

old_flos_txt

	db "Program requires FLOS v",0
hex_txt	db "----+",11,11,0

flos_ok


;======================================================================================
; MAIN PROGRAM CODE STARTS HERE
;======================================================================================

load_buffer_length equ $7800


	call kjt_clear_screen
	ld hl,start_text
	call kjt_print_string
	in a,(sys_serial_port)		; flush serial buffer at prog start

;---------------------------------------------------------------------------------------


wait_file	ld hl,waiting_text
	call kjt_print_string

recwloop	call receive_block
	jr nc,s_gbfhok			; if carry set = there was an error (code in A)
	cp $14				; if its a time out error, just wait again..
	jr z,recwloop			
	cp $2a				; if its a quit with key error, quite the prog
	jr nz,s_nfhdr
	xor a				
	ret
s_nfhdr	push af				; else its some other serial error..
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

	ld hl,serial_filename		; filename
        call is_command_exit            ; check filename for command 
        jr nc,not_a_exit_command        ; if CF=1, quit (exit command is present in filename)
        call s_badack                   ; drop serial connection
        ret

not_a_exit_command
	ld hl,receiving_text		; say "Receiving [filename]"
	call kjt_print_string
	ld hl,serial_filename
	call kjt_print_string
	ld hl,cr_txt
	call kjt_print_string

	ld hl,serial_filename		; filename location
	call kjt_create_file		; create the file stub
	jr z,fc_ok			
	cp $9
	jr z,fexists			; does file already exist?
	push af
	call s_badack
	call save_error			; quit on error
	pop af
	ret

fexists	call s_waitack
	ld hl,overwrite_text		; ask if want to overwrite
	call kjt_print_string
	call kjt_wait_key_press
	cp $35
	jr z,ovwr_file
	call s_badack
	ld hl,aborted_text
	call kjt_print_string
	jp wait_file	

ovwr_file	ld hl,serial_filename		;remove existing file
	call kjt_erase_file
	ret nz
	ld hl,serial_filename		;create a new file header
	call kjt_create_file		
	ret nz
	ld hl,ok_overwrite_text
	call kjt_print_string
		
fc_ok	ld de,(rx_sector_buffer+16)
	ld hl,(rx_sector_buffer+18)
	ld (len_lo),de
	ld (len_hi),hl

buff_lp	ld de,(len_lo)			; length of file low
	ld hl,(len_hi)			; length of file high
	ld iy,load_buffer			; load buffer pages
	ld c,load_buffer_length/256
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
	ld de,load_buffer_length
	ld c,0				; C,DE = File lenth
	ld b,my_bank			; B = bank
	ld ix,load_buffer			; IX = source address
	ld hl,serial_filename		; HL = filename
	call kjt_write_bytes_to_file		; write buffer bytes to file
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
	ld b,my_bank			; B = bank
	ld ix,load_buffer			; IX = source address
	ld hl,serial_filename		; HL = filename
	call kjt_write_bytes_to_file		; write bytes to file
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


s_waitack	ld a,"W"				; send "wait ack" to pause file 
	call kjt_serial_tx_byte
	ld a,"W"
	call kjt_serial_tx_byte	
	ret


; Search exit command in string and set CF if command was found.
; Input:
; HL - string to search command (e.g. filename)
; Output: 
; CF=1, exit command is found in string
; CF=0, not found
is_command_exit            
        push de
        push bc
        ld de,internal_command_exit
        ld b,8+1+3+1                    ; e.g. "12345678.EXT",0
        call compare_strings 

        pop bc
        pop de
        ret


compare_strings 
; (copy'n'paste from FLOSxxx.asm)
;
; both strings should be zero terminated.
; compare will fail if string lengths are different
; unless count (b) is reached
; carry flag set on return if same

	push hl			;set de = source string
	push de			;set hl = compare string
ocslp	ld a,(de)			;b = max chars to compare
	or a
	jr z,ocsbt
	cp (hl)
	jr nz,ocs_diff
	inc de
	inc hl
	djnz ocslp
	jr ocs_same
ocsbt	ld a,(de)			;check both strings at termination point
	or (hl)
	jr nz,ocs_diff
ocs_same	pop de
	pop hl
	scf			; carry flag set if same		
	ret
ocs_diff	pop de
	pop hl
	xor a			; carry flag zero if different	
	ret


;----------------------------------------------------------------------------------
internal_command_exit    
                db "EXIT.---",0         ; command, to exit sercopy

start_text	db 11," *************************************",11
		db    " *          Serial copy v2.2         *",11
		db    " * Copies multiple files from serial *",11
		db    " * link to disk.    ESC key to quit. *",11 
		db    " *************************************",11,11,0
		
waiting_text	db "Waiting for file..",11,0		

overwrite_text	db "File exists. Overwrite (y/n)",11,0

aborted_text	db "File dismissed.",11,11,0

ok_overwrite_text	db "Overwriting file..",11,0

receiving_text	db "Receiving: ",0
saved_text	db "OK, File saved to disk..",11,11,0

cr_txt		db 11,0

serial_error_text	db 11,11,"** Serial error! **",11,11,0

save_error_text	db 11,11,"** Save error! **",11,11,0

serial_headertag	db "Z80P.FHEADER"		;12 chars

serial_filename   	ds 18,0
len_lo		dw 0
len_hi		dw 0

rx_sector_buffer	ds 256,0
load_buffer	db 0			; Dont put anything after this - $7800 byte buffer

;------------------------------------------------------------------------------------------------
	